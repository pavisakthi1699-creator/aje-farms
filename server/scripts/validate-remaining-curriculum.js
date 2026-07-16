import fs from "node:fs";
import path from "node:path";
import process from "node:process";

import pg from "pg";

import { curriculumSourceDirectory, selectedCurricula } from "./remaining-curriculum-manifest.js";

function fail(message) {
  throw new Error(message);
}

async function validateCourse(pool, curriculum, sourceDir) {
  const markdownPath = path.resolve(sourceDir, curriculum.markdownFile);
  if (!fs.existsSync(markdownPath)) fail(`${curriculum.code}: source markdown is missing: ${markdownPath}`);
  const source = await pool.query(`select d.id, d.processing_status,
      exists (select 1 from storage.objects o where o.bucket_id = d.storage_bucket and o.name = d.storage_path) as storage_object_exists
    from public.source_documents d where d.file_name = $1`, [curriculum.sourceFile]);
  if (source.rowCount !== 1) fail(`${curriculum.code}: expected one source document for ${curriculum.sourceFile}, found ${source.rowCount}`);
  if (!source.rows[0].storage_object_exists) fail(`${curriculum.code}: source PDF is not uploaded to private Supabase Storage`);
  const course = await pool.query("select id, status, risk_level, source_link_status from public.courses where code = $1", [curriculum.code]);
  if (course.rowCount !== 1) fail(`${curriculum.code}: structured course is missing`);
  const courseRow = course.rows[0];
  if (courseRow.status !== "needs_review" || courseRow.risk_level !== "high" || courseRow.source_link_status !== "pending_review") fail(`${curriculum.code}: course safety status is not needs_review/high/pending_review`);
  const modules = await pool.query("select id, code, status, risk_level, source_link_status from public.course_modules where course_id = $1 order by sort_order", [courseRow.id]);
  if (modules.rowCount === 0) fail(`${curriculum.code}: no modules were imported`);
  if (modules.rows.some((row) => row.status !== "needs_review" || row.risk_level !== "high" || row.source_link_status !== "pending_review")) fail(`${curriculum.code}: a module has unsafe review state`);
  const lessons = await pool.query("select id, status, risk_level, source_link_status from public.lessons where module_id = any($1::uuid[])", [modules.rows.map((row) => row.id)]);
  if (lessons.rowCount < modules.rowCount) fail(`${curriculum.code}: every module must have at least one reading lesson`);
  if (lessons.rows.some((row) => row.status !== "needs_review" || row.risk_level !== "high" || row.source_link_status !== "pending_review")) fail(`${curriculum.code}: a lesson has unsafe review state`);
  const sourceLinks = await pool.query("select content_type, count(*)::int as count from public.content_source_assets where source_document_id = $1 and content_id = any($2::uuid[]) group by content_type", [source.rows[0].id, [courseRow.id, ...modules.rows.map((row) => row.id), ...lessons.rows.map((row) => row.id)]]);
  const counts = Object.fromEntries(sourceLinks.rows.map((row) => [row.content_type, row.count]));
  if (counts.course !== 1 || counts.module !== modules.rowCount || counts.lesson !== lessons.rowCount) fail(`${curriculum.code}: source links are incomplete`);
  const pathLink = await pool.query("select count(*)::int as count from public.learning_path_courses where course_id = $1", [courseRow.id]);
  if (Number(pathLink.rows[0].count) !== 1) fail(`${curriculum.code}: learning-path link is missing`);
  const contentCourse = await pool.query("select status, payload ->> 'sourceCourseCode' as source_course_code, jsonb_array_length(coalesce(payload -> 'lessons', '[]'::jsonb)) as lesson_count from public.content_courses where id = $1", [curriculum.contentCourseId]);
  if (contentCourse.rowCount !== 1 || contentCourse.rows[0].status !== "draft" || contentCourse.rows[0].source_course_code !== curriculum.code || Number(contentCourse.rows[0].lesson_count) !== lessons.rowCount) fail(`${curriculum.code}: learner payload is missing, incorrect, or visible before review`);
  const batch = await pool.query("select id, row_count, valid_count, error_count, status from public.curriculum_import_batches where metadata ->> 'course_code' = $1 and import_source = 'local_markdown_curriculum' order by completed_at desc limit 1", [curriculum.code]);
  if (batch.rowCount !== 1 || batch.rows[0].status !== "needs_review" || Number(batch.rows[0].error_count) !== 0 || Number(batch.rows[0].valid_count) !== Number(batch.rows[0].row_count)) fail(`${curriculum.code}: import batch is incomplete`);
  const staged = await pool.query("select count(*)::int as count from public.curriculum_staging_rows where batch_id = $1", [batch.rows[0].id]);
  if (Number(staged.rows[0].count) !== Number(batch.rows[0].row_count)) fail(`${curriculum.code}: staged row count does not match its import batch`);
  return { code: curriculum.code, modules: modules.rowCount, lessons: lessons.rowCount, stagedRows: Number(staged.rows[0].count), contentCourse: curriculum.contentCourseId };
}

async function main() {
  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) fail("SUPABASE_DATABASE_URL is required");
  const pool = new pg.Pool({ connectionString: databaseUrl });
  try {
    const results = [];
    for (const curriculum of selectedCurricula()) results.push(await validateCourse(pool, curriculum, curriculumSourceDirectory()));
    console.log(JSON.stringify({ valid: results }, null, 2));
  } finally {
    await pool.end();
  }
}

main().catch((error) => { console.error(`FAIL: ${error.message}`); process.exitCode = 1; });
