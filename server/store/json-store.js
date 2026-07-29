import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CommunityJsonStore } from './community-json-store.js';
import {
  approvedCoursesFromCatalog,
  createId,
  documentsFromCourses,
  hasApprovedLessonInCourses,
  isLearnerReadyCourse,
  normalizeApprovedCourse,
  normalizeContentDocument,
  normalizeEmail,
} from './utils.js';
import {
  createSessionToken,
  isSessionExpired,
  sessionExpiresAt,
} from './session-utils.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function jsonDataFilePath() {
  return (
    process.env.AJE_DATA_FILE ?? path.join(__dirname, '..', 'data.local.json')
  );
}

export class JsonStore {
  constructor({ catalog, filePath = jsonDataFilePath() }) {
    this.catalog = catalog;
    this.filePath = filePath;
    this.state = this.#load();
    this.#refreshBuiltInContent();
    this.community = new CommunityJsonStore(catalog, filePath, {
      persist: () => this.#saveAll(),
    });
    this.#syncCommunityFromFile();
  }

  catalogSnapshot() {
    return {
      courses: this.approvedContentCourses(),
      documents: this.approvedContentDocuments(),
      problemCategories: this.catalog.problemCategories,
      plans: this.activePlans(),
      communityPosts: this.community.communityPosts(),
    };
  }

  activePlans() {
    return this.state.plans
      .filter((plan) => plan.enabled)
      .sort((left, right) => left.sortOrder - right.sortOrder)
      .map((plan) => ({
        id: plan.id,
        title: plan.title,
        subtitle: plan.subtitle,
        price: `TZS ${plan.priceTzs.toLocaleString('en-US')}`,
        priceTzs: plan.priceTzs,
        durationDays: plan.durationDays,
        icon: plan.icon,
        recommended: plan.recommended,
      }));
  }

  async getPlan(planId) {
    return this.state.plans.find((plan) => plan.id === planId) ?? null;
  }

  // Staff pick a plan id; the price and duration always come from here, never
  // from request input.
  async recordPaymentRecord({
    userId,
    planId,
    method,
    amountTzs,
    currency = 'TZS',
    reference = null,
    note = null,
    recordedByUserId,
  }) {
    const plan = await this.getPlan(planId);
    if (!plan || !plan.enabled) return null;
    if (
      reference &&
      this.state.paymentRecords.some((item) => item.reference === reference)
    ) {
      const conflict = new Error('A payment with this reference already exists.');
      conflict.code = 'DUPLICATE_REFERENCE';
      throw conflict;
    }
    const now = new Date().toISOString();
    const record = {
      id: createId('payrec'),
      userId,
      planId,
      method,
      amountTzs,
      currency,
      reference,
      note,
      status: 'pending',
      recordedBy: recordedByUserId,
      approvedBy: null,
      approvedAt: null,
      reversedBy: null,
      reversedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.state.paymentRecords.push(record);
    this.#saveAll();
    return record;
  }

  async getPaymentRecord(paymentRecordId) {
    return (
      this.state.paymentRecords.find((item) => item.id === paymentRecordId) ??
      null
    );
  }

  // For the staff review queue: joins in the learner's email/display name so
  // the UI doesn't need a second lookup per row.
  async paymentRecordsForAdmin({ status, userId, limit = 50, offset = 0 } = {}) {
    const safeLimit = Math.max(1, Math.min(200, Number(limit) || 50));
    const safeOffset = Math.max(0, Number(offset) || 0);
    const filtered = this.state.paymentRecords
      .filter((item) => (status ? item.status === status : true))
      .filter((item) => (userId ? item.userId === userId : true))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));

    const usersById = new Map(this.state.users.map((user) => [user.id, user]));
    const records = filtered.slice(safeOffset, safeOffset + safeLimit).map((item) => {
      const user = usersById.get(item.userId);
      return {
        ...item,
        userEmail: user?.email ?? null,
        userDisplayName: user?.displayName ?? null,
      };
    });
    return { records, total: filtered.length };
  }

  // Idempotent: re-approving an already-approved record is a safe no-op — it
  // returns the existing record and entitlement rather than minting a second
  // grant of access. Not transactional in the JSON store (single in-process
  // writer, no concurrent clients), unlike the Postgres store's version.
  async approvePaymentRecord({ paymentRecordId, approvedByUserId, reason = null }) {
    const record = await this.getPaymentRecord(paymentRecordId);
    if (!record) return null;
    if (record.status !== 'pending') {
      return {
        paymentRecord: record,
        entitlement:
          this.state.entitlements.find(
            (item) => item.paymentRecordId === record.id,
          ) ?? null,
      };
    }

    const plan = await this.getPlan(record.planId);
    const now = new Date();
    const nowIso = now.toISOString();
    record.status = 'approved';
    record.approvedBy = approvedByUserId;
    record.approvedAt = nowIso;
    record.updatedAt = nowIso;

    const entitlement = {
      id: createId('ent'),
      userId: record.userId,
      planId: record.planId,
      paymentRecordId: record.id,
      status: 'active',
      grantedAt: nowIso,
      expiresAt: new Date(
        now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000,
      ).toISOString(),
      revokedAt: null,
      createdAt: nowIso,
      updatedAt: nowIso,
    };
    this.state.entitlements.push(entitlement);

    const user = await this.getUser(record.userId);
    if (user) {
      user.accountStatus = 'active';
      user.subscriptionPlan = plan.title;
      user.subscriptionStartedAt = nowIso;
      user.updatedAt = nowIso;
    }

    this.#appendAuditEvent({
      actorUserId: approvedByUserId,
      action: 'payment_approved',
      targetType: 'payment_record',
      targetId: record.id,
      previousStatus: 'pending',
      newStatus: 'approved',
      reason,
    });

    this.#saveAll();
    return { paymentRecord: record, entitlement };
  }

  // Idempotent for the same reason as approvePaymentRecord: reversing an
  // already-reversed record returns the current state rather than erroring
  // or double-writing history.
  async reversePaymentRecord({ paymentRecordId, actorUserId, reason = null }) {
    const record = await this.getPaymentRecord(paymentRecordId);
    if (!record) return null;
    if (record.status !== 'approved') {
      return { paymentRecord: record, entitlement: null };
    }

    const nowIso = new Date().toISOString();
    record.status = 'reversed';
    record.reversedBy = actorUserId;
    record.reversedAt = nowIso;
    record.updatedAt = nowIso;

    const entitlement = this.state.entitlements.find(
      (item) => item.paymentRecordId === record.id,
    );
    if (entitlement && entitlement.status === 'active') {
      entitlement.status = 'revoked';
      entitlement.revokedAt = nowIso;
      entitlement.updatedAt = nowIso;
    }

    const user = await this.getUser(record.userId);
    if (user) {
      // A learner can in principle hold more than one entitlement (e.g. two
      // approvals in quick succession); reversing one must not silently keep
      // showing its plan as active once it's the only one left standing.
      const remaining = this.state.entitlements.find(
        (item) => item.userId === user.id && item.status === 'active',
      );
      if (remaining) {
        const remainingPlan = await this.getPlan(remaining.planId);
        user.accountStatus = 'active';
        user.subscriptionPlan = remainingPlan?.title ?? null;
        user.subscriptionStartedAt = remaining.grantedAt;
      } else {
        user.accountStatus = 'suspended';
        user.subscriptionPlan = null;
        user.subscriptionStartedAt = null;
      }
      user.updatedAt = nowIso;
    }

    this.#appendAuditEvent({
      actorUserId,
      action: 'payment_reversed',
      targetType: 'payment_record',
      targetId: record.id,
      previousStatus: 'approved',
      newStatus: 'reversed',
      reason,
    });

    this.#saveAll();
    return { paymentRecord: record, entitlement: entitlement ?? null };
  }

  async entitlementsForUser(userId) {
    return this.state.entitlements.filter((item) => item.userId === userId);
  }

  async hasActiveEntitlement(userId) {
    const now = Date.now();
    return this.state.entitlements.some(
      (item) =>
        item.userId === userId &&
        item.status === 'active' &&
        Date.parse(item.expiresAt) > now,
    );
  }

  async auditEventsFor({ targetType, targetId }) {
    // Reversing insertion order rather than sorting by the millisecond-
    // precision createdAt string: two events (e.g. approve then reverse)
    // can land in the same millisecond, and a timestamp-string sort has no
    // way to break that tie correctly. Array push order already is true
    // chronological order and needs no tiebreak.
    return this.state.auditEvents
      .filter(
        (item) => item.targetType === targetType && item.targetId === targetId,
      )
      .reverse();
  }

  #appendAuditEvent({
    actorUserId,
    action,
    targetType,
    targetId,
    previousStatus = null,
    newStatus = null,
    reason = null,
    metadata = {},
  }) {
    this.state.auditEvents.push({
      id: createId('audit'),
      actorUserId,
      action,
      targetType,
      targetId,
      previousStatus,
      newStatus,
      reason,
      metadata,
      createdAt: new Date().toISOString(),
    });
  }

  approvedContentCourses() {
    return this.state.contentCourses
      .filter((item) => item.status === 'approved')
      .filter((item) => isLearnerReadyCourse(item.course))
      .map((item) => item.course);
  }

  contentCoursesForAdmin() {
    return this.state.contentCourses;
  }

  upsertContentCourse({
    course,
    status = 'approved',
    createOnly = false,
  }) {
    const normalizedCourse = normalizeApprovedCourse(course);
    if (
      createOnly &&
      this.state.contentCourses.some((item) => item.id === normalizedCourse.id)
    ) {
      const conflict = new Error('A course with this code already exists.');
      conflict.code = 'COURSE_ALREADY_EXISTS';
      throw conflict;
    }
    const record = {
      id: normalizedCourse.id,
      status,
      course: normalizedCourse,
      updatedAt: new Date().toISOString(),
    };
    this.state.contentCourses = this.state.contentCourses.filter(
      (item) => item.id !== record.id,
    );
    this.state.contentCourses.push(record);
    this.#saveAll();
    return record;
  }

  approvedContentDocuments() {
    return this.state.contentDocuments
      .filter((item) => item.status === 'approved')
      .map((item) => item.document);
  }

  contentDocumentsForAdmin() {
    return this.state.contentDocuments;
  }

  upsertContentDocument({ document, status = 'approved' }) {
    const normalizedDocument = normalizeContentDocument(document);
    const record = {
      id: normalizedDocument.id,
      status,
      document: normalizedDocument,
      updatedAt: new Date().toISOString(),
    };
    this.state.contentDocuments = this.state.contentDocuments.filter(
      (item) => item.id !== record.id,
    );
    this.state.contentDocuments.push(record);
    this.#saveAll();
    return record;
  }

  async getUser(userId) {
    return this.state.users.find((user) => user.id === userId);
  }

  async getUserByAuthUserId(authUserId) {
    if (!authUserId) return undefined;
    return this.state.users.find((user) => user.authUserId === authUserId);
  }

  async getUserByEmail(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) return undefined;
    return this.state.users.find(
      (user) => normalizeEmail(user.email) === normalizedEmail,
    );
  }

  // Called on every authenticated request with claims taken from the verified
  // Supabase JWT, never from request input. An account created before
  // Supabase Auth existed is matched by email and keeps its existing `id`, so
  // every row that already points at that id (progress, community posts,
  // moderation history) stays attached.
  async linkOrCreateUserForAuth({ authUserId, email }) {
    const normalizedEmail = normalizeEmail(email);
    const linked = await this.getUserByAuthUserId(authUserId);
    if (linked) {
      if (normalizedEmail && linked.email !== normalizedEmail) {
        linked.email = normalizedEmail;
        linked.updatedAt = new Date().toISOString();
        this.#saveAll();
      }
      return linked;
    }

    const existing = await this.getUserByEmail(normalizedEmail);
    if (existing) {
      existing.authUserId = authUserId;
      existing.email = normalizedEmail;
      existing.updatedAt = new Date().toISOString();
      this.#saveAll();
      return existing;
    }

    const now = new Date().toISOString();
    const user = {
      id: createId('user'),
      authUserId,
      email: normalizedEmail,
      phoneNumber: null,
      role: 'learner',
      accountStatus: 'pending_activation',
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.state.users.push(user);
    this.#saveAll();
    return user;
  }

  async setAccountStatus({ userId, accountStatus }) {
    const user = await this.getUser(userId);
    if (!user) return null;
    user.accountStatus = accountStatus;
    user.updatedAt = new Date().toISOString();
    this.#saveAll();
    return user;
  }

  async activateSubscription({ userId, planTitle }) {
    const user = await this.getUser(userId);
    if (!user) return null;
    user.subscriptionPlan = planTitle;
    user.subscriptionStartedAt = new Date().toISOString();
    user.accountStatus = 'active';
    user.updatedAt = user.subscriptionStartedAt;
    this.#saveAll();
    return user;
  }

  async cancelSubscription(userId) {
    const user = await this.getUser(userId);
    if (!user) return null;
    user.subscriptionPlan = null;
    user.subscriptionStartedAt = null;
    user.updatedAt = new Date().toISOString();
    this.#saveAll();
    return user;
  }

  async updateUserProfile(userId, { displayName, preferredLocation }) {
    const user = await this.getUser(userId);
    if (!user) return null;
    if (displayName !== undefined) {
      const trimmed = typeof displayName === 'string' ? displayName.trim() : '';
      user.displayName = trimmed.length > 0 ? trimmed : null;
    }
    if (preferredLocation !== undefined) {
      const trimmed =
        typeof preferredLocation === 'string' ? preferredLocation.trim() : '';
      user.preferredLocation = trimmed.length > 0 ? trimmed : null;
    }
    user.updatedAt = new Date().toISOString();
    this.#saveAll();
    return user;
  }

  async adminUsersForAdmin({ search = '', limit = 50, offset = 0 } = {}) {
    const query = String(search).trim().toLowerCase();
    const safeLimit = Math.max(1, Math.min(200, Number(limit) || 50));
    const safeOffset = Math.max(0, Number(offset) || 0);
    const activityByUser = new Map();
    const track = (userId, key) => {
      if (!userId) return;
      const current = activityByUser.get(userId) ?? {
        learningProgressCount: 0,
        paymentTransactionsCount: 0,
        notificationCount: 0,
        communityPostsCount: 0,
      };
      current[key] += 1;
      activityByUser.set(userId, current);
    };
    for (const item of this.state.learningProgress) {
      track(item.userId, 'learningProgressCount');
    }
    for (const item of this.state.paymentTransactions) {
      track(item.userId, 'paymentTransactionsCount');
    }
    for (const item of this.state.notifications) {
      track(item.userId, 'notificationCount');
    }
    for (const post of this.community.state.communityPosts) {
      if (typeof post.authorUserId === 'string' && post.authorUserId) {
        track(post.authorUserId, 'communityPostsCount');
      }
    }

    const sorted = [...this.state.users]
      .filter((user) => {
        if (!query) return true;
        return (
          String(user.email ?? '').toLowerCase().includes(query) ||
          String(user.displayName ?? '')
            .toLowerCase()
            .includes(query)
        );
      })
      .sort((left, right) => {
        const leftTs = Date.parse(left.updatedAt ?? left.createdAt ?? '');
        const rightTs = Date.parse(right.updatedAt ?? right.createdAt ?? '');
        return rightTs - leftTs;
      });

    const paged = sorted.slice(safeOffset, safeOffset + safeLimit).map((user) => {
      const activity = activityByUser.get(user.id) ?? {
        learningProgressCount: 0,
        paymentTransactionsCount: 0,
        notificationCount: 0,
        communityPostsCount: 0,
      };
      return {
        id: user.id,
        email: user.email ?? null,
        displayName: user.displayName ?? null,
        preferredLocation: user.preferredLocation ?? null,
        role: user.role ?? 'learner',
        accountStatus: user.accountStatus ?? 'pending_activation',
        subscriptionPlan: user.subscriptionPlan ?? null,
        subscriptionStartedAt: user.subscriptionStartedAt ?? null,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        ...activity,
      };
    });

    return { users: paged, total: sorted.length };
  }

  async notificationSettings(userId) {
    return (
      this.state.notificationSettings.find((item) => item.userId === userId) ?? {
        userId,
        enabled: true,
        communityReplies: true,
        moderationUpdates: true,
        learningReminders: true,
      }
    );
  }

  async updateNotificationSettings({ userId, settings }) {
    const current = await this.notificationSettings(userId);
    const next = {
      ...current,
      enabled:
        typeof settings.enabled === 'boolean' ? settings.enabled : current.enabled,
      communityReplies:
        typeof settings.communityReplies === 'boolean'
          ? settings.communityReplies
          : current.communityReplies,
      moderationUpdates:
        typeof settings.moderationUpdates === 'boolean'
          ? settings.moderationUpdates
          : current.moderationUpdates,
      learningReminders:
        typeof settings.learningReminders === 'boolean'
          ? settings.learningReminders
          : current.learningReminders,
      updatedAt: new Date().toISOString(),
    };
    this.state.notificationSettings =
      this.state.notificationSettings.filter((item) => item.userId !== userId);
    this.state.notificationSettings.push(next);
    this.#saveAll();
    return next;
  }

  async registerNotificationDevice({ userId, token, platform }) {
    const now = new Date().toISOString();
    const existing = this.state.notificationDevices.find(
      (item) => item.token === token,
    );
    if (existing) {
      existing.userId = userId;
      existing.platform = platform;
      existing.updatedAt = now;
      this.#saveAll();
      return existing;
    }
    const device = {
      id: createId('device'),
      userId,
      token,
      platform,
      createdAt: now,
      updatedAt: now,
    };
    this.state.notificationDevices.push(device);
    this.#saveAll();
    return device;
  }

  async notificationDevices(userId) {
    return this.state.notificationDevices.filter((item) => item.userId === userId);
  }

  async notificationsFor(userId) {
    return this.state.notifications
      .filter((item) => item.userId === userId)
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  async createNotification({ userId, type, title, body, data = {} }) {
    const settings = await this.notificationSettings(userId);
    if (!settings.enabled) return null;
    if (type === 'community_reply' && !settings.communityReplies) return null;
    if (type === 'moderation_update' && !settings.moderationUpdates) return null;
    const notification = {
      id: createId('notification'),
      userId,
      type,
      title,
      body,
      data,
      readAt: null,
      createdAt: new Date().toISOString(),
    };
    this.state.notifications.push(notification);
    this.#saveAll();
    return notification;
  }

  async markNotificationRead({ userId, notificationId }) {
    const notification = this.state.notifications.find(
      (item) => item.id === notificationId && item.userId === userId,
    );
    if (!notification) return null;
    notification.readAt = notification.readAt ?? new Date().toISOString();
    this.#saveAll();
    return notification;
  }

  async learningProgress(userId) {
    return this.state.learningProgress.filter((item) => item.userId === userId);
  }

  async markLessonCompleted({ userId, courseId, lessonId }) {
    if (
      !hasApprovedLessonInCourses(
        this.approvedContentCourses(),
        courseId,
        lessonId,
      )
    ) {
      return null;
    }
    const existing = this.state.learningProgress.find((item) => {
      return (
        item.userId === userId &&
        item.courseId === courseId &&
        item.lessonId === lessonId
      );
    });
    if (existing) return existing;
    const progress = {
      userId,
      courseId,
      lessonId,
      completedAt: new Date().toISOString(),
    };
    this.state.learningProgress.push(progress);
    this.#saveAll();
    return progress;
  }

  communityPosts() {
    return this.community.communityPosts();
  }

  async createPaymentTransaction(transaction) {
    this.state.paymentTransactions.push(transaction);
    this.#saveAll();
    return transaction;
  }

  async getPaymentTransaction(id) {
    return this.state.paymentTransactions.find((item) => item.id === id);
  }

  async markPaymentPaid(transactionId) {
    const transaction = await this.getPaymentTransaction(transactionId);
    if (!transaction) return null;
    if (transaction.status === 'paid') return transaction;

    const user = await this.activateSubscription({
      userId: transaction.userId,
      planTitle: transaction.planTitle,
    });
    transaction.status = 'paid';
    transaction.message = `Malipo yamethibitishwa kupitia ${transaction.method}.`;
    transaction.receiptNumber = `AJE-${transaction.id.slice(-6).toUpperCase()}`;
    transaction.subscriptionPlan = user.subscriptionPlan;
    transaction.subscriptionStartedAt = user.subscriptionStartedAt;
    this.#saveAll();
    return transaction;
  }

  async markPaymentFailed(transactionId, message) {
    const transaction = await this.getPaymentTransaction(transactionId);
    if (!transaction) return null;
    transaction.status = 'failed';
    transaction.message = message;
    this.#saveAll();
    return transaction;
  }

  createCommunityPost(payload) {
    return this.community.createCommunityPost(payload);
  }

  uploadCommunityPostImage(payload) {
    return this.community.uploadCommunityPostImage(payload);
  }

  addCommunityReply(payload) {
    return this.community.addCommunityReply(payload);
  }

  communityPostAuthorUserId(postId) {
    return this.community.communityPostAuthorUserId(postId);
  }

  reportCommunityPost(postId) {
    return this.community.reportCommunityPost(postId);
  }

  reportedCommunityPosts() {
    return this.community.reportedCommunityPosts();
  }

  resolveCommunityReport(payload) {
    return this.community.resolveCommunityReport(payload);
  }

  // Only used by the NODE_ENV=development dev-session issuer (see auth.js) so
  // local dev and the server test suite can authenticate without a real
  // Supabase Auth token. Production sessions come from Supabase JWTs and
  // never touch this table.
  async createAuthSession(userId) {
    await this.#purgeExpiredAuthSessions();
    const token = createSessionToken();
    const session = {
      token,
      userId,
      createdAt: new Date().toISOString(),
      expiresAt: sessionExpiresAt(),
    };
    this.state.authSessions.push(session);
    this.#saveAll();
    return session;
  }

  async getAuthSession(token) {
    await this.#purgeExpiredAuthSessions();
    const session = this.state.authSessions.find((item) => item.token === token);
    if (!session || isSessionExpired(session.expiresAt)) return null;
    return { userId: session.userId };
  }

  async #purgeExpiredAuthSessions() {
    this.state.authSessions = this.state.authSessions.filter(
      (item) => !isSessionExpired(item.expiresAt),
    );
  }

  #refreshBuiltInContent() {
    const now = new Date().toISOString();
    const builtInCourses = approvedCoursesFromCatalog(this.catalog);
    const builtInCourseIds = new Set(builtInCourses.map((course) => course.id));
    const existingById = new Map(
      this.state.contentCourses.map((record) => [record.id, record]),
    );
    this.state.contentCourses = [
      ...this.state.contentCourses.filter(
        (record) => !builtInCourseIds.has(record.id),
      ),
      ...builtInCourses.map((course) => {
        const existing = existingById.get(course.id);
        const existingVersion = Number(existing?.course?.contentVersion ?? 0);
        const builtInVersion = Number(course.contentVersion ?? 0);
        if (existing && existingVersion >= builtInVersion) return existing;
        return {
          id: course.id,
          status: 'approved',
          course,
          updatedAt: now,
        };
      }),
    ];

    const builtInDocuments = documentsFromCourses(builtInCourses);
    const legacyBuiltInDocumentIds = new Set([
      'mwongozo-mfupi-wa-pasheni',
      'ratiba-ya-chanjo',
      'udhibiti-wa-wadudu',
    ]);
    this.state.contentDocuments = [
      ...this.state.contentDocuments.filter(
        (record) =>
          !legacyBuiltInDocumentIds.has(record.id) ||
          !builtInCourseIds.has(record.document?.courseId),
      ),
      ...builtInDocuments.map((document) => ({
        id: document.id,
        status: 'approved',
        document,
        updatedAt: now,
      })),
    ];
  }

  #load() {
    if (!fs.existsSync(this.filePath)) {
      return initialMutableState();
    }

    try {
      const raw = fs.readFileSync(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      return normalizeMutableState(parsed);
    } catch (error) {
      throw new Error(
        `Failed to load AJE data store at ${this.filePath}: ${error.message}`,
      );
    }
  }

  #syncCommunityFromFile() {
    if (!fs.existsSync(this.filePath)) return;
    const parsed = JSON.parse(fs.readFileSync(this.filePath, 'utf8'));
    this.community.state = normalizeCommunityState(parsed, this.catalog);
  }

  #saveAll() {
    const nextState = {
      communityPosts: this.community.state.communityPosts,
      reportedPostIds: this.community.state.reportedPostIds,
      users: this.state.users,
      paymentTransactions: this.state.paymentTransactions,
      authSessions: this.state.authSessions,
      learningProgress: this.state.learningProgress,
      notificationSettings: this.state.notificationSettings,
      notificationDevices: this.state.notificationDevices,
      notifications: this.state.notifications,
      contentCourses: this.state.contentCourses,
      contentDocuments: this.state.contentDocuments,
      plans: this.state.plans,
      paymentRecords: this.state.paymentRecords,
      entitlements: this.state.entitlements,
      auditEvents: this.state.auditEvents,
    };
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    const tmpPath = `${this.filePath}.tmp`;
    fs.writeFileSync(tmpPath, JSON.stringify(nextState, null, 2));
    fs.renameSync(tmpPath, this.filePath);
  }
}

// Mirrors the `plans` seed in server/store/schema.sql so the JSON store
// (local dev, tests) and Postgres store expose identical plan ids/prices.
const PLAN_SEED = [
  {
    id: 'wiki-1',
    title: 'Wiki 1',
    subtitle: 'Ufikiaji wa haraka',
    priceTzs: 3000,
    durationDays: 7,
    icon: 'calendar_month',
    recommended: false,
    enabled: true,
    sortOrder: 1,
  },
  {
    id: 'mwezi-1',
    title: 'Mwezi 1',
    subtitle: 'Thamani bora zaidi',
    priceTzs: 10000,
    durationDays: 30,
    icon: 'star',
    recommended: true,
    enabled: true,
    sortOrder: 2,
  },
  {
    id: 'mwaka-1',
    title: 'Mwaka 1',
    subtitle: 'Okoa TZS 20,000',
    priceTzs: 100000,
    durationDays: 365,
    icon: 'trending_up',
    recommended: false,
    enabled: true,
    sortOrder: 3,
  },
];

function initialMutableState() {
  return {
    users: [],
    paymentTransactions: [],
    authSessions: [],
    learningProgress: [],
    notificationSettings: [],
    notificationDevices: [],
    notifications: [],
    contentCourses: [],
    contentDocuments: [],
    plans: PLAN_SEED.map((plan) => ({ ...plan })),
    paymentRecords: [],
    entitlements: [],
    auditEvents: [],
  };
}

function normalizeMutableState(raw) {
  const seed = initialMutableState();
  return {
    users: Array.isArray(raw.users) ? raw.users : seed.users,
    paymentTransactions: Array.isArray(raw.paymentTransactions)
      ? raw.paymentTransactions
      : seed.paymentTransactions,
    authSessions: Array.isArray(raw.authSessions)
      ? raw.authSessions
      : seed.authSessions,
    learningProgress: Array.isArray(raw.learningProgress)
      ? raw.learningProgress
      : seed.learningProgress,
    notificationSettings: Array.isArray(raw.notificationSettings)
      ? raw.notificationSettings
      : seed.notificationSettings,
    notificationDevices: Array.isArray(raw.notificationDevices)
      ? raw.notificationDevices
      : seed.notificationDevices,
    notifications: Array.isArray(raw.notifications)
      ? raw.notifications
      : seed.notifications,
    contentCourses: Array.isArray(raw.contentCourses)
      ? raw.contentCourses
      : seed.contentCourses,
    contentDocuments: Array.isArray(raw.contentDocuments)
      ? raw.contentDocuments
      : seed.contentDocuments,
    plans: Array.isArray(raw.plans) && raw.plans.length > 0
      ? raw.plans
      : seed.plans,
    paymentRecords: Array.isArray(raw.paymentRecords)
      ? raw.paymentRecords
      : seed.paymentRecords,
    entitlements: Array.isArray(raw.entitlements)
      ? raw.entitlements
      : seed.entitlements,
    auditEvents: Array.isArray(raw.auditEvents)
      ? raw.auditEvents
      : seed.auditEvents,
  };
}

function normalizeCommunityState(raw, catalog) {
  const seedPosts = catalog.communityPosts.map((post) => ({
    ...post,
    replies: post.replies.map((reply) => ({ ...reply })),
  }));
  const seedIds = new Set(seedPosts.map((post) => post.id));
  const legacySeedIds = new Set([
    'seed-pasheni-disease',
    'seed-kuku-start',
    'seed-nyanya-market',
  ]);
  const storedPosts = Array.isArray(raw.communityPosts)
    ? raw.communityPosts.filter(
        (post) => !seedIds.has(post.id) && !legacySeedIds.has(post.id),
      )
    : [];
  return {
    communityPosts: [...storedPosts, ...seedPosts],
    reportedPostIds: Array.isArray(raw.reportedPostIds)
      ? raw.reportedPostIds
      : [],
  };
}
