import fs from "node:fs";
import crypto from "node:crypto";
import process from "node:process";

import pg from "pg";

const MD_PATH = "/Users/frankmchaina/Downloads/MAGONJWA YA KUKU TIBA ZAKE ZA ASILI.md";
const SOURCE_FILE_NAME = "MAGONJWA YA KUKU TIBA ZAKE ZA ASILI.pdf";
const COURSE_CODE = "CRS-KUK-02";
const CONTENT_COURSE_ID = "magonjwa-ya-kuku-tiba-asili";

function clean(value) {
  return String(value ?? "")
    .replace(/\\([._*\-[\]()])/g, "$1")
    .replace(/\s+/g, " ")
    .trim();
}

function parseCsvLine(line) {
  const out = [];
  let current = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    const next = line[i + 1];
    if (char === "\"" && inQuotes && next === "\"") {
      current += "\"";
      i += 1;
    } else if (char === "\"") {
      inQuotes = !inQuotes;
    } else if (char === "," && !inQuotes) {
      out.push(clean(current));
      current = "";
    } else {
      current += char;
    }
  }
  out.push(clean(current));
  return out;
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
    if (!line || line.startsWith("unique\\_code")) continue;
    sections[current].push(line);
  }
  return sections;
}

function rowsFor(sections, name) {
  return (sections[name] ?? []).map((line) => {
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
  const [title, ...rest] = clean(content).split(/\s+-\s+/);
  return {
    title: clean(title),
    summary: clean(rest.join(" - ")),
  };
}

function moduleCodeFromOrdinal(index) {
  return `MOD-KUK-${String(index + 1).padStart(2, "0")}`;
}

function lessonModuleCode(code, index) {
  if (code.startsWith("LSN-KUK-")) return "MOD-KUK-01";
  if (code.startsWith("CHK-KUK-")) return moduleCodeFromOrdinal(index);
  if (code.startsWith("QZ-KUK-")) {
    const number = Number(code.replace("QZ-KUK-", ""));
    if ([1, 2, 3].includes(number)) return "MOD-KUK-01";
    if ([4, 5, 6, 7, 8, 11, 14].includes(number)) return "MOD-KUK-02";
    return "MOD-KUK-03";
  }
  return "MOD-KUK-01";
}

function answerFromContent(content) {
  const match = clean(content).match(/^(.*?)(?:\s+Jibu:\s*)(.+)$/i);
  if (!match) return { question: clean(content), answer: null };
  return { question: clean(match[1]), answer: clean(match[2]) };
}

function checklistItems(content) {
  const normalized = clean(content);
  const withoutPrefix = normalized.replace(/^Moduli\s+\d+:\s*/i, "");
  return withoutPrefix
    .split(/\.\s+/)
    .map((item) => clean(item.replace(/\.$/, "")))
    .filter(Boolean);
}

function buildRows(markdown, sourceDocumentId) {
  const sections = parseSections(markdown);
  const courseRaw = rowsFor(sections, "courses")[0];
  const modulesRaw = rowsFor(sections, "modules");
  const lessonsRaw = rowsFor(sections, "lessons")[0] ? rowsFor(sections, "lessons") : rowsFor(sections, "lessons za Moduli ya kwanza pekee");
  const checklistsRaw = rowsFor(sections, "checklists");
  const quizzesRaw = rowsFor(sections, "quizzes");
  const faqsRaw = rowsFor(sections, "faq");
  const gapsRaw = rowsFor(sections, "content_gaps");
  if (!courseRaw) throw new Error("No course row found in markdown");

  const courseTitle = splitTitleSummary(courseRaw.content);
  const rows = [
    {
      item_type: "course",
      external_id: COURSE_CODE,
      code: COURSE_CODE,
      title_sw: courseTitle.title,
      summary_sw: courseTitle.summary || courseRaw.content,
      status: courseRaw.status,
      risk_level: courseRaw.risk_level,
      source_reference: courseRaw.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: 10,
    },
    {
      item_type: "learning_path",
      external_id: "LP-KUK-MAGONJWA",
      learning_path_code: "magonjwa-ya-kuku-na-tiba-asili",
      code: "magonjwa-ya-kuku-na-tiba-asili",
      title_sw: "Magonjwa ya Kuku na Tiba za Asili",
      summary_sw: courseTitle.summary || courseRaw.content,
      status: courseRaw.status,
      risk_level: courseRaw.risk_level,
      source_reference: courseRaw.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: 20,
    },
    {
      item_type: "learning_path_course",
      external_id: "LPC-KUK-MAGONJWA",
      learning_path_code: "magonjwa-ya-kuku-na-tiba-asili",
      course_code: COURSE_CODE,
      status: courseRaw.status,
      risk_level: courseRaw.risk_level,
      source_reference: courseRaw.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: 10,
    },
  ];

  modulesRaw.forEach((row, index) => {
    rows.push({
      item_type: "module",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      module_code: row.code,
      title_sw: row.content,
      summary_sw: row.content,
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  lessonsRaw.forEach((row, index) => {
    rows.push({
      item_type: "lesson",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      module_code: lessonModuleCode(row.code, index),
      lesson_code: row.code,
      title_sw: row.content.split(/\.\s+/)[0],
      body_sw: row.content,
      lesson_type: "reading",
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  modulesRaw.slice(1).forEach((row, index) => {
    const moduleIndex = index + 1;
    const lessonCode = `${row.code}-READING-01`;
    rows.push({
      item_type: "lesson",
      external_id: lessonCode,
      code: lessonCode.toLowerCase(),
      course_code: COURSE_CODE,
      module_code: row.code,
      lesson_code: lessonCode,
      title_sw: row.content,
      body_sw: `Soma sehemu hii ya kitabu na hakiki mapendekezo yote na mtaalamu kabla ya kutumia tiba kwa kuku. Chanzo: ${row.source_reference}`,
      lesson_type: "reading",
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (moduleIndex + 1) * 100,
    });
  });

  checklistsRaw.forEach((row, index) => {
    const moduleCode = lessonModuleCode(row.code, index);
    rows.push({
      item_type: "checklist",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      module_code: moduleCode,
      lesson_code: moduleCode === "MOD-KUK-01" ? "LSN-KUK-001" : `${moduleCode}-READING-01`,
      title_sw: row.content.split(":")[0],
      items_sw: checklistItems(row.content),
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  quizzesRaw.forEach((row, index) => {
    const parsed = answerFromContent(row.content);
    const moduleCode = lessonModuleCode(row.code, index);
    rows.push({
      item_type: "quiz",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      module_code: moduleCode,
      lesson_code: moduleCode === "MOD-KUK-01" ? "LSN-KUK-001" : `${moduleCode}-READING-01`,
      question_sw: parsed.question,
      options_sw: parsed.answer ? [parsed.answer] : [],
      correct_answer: parsed.answer,
      explanation_sw: parsed.answer,
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  faqsRaw.forEach((row, index) => {
    const parsed = answerFromContent(row.content);
    rows.push({
      item_type: "faq",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      question_sw: parsed.question,
      answer_sw: parsed.answer ?? row.content,
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  gapsRaw.forEach((row, index) => {
    rows.push({
      item_type: "content_gap",
      external_id: row.code,
      code: row.code.toLowerCase(),
      course_code: COURSE_CODE,
      title_sw: row.content,
      body_sw: row.content,
      status: row.status,
      risk_level: row.risk_level,
      source_reference: row.source_reference,
      source_document_ids: [sourceDocumentId],
      sort_order: (index + 1) * 10,
    });
  });

  return rows;
}

function requireFields(row, fields) {
  for (const field of fields) {
    if (!row[field]) throw new Error(`${row.item_type} ${row.external_id ?? row.code} missing ${field}`);
  }
}

function validateRows(rows) {
  for (const row of rows) {
    if (row.item_type === "course") requireFields(row, ["title_sw"]);
    if (row.item_type === "module") requireFields(row, ["course_code", "module_code", "title_sw"]);
    if (row.item_type === "lesson") requireFields(row, ["course_code", "module_code", "lesson_code", "title_sw"]);
    if (row.item_type === "checklist") requireFields(row, ["course_code", "module_code", "lesson_code", "title_sw"]);
    if (row.item_type === "quiz") requireFields(row, ["course_code", "module_code", "lesson_code", "question_sw"]);
    if (row.item_type === "faq") requireFields(row, ["course_code", "question_sw", "answer_sw"]);
    if (!["needs_review", "draft", "approved", "published", "archived", "failed"].includes(row.status)) {
      throw new Error(`${row.item_type} ${row.external_id ?? row.code} has invalid status ${row.status}`);
    }
    if (!["normal", "medium", "high"].includes(row.risk_level)) {
      throw new Error(`${row.item_type} ${row.external_id ?? row.code} has invalid risk ${row.risk_level}`);
    }
  }
}

function buildContentCourse(rows, sourceDocument) {
  const course = rows.find((row) => row.item_type === "course");
  const modules = rows.filter((row) => row.item_type === "module");
  const moduleByCode = new Map(modules.map((row) => [row.module_code, row]));
  const source = {
    sourceDocumentId: sourceDocument.id,
    sourceTitle: sourceDocument.title,
    fileName: sourceDocument.file_name,
    storagePath: sourceDocument.storage_path,
  };
  const itemRows = rows.filter((row) => ["lesson", "checklist", "quiz", "faq"].includes(row.item_type));
  return {
    id: CONTENT_COURSE_ID,
    sourceCourseCode: COURSE_CODE,
    title: course.title_sw,
    description: course.summary_sw,
    badge: "Needs review",
    icon: "health_and_safety",
    progress: 0,
    source,
    riskLevel: "high",
    reviewStatus: "needs_review",
    outcomes: modules.map((row) => row.title_sw),
    modules: modules.map((row) => ({
      code: row.module_code,
      title: row.title_sw,
      summary: row.summary_sw,
      sortOrder: Number(row.sort_order ?? 0),
      status: row.status,
      riskLevel: row.risk_level,
      source,
    })),
    lessons: [
      ...itemRows.map((row) => ({
        id: row.lesson_code ?? row.code ?? row.external_id,
        title: row.title_sw ?? row.question_sw,
        type: row.item_type === "lesson" ? row.lesson_type : row.item_type === "quiz" ? "quiz" : row.item_type,
        meta: row.item_type === "quiz" ? "Swali" : row.item_type === "faq" ? "Jibu" : row.item_type === "checklist" ? "Checklist" : "Somo",
        description: row.body_sw ?? row.answer_sw ?? row.explanation_sw ?? row.question_sw ?? row.title_sw,
        isPremium: false,
        moduleCode: row.module_code ?? null,
        moduleTitle: moduleByCode.get(row.module_code)?.title_sw ?? null,
        status: row.status,
        riskLevel: row.risk_level,
        sourceReference: row.source_reference,
        question: row.question_sw ?? null,
        answer: row.answer_sw ?? row.correct_answer ?? null,
        options: row.options_sw ?? [],
        items: row.items_sw ?? [],
        source,
      })),
      {
        id: "magonjwa-ya-kuku-pdf",
        title: sourceDocument.title,
        type: "pdf",
        meta: "PDF",
        description: "Kitabu asili kilichotumika kujenga kozi hii.",
        isPremium: false,
        status: "needs_review",
        riskLevel: "high",
        url: null,
        source,
      },
    ],
    contentGaps: rows.filter((row) => row.item_type === "content_gap").map((row) => ({
      code: row.code,
      title: row.title_sw,
      description: row.body_sw,
      status: row.status,
      riskLevel: row.risk_level,
      sourceReference: row.source_reference,
      source,
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
  const pool = new pg.Pool({ connectionString: databaseUrl });
  const result = {};
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
    const rows = buildRows(fs.readFileSync(MD_PATH, "utf8"), sourceDocument.id);
    validateRows(rows);

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
        MD_PATH,
        rows.length,
        JSON.stringify({
          mode: "direct_markdown_import",
          source_document_id: sourceDocument.id,
          source_file_name: SOURCE_FILE_NAME,
          review_reason: "Livestock disease and treatment content is high risk and requires expert review.",
        }),
      ],
    );
    const batchId = batch.rows[0].id;
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

    const courseRow = rows.find((row) => row.item_type === "course");
    const courseInsert = await pool.query(
      `insert into public.courses (
         code, title_sw, language_code, status, risk_level, import_source,
         external_id, source_reference, source_link_status, sort_order,
         summary_sw, description_sw
       ) values ($1, $2, 'sw', 'needs_review', 'high', 'notebooklm', $3, $4, 'pending_review', $5, $6, $6)
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
      [COURSE_CODE, courseRow.title_sw, courseRow.external_id, courseRow.source_reference, Number(courseRow.sort_order ?? 0), courseRow.summary_sw],
    );
    const course = courseInsert.rows[0];
    await upsertSourceAsset(pool, "course", course.id, sourceDocument.id, courseRow.source_reference);

    const moduleIdByCode = new Map();
    for (const row of rows.filter((item) => item.item_type === "module")) {
      const moduleInsert = await pool.query(
        `insert into public.course_modules (
           course_id, code, title_sw, status, risk_level, import_source,
           external_id, source_reference, source_link_status, sort_order, summary_sw
         ) values ($1, $2, $3, 'needs_review', 'high', 'notebooklm', $4, $5, 'pending_review', $6, $7)
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
        [course.id, row.module_code, row.title_sw, row.external_id, row.source_reference, Number(row.sort_order ?? 0), row.summary_sw],
      );
      const module = moduleInsert.rows[0];
      moduleIdByCode.set(module.code, module.id);
      await upsertSourceAsset(pool, "module", module.id, sourceDocument.id, row.source_reference);
    }

    let lessonCount = 0;
    for (const row of rows.filter((item) => item.item_type === "lesson")) {
      const moduleId = moduleIdByCode.get(row.module_code);
      if (!moduleId) throw new Error(`Module not found for lesson ${row.lesson_code}: ${row.module_code}`);
      const lessonInsert = await pool.query(
        `insert into public.lessons (
           module_id, code, title_sw, body_sw, lesson_type, status, risk_level,
           import_source, external_id, source_reference, source_link_status, sort_order
         ) values ($1, $2, $3, $4, 'reading', 'needs_review', 'high', 'notebooklm', $5, $6, 'pending_review', $7)
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
         returning id`,
        [moduleId, row.lesson_code, row.title_sw, row.body_sw, row.external_id, row.source_reference, Number(row.sort_order ?? 0)],
      );
      lessonCount += 1;
      await upsertSourceAsset(pool, "lesson", lessonInsert.rows[0].id, sourceDocument.id, row.source_reference);
    }

    const pathRow = rows.find((row) => row.item_type === "learning_path");
    const pathInsert = await pool.query(
      `insert into public.learning_paths (
         code, title_sw, status, description_sw, import_source,
         external_id, source_reference, sort_order
       ) values ($1, $2, 'needs_review', $3, 'notebooklm', $4, $5, $6)
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
      [pathRow.learning_path_code, pathRow.title_sw, pathRow.summary_sw, pathRow.external_id, pathRow.source_reference, Number(pathRow.sort_order ?? 0)],
    );
    await pool.query(
      `insert into public.learning_path_courses (
         learning_path_id, course_id, sort_order, required
       ) values ($1, $2, 10, true)
       on conflict (learning_path_id, course_id) do update
       set sort_order = excluded.sort_order,
           required = excluded.required`,
      [pathInsert.rows[0].id, course.id],
    );

    const contentCourse = buildContentCourse(rows, sourceDocument);
    await pool.query(
      `insert into public.content_courses (id, status, payload, updated_at)
       values ($1, 'draft', $2::jsonb, now())
       on conflict (id) do update
       set status = excluded.status,
           payload = excluded.payload,
           updated_at = now()`,
      [CONTENT_COURSE_ID, JSON.stringify(contentCourse)],
    );

    await pool.query(
      `update public.curriculum_staging_rows
       set validation_status = 'promoted',
           promoted_at = now(),
           promotion_result = jsonb_build_object('mode', 'direct_markdown_import', 'source_document_id', $2::text)
       where batch_id = $1`,
      [batchId, sourceDocument.id],
    );

    result.batchId = batchId;
    result.rows = rows.length;
    result.course = course;
    result.modules = moduleIdByCode.size;
    result.lessons = lessonCount;
    result.contentCourse = {
      id: CONTENT_COURSE_ID,
      status: "draft",
      lessons: contentCourse.lessons.length,
      modules: contentCourse.modules.length,
      contentGaps: contentCourse.contentGaps.length,
    };

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
