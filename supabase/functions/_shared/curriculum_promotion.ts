import { codeFromText, serviceClient } from "./supabase.ts";
import { parseJsonArray, type CurriculumRow } from "./curriculum.ts";

type Supabase = ReturnType<typeof serviceClient>;

const ITEM_TYPES = new Set([
  "course",
  "module",
  "lesson",
  "fact",
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
      if (row.delivery_type && !["video", "text"].includes(row.delivery_type)) {
        return { valid: false, message: "delivery_type must be video or text" };
      }
      return { valid: true };
    case "module":
      if (!row.course_code) return { valid: false, message: "course_code is required for module" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for module" };
      return { valid: true };
    case "lesson":
      if (!row.course_code) return { valid: false, message: "course_code is required for lesson" };
      if (!row.module_code) return { valid: false, message: "module_code is required for lesson" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for lesson" };
      if (row.lesson_type && !["reading", "video"].includes(row.lesson_type)) {
        return { valid: false, message: "lesson_type must be reading or video" };
      }
      return { valid: true };
    case "fact":
      if (!row.course_code) return { valid: false, message: "course_code is required for fact" };
      if (!row.fact_sw && !row.body_sw && !row.answer_sw) {
        return { valid: false, message: "fact_sw is required for fact" };
      }
      if (!row.source_segment_id) {
        return { valid: false, message: "source_segment_id is required for fact" };
      }
      return { valid: true };
    case "checklist":
      if (!row.course_code) return { valid: false, message: "course_code is required for checklist" };
      if (!row.module_code) return { valid: false, message: "module_code is required for checklist" };
      if (!row.lesson_code) return { valid: false, message: "lesson_code is required for checklist" };
      if (!row.title_sw) return { valid: false, message: "title_sw is required for checklist" };
      if (!row.source_segment_id) {
        return { valid: false, message: "source_segment_id is required to convert checklist items into grounding facts" };
      }
      return { valid: true };
    case "quiz":
      // Quizzes are intentionally accepted and ignored so older NotebookLM
      // exports remain importable without creating learner quiz content.
      return { valid: true };
    case "faq":
      if (!row.course_code) return { valid: false, message: "course_code is required for faq" };
      if (!row.question_sw || !row.answer_sw) {
        return { valid: false, message: "question_sw and answer_sw are required for faq" };
      }
      if (!row.source_segment_id) {
        return { valid: false, message: "source_segment_id is required to convert FAQ answers into grounding facts" };
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
    case "fact":
      return importGroundingFact(admin, normalized, rowNumber);
    case "checklist":
      return importGroundingFact(admin, {
        ...normalized,
        fact_sw: parseJsonArray(normalized.items_sw).map(String).join("\n"),
      }, rowNumber, "checklist");
    case "quiz":
      return { row_number: rowNumber, item_type: "quiz_ignored" };
    case "faq":
      return importGroundingFact(admin, {
        ...normalized,
        fact_sw: normalized.answer_sw,
      }, rowNumber, "faq");
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
    delivery_type: row.delivery_type === "video" ? "video" : "text",
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
    lesson_type: row.lesson_type === "video" ? "video" : "reading",
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

async function importGroundingFact(
  admin: Supabase,
  row: CurriculumRow,
  rowNumber: number,
  legacyType = "fact",
): Promise<PromotionResult> {
  const course = await findCourse(admin, row.course_code);
  const module = row.module_code
    ? await findModule(admin, row.course_code, row.module_code)
    : null;
  const lesson = row.lesson_code
    ? await findLesson(admin, row.course_code, row.module_code, row.lesson_code)
    : null;
  if (!row.source_segment_id) throw new Error("source_segment_id is required for grounding fact");
  const fact = row.fact_sw ?? row.body_sw ?? row.answer_sw;
  if (!fact?.trim()) throw new Error("fact_sw is required for grounding fact");
  const fallbackCode = `${legacyType}-${rowNumber}`;
  const payload = {
    course_id: course.id,
    module_id: module?.id ?? null,
    lesson_id: lesson?.id ?? null,
    source_segment_id: row.source_segment_id,
    code: row.code || codeFromText(row.title_sw ?? row.question_sw ?? fact, fallbackCode),
    fact_sw: fact.trim(),
    question_sw: row.question_sw ?? null,
    status: rowStatus(row) === "published" ? "needs_review" : rowStatus(row),
    risk_level: rowRiskLevel(row),
    import_source: "notebooklm",
    external_id: row.external_id || `${legacyType}:${fallbackCode}`,
  };
  const { data, error } = await admin
    .from("grounding_facts")
    .upsert(payload, { onConflict: "import_source,external_id" })
    .select("id, code")
    .single();
  if (error) throw error;
  return { row_number: rowNumber, item_type: "fact", id: data.id, code: data.code };
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
