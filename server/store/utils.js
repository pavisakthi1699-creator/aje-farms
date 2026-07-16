import crypto from 'node:crypto';

export const otpTtlMs = 10 * 60 * 1000;

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

function otpPepper() {
  return process.env.AJE_OTP_PEPPER ?? 'aje-farms-dev-otp-pepper';
}

export function hashOtp(otp) {
  return crypto
    .createHash('sha256')
    .update(`${otp}:${otpPepper()}`)
    .digest('hex');
}

export function verifyOtpHash(otp, otpHash) {
  const candidate = hashOtp(otp);
  const left = Buffer.from(candidate, 'utf8');
  const right = Buffer.from(otpHash, 'utf8');
  if (left.length !== right.length) return false;
  return crypto.timingSafeEqual(left, right);
}

export function userFromRow(row) {
  return {
    id: row.id,
    phoneNumber: row.phone_number,
    role: row.role,
    subscriptionPlan: row.subscription_plan,
    subscriptionStartedAt: row.subscription_started_at
      ? new Date(row.subscription_started_at).toISOString()
      : null,
    displayName: row.display_name ?? null,
    preferredLocation: row.preferred_location ?? null,
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
    phoneNumber: row.phone_number,
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
