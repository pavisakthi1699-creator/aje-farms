import express from 'express';

import { catalog } from './catalog.js';
import {
  isAllowlistedAdminPhone,
  userHasAdminAccess,
  userWithEffectiveRole,
  requireAdminSession,
  requireAuthPhoneMatch,
  requireAuthSession,
} from './auth.js';
import { chatWithMwalimuServer } from './mwalimu.js';
import { createNotificationProvider } from './notifications.js';
import { createPaymentProvider } from './payments.js';
import { createOtpCode, createOtpSender } from './sms.js';
import { createStore, normalizePhoneNumber, resolveStoreConfig } from './store.js';
import {
  communityDisplayName,
  isValidCommunityImagePath,
  normalizeApprovedCourse,
  normalizeContentDocument,
} from './store/utils.js';

export async function registerApiRoutes(app) {
  const store = await createStore(catalog);
  const otpSender = createOtpSender();
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
      sms: {
        provider: otpSender.name,
        ready: !isProduction || otpSender.isProductionReady,
      },
      payments: {
        provider: paymentProvider.name,
        ready: paymentProvider.isProductionReady || !isProduction,
      },
      notifications: {
        provider: notificationProvider.name,
        ready: notificationProvider.isProductionReady || !isProduction,
      },
      ai: {
        provider: process.env.GEMINI_API_KEY ? 'gemini' : 'knowledge-base',
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

  app.get('/api/catalog', async (_req, res) => {
    res.json(await store.catalogSnapshot());
  });

  // Resolves a lesson video to a short-lived signed URL. The player opens that
  // URL in an external viewer, which cannot carry an Authorization header, so
  // the session is enforced here and only the resolved URL is handed out.
  app.get(
    '/api/lessons/:lessonId/video-url',
    requireAuthSession(store),
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
      if (status !== 'draft' && status !== 'approved') {
        res.status(400).json({ error: 'Content status is invalid.' });
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
          }),
        });
      } catch (error) {
        res.status(error?.code === 'CURRICULUM_CONFLICT' ? 409 : 400).json({
          error:
            error instanceof Error
              ? error.message
              : 'Course content is invalid.',
        });
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

  app.get('/api/community/posts', async (_req, res) => {
    res.json({ posts: await store.communityPosts() });
  });

  app.post('/api/auth/request-otp', async (req, res) => {
    const { phoneNumber } = req.body;

    if (typeof phoneNumber !== 'string' || phoneNumber.trim().length < 9) {
      res.status(400).json({ error: 'Phone number is required.' });
      return;
    }

    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    const retryAfterSeconds = await store.otpRequestDelaySeconds(
      normalizedPhone,
    );
    if (retryAfterSeconds > 0) {
      res.status(429).json({
        error: `Subiri sekunde ${retryAfterSeconds} kabla ya kutuma OTP tena.`,
        retryAfterSeconds,
      });
      return;
    }

    const otp = createOtpCode();
    let delivery;
    try {
      delivery = await otpSender.sendOtp({
        phoneNumber: normalizedPhone,
        otp,
      });
    } catch (error) {
      console.error('OTP delivery failed:', error);
      res.status(502).json({
        error: 'Imeshindikana kutuma OTP. Jaribu tena baadae.',
      });
      return;
    }

    const challenge = await store.createOtpChallenge({
      phoneNumber: normalizedPhone,
      otp,
      deliveryProvider: delivery.provider,
    });

    res.json({
      challengeId: challenge.id,
      message: `OTP imetumwa kwa ${normalizedPhone}.`,
      debugOtp: delivery.debugOtp,
      retryAfterSeconds: 60,
    });
  });

  app.post('/api/auth/verify-otp', async (req, res) => {
    const { phoneNumber, otp, challengeId } = req.body;
    const normalizedPhone =
      typeof phoneNumber === 'string' ? normalizePhoneNumber(phoneNumber) : '';
    const result =
      typeof challengeId === 'string'
        ? await store.consumeOtpChallenge({
            challengeId,
            phoneNumber: normalizedPhone,
            otp,
          })
        : { status: 'missing' };

    if (result.status === 'missing' || result.status === 'expired') {
      res.status(400).json({ error: 'OTP imeisha muda wake. Tuma tena.' });
      return;
    }
    if (result.status === 'invalid') {
      res.status(401).json({ error: 'OTP si sahihi. Jaribu tena.' });
      return;
    }

    const user = userWithEffectiveRole(
      await store.ensureUser(normalizedPhone),
      normalizedPhone,
    );
    const authSession = await store.createAuthSession(normalizedPhone);
    res.json({
      phoneNumber: user.phoneNumber,
      user,
      sessionToken: authSession.token,
    });
  });

  app.get('/api/auth/whoami', requireAuthSession(store), async (req, res) => {
    const user = await store.getUser(req.authPhoneNumber);
    if (!user) {
      res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
      return;
    }
    const allowlistedAdmin = isAllowlistedAdminPhone(req.authPhoneNumber);
    const effectiveUser = userWithEffectiveRole(user, req.authPhoneNumber);
    res.json({
      phoneNumber: effectiveUser.phoneNumber,
      role: effectiveUser.role,
      hasAdminAccess: userHasAdminAccess(user, req.authPhoneNumber),
      allowlistedAdmin,
      source: allowlistedAdmin
        ? 'phone_allowlist'
        : user.role === 'admin'
          ? 'stored_role'
          : 'learner',
    });
  });

  app.get(
    '/api/users/by-phone/:phoneNumber',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const user = await store.getUser(req.params.phoneNumber);
      if (!user) {
        res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
        return;
      }
      res.json({
        user: userWithEffectiveRole(user, req.authPhoneNumber),
      });
    },
  );

  app.post(
    '/api/users/by-phone/:phoneNumber/profile',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const user = await store.updateUserProfile(req.params.phoneNumber, {
        displayName: req.body?.displayName,
        preferredLocation: req.body?.preferredLocation,
      });
    res.json({
      user: userWithEffectiveRole(user, req.authPhoneNumber),
    });
    },
  );

  app.post(
    '/api/users/by-phone/:phoneNumber/subscription/cancel',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const user = await store.cancelSubscription(req.params.phoneNumber);
      if (!user) {
        res.status(404).json({ error: 'Mtumiaji hajapatikana.' });
        return;
      }
    res.json({
      user: userWithEffectiveRole(user, req.authPhoneNumber),
    });
    },
  );

  app.get(
    '/api/users/by-phone/:phoneNumber/progress',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const progress = await store.learningProgress(req.params.phoneNumber);
      res.json({
        completedLessons: progress.map(
          (item) => `${item.courseId}:${item.lessonId}`,
        ),
        progress,
      });
    },
  );

  app.get(
    '/api/users/by-phone/:phoneNumber/notifications',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      res.json({
        settings: await store.notificationSettings(req.params.phoneNumber),
        notifications: await store.notificationsFor(req.params.phoneNumber),
      });
    },
  );

  app.put(
    '/api/users/by-phone/:phoneNumber/notifications/settings',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      res.json({
        settings: await store.updateNotificationSettings({
          phoneNumber: req.params.phoneNumber,
          settings: req.body,
        }),
      });
    },
  );

  app.post(
    '/api/users/by-phone/:phoneNumber/notifications/devices',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const { token, platform } = req.body;
      if (typeof token !== 'string' || typeof platform !== 'string') {
        res.status(400).json({ error: 'Device token and platform are required.' });
        return;
      }
      res.json({
        device: await store.registerNotificationDevice({
          phoneNumber: req.params.phoneNumber,
          token,
          platform,
        }),
      });
    },
  );

  app.post(
    '/api/users/by-phone/:phoneNumber/notifications/:notificationId/read',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const notification = await store.markNotificationRead({
        phoneNumber: req.params.phoneNumber,
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
    '/api/users/by-phone/:phoneNumber/progress/lessons',
    requireAuthSession(store),
    requireAuthPhoneMatch('phoneNumber'),
    async (req, res) => {
      const { courseId, lessonId } = req.body;
      if (typeof courseId !== 'string' || typeof lessonId !== 'string') {
        res.status(400).json({ error: 'Course and lesson are required.' });
        return;
      }
      const progress = await store.markLessonCompleted({
        phoneNumber: req.params.phoneNumber,
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
      const { planTitle, price, method, phoneNumber } = req.body;

      if (
        typeof planTitle !== 'string' ||
        typeof price !== 'string' ||
        typeof method !== 'string' ||
        typeof phoneNumber !== 'string' ||
        phoneNumber.trim().length < 9
      ) {
        res.status(400).json({ error: 'Payment details are required.' });
        return;
      }

      const id = `pay-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      const normalizedPhone = normalizePhoneNumber(phoneNumber);
      if (normalizedPhone !== req.authPhoneNumber) {
        res.status(403).json({ error: 'Huna ruhusa kwa akaunti hii.' });
        return;
      }
      const providerCheckout = paymentProvider.startCheckout({
        transactionId: id,
        planTitle,
        price,
        method,
        phoneNumber: normalizedPhone,
      });
      const transaction = {
        id,
        planTitle,
        price,
        method,
        phoneNumber: normalizedPhone,
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
      let transaction = await store.getPaymentTransaction(
        req.params.transactionId,
      );
      if (!transaction) {
        res.status(404).json({ error: 'Muamala haujapatikana.' });
        return;
      }
      if (transaction.phoneNumber !== req.authPhoneNumber) {
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
      // session so it cannot be spoofed, and so a phone number never lands in
      // the publicly readable author label.
      const user = await store.getUser(req.authPhoneNumber);
      res.json(
        await store.createCommunityPost({
          author: communityDisplayName(user, req.authPhoneNumber),
          authorPhone: req.authPhoneNumber,
          content,
          location,
          tags,
          imagePath: imagePath ?? null,
          isExpert: userHasAdminAccess(user, req.authPhoneNumber),
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
      const user = await store.getUser(req.authPhoneNumber);
      const author = communityDisplayName(user, req.authPhoneNumber);
      res.json(
        await store.addCommunityReply({
          postId: req.params.postId,
          author,
          authorPhone: req.authPhoneNumber,
          body,
          isExpert: userHasAdminAccess(user, req.authPhoneNumber),
        }),
      );
      const authorPhone = await store.communityPostAuthorPhone(
        req.params.postId,
      );
      if (authorPhone && authorPhone !== req.authPhoneNumber) {
        await createAndDispatchNotification({
          store,
          notificationProvider,
          phoneNumber: authorPhone,
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
      if (action !== 'dismiss' && action !== 'hide') {
        res.status(400).json({ error: 'Moderation action is required.' });
        return;
      }
      const post = await store.resolveCommunityReport({
        postId: req.params.postId,
        action,
        moderatorPhoneNumber: req.authPhoneNumber,
      });
      if (!post) {
        res.status(404).json({ error: 'Post haijapatikana.' });
        return;
      }
      const authorPhone = await store.communityPostAuthorPhone(
        req.params.postId,
      );
      if (authorPhone) {
        await createAndDispatchNotification({
          store,
          notificationProvider,
          phoneNumber: authorPhone,
          type: 'moderation_update',
          title: action === 'hide' ? 'Post imefichwa' : 'Ripoti imepitiwa',
          body:
            action === 'hide'
              ? 'Post yako imefichwa baada ya ukaguzi wa timu ya AJE.'
              : 'Ripoti kuhusu post yako imepitiwa na timu ya AJE.',
          data: { postId: post.id, action },
        });
      }
      res.json({ post, action });
    },
  );

  app.post('/api/mwalimu-chat', async (req, res) => {
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
  });

  return store;
}

function isAuthorizedDevelopmentWebhook(req) {
  const secret = process.env.AJE_DEV_PAYMENT_WEBHOOK_SECRET;
  if (!secret) return false;
  return req.headers['x-aje-webhook-secret'] === secret;
}

export async function createAndDispatchNotification({
  store,
  notificationProvider,
  phoneNumber,
  type,
  title,
  body,
  data,
}) {
  const notification = await store.createNotification({
    phoneNumber,
    type,
    title,
    body,
    data,
  });
  if (!notification) return null;
  try {
    await notificationProvider.send(
      notification,
      await store.notificationDevices(phoneNumber),
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
  return normalizeContentDocument(rawDocument);
}
