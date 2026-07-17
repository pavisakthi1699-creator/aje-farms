import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CommunityJsonStore } from './community-json-store.js';
import {
  approvedCoursesFromCatalog,
  createId,
  documentsFromCourses,
  hashOtp,
  hasApprovedLessonInCourses,
  isLearnerReadyCourse,
  normalizeApprovedCourse,
  normalizeContentDocument,
  normalizePhoneNumber,
  otpTtlMs,
  verifyOtpHash,
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
      plans: this.catalog.plans,
      communityPosts: this.community.communityPosts(),
    };
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

  upsertContentCourse({ course, status = 'approved' }) {
    const normalizedCourse = normalizeApprovedCourse(course);
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

  async getUser(phoneNumber) {
    return this.state.users.find(
      (user) => user.phoneNumber === normalizePhoneNumber(phoneNumber),
    );
  }

  async ensureUser(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const existing = await this.getUser(normalizedPhone);
    if (existing) return existing;

    const now = new Date().toISOString();
    const user = {
      id: createId('user'),
      phoneNumber: normalizedPhone,
      role: 'learner',
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.state.users.push(user);
    this.#saveAll();
    return user;
  }

  async activateSubscription({ phoneNumber, planTitle }) {
    const user = await this.ensureUser(phoneNumber);
    user.subscriptionPlan = planTitle;
    user.subscriptionStartedAt = new Date().toISOString();
    user.updatedAt = user.subscriptionStartedAt;
    this.#saveAll();
    return user;
  }

  async cancelSubscription(phoneNumber) {
    const user = await this.getUser(phoneNumber);
    if (!user) return null;
    user.subscriptionPlan = null;
    user.subscriptionStartedAt = null;
    user.updatedAt = new Date().toISOString();
    this.#saveAll();
    return user;
  }

  async updateUserProfile(phoneNumber, { displayName, preferredLocation }) {
    const user = await this.ensureUser(phoneNumber);
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
    const activityByPhone = new Map();
    const track = (phoneNumber, key) => {
      const current = activityByPhone.get(phoneNumber) ?? {
        learningProgressCount: 0,
        paymentTransactionsCount: 0,
        notificationCount: 0,
        communityPostsCount: 0,
      };
      current[key] += 1;
      activityByPhone.set(phoneNumber, current);
    };
    for (const item of this.state.learningProgress) {
      track(item.phoneNumber, 'learningProgressCount');
    }
    for (const item of this.state.paymentTransactions) {
      track(item.phoneNumber, 'paymentTransactionsCount');
    }
    for (const item of this.state.notifications) {
      track(item.phoneNumber, 'notificationCount');
    }
    for (const post of this.community.state.communityPosts) {
      if (typeof post.author === 'string' && post.author.startsWith('+')) {
        track(post.author, 'communityPostsCount');
      }
    }

    const sorted = [...this.state.users]
      .filter((user) => {
        if (!query) return true;
        return (
          String(user.phoneNumber).toLowerCase().includes(query) ||
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
      const activity = activityByPhone.get(user.phoneNumber) ?? {
        learningProgressCount: 0,
        paymentTransactionsCount: 0,
        notificationCount: 0,
        communityPostsCount: 0,
      };
      return {
        id: user.id,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName ?? null,
        preferredLocation: user.preferredLocation ?? null,
        role: user.role ?? 'learner',
        subscriptionPlan: user.subscriptionPlan ?? null,
        subscriptionStartedAt: user.subscriptionStartedAt ?? null,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        ...activity,
      };
    });

    return { users: paged, total: sorted.length };
  }

  async notificationSettings(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    return (
      this.state.notificationSettings.find(
        (item) => item.phoneNumber === normalizedPhone,
      ) ?? {
        phoneNumber: normalizedPhone,
        enabled: true,
        communityReplies: true,
        moderationUpdates: true,
        learningReminders: true,
      }
    );
  }

  async updateNotificationSettings({ phoneNumber, settings }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const current = await this.notificationSettings(normalizedPhone);
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
      this.state.notificationSettings.filter(
        (item) => item.phoneNumber !== normalizedPhone,
      );
    this.state.notificationSettings.push(next);
    this.#saveAll();
    return next;
  }

  async registerNotificationDevice({ phoneNumber, token, platform }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const now = new Date().toISOString();
    const existing = this.state.notificationDevices.find(
      (item) => item.token === token,
    );
    if (existing) {
      existing.phoneNumber = normalizedPhone;
      existing.platform = platform;
      existing.updatedAt = now;
      this.#saveAll();
      return existing;
    }
    const device = {
      id: createId('device'),
      phoneNumber: normalizedPhone,
      token,
      platform,
      createdAt: now,
      updatedAt: now,
    };
    this.state.notificationDevices.push(device);
    this.#saveAll();
    return device;
  }

  async notificationDevices(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    return this.state.notificationDevices.filter(
      (item) => item.phoneNumber === normalizedPhone,
    );
  }

  async notificationsFor(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    return this.state.notifications
      .filter((item) => item.phoneNumber === normalizedPhone)
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  async createNotification({ phoneNumber, type, title, body, data = {} }) {
    const settings = await this.notificationSettings(phoneNumber);
    if (!settings.enabled) return null;
    if (type === 'community_reply' && !settings.communityReplies) return null;
    if (type === 'moderation_update' && !settings.moderationUpdates) return null;
    const notification = {
      id: createId('notification'),
      phoneNumber: normalizePhoneNumber(phoneNumber),
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

  async markNotificationRead({ phoneNumber, notificationId }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const notification = this.state.notifications.find(
      (item) =>
        item.id === notificationId && item.phoneNumber === normalizedPhone,
    );
    if (!notification) return null;
    notification.readAt = notification.readAt ?? new Date().toISOString();
    this.#saveAll();
    return notification;
  }

  async learningProgress(phoneNumber) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    return this.state.learningProgress.filter(
      (item) => item.phoneNumber === normalizedPhone,
    );
  }

  async markLessonCompleted({ phoneNumber, courseId, lessonId }) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (
      !hasApprovedLessonInCourses(
        this.approvedContentCourses(),
        courseId,
        lessonId,
      )
    ) {
      return null;
    }
    await this.ensureUser(normalizedPhone);
    const existing = this.state.learningProgress.find((item) => {
      return (
        item.phoneNumber === normalizedPhone &&
        item.courseId === courseId &&
        item.lessonId === lessonId
      );
    });
    if (existing) return existing;
    const progress = {
      phoneNumber: normalizedPhone,
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

  async otpRequestDelaySeconds(phoneNumber, cooldownMs = 60 * 1000) {
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const now = Date.now();
    const latestChallenge = this.state.otpChallenges
      .filter((item) => item.phoneNumber === normalizedPhone)
      .map((item) => ({
        ...item,
        createdAt: item.createdAt ?? item.expiresAt - otpTtlMs,
      }))
      .sort((left, right) => right.createdAt - left.createdAt)[0];
    if (!latestChallenge) return 0;
    const nextAllowedAt = latestChallenge.createdAt + cooldownMs;
    return Math.max(0, Math.ceil((nextAllowedAt - now) / 1000));
  }

  async createOtpChallenge({ phoneNumber, otp, deliveryProvider }) {
    const now = Date.now();
    const challenge = {
      id: createId('otp'),
      phoneNumber: normalizePhoneNumber(phoneNumber),
      otpHash: hashOtp(otp),
      createdAt: now,
      expiresAt: now + otpTtlMs,
      deliveryProvider,
    };
    this.state.otpChallenges = this.state.otpChallenges.filter(
      (item) => item.expiresAt >= Date.now(),
    );
    this.state.otpChallenges.push(challenge);
    this.#saveAll();
    return challenge;
  }

  async consumeOtpChallenge({ challengeId, phoneNumber, otp }) {
    const challenge = this.state.otpChallenges.find(
      (item) => item.id === challengeId,
    );
    if (!challenge) return { status: 'missing' };
    if (challenge.expiresAt < Date.now()) {
      this.state.otpChallenges = this.state.otpChallenges.filter(
        (item) => item.id !== challengeId,
      );
      this.#saveAll();
      return { status: 'expired' };
    }
    const otpHash = challenge.otpHash ?? hashOtp(challenge.otp ?? '');
    if (
      challenge.phoneNumber !== phoneNumber ||
      !verifyOtpHash(otp, otpHash)
    ) {
      return { status: 'invalid' };
    }
    this.state.otpChallenges = this.state.otpChallenges.filter(
      (item) => item.id !== challengeId,
    );
    this.#saveAll();
    return { status: 'verified' };
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
      phoneNumber: transaction.phoneNumber,
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

  addCommunityReply(payload) {
    return this.community.addCommunityReply(payload);
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

  async createAuthSession(phoneNumber) {
    await this.#purgeExpiredAuthSessions();
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const token = createSessionToken();
    const session = {
      token,
      phoneNumber: normalizedPhone,
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
    return { phoneNumber: session.phoneNumber };
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
      otpChallenges: this.state.otpChallenges,
      paymentTransactions: this.state.paymentTransactions,
      authSessions: this.state.authSessions,
      learningProgress: this.state.learningProgress,
      notificationSettings: this.state.notificationSettings,
      notificationDevices: this.state.notificationDevices,
      notifications: this.state.notifications,
      contentCourses: this.state.contentCourses,
      contentDocuments: this.state.contentDocuments,
    };
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    const tmpPath = `${this.filePath}.tmp`;
    fs.writeFileSync(tmpPath, JSON.stringify(nextState, null, 2));
    fs.renameSync(tmpPath, this.filePath);
  }
}

function initialMutableState() {
  return {
    users: [],
    otpChallenges: [],
    paymentTransactions: [],
    authSessions: [],
    learningProgress: [],
    notificationSettings: [],
    notificationDevices: [],
    notifications: [],
    contentCourses: [],
    contentDocuments: [],
  };
}

function normalizeMutableState(raw) {
  const seed = initialMutableState();
  return {
    users: Array.isArray(raw.users) ? raw.users : seed.users,
    otpChallenges: Array.isArray(raw.otpChallenges)
      ? raw.otpChallenges
      : seed.otpChallenges,
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
