import crypto from 'node:crypto';

export const defaultHomeTopics = [
  'Matunda na Mbogamboga',
  'Nafaka',
  'Mifugo',
  'Mengineyo',
];

export const defaultCommunityTopics = [
  'Magonjwa',
  'Mifugo',
  'Masoko',
  'Kuku',
  'Nyanya',
];

export const minHomeTopics = 1;
export const maxHomeTopics = 12;
export const maxHomeTopicLength = 40;

export function legacyHomeTopics(topics) {
  const legacy = topics.slice(0, defaultHomeTopics.length);
  const normalized = new Set(
    legacy.map((topic) => topic.toLocaleLowerCase('sw')),
  );
  for (const fallback of defaultHomeTopics) {
    if (legacy.length >= defaultHomeTopics.length) break;
    const key = fallback.toLocaleLowerCase('sw');
    if (normalized.has(key)) continue;
    legacy.push(fallback);
    normalized.add(key);
  }
  return legacy;
}

export function mergeLegacyHomeTopics(current, submitted) {
  const merged = current.map(
    (topic, index) => submitted[index] ?? topic,
  );
  if (current.length >= defaultHomeTopics.length) return merged;

  const projection = legacyHomeTopics(current);
  let lastChangedPadding = -1;
  for (let index = current.length; index < submitted.length; index += 1) {
    if (submitted[index] !== projection[index]) lastChangedPadding = index;
  }
  for (
    let index = current.length;
    index <= lastChangedPadding;
    index += 1
  ) {
    merged.push(submitted[index]);
  }
  return merged;
}

export function normalizeHomeTopics(value) {
  if (
    !Array.isArray(value) ||
    value.length < minHomeTopics ||
    value.length > maxHomeTopics
  ) {
    throw new Error(
      `Home topics must contain ${minHomeTopics}–${maxHomeTopics} labels.`,
    );
  }
  if (value.some((item) => typeof item !== 'string')) {
    throw new Error('Each home topic must be text.');
  }
  const topics = value.map((item) => item.trim());
  if (
    topics.some(
      (item) => item.length === 0 || item.length > maxHomeTopicLength,
    )
  ) {
    throw new Error(
      `Each home topic must contain 1–${maxHomeTopicLength} characters.`,
    );
  }
  if (
    new Set(topics.map((item) => item.toLocaleLowerCase('sw'))).size !==
    topics.length
  ) {
    throw new Error('Home topic labels must be unique.');
  }
  return topics;
}

export function normalizeCommunityTopics(value) {
  const topics = normalizeHomeTopics(value);
  if (topics.some((topic) => topic.toLocaleLowerCase('sw') === 'zote')) {
    throw new Error('Community topics cannot use the reserved label Zote.');
  }
  return topics;
}

export function createId(prefix) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function createLessonId(title) {
  return String(title ?? '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/[\s_]+/g, '-')
    .replace(/-+/g, '-');
}

export function approvedCoursesFromCatalog(catalog) {
  return catalog.courses.map(normalizeApprovedCourse);
}

export function isLearnerReadyCourse(course) {
  if (course.riskLevel === 'high' || course.risk_level === 'high') return false;
  if (
    course.status != null &&
    course.status !== 'approved' &&
    course.status !== 'published'
  ) {
    return false;
  }
  if (Array.isArray(course.contentGaps) && course.contentGaps.length > 0) {
    return false;
  }
  const reviewedItems = [
    ...(Array.isArray(course.modules) ? course.modules : []),
    ...(Array.isArray(course.lessons) ? course.lessons : []),
  ];
  const lessons = Array.isArray(course.lessons) ? course.lessons : [];
  if (lessons.length === 0) return false;
  if (
    lessons.some(
      (lesson) => lesson.type !== 'reading' && lesson.type !== 'video',
    )
  ) {
    return false;
  }
  return reviewedItems.every((item) => {
    if (item.riskLevel === 'high' || item.risk_level === 'high') return false;
    if (item.status == null) return true;
    return item.status === 'approved' || item.status === 'published';
  });
}

export function documentsFromCourses(courses) {
  return courses.flatMap((course) => {
    const normalizedCourse = normalizeApprovedCourse(course);
    return normalizedCourse.lessons
      .filter((lesson) => lesson.type === 'pdf')
      .map((lesson) =>
        normalizeContentDocument({
          id: lesson.id,
          title: lesson.title,
          courseId: normalizedCourse.id,
          courseTitle: normalizedCourse.title,
          description: lesson.description,
          type: lesson.type,
          sizeLabel: lesson.meta,
          url: lesson.url ?? null,
          isPremium: lesson.isPremium,
        }),
      );
  });
}

export function normalizeApprovedCourse(course) {
  return {
    ...course,
    id: String(course.id),
    title: String(course.title),
    description: String(course.description),
    badge: String(course.badge),
    icon: String(course.icon),
    progress: 0,
    lessons: course.lessons.map((lesson) => ({
      ...lesson,
      id: lesson.id ?? createLessonId(lesson.title),
      title: String(lesson.title),
      type: String(lesson.type),
      meta: String(lesson.meta),
      description: String(lesson.description),
      isPremium: Boolean(lesson.isPremium),
      isCompleted: false,
    })),
  };
}

export function normalizeContentDocument(document) {
  return {
    id: String(document.id ?? createLessonId(document.title)),
    title: String(document.title),
    courseId: String(document.courseId),
    courseTitle: String(document.courseTitle),
    description: String(document.description),
    type: String(document.type ?? 'pdf'),
    sizeLabel: String(document.sizeLabel ?? ''),
    url: document.url ? String(document.url) : null,
    imageUrl: document.imageUrl ? String(document.imageUrl) : null,
    introVideoUrl: document.introVideoUrl ? String(document.introVideoUrl) : null,
    isPremium: Boolean(document.isPremium),
  };
}

export function hasApprovedLesson(catalog, courseId, lessonId) {
  return hasApprovedLessonInCourses(catalog.courses, courseId, lessonId);
}

export function hasApprovedLessonInCourses(courses, courseId, lessonId) {
  const course = courses.find((item) => item.id === courseId);
  if (!course) return false;
  return course.lessons.some((lesson) => {
    return (lesson.id ?? createLessonId(lesson.title)) === lessonId;
  });
}

export function normalizePhoneNumber(value) {
  const digits = String(value ?? '').replace(/\D/g, '');
  if (digits.startsWith('255')) return `+${digits}`;
  if (digits.startsWith('0')) return `+255${digits.slice(1)}`;
  if (digits.length === 9) return `+255${digits}`;
  return `+${digits}`;
}

// Email is the sign-in identifier, so it is compared case-insensitively and
// stored in the same normalized form the unique index uses (lower(email)).
// Returns null rather than '' so it maps cleanly onto a nullable column.
export function normalizeEmail(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim().toLowerCase();
  return trimmed.length > 0 ? trimmed : null;
}

function displayNamePepper() {
  return process.env.AJE_OTP_PEPPER ?? 'aje-farms-dev-otp-pepper';
}

// Community posts are served by an unauthenticated endpoint, so the stored
// author label must never reveal the user's internal id. Falls back to a
// stable pseudonymous handle when the user has not set a display name.
export function communityDisplayName(user, userId) {
  const displayName = String(user?.displayName ?? '').trim();
  if (displayName) return displayName;
  const suffix = crypto
    .createHash('sha256')
    .update(`${userId}:${displayNamePepper()}`)
    .digest('hex')
    .slice(0, 4);
  return `Mkulima ${suffix}`;
}

export const communityPostImagesBucket = 'community-post-images';

export function extensionForImageContentType(contentType) {
  const normalized = String(contentType ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  switch (normalized) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    default:
      return null;
  }
}

const communityImagePathPattern = /^[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$/;

// `imagePath` is a bare generated filename returned by our own upload
// endpoint; this guards against a caller sending an arbitrary string (path
// traversal, another bucket's object, etc.) when referencing it on a post.
export function isValidCommunityImagePath(imagePath) {
  return (
    typeof imagePath === 'string' &&
    imagePath.length <= 200 &&
    communityImagePathPattern.test(imagePath)
  );
}

// The bucket is public, so the URL needs no signing (unlike lesson videos,
// which are gated behind a paid session). Only the upload path is
// authenticated.
export function communityPostImageUrl(imagePath) {
  if (!imagePath) return null;
  const supabaseUrl = process.env.SUPABASE_URL;
  if (!supabaseUrl) return null;
  return `${supabaseUrl}/storage/v1/object/public/${communityPostImagesBucket}/${encodeURIComponent(imagePath)}`;
}

// Lesson videos live in the private source-documents bucket. Unlike community
// images they are never served by public URL: `lessonVideoUrl` signs them per
// request so playback stays behind a paid session.
export const lessonVideosBucket = 'source-documents';
export const lessonVideosPrefix = 'lesson-videos';
export const contentMediaBucket = 'content-media';
export const contentMediaPrefix = 'previews';

export function extensionForVideoContentType(contentType) {
  const normalized = String(contentType ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  switch (normalized) {
    case 'video/mp4':
      return 'mp4';
    case 'video/quicktime':
      return 'mov';
    case 'video/webm':
      return 'webm';
    default:
      return null;
  }
}

export function extensionForContentMedia(contentType, kind) {
  if (kind === 'image') return extensionForImageContentType(contentType);
  if (kind === 'video') return extensionForVideoContentType(contentType);
  return null;
}

export function contentMediaPublicUrl(mediaPath) {
  const supabaseUrl = process.env.SUPABASE_URL;
  if (!supabaseUrl || !mediaPath) return null;
  return `${supabaseUrl}/storage/v1/object/public/${contentMediaBucket}/${encodeURIComponent(mediaPath)}`;
}

const lessonVideoPathPattern = new RegExp(
  `^${lessonVideosPrefix}/[A-Za-z0-9_-]+\\.(mp4|mov|webm)$`,
);

// `videoPath` is a bucket-relative object key minted by our own signed-upload
// endpoint. Validating it stops a caller from pointing a lesson at an
// arbitrary object in the bucket — which holds unpublished source documents.
export function isValidLessonVideoPath(videoPath) {
  return (
    typeof videoPath === 'string' &&
    videoPath.length <= 200 &&
    lessonVideoPathPattern.test(videoPath)
  );
}

export function userFromRow(row) {
  return {
    id: row.id,
    phoneNumber: row.phone_number ?? null,
    email: row.email ?? null,
    authUserId: row.auth_user_id ?? null,
    accountStatus: row.account_status,
    role: row.role,
    subscriptionPlan: row.subscription_plan,
    subscriptionStartedAt: row.subscription_started_at
      ? new Date(row.subscription_started_at).toISOString()
      : null,
    displayName: row.display_name ?? null,
    preferredLocation: row.preferred_location ?? null,
    termsAcceptedVersion: row.terms_accepted_version ?? null,
    termsAcceptedAt: row.terms_accepted_at
      ? new Date(row.terms_accepted_at).toISOString()
      : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

export function paymentFromRow(row) {
  return {
    id: row.id,
    planTitle: row.plan_title,
    price: row.price,
    method: row.method,
    userId: row.user_id,
    status: row.status,
    message: row.message,
    receiptNumber: row.receipt_number,
    provider: row.provider,
    providerReference: row.provider_reference,
    checkoutInstructions: row.checkout_instructions,
    autoConfirmAt: row.auto_confirm_at
      ? new Date(row.auto_confirm_at).toISOString()
      : null,
    subscriptionPlan: row.subscription_plan,
    subscriptionStartedAt: row.subscription_started_at
      ? new Date(row.subscription_started_at).toISOString()
      : null,
  };
}
