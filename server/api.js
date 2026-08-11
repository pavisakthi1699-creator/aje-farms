import express from 'express';

import { catalog } from './catalog.js';
import {
  isAllowlistedAdminEmail,
  userHasAdminAccess,
  userWithEffectiveRole,
  requireAdminSession,
  requireAuthSession,
} from './auth.js';
import { hasConfiguredGeminiApiKey } from './gemini-config.js';
import { chatWithMwalimuServer } from './mwalimu.js';
import { createNotificationProvider } from './notifications.js';
import { createPaymentProvider } from './payments.js';
import { createStore, resolveStoreConfig } from './store.js';
import {
  communityDisplayName,
  isValidCommunityImagePath,
  isValidLessonVideoPath,
  normalizeApprovedCourse,
  normalizeContentDocument,
  normalizeEmail,
  normalizeHomeTopics,
  normalizeCommunityTopics,
  defaultHomeTopics,
  legacyHomeTopics,
} from './store/utils.js';

function devModeEnabled() {
  return (
    ['development', 'test'].includes(process.env.NODE_ENV) &&
    process.env.AJE_ENABLE_DEBUG_OTP === 'true'
  );
}

function legacyDevelopmentPaymentsEnabled() {
  return (
    devModeEnabled() &&
    process.env.AJE_ENABLE_LEGACY_DEV_PAYMENTS === 'true'
  );
}

export async function registerApiRoutes(app) {
  const store = await createStore(catalog);
  const paymentProvider = createPaymentProvider();
  const notificationProvider = createNotificationProvider();

  app.get('/api/health/live', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/api/health', (_req, res) => {
    const storeConfig = resolveStoreConfig(process.env);
    const isProduction = process.env.NODE_ENV === 'production';
    const checks = {
      store: {
        mode: storeConfig.mode,
        schema: storeConfig.schema,
        ready:
          !['postgres', 'supabase'].includes(storeConfig.mode) ||
          Boolean(storeConfig.databaseUrl),
      },
      auth: {
        provider: 'supabase',
        ready:
          !isProduction ||
          Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY),
      },
      payments: {
        provider: 'manual',
        ready: true,
      },
      notifications: {
        provider: notificationProvider.name,
        ready: notificationProvider.isProductionReady || !isProduction,
      },
      ai: {
        provider: hasConfiguredGeminiApiKey() ? 'gemini' : 'knowledge-base',
        ready: true,
      },
    };
    const ready = Object.values(checks).every((check) => check.ready);
    res.status(ready ? 200 : 503).json({
      status: ready ? 'ok' : 'degraded',
      environment: process.env.NODE_ENV ?? 'development',
      checks,
    });
  });

  app.get(
    '/api/catalog',
    requireAuthSession(store),
    async (req, res) => {
      const snapshot = await store.catalogSnapshot();
      const compatibleSnapshot = withCompatibleHomeTopics(snapshot);
      if (await hasPaidLearningAccess(store, req.userId)) {
        res.json(compatibleSnapshot);
        return;
      }
      res.json(lockedCatalogSnapshot(compatibleSnapshot));
    },
  );

  // Resolves a lesson video to a short-lived signed URL. The player opens that
  // URL in an external viewer, which cannot carry an Authorization header, so
  // the session is enforced here and only the resolved URL is handed out.
  app.get(
    '/api/lessons/:lessonId/video-url',
    requireAuthSession(store),
    requirePaidLearningAccess(store),
    async (req, res) => {
      if (typeof store.lessonVideoUrl !== 'function') {
        res.status(404).json({ error: 'Video haipatikani.' });
        return;
      }
      const url = await store.lessonVideoUrl(req.params.lessonId);
      if (!url) {
        res.status(404).json({ error: 'Video haijachapishwa au haipatikani.' });
        return;
      }
      res.json({ url });
    },
  );

  app.get(
    '/api/lessons/:lessonId/video',
    requireAuthSession(store),
    requirePaidLearningAccess(store),
    async (req, res) => {
      if (typeof store.lessonVideoUrl !== 'function') {
        res.status(404).json({ error: 'Video haipatikani.' });
        return;
      }
      const url = await store.lessonVideoUrl(req.params.lessonId);
      if (!url) {
        res.status(404).json({ error: 'Video haijachapishwa au haipatikani.' });
        return;
      }
      res.redirect(302, url);
    },
  );

  // Source books stay in private storage. Paid learners receive a short-lived
  // URL only when the PDF is linked to a published reading lesson.
  app.get(
    '/api/lessons/:lessonId/source-url',
    requireAuthSession(store),
    requirePaidLearningAccess(store),
    async (req, res) => {
      if (typeof store.lessonSourceDocumentUrl !== 'function') {
        res.status(404).json({ error: 'Kitabu cha chanzo hakipatikani.' });
        return;
      }
      const url = await store.lessonSourceDocumentUrl(req.params.lessonId);
      if (!url) {
        res.status(404).json({
          error: 'Kitabu cha chanzo hakijachapishwa au hakipatikani.',
        });
        return;
      }
      res.json({ url });
    },
  );

  app.get(
    '/api/admin/content/courses',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json({ courses: await store.contentCoursesForAdmin() });
    },
  );

  app.put(
    '/api/admin/content/courses/:courseId',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const status = req.body.status ?? 'approved';
      const createOnly = req.body.createOnly ?? false;
      if (status !== 'draft' && status !== 'approved') {
        res.status(400).json({ error: 'Content status is invalid.' });
        return;
      }
      if (typeof createOnly !== 'boolean') {
        res.status(400).json({ error: 'createOnly must be a boolean.' });
        return;
      }
      try {
        const curriculumSchemaVersion =
          req.body.curriculumSchemaVersion ?? null;
        const baseUpdatedAt = req.body.baseUpdatedAt ?? null;
        if (
          curriculumSchemaVersion != null &&
          curriculumSchemaVersion !== 2
        ) {
          res.status(400).json({ error: 'Curriculum schema version is invalid.' });
          return;
        }
        if (
          curriculumSchemaVersion === 2 &&
          (typeof baseUpdatedAt !== 'string' ||
            Number.isNaN(Date.parse(baseUpdatedAt)))
        ) {
          res.status(400).json({
            error: 'Curriculum baseUpdatedAt is required.',
          });
          return;
        }
        const course = normalizeContentCourseRequest(
          req.params.courseId,
          req.body.course ?? req.body,
        );
        res.json({
          course: await store.upsertContentCourse({
            course,
            status,
            replaceCurriculum: curriculumSchemaVersion === 2,
            baseUpdatedAt,
            createOnly,
          }),
        });
      } catch (error) {
        const conflict =
          error?.code === 'CURRICULUM_CONFLICT' ||
          error?.code === 'COURSE_ALREADY_EXISTS';
        res.status(conflict ? 409 : 400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Course content is invalid.',
        });
      }
    },
  );

  // Hands the admin app a signed URL it can PUT a lesson video to. The file
  // never passes through this process; only the resulting object key comes
  // back, and `normalizeContentCourseRequest` validates it before a lesson can
  // reference it.
  app.post(
    '/api/admin/content/lesson-videos/upload-url',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const contentType = req.body?.contentType;
      if (typeof contentType !== 'string' || contentType.trim() === '') {
        res.status(400).json({ error: 'Aina ya video inahitajika.' });
        return;
      }
      if (typeof store.createLessonVideoUploadUrl !== 'function') {
        res.status(501).json({
          error: 'Upload ya video haipatikani kwenye mazingira haya.',
        });
        return;
      }
      const upload = await store.createLessonVideoUploadUrl({ contentType });
      if (!upload) {
        res.status(501).json({
          error:
            'Upload ya video haipatikani. Tumia MP4, MOV au WEBM kwenye mazingira ya production.',
        });
        return;
      }
      res.json(upload);
    },
  );

  app.post(
    '/api/admin/content/media/upload-url',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const { contentType, kind } = req.body ?? {};
      const normalizedType = String(contentType ?? '').split(';')[0].trim().toLowerCase();
      const allowed = kind === 'image'
        ? ['image/jpeg', 'image/png', 'image/webp']
        : kind === 'video'
          ? ['video/mp4', 'video/quicktime', 'video/webm']
          : [];
      if (!allowed.includes(normalizedType)) {
        res.status(400).json({ error: 'Aina ya faili haikubaliki.' });
        return;
      }
      if (typeof store.createContentMediaUploadUrl !== 'function') {
        res.status(501).json({ error: 'Upload ya media haipatikani kwenye mazingira haya.' });
        return;
      }
      const upload = await store.createContentMediaUploadUrl({ contentType: normalizedType, kind });
      if (!upload) {
        res.status(501).json({ error: 'Upload ya media haipatikani kwenye mazingira haya.' });
        return;
      }
      res.json(upload);
    },
  );

  app.get(
    '/api/admin/content/source-segments',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const search =
        typeof req.query.search === 'string' ? req.query.search.trim() : '';
      if (search.length > 200) {
        res.status(400).json({ error: 'Source search is too long.' });
        return;
      }
      const requestedLimit = Number.parseInt(String(req.query.limit ?? '50'), 10);
      const limit = Number.isInteger(requestedLimit)
        ? Math.min(Math.max(requestedLimit, 1), 100)
        : 50;
      if (typeof store.sourceSegmentsForAdmin !== 'function') {
        res.json({ segments: [] });
        return;
      }
      try {
        res.json({
          segments: await store.sourceSegmentsForAdmin({ search, limit }),
        });
      } catch {
        res.status(500).json({ error: 'Source segments could not be loaded.' });
      }
    },
  );

  app.post(
    '/api/admin/content/lessons/:lessonId/source-review',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const sourceSegmentId =
        typeof req.body.sourceSegmentId === 'string'
          ? req.body.sourceSegmentId.trim()
          : '';
      const evidenceNote =
        typeof req.body.evidenceNote === 'string'
          ? req.body.evidenceNote.trim()
          : '';
      const groundingFact =
        typeof req.body.groundingFact === 'string'
          ? req.body.groundingFact.trim()
          : '';
      if (!sourceSegmentId || !evidenceNote || !groundingFact) {
        res.status(400).json({
          error:
            'Source segment, evidence note, and grounding fact are required.',
        });
        return;
      }
      if (evidenceNote.length > 2000 || groundingFact.length > 2000) {
        res.status(400).json({
          error: 'Evidence notes and grounding facts must be 2,000 characters or less.',
        });
        return;
      }
      if (typeof store.approveLessonSource !== 'function') {
        res.status(501).json({
          error: 'Source review requires the production content store.',
        });
        return;
      }
      try {
        const reviewer = await store.getUser(req.userId);
        const result = await store.approveLessonSource({
          lessonId: req.params.lessonId,
          sourceSegmentId,
          evidenceNote,
          groundingFact,
          reviewerActorId: reviewer?.id ?? null,
        });
        res.json(result);
      } catch (error) {
        res.status(400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Lesson source review failed.',
        });
      }
    },
  );

  app.post(
    '/api/admin/content/lessons/:lessonId/video-evidence',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const transcript = typeof req.body.transcript === 'string' ? req.body.transcript.trim() : '';
      const evidenceNote = typeof req.body.evidenceNote === 'string' ? req.body.evidenceNote.trim() : '';
      const groundingFact = typeof req.body.groundingFact === 'string' ? req.body.groundingFact.trim() : '';
      if (transcript.length < 40 || !evidenceNote || !groundingFact) {
        res.status(400).json({ error: 'Video transcript (at least 40 characters), evidence note, and grounding fact are required.' });
        return;
      }
      if (transcript.length > 20000 || evidenceNote.length > 2000 || groundingFact.length > 2000) {
        res.status(400).json({ error: 'Video evidence is too long.' });
        return;
      }
      if (typeof store.registerUploadedVideoEvidence !== 'function') {
        res.status(501).json({ error: 'Video evidence requires the production content store.' });
        return;
      }
      try {
        const reviewer = await store.getUser(req.userId);
        res.json(await store.registerUploadedVideoEvidence({ lessonId: req.params.lessonId, transcript, evidenceNote, groundingFact, reviewerActorId: reviewer?.id ?? null }));
      } catch (error) {
        res.status(400).json({ error: error instanceof Error ? error.message : 'Video evidence could not be saved.' });
      }
    },
  );

  app.get(
    '/api/admin/settings/home-topics',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json(homeTopicsPayload(await store.homeTopics()));
    },
  );

  app.put(
    '/api/admin/settings/community-topics',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      let topics;
      try {
        topics = normalizeCommunityTopics(req.body?.topics);
      } catch (error) {
        res.status(400).json({ error: error instanceof Error ? error.message : 'Community topics are invalid.' });
        return;
      }
      try {
        res.json({ topics: await store.updateCommunityTopics(topics) });
      } catch (error) {
        console.error('Failed to update community topics:', error);
        res.status(500).json({ error: 'Failed to update community topics.' });
      }
    },
  );

  app.get(
    '/api/admin/settings/community-topics',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json({ topics: await store.communityTopics() });
    },
  );

  app.put(
    '/api/admin/settings/home-topics-v2',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      let topics;
      try {
        topics = normalizeHomeTopics(req.body?.topics);
      } catch (error) {
        res.status(400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Home topics are invalid.',
        });
        return;
      }
      try {
        res.json(homeTopicsPayload(await store.updateHomeTopics(topics)));
      } catch (error) {
        console.error('Failed to update home topics:', error);
        res.status(500).json({ error: 'Failed to update home topics.' });
      }
    },
  );

  app.put(
    '/api/admin/settings/home-topics',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      let legacyTopics;
      try {
        if (
          !Array.isArray(req.body?.topics) ||
          req.body.topics.length !== defaultHomeTopics.length
        ) {
          throw new Error('Legacy home topics must contain four labels.');
        }
        legacyTopics = normalizeHomeTopics(req.body.topics);
      } catch (error) {
        res.status(400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Home topics are invalid.',
        });
        return;
      }
      try {
        res.json(
          homeTopicsPayload(await store.updateLegacyHomeTopics(legacyTopics)),
        );
      } catch (error) {
        const isConflict =
          error instanceof Error &&
          error.message === 'Home topic labels must be unique.';
        if (isConflict) {
          res.status(409).json({ error: error.message });
          return;
        }
        console.error('Failed to update legacy home topics:', error);
        res.status(500).json({ error: 'Failed to update home topics.' });
      }
    },
  );

  app.get(
    '/api/admin/content/documents',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json({ documents: await store.contentDocumentsForAdmin() });
    },
  );

  app.put(
    '/api/admin/content/documents/:documentId',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const status = req.body.status ?? 'approved';
      if (status !== 'draft' && status !== 'approved') {
        res.status(400).json({ error: 'Content status is invalid.' });
        return;
      }
      try {
        const document = normalizeContentDocumentRequest(
          req.params.documentId,
          req.body.document ?? req.body,
        );
        res.json({
          document: await store.upsertContentDocument({ document, status }),
        });
      } catch (error) {
        res.status(400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Document content is invalid.',
        });
      }
    },
  );

  app.get(
    '/api/admin/users',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const search =
        typeof req.query.search === 'string' ? req.query.search : '';
      const limit =
        typeof req.query.limit === 'string'
          ? Number.parseInt(req.query.limit, 10)
          : undefined;
      const offset =
        typeof req.query.offset === 'string'
          ? Number.parseInt(req.query.offset, 10)
          : undefined;
      const result = await store.adminUsersForAdmin({
        search,
        limit,
        offset,
      });
      res.json(result);
    },
  );

  app.put(
    '/api/admin/users/:userId/access',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const action = req.body.action;
      if (action !== 'suspend' && action !== 'reset_pending') {
        res.status(400).json({ error: 'User access action is invalid.' });
        return;
      }
      if (req.params.userId === req.userId) {
        res.status(409).json({ error: 'Huwezi kubadilisha akaunti yako mwenyewe.' });
        return;
      }
      const target = await store.getUser(req.params.userId);
      if (!target) {
        res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
        return;
      }
      if (target.role === 'admin') {
        res.status(409).json({ error: 'Ufikiaji wa admin hauwezi kubadilishwa hapa.' });
        return;
      }

      try {
        await store.moderateUserAccess({
          userId: target.id,
          action,
          actorUserId: req.userId,
          reason:
            typeof req.body.reason === 'string' && req.body.reason.trim()
              ? req.body.reason.trim()
              : action === 'suspend'
                ? 'Admin suspension'
                : 'Admin reset to pending',
        });
      } catch (error) {
        if (
          error?.code === 'ACTIVE_ENTITLEMENT_EXISTS' ||
          error?.code === 'ADMIN_ACCESS_PROTECTED'
        ) {
          res.status(409).json({ error: error.message });
          return;
        }
        throw error;
      }

      const updatedUser = await store.getUser(target.id);
      res.json({
        user: {
          id: updatedUser.id,
          accountStatus: updatedUser.accountStatus,
        },
        action,
      });
    },
  );

  // The plan catalog staff pick from when recording a payment — never a
  // free-typed price. See server/store/schema.sql for the `plans` table.
  app.get(
    '/api/admin/plans',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json({ plans: await store.activePlans() });
    },
  );

  app.get(
    '/api/admin/payments',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const status =
        typeof req.query.status === 'string' ? req.query.status : undefined;
      if (status && !['pending', 'approved', 'reversed'].includes(status)) {
        res.status(400).json({ error: 'Invalid status filter.' });
        return;
      }
      const userId =
        typeof req.query.userId === 'string' ? req.query.userId : undefined;
      const limit =
        typeof req.query.limit === 'string'
          ? Number.parseInt(req.query.limit, 10)
          : undefined;
      const offset =
        typeof req.query.offset === 'string'
          ? Number.parseInt(req.query.offset, 10)
          : undefined;
      const result = await store.paymentRecordsForAdmin({
        status,
        userId,
        limit,
        offset,
      });
      res.json(result);
    },
  );

  app.get(
    '/api/admin/payments/:paymentRecordId',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const record = await store.getPaymentRecord(req.params.paymentRecordId);
      if (!record) {
        res.status(404).json({ error: 'Payment record haijapatikana.' });
        return;
      }
      res.json({ paymentRecord: record });
    },
  );

  // Records a cash/bank-transfer payment against a real plan id. This never
  // grants access by itself — only POST .../approve does that.
  app.post(
    '/api/admin/payments',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const { userId, planId, method, amountTzs, currency, reference, note } =
        req.body ?? {};
      if (
        typeof userId !== 'string' ||
        userId.trim() === '' ||
        typeof planId !== 'string' ||
        planId.trim() === '' ||
        (method !== 'cash' && method !== 'bank_transfer') ||
        !Number.isInteger(amountTzs) ||
        amountTzs < 0
      ) {
        res.status(400).json({ error: 'Payment details are invalid.' });
        return;
      }
      const learner = await store.getUser(userId);
      if (!learner) {
        res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
        return;
      }
      try {
        const record = await store.recordPaymentRecord({
          userId,
          planId,
          method,
          amountTzs,
          currency: typeof currency === 'string' && currency ? currency : undefined,
          reference:
            typeof reference === 'string' && reference.trim()
              ? reference.trim()
              : null,
          note: typeof note === 'string' && note.trim() ? note.trim() : null,
          recordedByUserId: req.userId,
        });
        if (!record) {
          res.status(400).json({ error: 'Plan haijapatikana au imezimwa.' });
          return;
        }
        res.json({ paymentRecord: record });
      } catch (error) {
        if (error?.code === 'PAYMENT_AMOUNT_MISMATCH') {
          res.status(422).json({ error: error.message });
          return;
        }
        if (error?.code === 'DUPLICATE_REFERENCE') {
          res.status(409).json({ error: error.message });
          return;
        }
        throw error;
      }
    },
  );

  // Transactional and idempotent (see PostgresStore#approvePaymentRecord):
  // pressing approve twice never grants a second entitlement.
  app.post(
    '/api/admin/payments/:paymentRecordId/approve',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      try {
        const reason =
          typeof req.body?.reason === 'string' && req.body.reason.trim()
            ? req.body.reason.trim()
            : null;
        const result = await store.approvePaymentRecord({
          paymentRecordId: req.params.paymentRecordId,
          approvedByUserId: req.userId,
          reason,
        });
        if (!result) {
          res.status(404).json({ error: 'Payment record haijapatikana.' });
          return;
        }
        res.json(result);
      } catch (error) {
        if (error?.code === 'ACCOUNT_SUSPENDED') {
          res.status(409).json({ error: error.message });
          return;
        }
        throw error;
      }
    },
  );

  app.post(
    '/api/admin/payments/:paymentRecordId/reverse',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const reason =
        typeof req.body?.reason === 'string' && req.body.reason.trim()
          ? req.body.reason.trim()
          : null;
      const result = await store.reversePaymentRecord({
        paymentRecordId: req.params.paymentRecordId,
        actorUserId: req.userId,
        reason,
      });
      if (!result) {
        res.status(404).json({ error: 'Payment record haijapatikana.' });
        return;
      }
      res.json(result);
    },
  );

  app.get(
    '/api/admin/payments/:paymentRecordId/audit',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const events = await store.auditEventsFor({
        targetType: 'payment_record',
        targetId: req.params.paymentRecordId,
      });
      res.json({ events });
    },
  );

  app.get('/api/community/posts', async (_req, res) => {
    res.json({ posts: await store.communityPosts() });
  });

  // Development/test only: Flutter authenticates via Supabase Auth directly
  // and never calls this. It exists so local dev and `npm run test:server`
  // can obtain a session without a real Supabase project configured — see
  // requireAuthSession in auth.js, which accepts either kind of token.
  app.post('/api/auth/dev-session', async (req, res) => {
    if (!devModeEnabled()) {
      res.status(404).json({ error: 'Not found.' });
      return;
    }
    const email = normalizeEmail(req.body?.email);
    if (!email) {
      res.status(400).json({ error: 'Email is required.' });
      return;
    }
    const user = await store.linkOrCreateUserForAuth({
      authUserId: `dev-${email}`,
      email,
    });
    const authSession = await store.createAuthSession(user.id);
    res.json({
      user: userWithEffectiveRole(user, user.email),
      sessionToken: authSession.token,
    });
  });

  app.get('/api/auth/whoami', requireAuthSession(store), async (req, res) => {
    const user = await store.getUser(req.userId);
    if (!user) {
      res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
      return;
    }
    const allowlistedAdmin = isAllowlistedAdminEmail(user.email);
    const effectiveUser = userWithEffectiveRole(user, user.email);
    res.json({
      user: effectiveUser,
      accountStatus: user.accountStatus,
      role: effectiveUser.role,
      hasAdminAccess: userHasAdminAccess(user, user.email),
      allowlistedAdmin,
      source: allowlistedAdmin
        ? 'email_allowlist'
        : user.role === 'admin'
          ? 'stored_role'
          : 'learner',
    });
  });

  app.get('/api/users/me', requireAuthSession(store), async (req, res) => {
    const user = await store.getUser(req.userId);
    if (!user) {
      res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
      return;
    }
    res.json({
      user: userWithEffectiveRole(user, user.email),
    });
  });

  app.post(
    '/api/users/me/profile',
    requireAuthSession(store),
    async (req, res) => {
      const user = await store.updateUserProfile(req.userId, {
        displayName: req.body?.displayName,
        preferredLocation: req.body?.preferredLocation,
      });
      res.json({
        user: userWithEffectiveRole(user, user?.email),
      });
    },
  );

  app.post(
    '/api/users/me/subscription/cancel',
    requireAuthSession(store),
    async (req, res) => {
      const user = await store.cancelSubscription(req.userId);
      if (!user) {
        res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
        return;
      }
      res.json({
        user: userWithEffectiveRole(user, user.email),
      });
    },
  );

  app.get(
    '/api/users/me/progress',
    requireAuthSession(store),
    async (req, res) => {
      const progress = await store.learningProgress(req.userId);
      res.json({
        completedLessons: progress.map(
          (item) => `${item.courseId}:${item.lessonId}`,
        ),
        progress,
      });
    },
  );

  app.get(
    '/api/users/me/notifications',
    requireAuthSession(store),
    async (req, res) => {
      res.json({
        settings: await store.notificationSettings(req.userId),
        notifications: await store.notificationsFor(req.userId),
      });
    },
  );

  app.put(
    '/api/users/me/notifications/settings',
    requireAuthSession(store),
    async (req, res) => {
      res.json({
        settings: await store.updateNotificationSettings({
          userId: req.userId,
          settings: req.body,
        }),
      });
    },
  );

  app.post(
    '/api/users/me/notifications/devices',
    requireAuthSession(store),
    async (req, res) => {
      const { token, platform } = req.body;
      if (typeof token !== 'string' || typeof platform !== 'string') {
        res.status(400).json({ error: 'Device token and platform are required.' });
        return;
      }
      res.json({
        device: await store.registerNotificationDevice({
          userId: req.userId,
          token,
          platform,
        }),
      });
    },
  );

  app.post(
    '/api/users/me/notifications/:notificationId/read',
    requireAuthSession(store),
    async (req, res) => {
      const notification = await store.markNotificationRead({
        userId: req.userId,
        notificationId: req.params.notificationId,
      });
      if (!notification) {
        res.status(404).json({ error: 'Notification haijapatikana.' });
        return;
      }
      res.json({ notification });
    },
  );

  app.post(
    '/api/users/me/progress/lessons',
    requireAuthSession(store),
    requirePaidLearningAccess(store),
    async (req, res) => {
      const { courseId, lessonId } = req.body;
      if (typeof courseId !== 'string' || typeof lessonId !== 'string') {
        res.status(400).json({ error: 'Course and lesson are required.' });
        return;
      }
      const progress = await store.markLessonCompleted({
        userId: req.userId,
        courseId,
        lessonId,
      });
      if (!progress) {
        res.status(404).json({ error: 'Somo halijapatikana.' });
        return;
      }
      res.json(progress);
    },
  );

  app.post(
    '/api/payments/checkout',
    requireAuthSession(store),
    async (req, res) => {
      if (!legacyDevelopmentPaymentsEnabled()) {
        res.status(404).json({ error: 'Not found.' });
        return;
      }
      const { planTitle, price, method } = req.body;

      if (
        typeof planTitle !== 'string' ||
        typeof price !== 'string' ||
        typeof method !== 'string'
      ) {
        res.status(400).json({ error: 'Payment details are required.' });
        return;
      }

      const id = `pay-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      const providerCheckout = paymentProvider.startCheckout({
        transactionId: id,
        planTitle,
        price,
        method,
        userId: req.userId,
      });
      const transaction = {
        id,
        planTitle,
        price,
        method,
        userId: req.userId,
        status: providerCheckout.status,
        message: providerCheckout.message,
        receiptNumber: null,
        provider: providerCheckout.provider,
        providerReference: providerCheckout.providerReference,
        checkoutInstructions: providerCheckout.checkoutInstructions,
        autoConfirmAt: providerCheckout.autoConfirmAt,
        subscriptionPlan: null,
        subscriptionStartedAt: null,
      };
      res.json(await store.createPaymentTransaction(transaction));
    },
  );

  app.get(
    '/api/payments/:transactionId',
    requireAuthSession(store),
    async (req, res) => {
      if (!legacyDevelopmentPaymentsEnabled()) {
        res.status(404).json({ error: 'Not found.' });
        return;
      }
      let transaction = await store.getPaymentTransaction(
        req.params.transactionId,
      );
      if (!transaction) {
        res.status(404).json({ error: 'Muamala haujapatikana.' });
        return;
      }
      if (transaction.userId !== req.userId) {
        res.status(403).json({ error: 'Huna ruhusa kwa muamala huu.' });
        return;
      }
      if (paymentProvider.shouldConfirm(transaction)) {
        transaction = await store.markPaymentPaid(transaction.id);
      }
      res.json(transaction);
    },
  );

  app.post('/api/payments/webhook/development', async (req, res) => {
    if (!legacyDevelopmentPaymentsEnabled()) {
      res.status(404).json({ error: 'Not found.' });
      return;
    }
    if (!isAuthorizedDevelopmentWebhook(req)) {
      res.status(401).json({ error: 'Webhook secret is required.' });
      return;
    }
    const { transactionId, status, message } = req.body;
    if (typeof transactionId !== 'string') {
      res.status(400).json({ error: 'transactionId is required.' });
      return;
    }

    const transaction =
      status === 'failed'
        ? await store.markPaymentFailed(
            transactionId,
            typeof message === 'string' ? message : 'Malipo yameshindikana.',
          )
        : await store.markPaymentPaid(transactionId);
    if (!transaction) {
      res.status(404).json({ error: 'Muamala haujapatikana.' });
      return;
    }
    res.json(transaction);
  });

  app.post(
    '/api/community/posts/image',
    requireAuthSession(store),
    express.raw({
      type: ['image/jpeg', 'image/png', 'image/webp'],
      limit: '6mb',
    }),
    async (req, res) => {
      if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
        res.status(400).json({ error: 'Picha inahitajika.' });
        return;
      }
      const imagePath = await store.uploadCommunityPostImage({
        contentType: req.get('Content-Type'),
        bytes: req.body,
      });
      if (!imagePath) {
        res
          .status(501)
          .json({ error: 'Upload ya picha haipatikani kwenye mazingira haya.' });
        return;
      }
      res.json({ imagePath });
    },
  );

  app.post(
    '/api/community/posts',
    requireAuthSession(store),
    async (req, res) => {
      const { content, location, tags, imagePath } = req.body;

      if (
        typeof content !== 'string' ||
        content.trim().length < 12 ||
        typeof location !== 'string' ||
        location.trim().length === 0 ||
        !Array.isArray(tags) ||
        tags.some((tag) => typeof tag !== 'string') ||
        (imagePath !== undefined &&
          imagePath !== null &&
          !isValidCommunityImagePath(imagePath))
      ) {
        res.status(400).json({ error: 'Post details are required.' });
        return;
      }

      // `author` is deliberately ignored if supplied: authorship comes from the
      // session so it cannot be spoofed, and so the internal user id never
      // lands in the publicly readable author label.
      const user = await store.getUser(req.userId);
      res.json(
        await store.createCommunityPost({
          author: communityDisplayName(user, req.userId),
          authorUserId: req.userId,
          content,
          location,
          tags,
          imagePath: imagePath ?? null,
          isExpert: userHasAdminAccess(user, user?.email),
        }),
      );
    },
  );

  app.post(
    '/api/community/posts/:postId/replies',
    requireAuthSession(store),
    async (req, res) => {
      const { body } = req.body;

      if (typeof body !== 'string' || body.trim().length === 0) {
        res.status(400).json({ error: 'Reply details are required.' });
        return;
      }

      // As with posts, a client-supplied `author` is ignored.
      const user = await store.getUser(req.userId);
      const author = communityDisplayName(user, req.userId);
      res.json(
        await store.addCommunityReply({
          postId: req.params.postId,
          author,
          authorUserId: req.userId,
          body,
          isExpert: userHasAdminAccess(user, user?.email),
        }),
      );
      const authorUserId = await store.communityPostAuthorUserId(
        req.params.postId,
      );
      if (authorUserId && authorUserId !== req.userId) {
        await createAndDispatchNotification({
          store,
          notificationProvider,
          userId: authorUserId,
          type: 'community_reply',
          title: 'Jibu jipya kwenye jamii',
          body: `${author} amejibu post yako.`,
          data: { postId: req.params.postId },
        });
      }
    },
  );

  app.post(
    '/api/community/posts/:postId/report',
    requireAuthSession(store),
    async (req, res) => {
      await store.reportCommunityPost(req.params.postId);
      res.json({
        postId: req.params.postId,
        status: 'received',
      });
    },
  );

  app.get(
    '/api/admin/moderation/reports',
    requireAuthSession(store),
    requireAdminSession(store),
    async (_req, res) => {
      res.json({ reports: await store.reportedCommunityPosts() });
    },
  );

  app.post(
    '/api/admin/moderation/posts/:postId/resolve',
    requireAuthSession(store),
    requireAdminSession(store),
    async (req, res) => {
      const { action } = req.body;
      if (action !== 'dismiss' && action !== 'hide' && action !== 'restore') {
        res.status(400).json({ error: 'Moderation action is required.' });
        return;
      }
      const post = await store.resolveCommunityReport({
        postId: req.params.postId,
        action,
        moderatorUserId: req.userId,
      });
      if (!post) {
        res.status(404).json({ error: 'Post haijapatikana.' });
        return;
      }
      const authorUserId = await store.communityPostAuthorUserId(
        req.params.postId,
      );
      if (authorUserId) {
        await createAndDispatchNotification({
          store,
          notificationProvider,
          userId: authorUserId,
          type: 'moderation_update',
          title: action === 'hide'
            ? 'Post imefichwa'
            : action === 'restore'
              ? 'Post imerejeshwa'
              : 'Ripoti imepitiwa',
          body:
            action === 'hide'
              ? 'Post yako imefichwa baada ya ukaguzi wa timu ya AJE.'
              : action === 'restore'
                ? 'Post yako imerejeshwa baada ya ukaguzi wa timu ya AJE.'
              : 'Ripoti kuhusu post yako imepitiwa na timu ya AJE.',
          data: { postId: post.id, action },
        });
      }
      res.json({ post, action });
    },
  );

  app.post(
    '/api/mwalimu-chat',
    requireAuthSession(store),
    requirePaidLearningAccess(store),
    async (req, res) => {
      const { message, history } = req.body;

      if (typeof message !== 'string' || message.trim().length === 0) {
        res.status(400).json({ error: 'Message is required.' });
        return;
      }

      try {
        const groundingSources =
          typeof store.groundingSources === 'function'
            ? await store.groundingSources(message)
            : null;
        const answer = await chatWithMwalimuServer(
          message,
          Array.isArray(history) ? history : [],
          (await store.catalogSnapshot()).courses,
          groundingSources,
        );
        res.json(answer);
      } catch (error) {
        console.error('Mwalimu AI server error:', error);
        res.status(500).json({
          error:
            'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.',
        });
      }
    }
  );

  return store;
}

function requirePaidLearningAccess(store) {
  return async (req, res, next) => {
    if (await hasPaidLearningAccess(store, req.userId)) {
      next();
      return;
    }
    res.status(403).json({
      error: 'Ufikiaji wa mafunzo unahitaji malipo yaliyoidhinishwa na admin.',
    });
  };
}

async function hasPaidLearningAccess(store, userId) {
  const user = await store.getUser(userId);
  return (
    userHasAdminAccess(user, user?.email) ||
    (user?.accountStatus === 'active' &&
      typeof store.hasActiveEntitlement === 'function' &&
      (await store.hasActiveEntitlement(userId)))
  );
}

function lockedCatalogSnapshot(snapshot) {
  return {
    ...snapshot,
    courses: snapshot.courses.map((course) => ({
      ...course,
      lessons: course.lessons.map((lesson) => ({
        ...lesson,
        description: '',
        resourceUrl: null,
        resourcePath: null,
        isPremium: true,
      })),
    })),
    documents: snapshot.documents.map((document) => ({
      ...document,
      url: null,
      isPremium: true,
    })),
  };
}

function homeTopicsPayload(topics) {
  return {
    topics: legacyHomeTopics(topics),
    topicsV2: topics,
  };
}

function withCompatibleHomeTopics(snapshot) {
  return {
    ...snapshot,
    homeTopics: legacyHomeTopics(snapshot.homeTopics),
    homeTopicsV2: snapshot.homeTopics,
  };
}

function isAuthorizedDevelopmentWebhook(req) {
  const secret = process.env.AJE_DEV_PAYMENT_WEBHOOK_SECRET;
  if (!secret) return false;
  return req.headers['x-aje-webhook-secret'] === secret;
}

export async function createAndDispatchNotification({
  store,
  notificationProvider,
  userId,
  type,
  title,
  body,
  data,
}) {
  const notification = await store.createNotification({
    userId,
    type,
    title,
    body,
    data,
  });
  if (!notification) return null;
  try {
    await notificationProvider.send(
      notification,
      await store.notificationDevices(userId),
    );
  } catch (error) {
    console.error(
      'Push notification delivery failed:',
      error instanceof Error ? error.message : error,
    );
  }
  return notification;
}

function normalizeContentCourseRequest(courseId, rawCourse) {
  if (!rawCourse || typeof rawCourse !== 'object') {
    throw new Error('Course content is required.');
  }
  if (rawCourse.id !== courseId) {
    throw new Error('Course id must match the route.');
  }
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]{2,49}$/.test(courseId)) {
    throw new Error(
      'Course id must use 3-50 letters, numbers, hyphens, or underscores.',
    );
  }
  const requiredStrings = [
    'id',
    'title',
    'description',
    'badge',
    'icon',
    'imageUrl',
  ];
  for (const field of requiredStrings) {
    if (typeof rawCourse[field] !== 'string' || rawCourse[field].trim() === '') {
      throw new Error(`Course ${field} is required.`);
    }
  }
  if (
    rawCourse.introVideoUrl != null &&
    (typeof rawCourse.introVideoUrl !== 'string' || rawCourse.introVideoUrl.trim() === '')
  ) {
    throw new Error('Course introVideoUrl must be a non-empty string when provided.');
  }
  if (!Array.isArray(rawCourse.outcomes) || rawCourse.outcomes.length === 0) {
    throw new Error('Course outcomes are required.');
  }
  if (!Array.isArray(rawCourse.lessons) || rawCourse.lessons.length === 0) {
    throw new Error('Course lessons are required.');
  }
  for (const lesson of rawCourse.lessons) {
    for (const field of ['title', 'type', 'meta']) {
      if (typeof lesson[field] !== 'string' || lesson[field].trim() === '') {
        throw new Error(`Lesson ${field} is required.`);
      }
    }
    if (
      lesson.moduleTitle != null &&
      (typeof lesson.moduleTitle !== 'string' ||
        lesson.moduleTitle.trim() === '')
    ) {
      throw new Error('Lesson moduleTitle must be a non-empty string.');
    }
    if (
      lesson.moduleKey != null &&
      (typeof lesson.moduleKey !== 'string' || lesson.moduleKey.trim() === '')
    ) {
      throw new Error('Lesson moduleKey must be a non-empty string.');
    }
    if (lesson.type !== 'reading' && lesson.type !== 'video') {
      throw new Error('Lesson type must be reading or video.');
    }
    if (
      lesson.type === 'reading' &&
      (typeof lesson.description !== 'string' ||
        lesson.description.trim() === '')
    ) {
      throw new Error('Reading lesson description is required.');
    }
    if (
      lesson.durationMinutes != null &&
      (!Number.isInteger(lesson.durationMinutes) ||
        lesson.durationMinutes <= 0)
    ) {
      throw new Error('Lesson durationMinutes must be a positive integer.');
    }
    if (lesson.resourceUrl != null) {
      let resourceUrl;
      try {
        resourceUrl = new URL(lesson.resourceUrl);
      } catch {
        throw new Error('Lesson resourceUrl must be a valid web URL.');
      }
      if (
        resourceUrl.protocol !== 'https:' &&
        resourceUrl.protocol !== 'http:'
      ) {
        throw new Error('Lesson resourceUrl must use HTTP or HTTPS.');
      }
    }
    if (lesson.videoPath != null && !isValidLessonVideoPath(lesson.videoPath)) {
      throw new Error('Lesson videoPath must come from the video upload.');
    }
  }
  const fallbackModuleTitle = rawCourse.outcomes[0] ?? 'Somo';
  return normalizeApprovedCourse({
    ...rawCourse,
    lessons: rawCourse.lessons.map((lesson) => ({
      ...lesson,
      moduleTitle: lesson.moduleTitle ?? fallbackModuleTitle,
    })),
  });
}

function normalizeContentDocumentRequest(documentId, rawDocument) {
  if (!rawDocument || typeof rawDocument !== 'object') {
    throw new Error('Document content is required.');
  }
  if (rawDocument.id !== documentId) {
    throw new Error('Document id must match the route.');
  }
  const requiredStrings = [
    'id',
    'title',
    'courseId',
    'courseTitle',
    'description',
    'type',
    'sizeLabel',
  ];
  for (const field of requiredStrings) {
    if (
      typeof rawDocument[field] !== 'string' ||
      rawDocument[field].trim() === ''
    ) {
      throw new Error(`Document ${field} is required.`);
    }
  }
  if (
    rawDocument.url != null &&
    (typeof rawDocument.url !== 'string' || rawDocument.url.trim() === '')
  ) {
    throw new Error('Document url must be a non-empty string when provided.');
  }
  for (const field of ['imageUrl', 'introVideoUrl']) {
    if (
      rawDocument[field] != null &&
      (typeof rawDocument[field] !== 'string' || rawDocument[field].trim() === '')
    ) {
      throw new Error(`Document ${field} must be a non-empty string when provided.`);
    }
  }
  return normalizeContentDocument(rawDocument);
}
