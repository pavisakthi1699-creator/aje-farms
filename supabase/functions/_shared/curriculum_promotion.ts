import { codeFromText, serviceClient } from "./supabase.ts";
import { parseJsonArray, type CurriculumRow } from "./curriculum.ts";

type Supabase = ReturnType<typeof serviceClient>;

const ITEM_TYPES = new Set([
  "course",
  "module",
  "lesson",
  "checklist",
  "quiz",
  "faq",
  "content_gap",
  "learning_path",
  "learning_path_course",
]);

export type PromotionResult = {
  row_number: number;
  item_type: string;
  id?: string;
  code?: string;
};

function getItemType(row: CurriculumRow): CurriculumRow["item_type"] {
  return (row.item_type ?? row.record_type ?? "module") as CurriculumRow["item_type"];
}

function rowStatus(row: CurriculumRow): string {
  return row.status ?? "draft";
}

function rowRiskLevel(row: CurriculumRow): string {
  return row.risk_level ?? "normal";
}

export function validateCurriculumRow(row: CurriculumRow): { valid: true } | { valid: false; message: string } {
  const itemType = getItemType(row);
  if (!ITEM_TYPES.has(itemType)) return { valid: false, message: `Unsupported item_type: ${itemType}` };

  if (row.sort_order !== undefined && Number.isNaN(Number(row.sort_order))) {
    return { valid: false, message: "sort_order must be numeric when provided" };
  }

  if (row.risk_level && !["normal", "medium", "high"].includes(row.risk_level)) {
    return { valid: false, message: "risk_level must be one of normal|medium|high" };
  }

  if (row.status && !["draft", "needs_review", "approved", "published", "archived", "failed"].includes(row.status)) {
    return { valid: false, message: "status is invalid" };
  }

  switch (itemType) {
    case "course":
      if (!row.title_sw) return { valid: false, message: "title_sw is required for course" };
      return { valid: true };
    case "module":
      if (!row.course_code) return { valid: false, message: "course_code is required for module" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for module" };
      return { valid: true };
    case "lesson":
      if (!row.course_code) return { valid: false, message: "course_code is required for lesson" };
      if (!row.module_code) return { valid: false, message: "module_code is required for lesson" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for lesson" };
      return { valid: true };
    case "checklist":
      if (!row.course_code) return { valid: false, message: "course_code is required for checklist" };
      if (!row.module_code) return { valid: false, message: "module_code is required for checklist" };
      if (!row.lesson_code) return { valid: false, message: "lesson_code is required for checklist" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for checklist" };
      return { valid: true };
    case "quiz":
      if (!row.course_code) return { valid: false, message: "course_code is required for quiz" };
      if (!row.module_code) return { valid: false, message: "module_code is required for quiz" };
      if (!row.lesson_code) return { valid: false, message: "lesson_code is required for quiz" };
      if (!row.question_sw) return { valid: false, message: "question_sw is required for quiz" };
      return { valid: true };
    case "faq":
      if (!row.course_code) return { valid: false, message: "course_code is required for faq" };
      if (!row.question_sw || !row.answer_sw) {
        return { valid: false, message: "question_sw and answer_sw are required for faq" };
      }
      return { valid: true };
    case "content_gap":
      if (!row.title_sw) return { valid: false, message: "title_sw is required for content_gap" };
      return { valid: true };
    case "learning_path":
      if (!row.title_sw) return { valid: false, message: "title_sw is required for learning_path" };
      return { valid: true };
    case "learning_path_course":
      if (!row.learning_path_code) return { valid: false, message: "learning_path_code is required" };
      if (!row.course_code) return { valid: false, message: "course_code is required for learning_path_course" };
      return { valid: true };
    default:
      return { valid: false, message: `Unsupported item_type: ${itemType}` };
  }
}

export async function importRow(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const normalized = { ...row, item_type: getItemType(row) } as CurriculumRow;

  switch (normalized.item_type) {
    case "course":
      return importCourse(admin, normalized, rowNumber);
    case "module":
      return importModule(admin, normalized, rowNumber);
    case "lesson":
      return importLesson(admin, normalized, rowNumber);
    case "checklist":
      return importChecklist(admin, normalized, rowNumber);
    case "quiz":
      return importQuiz(admin, normalized, rowNumber);
    case "faq":
      return importFaq(admin, normalized, rowNumber);
    case "content_gap":
      return importContentGap(admin, normalized, rowNumber);
    case "learning_path":
      return importLearningPath(admin, normalized, rowNumber);
    case "learning_path_course":
      return importLearningPathCourse(admin, normalized, rowNumber);
    default:
      throw new Error(`Unsupported item_type: ${normalized.item_type}`);
  }
}

async function findCourse(admin: Supabase, code?: string) {
  if (!code) throw new Error("course_code is required");
  const { data, error } = await admin.from("courses").select("id, code").eq("code", code).maybeSingle();
  if (error) throw error;
  if (!data) throw new Error(`Course not found: ${code}`);
  return data;
}

async function findOrCreateCategory(admin: Supabase, row: CurriculumRow) {
  const categoryCode = row.category_code?.trim();
  if (!categoryCode) return null;

  const { data: existing, error: existingError } = await admin
    .from("categories")
    .select("id")
    .eq("code", categoryCode)
    .maybeSingle();
  if (existingError) throw existingError;
  if (existing) return existing;

  const { data, error } = await admin
    .from("categories")
    .upsert({
      code: categoryCode,
      name_sw: row.category_name_sw?.trim() || categoryCode,
      description_sw: row.category_description_sw?.trim() || null,
      status: "draft",
    }, { onConflict: "code" })
    .select("id")
    .single();
  if (error) throw error;
  return data;
}

async function findModule(admin: Supabase, courseCode?: string, moduleCode?: string) {
  const course = await findCourse(admin, courseCode);
  if (!moduleCode) throw new Error("module_code is required");
  const { data, error } = await admin.from("course_modules").select("id, code").eq("course_id", course.id).eq("code", moduleCode).maybeSingle();
  if (error) throw error;
  if (!data) throw new Error(`Module not found: ${moduleCode}`);
  return data;
}

async function findLesson(admin: Supabase, courseCode?: string, moduleCode?: string, lessonCode?: string) {
  const module = await findModule(admin, courseCode, moduleCode);
  if (!lessonCode) throw new Error("lesson_code is required");
  const { data, error } = await admin.from("lessons").select("id, code").eq("module_id", module.id).eq("code", lessonCode).maybeSingle();
  if (error) throw error;
  if (!data) throw new Error(`Lesson not found: ${lessonCode}`);
  return data;
}

async function linkSource(admin: Supabase, contentType: string, contentId: string, sourceSegmentId?: string, sourceReference?: string) {
  if (!sourceSegmentId) return "source_missing";

  const { data: segment, error } = await admin
    .from("source_segments")
    .select("id, source_document_id")
    .eq("id", sourceSegmentId)
    .maybeSingle();
  if (error) throw error;
  if (!segment) return "source_missing";

  await admin.from("content_source_links").upsert({
    content_type: contentType,
    content_id: contentId,
    source_segment_id: segment.id,
    source_document_id: segment.source_document_id,
    link_status: "pending_review",
    evidence_note: sourceReference ?? null,
  }, { onConflict: "content_type,content_id,source_segment_id" });

  return "pending_review";
}

async function linkSourceAssets(
  admin: Supabase,
  contentType: string,
  contentId: string,
  sourceDocumentIds: string[],
  sourceReference?: string,
) {
  for (const sourceDocumentId of sourceDocumentIds) {
    await admin.from("content_source_assets").upsert({
      content_type: contentType,
      content_id: contentId,
      source_document_id: sourceDocumentId,
      link_status: "pending_review",
      evidence_note: sourceReference ?? null,
    }, { onConflict: "content_type,content_id,source_document_id" });
  }
}

function parseSourceDocumentIds(row: CurriculumRow): string[] {
  const ids: string[] = [];
  const sourceDocumentIds = parseJsonArray(row.source_document_ids)
    .map((value) => String(value).trim())
    .filter(Boolean);
  ids.push(...sourceDocumentIds);
  if (row.video_source_document_id) ids.push(row.video_source_document_id.trim());
  if (row.transcript_source_document_id) ids.push(row.transcript_source_document_id.trim());
  return [...new Set(ids)];
}

function basePayload(row: CurriculumRow, fallbackCode: string) {
  const title = row.title_sw ?? row.question_sw ?? fallbackCode;
  const itemType = getItemType(row);
  const shouldHoldForReview = Boolean(row.source_reference || row.source_reference_text || parseSourceDocumentIds(row).length > 0);
  const sourceLinkStatus = row.source_segment_id ? "pending_review" : shouldHoldForReview ? "pending_review" : "source_missing";

  return {
    code: row.code || codeFromText(title, fallbackCode),
    status: rowStatus(row),
    risk_level: rowRiskLevel(row),
    import_source: "notebooklm",
    external_id: row.external_id || `${itemType}:${fallbackCode}`,
    source_reference: row.source_reference ?? row.source_reference_text ?? null,
    source_link_status: sourceLinkStatus,
    sort_order: Number(row.sort_order ?? 0),
  };
}

async function importCourse(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const category = await findOrCreateCategory(admin, row);
  const payload = {
    ...basePayload(row, `course-${rowNumber}`),
    title_sw: row.title_sw,
    summary_sw: row.summary_sw ?? null,
    ...(category ? { category_id: category.id } : {}),
  };
  const { data, error } = await admin.from("courses").upsert(payload, { onConflict: "code" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "course", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("courses").update({ source_link_status: status }).eq("id", data.id);
  const sourceDocumentIds = parseSourceDocumentIds(row);
  if (sourceDocumentIds.length > 0) {
    await linkSourceAssets(admin, "course", data.id, sourceDocumentIds, row.source_reference ?? row.source_reference_text);
    await admin.from("courses").update({ source_link_status: "pending_review" }).eq("id", data.id);
  }
  return { row_number: rowNumber, item_type: "course", id: data.id, code: data.code };
}

async function importModule(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const course = await findCourse(admin, row.course_code);
  const payload = {
    ...basePayload(row, `${course.code}-module-${rowNumber}`),
    course_id: course.id,
    code: row.module_code || row.code || codeFromText(row.title_sw ?? `module-${rowNumber}`, `module-${rowNumber}`),
    title_sw: row.title_sw,
    summary_sw: row.summary_sw ?? null,
  };
  const { data, error } = await admin.from("course_modules").upsert(payload, { onConflict: "course_id,code" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "module", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("course_modules").update({ source_link_status: status }).eq("id", data.id);
  const sourceDocumentIds = parseSourceDocumentIds(row);
  if (sourceDocumentIds.length > 0) {
    await linkSourceAssets(admin, "module", data.id, sourceDocumentIds, row.source_reference ?? row.source_reference_text);
    await admin.from("course_modules").update({ source_link_status: "pending_review" }).eq("id", data.id);
  }
  return { row_number: rowNumber, item_type: "module", id: data.id, code: data.code };
}

async function importLesson(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const module = await findModule(admin, row.course_code, row.module_code);
  const payload = {
    ...basePayload(row, `${module.code}-lesson-${rowNumber}`),
    module_id: module.id,
    code: row.lesson_code || row.code || codeFromText(row.title_sw ?? `lesson-${rowNumber}`, `lesson-${rowNumber}`),
    title_sw: row.title_sw,
    body_sw: row.body_sw ?? row.source_reference_text ?? null,
    lesson_type: row.lesson_type ?? "reading",
  };
  const { data, error } = await admin.from("lessons").upsert(payload, { onConflict: "import_source,external_id" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "lesson", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("lessons").update({ source_link_status: status }).eq("id", data.id);

  const sourceDocumentIds = parseSourceDocumentIds(row);
  if (sourceDocumentIds.length > 0) {
    await linkSourceAssets(admin, "lesson", data.id, sourceDocumentIds, row.source_reference ?? row.source_reference_text);
    await admin.from("lessons").update({ source_link_status: "pending_review" }).eq("id", data.id);
  }

  const resourceEntries = [
    row.video_source_document_id
      ? {
          lesson_id: data.id,
          resource_type: "video",
          title_sw: row.title_sw,
          transcript_source_document_id: row.transcript_source_document_id ?? null,
          status: "draft",
        }
      : null,
    row.transcript_source_document_id
      ? {
          lesson_id: data.id,
          resource_type: "transcript",
          title_sw: `${row.title_sw ?? "Transcript"} (Transcript)`,
          transcript_source_document_id: row.transcript_source_document_id,
          status: "draft",
        }
      : null,
  ].filter(Boolean);

  for (const resource of resourceEntries) {
    await admin.from("lesson_resources").upsert(resource, {
      onConflict: "lesson_id,resource_type,title_sw",
    });
  }

  return { row_number: rowNumber, item_type: "lesson", id: data.id, code: data.code };
}

async function importChecklist(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const lesson = await findLesson(admin, row.course_code, row.module_code, row.lesson_code);
  const payload = {
    ...basePayload(row, `checklist-${rowNumber}`),
    lesson_id: lesson.id,
    title_sw: row.title_sw,
    items_sw: parseJsonArray(row.items_sw),
  };
  const { data, error } = await admin.from("checklists").upsert(payload, { onConflict: "import_source,external_id" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "checklist", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("checklists").update({ source_link_status: status }).eq("id", data.id);
  return { row_number: rowNumber, item_type: "checklist", id: data.id, code: data.code };
}

async function importQuiz(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const lesson = await findLesson(admin, row.course_code, row.module_code, row.lesson_code);
  const payload = {
    ...basePayload(row, `quiz-${rowNumber}`),
    lesson_id: lesson.id,
    question_sw: row.question_sw,
    options_sw: parseJsonArray(row.options_sw),
    correct_answer: row.correct_answer ?? null,
    explanation_sw: row.explanation_sw ?? null,
  };
  const { data, error } = await admin.from("quiz_questions").upsert(payload, { onConflict: "import_source,external_id" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "quiz_question", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("quiz_questions").update({ source_link_status: status }).eq("id", data.id);
  return { row_number: rowNumber, item_type: "quiz", id: data.id, code: data.code };
}

async function importFaq(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const course = await findCourse(admin, row.course_code);
  const payload = {
    ...basePayload(row, `faq-${rowNumber}`),
    course_id: course.id,
    question_sw: row.question_sw,
    answer_sw: row.answer_sw,
  };
  const { data, error } = await admin.from("faq_entries").upsert(payload, { onConflict: "import_source,external_id" }).select("id, code").single();
  if (error) throw error;
  const status = await linkSource(admin, "faq_entry", data.id, row.source_segment_id, row.source_reference ?? row.source_reference_text);
  await admin.from("faq_entries").update({ source_link_status: status }).eq("id", data.id);
  return { row_number: rowNumber, item_type: "faq", id: data.id, code: data.code };
}

async function importContentGap(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const course = row.course_code ? await findCourse(admin, row.course_code) : null;
  const payload = {
    ...basePayload(row, `gap-${rowNumber}`),
    course_id: course?.id ?? null,
    title_sw: row.title_sw,
    description_sw: row.body_sw ?? row.summary_sw ?? null,
  };
  const { data, error } = await admin.from("content_gaps").upsert(payload, { onConflict: "import_source,external_id" }).select("id, code").single();
  if (error) throw error;
  return { row_number: rowNumber, item_type: "content_gap", id: data.id, code: data.code };
}

async function importLearningPath(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const payload = {
    ...basePayload(row, `path-${rowNumber}`),
    code: row.learning_path_code || row.code || codeFromText(row.title_sw ?? `path-${rowNumber}`, `path-${rowNumber}`),
    title_sw: row.title_sw,
    description_sw: row.summary_sw ?? null,
  };
  const { data, error } = await admin.from("learning_paths").upsert(payload, { onConflict: "code" }).select("id, code").single();
  if (error) throw error;
  return { row_number: rowNumber, item_type: "learning_path", id: data.id, code: data.code };
}

async function importLearningPathCourse(admin: Supabase, row: CurriculumRow, rowNumber: number): Promise<PromotionResult> {
  const { data: path, error: pathError } = await admin.from("learning_paths").select("id").eq("code", row.learning_path_code).maybeSingle();
  if (pathError) throw pathError;
  if (!path) throw new Error(`Learning path not found: ${row.learning_path_code}`);
  const course = await findCourse(admin, row.course_code);
  const { data, error } = await admin.from("learning_path_courses").upsert({
    learning_path_id: path.id,
    course_id: course.id,
    sort_order: Number(row.sort_order ?? 0),
    required: true,
  }, { onConflict: "learning_path_id,course_id" }).select("id").single();
  if (error) throw error;
  return { row_number: rowNumber, item_type: "learning_path_course", id: data.id, code: course.code };
}
