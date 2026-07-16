import fs from "node:fs";
import crypto from "node:crypto";
import process from "node:process";

import pg from "pg";

const IMPORT_PATH = "imports/ushuhuda-wangu/ushuhuda_wangu_curriculum_import.json";
const SOURCE_FILE_NAME = "Ushuhuda Wangu Toleo La 4 . DR MDASHIRU NURU IBRAHIM.pdf";
const COURSE_CODE = "CRS-USH-01";
const CONTENT_COURSE_ID = "ushuhuda-wangu";

const REQUIRED_BY_TYPE = {
  course: ["title_sw"],
  module: ["course_code", "module_code", "title_sw"],
  lesson: ["course_code", "module_code", "lesson_code", "title_sw"],
  checklist: ["course_code", "module_code", "lesson_code", "title_sw"],
  quiz: ["course_code", "module_code", "lesson_code", "question_sw"],
  faq: ["course_code", "question_sw", "answer_sw"],
  content_gap: ["title_sw"],
  learning_path: ["learning_path_code", "title_sw"],
  learning_path_course: ["learning_path_code", "course_code"],
};

function parseJsonArray(value) {
  if (Array.isArray(value)) return value;
  if (typeof value !== "string" || value.trim() === "") return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [parsed];
  } catch {
    return value.split("|").map((item) => item.trim()).filter(Boolean);
  }
}

function validateRow(row) {
  const itemType = row.item_type ?? row.record_type ?? "module";
  const required = REQUIRED_BY_TYPE[itemType];
  if (!required) return `Unsupported item_type: ${itemType}`;
  const missing = required.filter((field) => !row[field]);
  if (missing.length > 0) return `Missing required fields: ${missing.join(", ")}`;
  return null;
}

function evidenceFor(row) {
  return row.source_reference ?? row.source_reference_text ?? SOURCE_FILE_NAME;
}

function enrichRows(rows, sourceDocumentId) {
  return rows
    .map((row) => ({
      ...row,
      item_type: row.item_type ?? row.record_type ?? "module",
      source_document_ids: [sourceDocumentId],
      source_reference: evidenceFor(row),
    }))
    .filter((row) => !["quiz", "checklist", "faq"].includes(row.item_type));
}

function buildContentCourse(rows, sourceDocument) {
  const course = rows.find((row) => row.item_type === "course");
  const modules = rows
    .filter((row) => row.item_type === "module")
    .sort((a, b) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0));
  const moduleByCode = new Map(modules.map((row) => [row.module_code ?? row.code, row]));
  const sourceMeta = {
    sourceDocumentId: sourceDocument.id,
    sourceTitle: sourceDocument.title,
    fileName: sourceDocument.file_name,
    storagePath: sourceDocument.storage_path,
  };

  const readingLessons = rows
    .filter((row) => row.item_type === "lesson")
    .sort((a, b) => Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0))
    .map((row) => ({
      id: row.lesson_code ?? row.code,
      title: row.title_sw,
      type: row.lesson_type ?? "reading",
      meta: "Somo",
      description: row.body_sw ?? row.summary_sw ?? row.source_reference ?? "",
      isPremium: false,
      moduleCode: row.module_code,
      moduleTitle: moduleByCode.get(row.module_code)?.title_sw ?? null,
      source: sourceMeta,
    }));

  return {
    id: CONTENT_COURSE_ID,
    sourceCourseCode: COURSE_CODE,
    title: course.title_sw,
    description: course.summary_sw,
    badge: "Kitabu",
    icon: "menu_book",
    progress: 0,
    source: sourceMeta,
    outcomes: modules.map((row) => row.title_sw),
    modules: modules.map((row) => ({
      code: row.module_code ?? row.code,
      title: row.title_sw,
      summary: row.summary_sw ?? null,
      sortOrder: Number(row.sort_order ?? 0),
      source: sourceMeta,
    })),
    lessons: readingLessons,
    contentGaps: rows
      .filter((row) => row.item_type === "content_gap")
      .map((row) => ({
        code: row.code ?? row.external_id,
        title: row.title_sw,
        description: row.body_sw ?? row.summary_sw ?? null,
        source: sourceMeta,
      })),
  };
}

async function upsertSourceAsset(pool, contentType, contentId, sourceDocumentId, evidenceNote) {
  await pool.query(
    `insert into public.content_source_assets (
       content_type, content_id, source_document_id, link_status, evidence_note
     ) values ($1, $2, $3, 'pending_review', $4)
     on conflict (content_type, content_id, source_document_id) do update
     set link_status = excluded.link_status,
         evidence_note = excluded.evidence_note,
         updated_at = now()`,
    [contentType, contentId, sourceDocumentId, evidenceNote],
  );
}

async function main() {
  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error("SUPABASE_DATABASE_URL is required");

  const raw = fs.readFileSync(IMPORT_PATH, "utf8");
  const parsed = JSON.parse(raw);
  const originalRows = parsed.rows ?? parsed;
  if (!Array.isArray(originalRows)) throw new Error("Import JSON must contain rows");

  const pool = new pg.Pool({ connectionString: databaseUrl });
  const result = {
    stagedRows: 0,
    invalidRows: 0,
    structured: {},
    contentCourse: null,
    batchId: null,
  };

  try {
    await pool.query("begin");

    const sourceResult = await pool.query(
      `select id, title, file_name, storage_path
       from public.source_documents
       where file_name = $1`,
      [SOURCE_FILE_NAME],
    );
    if (sourceResult.rowCount !== 1) {
      throw new Error(`Expected one source document for ${SOURCE_FILE_NAME}, found ${sourceResult.rowCount}`);
    }
    const sourceDocument = sourceResult.rows[0];
    const rows = enrichRows(originalRows, sourceDocument.id);
    const errors = rows.map((row, index) => ({ row, index, error: validateRow(row) })).filter((item) => item.error);
    if (errors.length > 0) {
      throw new Error(`Import validation failed: ${JSON.stringify(errors.slice(0, 5))}`);
    }

    const batchHash = crypto.createHash("sha256").update(JSON.stringify({ rows })).digest("hex");
    const batch = await pool.query(
      `insert into public.curriculum_import_batches (
         import_source, batch_hash, file_name, row_count, valid_count, error_count,
         status, metadata, completed_at
       ) values (
         'notebooklm', $1, $2, $3, $3, 0, 'needs_review',
         $4::jsonb, now()
       )
       on conflict (batch_hash) do update
       set file_name = excluded.file_name,
           row_count = excluded.row_count,
           valid_count = excluded.valid_count,
           error_count = excluded.error_count,
           status = excluded.status,
           metadata = excluded.metadata,
           completed_at = now()
       returning id`,
      [
        batchHash,
        IMPORT_PATH,
        rows.length,
        JSON.stringify({
          mode: "direct_pg_import",
          source_document_id: sourceDocument.id,
          source_file_name: SOURCE_FILE_NAME,
        }),
      ],
    );
    const batchId = batch.rows[0].id;
    result.batchId = batchId;
    await pool.query(`delete from public.curriculum_staging_rows where batch_id = $1`, [batchId]);
    await pool.query(`delete from public.curriculum_import_errors where batch_id = $1`, [batchId]);

    for (const [index, row] of rows.entries()) {
      await pool.query(
        `insert into public.curriculum_staging_rows (
           batch_id, row_number, external_row_id, item_type, row_data,
           validation_status, promotion_result, promoted_at
         ) values ($1, $2, $3, $4, $5::jsonb, 'valid', '{}'::jsonb, null)
         on conflict (batch_id, row_number) do update
         set external_row_id = excluded.external_row_id,
             item_type = excluded.item_type,
             row_data = excluded.row_data,
             validation_status = excluded.validation_status,
             error_code = null,
             error_message = null,
             promotion_result = '{}'::jsonb,
             promoted_at = null`,
        [batchId, index + 1, row.external_id ?? null, row.item_type, JSON.stringify(row)],
      );
    }
    result.stagedRows = rows.length;

    const courseRow = rows.find((row) => row.item_type === "course");
    const courseInsert = await pool.query(
      `insert into public.courses (
         code, title_sw, language_code, status, risk_level, import_source,
         external_id, source_reference, source_link_status, sort_order,
         summary_sw, description_sw
       ) values ($1, $2, 'sw', 'draft', $3, 'notebooklm', $4, $5, 'pending_review', $6, $7, $7)
       on conflict (code) do update
       set title_sw = excluded.title_sw,
           status = excluded.status,
           risk_level = excluded.risk_level,
           import_source = excluded.import_source,
           external_id = excluded.external_id,
           source_reference = excluded.source_reference,
           source_link_status = excluded.source_link_status,
           sort_order = excluded.sort_order,
           summary_sw = excluded.summary_sw,
           description_sw = excluded.description_sw,
           updated_at = now()
       returning id, code`,
      [
        courseRow.code ?? COURSE_CODE,
        courseRow.title_sw,
        courseRow.risk_level ?? "normal",
        courseRow.external_id ?? COURSE_CODE,
        evidenceFor(courseRow),
        Number(courseRow.sort_order ?? 0),
        courseRow.summary_sw ?? null,
      ],
    );
    const course = courseInsert.rows[0];
    result.structured.course = course;
    await upsertSourceAsset(pool, "course", course.id, sourceDocument.id, evidenceFor(courseRow));

    const moduleIdByCode = new Map();
    for (const row of rows.filter((item) => item.item_type === "module")) {
      const moduleInsert = await pool.query(
        `insert into public.course_modules (
           course_id, code, title_sw, status, risk_level, import_source,
           external_id, source_reference, source_link_status, sort_order, summary_sw
         ) values ($1, $2, $3, 'draft', $4, 'notebooklm', $5, $6, 'pending_review', $7, $8)
         on conflict (course_id, code) do update
         set title_sw = excluded.title_sw,
             status = excluded.status,
             risk_level = excluded.risk_level,
             import_source = excluded.import_source,
             external_id = excluded.external_id,
             source_reference = excluded.source_reference,
             source_link_status = excluded.source_link_status,
             sort_order = excluded.sort_order,
             summary_sw = excluded.summary_sw,
             updated_at = now()
         returning id, code`,
        [
          course.id,
          row.module_code ?? row.code,
          row.title_sw,
          row.risk_level ?? "normal",
          row.external_id ?? row.module_code ?? row.code,
          evidenceFor(row),
          Number(row.sort_order ?? 0),
          row.summary_sw ?? null,
        ],
      );
      const module = moduleInsert.rows[0];
      moduleIdByCode.set(module.code, module.id);
      await upsertSourceAsset(pool, "module", module.id, sourceDocument.id, evidenceFor(row));
    }
    result.structured.modules = moduleIdByCode.size;

    const lessonIdByCode = new Map();
    for (const row of rows.filter((item) => item.item_type === "lesson")) {
      const moduleId = moduleIdByCode.get(row.module_code);
      if (!moduleId) throw new Error(`Module not found for lesson ${row.lesson_code}: ${row.module_code}`);
      const lessonInsert = await pool.query(
        `insert into public.lessons (
           module_id, code, title_sw, body_sw, lesson_type, status, risk_level,
           import_source, external_id, source_reference, source_link_status, sort_order
         ) values ($1, $2, $3, $4, $5, 'draft', $6, 'notebooklm', $7, $8, 'pending_review', $9)
         on conflict (module_id, code) do update
         set title_sw = excluded.title_sw,
             body_sw = excluded.body_sw,
             lesson_type = excluded.lesson_type,
             status = excluded.status,
             risk_level = excluded.risk_level,
             import_source = excluded.import_source,
             external_id = excluded.external_id,
             source_reference = excluded.source_reference,
             source_link_status = excluded.source_link_status,
             sort_order = excluded.sort_order,
             updated_at = now()
         returning id, code`,
        [
          moduleId,
          row.lesson_code ?? row.code,
          row.title_sw,
          row.body_sw ?? row.source_reference_text ?? row.summary_sw ?? null,
          row.lesson_type ?? "reading",
          row.risk_level ?? "normal",
          row.external_id ?? row.lesson_code ?? row.code,
          evidenceFor(row),
          Number(row.sort_order ?? 0),
        ],
      );
      const lesson = lessonInsert.rows[0];
      lessonIdByCode.set(lesson.code, lesson.id);
      await upsertSourceAsset(pool, "lesson", lesson.id, sourceDocument.id, evidenceFor(row));
    }
    result.structured.lessons = lessonIdByCode.size;

    const pathRow = rows.find((row) => row.item_type === "learning_path");
    if (pathRow) {
      const pathInsert = await pool.query(
        `insert into public.learning_paths (
           code, title_sw, status, description_sw, import_source,
           external_id, source_reference, sort_order
         ) values ($1, $2, 'draft', $3, 'notebooklm', $4, $5, $6)
         on conflict (code) do update
         set title_sw = excluded.title_sw,
             status = excluded.status,
             description_sw = excluded.description_sw,
             import_source = excluded.import_source,
             external_id = excluded.external_id,
             source_reference = excluded.source_reference,
             sort_order = excluded.sort_order,
             updated_at = now()
         returning id, code`,
        [
          pathRow.learning_path_code ?? pathRow.code,
          pathRow.title_sw,
          pathRow.summary_sw ?? null,
          pathRow.external_id ?? pathRow.learning_path_code ?? pathRow.code,
          evidenceFor(pathRow),
          Number(pathRow.sort_order ?? 0),
        ],
      );
      const path = pathInsert.rows[0];
      await pool.query(
        `insert into public.learning_path_courses (
           learning_path_id, course_id, sort_order, required
         ) values ($1, $2, $3, true)
         on conflict (learning_path_id, course_id) do update
         set sort_order = excluded.sort_order,
             required = excluded.required`,
        [path.id, course.id, Number(rows.find((row) => row.item_type === "learning_path_course")?.sort_order ?? 0)],
      );
      result.structured.learningPath = path;
    }

    const contentCourse = buildContentCourse(rows, sourceDocument);
    await pool.query(
      `insert into public.content_courses (id, status, payload, updated_at)
       values ($1, 'draft', $2::jsonb, now())
       on conflict (id) do update
       set status = excluded.status,
           payload = excluded.payload,
           updated_at = now()`,
      [contentCourse.id, JSON.stringify(contentCourse)],
    );
    result.contentCourse = {
      id: contentCourse.id,
      status: "draft",
      lessons: contentCourse.lessons.length,
      modules: contentCourse.modules.length,
      contentGaps: contentCourse.contentGaps.length,
    };

    await pool.query(
      `update public.curriculum_staging_rows
       set validation_status = 'promoted',
           promoted_at = now(),
           promotion_result = jsonb_build_object('mode', 'direct_pg_import', 'source_document_id', $2::text)
       where batch_id = $1`,
      [batchId, sourceDocument.id],
    );
    await pool.query(
      `update public.curriculum_import_batches
       set status = 'needs_review',
           metadata = metadata || $2::jsonb,
           completed_at = now()
       where id = $1`,
      [
        batchId,
        JSON.stringify({
          promoted_count: rows.length,
          structured_course_id: course.id,
          content_course_id: CONTENT_COURSE_ID,
        }),
      ],
    );

    await pool.query("commit");
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    await pool.query("rollback");
    console.error(error);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
