import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

import pg from "pg";

import { curriculumSourceDirectory, selectedCurricula } from "./remaining-curriculum-manifest.js";

const IMPORT_SOURCE = "local_markdown_curriculum";

function clean(value) {
  return String(value ?? "").replace(/\\([._*\-[\]()])/g, "$1").replace(/\s+/g, " ").trim();
}

function parseCsvLine(line) {
  const values = [];
  let value = "";
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (character === '"' && quoted && line[index + 1] === '"') {
      value += '"';
      index += 1;
    } else if (character === '"') {
      quoted = !quoted;
    } else if (character === "," && !quoted) {
      values.push(clean(value));
      value = "";
    } else {
      value += character;
    }
  }
  values.push(clean(value));
  return values;
}

function parseSections(markdown) {
  const sections = {};
  let current = null;
  for (const rawLine of markdown.split(/\r?\n/)) {
    const heading = rawLine.match(/^###\s+\d+\\\.\s+(.+)$/);
    if (heading) {
      current = clean(heading[1]).replace(/\s+\(.+\)$/, "");
      sections[current] = [];
      continue;
    }
    if (!current) continue;
    const line = rawLine.trim();
    if (line && !line.startsWith("unique\\_code")) sections[current].push(line);
  }
  return sections;
}

function rowsFor(sections, section) {
  return (sections[section] ?? []).map((line) => {
    const [code, content, sourceReference, status, riskLevel] = parseCsvLine(line);
    return {
      code,
      content,
      source_reference: sourceReference,
      status: status || "needs_review",
      risk_level: riskLevel || "high",
    };
  });
}

function splitTitleSummary(content) {
  const [title, ...summary] = clean(content).split(/\s+-\s+/);
  return { title: clean(title), summary: clean(summary.join(" - ")) };
}

function lessonTitle(content) {
  return clean(content).split(/\.\s+/)[0] || clean(content);
}

function safetyReading(module) {
  return `Soma sehemu hii ya chanzo na thibitisha ushauri wowote wa pembejeo, dawa, mbolea, afya ya mifugo, au makadirio ya fedha na mtaalamu kabla ya kuutumia. Rejea: ${module.source_reference}`;
}

function buildRows(markdown, curriculum, sourceDocumentId) {
  const sections = parseSections(markdown);
  const course = rowsFor(sections, "courses")[0];
  const modules = rowsFor(sections, "modules");
  const lessons = rowsFor(sections, "lessons");
  const checklists = rowsFor(sections, "checklists");
  const quizzes = rowsFor(sections, "quizzes");
  const faqs = rowsFor(sections, "faq");
  const gaps = rowsFor(sections, "content_gaps");
  if (!course || course.code !== curriculum.code || modules.length === 0) {
    throw new Error(`${curriculum.markdownFile} does not match ${curriculum.code} or has no modules`);
  }

  const title = splitTitleSummary(course.content);
  const source = { source_document_ids: [sourceDocumentId], source_reference: course.source_reference };
  const rows = [
    { item_type: "course", external_id: course.code, code: course.code, title_sw: title.title, summary_sw: title.summary || course.content, status: course.status, risk_level: course.risk_level, sort_order: 10, ...source },
    { item_type: "learning_path", external_id: `LP-${course.code}`, learning_path_code: `path-${course.code.toLowerCase()}`, code: `path-${course.code.toLowerCase()}`, title_sw: title.title, summary_sw: title.summary || course.content, status: course.status, risk_level: course.risk_level, sort_order: 10, ...source },
    { item_type: "learning_path_course", external_id: `LPC-${course.code}`, learning_path_code: `path-${course.code.toLowerCase()}`, course_code: course.code, status: course.status, risk_level: course.risk_level, sort_order: 10, ...source },
  ];
  modules.forEach((module, index) => rows.push({
    item_type: "module", external_id: module.code, code: module.code.toLowerCase(), course_code: course.code, module_code: module.code,
    title_sw: module.content, summary_sw: module.content, status: module.status, risk_level: module.risk_level, sort_order: (index + 1) * 10,
    source_document_ids: [sourceDocumentId], source_reference: module.source_reference,
  }));
  lessons.forEach((lesson, index) => rows.push({
    item_type: "lesson", external_id: lesson.code, code: lesson.code.toLowerCase(), course_code: course.code, module_code: modules[0].code, lesson_code: lesson.code,
    title_sw: lessonTitle(lesson.content), body_sw: lesson.content, lesson_type: "reading", status: lesson.status, risk_level: lesson.risk_level, sort_order: (index + 1) * 10,
    source_document_ids: [sourceDocumentId], source_reference: lesson.source_reference,
  }));
  modules.slice(1).forEach((module, index) => rows.push({
    item_type: "lesson", external_id: `${module.code}-READING-01`, code: `${module.code}-reading-01`.toLowerCase(), course_code: course.code, module_code: module.code, lesson_code: `${module.code}-READING-01`,
    title_sw: module.content, body_sw: safetyReading(module), lesson_type: "reading", status: module.status, risk_level: module.risk_level, sort_order: (index + 2) * 100,
    source_document_ids: [sourceDocumentId], source_reference: module.source_reference,
  }));
  for (const [type, items] of [["checklist", checklists], ["quiz", quizzes], ["faq", faqs], ["content_gap", gaps]]) {
    items.forEach((item, index) => rows.push({
      item_type: type, external_id: item.code, code: item.code.toLowerCase(), course_code: course.code, module_code: modules[0].code, lesson_code: lessons[0]?.code ?? `${modules[0].code}-READING-01`,
      title_sw: type === "content_gap" ? item.content : undefined, body_sw: type === "content_gap" ? item.content : undefined, question_sw: type === "quiz" || type === "faq" ? item.content : undefined,
      items_sw: type === "checklist" ? [item.content] : undefined, answer_sw: type === "faq" ? item.content : undefined, status: item.status, risk_level: item.risk_level, sort_order: (index + 1) * 10,
      source_document_ids: [sourceDocumentId], source_reference: item.source_reference,
    }));
  }
  return rows;
}

async function linkSource(pool, contentType, contentId, sourceDocumentId, evidence) {
  await pool.query(`insert into public.content_source_assets (content_type, content_id, source_document_id, link_status, evidence_note)
    values ($1, $2, $3, 'pending_review', $4)
    on conflict (content_type, content_id, source_document_id) do update set link_status = excluded.link_status, evidence_note = excluded.evidence_note, updated_at = now()`, [contentType, contentId, sourceDocumentId, evidence]);
}

function buildContentCourse(rows, sourceDocument, curriculum) {
  const course = rows.find((row) => row.item_type === "course");
  const modules = rows.filter((row) => row.item_type === "module");
  const modulesByCode = new Map(modules.map((module) => [module.module_code, module]));
  const source = { sourceDocumentId: sourceDocument.id, sourceTitle: sourceDocument.title, fileName: sourceDocument.file_name, storagePath: sourceDocument.storage_path };
  return {
    id: curriculum.contentCourseId, sourceCourseCode: curriculum.code, title: course.title_sw, description: course.summary_sw, badge: "Inahitaji uhakiki", icon: "menu_book", progress: 0,
    source, riskLevel: "high", reviewStatus: "needs_review", outcomes: modules.map((module) => module.title_sw),
    modules: modules.map((module) => ({ code: module.module_code, title: module.title_sw, summary: module.summary_sw, sortOrder: module.sort_order, status: "needs_review", riskLevel: "high", source })),
    lessons: rows.filter((row) => row.item_type === "lesson").map((lesson) => ({ id: lesson.lesson_code, title: lesson.title_sw, type: "reading", meta: "Somo", description: lesson.body_sw, isPremium: false, moduleCode: lesson.module_code, moduleTitle: modulesByCode.get(lesson.module_code)?.title_sw ?? null, status: "needs_review", riskLevel: "high", sourceReference: lesson.source_reference, source })),
    contentGaps: rows.filter((row) => row.item_type === "content_gap").map((gap) => ({ code: gap.code, title: gap.title_sw, description: gap.body_sw, status: "needs_review", riskLevel: "high", sourceReference: gap.source_reference, source })),
  };
}

async function ingest(pool, curriculum, sourceDir) {
  const markdownPath = path.resolve(sourceDir, curriculum.markdownFile);
  const markdown = fs.readFileSync(markdownPath, "utf8");
  const sourceResult = await pool.query("select id, title, file_name, storage_path from public.source_documents where file_name = $1", [curriculum.sourceFile]);
  if (sourceResult.rowCount !== 1) throw new Error(`${curriculum.code}: expected one source document for ${curriculum.sourceFile}, found ${sourceResult.rowCount}`);
  const sourceDocument = sourceResult.rows[0];
  const rows = buildRows(markdown, curriculum, sourceDocument.id);
  const batchHash = crypto.createHash("sha256").update(JSON.stringify({ curriculum, rows })).digest("hex");
  const batch = await pool.query(`insert into public.curriculum_import_batches (import_source, batch_hash, file_name, row_count, valid_count, error_count, status, metadata, completed_at)
    values ($1, $2, $3, $4, $4, 0, 'needs_review', $5::jsonb, now())
    on conflict (batch_hash) do update set row_count = excluded.row_count, valid_count = excluded.valid_count, error_count = excluded.error_count, status = excluded.status, metadata = excluded.metadata, completed_at = now()
    returning id`, [IMPORT_SOURCE, batchHash, markdownPath, rows.length, JSON.stringify({ course_code: curriculum.code, source_markdown_file: curriculum.markdownFile, source_document_id: sourceDocument.id, content_course_id: curriculum.contentCourseId, review_reason: "All generated curriculum remains hidden until source and subject-matter review are complete." })]);
  const batchId = batch.rows[0].id;
  await pool.query("delete from public.curriculum_staging_rows where batch_id = $1", [batchId]);
  for (const [index, row] of rows.entries()) await pool.query(`insert into public.curriculum_staging_rows (batch_id, row_number, external_row_id, item_type, row_data, validation_status, promotion_result)
    values ($1, $2, $3, $4, $5::jsonb, 'valid', '{}'::jsonb)`, [batchId, index + 1, row.external_id, row.item_type, JSON.stringify(row)]);

  const courseRow = rows.find((row) => row.item_type === "course");
  const course = (await pool.query(`insert into public.courses (code, title_sw, language_code, status, risk_level, import_source, external_id, source_reference, source_link_status, sort_order, summary_sw, description_sw)
    values ($1, $2, 'sw', 'needs_review', 'high', $3, $4, $5, 'pending_review', $6, $7, $7)
    on conflict (code) do update set title_sw = excluded.title_sw, status = excluded.status, risk_level = excluded.risk_level, import_source = excluded.import_source, external_id = excluded.external_id, source_reference = excluded.source_reference, source_link_status = excluded.source_link_status, sort_order = excluded.sort_order, summary_sw = excluded.summary_sw, description_sw = excluded.description_sw, updated_at = now() returning id, code`, [curriculum.code, courseRow.title_sw, IMPORT_SOURCE, courseRow.external_id, courseRow.source_reference, courseRow.sort_order, courseRow.summary_sw])).rows[0];
  await linkSource(pool, "course", course.id, sourceDocument.id, courseRow.source_reference);
  const moduleIds = new Map();
  for (const moduleRow of rows.filter((row) => row.item_type === "module")) {
    const module = (await pool.query(`insert into public.course_modules (course_id, code, title_sw, status, risk_level, import_source, external_id, source_reference, source_link_status, sort_order, summary_sw)
      values ($1, $2, $3, 'needs_review', 'high', $4, $5, $6, 'pending_review', $7, $8)
      on conflict (course_id, code) do update set title_sw = excluded.title_sw, status = excluded.status, risk_level = excluded.risk_level, import_source = excluded.import_source, external_id = excluded.external_id, source_reference = excluded.source_reference, source_link_status = excluded.source_link_status, sort_order = excluded.sort_order, summary_sw = excluded.summary_sw, updated_at = now() returning id, code`, [course.id, moduleRow.module_code, moduleRow.title_sw, IMPORT_SOURCE, moduleRow.external_id, moduleRow.source_reference, moduleRow.sort_order, moduleRow.summary_sw])).rows[0];
    moduleIds.set(module.code, module.id);
    await linkSource(pool, "module", module.id, sourceDocument.id, moduleRow.source_reference);
  }
  let lessonCount = 0;
  for (const lessonRow of rows.filter((row) => row.item_type === "lesson")) {
    const moduleId = moduleIds.get(lessonRow.module_code);
    const lesson = (await pool.query(`insert into public.lessons (module_id, code, title_sw, body_sw, lesson_type, status, risk_level, import_source, external_id, source_reference, source_link_status, sort_order)
      values ($1, $2, $3, $4, 'reading', 'needs_review', 'high', $5, $6, $7, 'pending_review', $8)
      on conflict (module_id, code) do update set title_sw = excluded.title_sw, body_sw = excluded.body_sw, lesson_type = excluded.lesson_type, status = excluded.status, risk_level = excluded.risk_level, import_source = excluded.import_source, external_id = excluded.external_id, source_reference = excluded.source_reference, source_link_status = excluded.source_link_status, sort_order = excluded.sort_order, updated_at = now() returning id`, [moduleId, lessonRow.lesson_code, lessonRow.title_sw, lessonRow.body_sw, IMPORT_SOURCE, lessonRow.external_id, lessonRow.source_reference, lessonRow.sort_order])).rows[0];
    lessonCount += 1;
    await linkSource(pool, "lesson", lesson.id, sourceDocument.id, lessonRow.source_reference);
  }
  const pathRow = rows.find((row) => row.item_type === "learning_path");
  const learningPath = (await pool.query(`insert into public.learning_paths (code, title_sw, status, description_sw, import_source, external_id, source_reference, sort_order)
    values ($1, $2, 'needs_review', $3, $4, $5, $6, $7)
    on conflict (code) do update set title_sw = excluded.title_sw, status = excluded.status, description_sw = excluded.description_sw, import_source = excluded.import_source, external_id = excluded.external_id, source_reference = excluded.source_reference, sort_order = excluded.sort_order, updated_at = now() returning id`, [pathRow.learning_path_code, pathRow.title_sw, pathRow.summary_sw, IMPORT_SOURCE, pathRow.external_id, pathRow.source_reference, pathRow.sort_order])).rows[0];
  await pool.query(`insert into public.learning_path_courses (learning_path_id, course_id, sort_order, required) values ($1, $2, 10, true) on conflict (learning_path_id, course_id) do update set sort_order = excluded.sort_order, required = excluded.required`, [learningPath.id, course.id]);
  const contentCourse = buildContentCourse(rows, sourceDocument, curriculum);
  await pool.query(`insert into public.content_courses (id, status, payload, updated_at) values ($1, 'draft', $2::jsonb, now()) on conflict (id) do update set status = excluded.status, payload = excluded.payload, updated_at = now()`, [curriculum.contentCourseId, JSON.stringify(contentCourse)]);
  await pool.query(`update public.curriculum_staging_rows set validation_status = case when item_type in ('course', 'module', 'lesson', 'learning_path', 'learning_path_course') then 'promoted' else 'valid' end, promoted_at = case when item_type in ('course', 'module', 'lesson', 'learning_path', 'learning_path_course') then now() else null end, promotion_result = jsonb_build_object('mode', 'direct_markdown_import', 'source_document_id', $2::text) where batch_id = $1`, [batchId, sourceDocument.id]);
  return { code: curriculum.code, batchId, stagedRows: rows.length, modules: moduleIds.size, lessons: lessonCount, contentCourseId: curriculum.contentCourseId, contentCourseStatus: "draft" };
}

async function main() {
  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error("SUPABASE_DATABASE_URL is required");
  const pool = new pg.Pool({ connectionString: databaseUrl });
  const client = await pool.connect();
  try {
    await client.query("begin");
    const results = [];
    for (const curriculum of selectedCurricula()) results.push(await ingest(client, curriculum, curriculumSourceDirectory()));
    await client.query("commit");
    console.log(JSON.stringify({ imported: results }, null, 2));
  } catch (error) {
    await client.query("rollback");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
