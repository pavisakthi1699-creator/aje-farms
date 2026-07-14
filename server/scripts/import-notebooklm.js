import "dotenv/config";

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import crypto from "node:crypto";

import pg from "pg";

const DEFAULT_COURSE_CODE = "RICE-SEED-001";
const DEFAULT_COURSE_TITLE = "Aina za Mbegu za Mpunga na Sifa Zake";
const DEFAULT_LANGUAGE = "sw";
const DEFAULT_VIDEO_FILE = "WhatsApp Video 2026-07-06 at 18.09.24.mp4";
const DEFAULT_TRANSCRIPT_FILE = "video-transcript-rice-seed-001.txt";
const DEFAULT_LEARNING_PATH_CODE = "uchaguzi-wa-mbegu-za-mpunga";
const DEFAULT_LEARNING_PATH_TITLE = "Uchaguzi wa Mbegu za Mpunga";

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const csvPath = args.file;
  if (!csvPath) {
    fail("Missing --file. Example: npm run import:notebooklm -- --file imports/rice-seed-video-course/rice_seed_video_course.csv");
  }

  const resolvedCsvPath = path.resolve(process.cwd(), csvPath);
  if (!fs.existsSync(resolvedCsvPath)) {
    fail(`CSV file not found: ${resolvedCsvPath}`);
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const editorJwt = process.env.AJE_EDITOR_JWT ?? process.env.SUPABASE_EDITOR_JWT;
  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;

  if (!supabaseUrl) fail("SUPABASE_URL is required");
  if (!editorJwt) fail("AJE_EDITOR_JWT (or SUPABASE_EDITOR_JWT) is required for Edge Function calls");
  if (!databaseUrl) fail("SUPABASE_DATABASE_URL (or DATABASE_URL) is required to register source documents");

  const sourceText = fs.readFileSync(resolvedCsvPath, "utf8");
  const rows = parseCsvRows(sourceText);
  if (rows.length === 0) fail("No rows found in CSV");

  const pool = new pg.Pool({ connectionString: databaseUrl });
  try {
    const videoSource = await upsertSourceDocument(pool, {
      title: "WhatsApp Video 2026-07-06 at 18.09.24",
      sourceType: "video",
      sourceKind: "video",
      fileName: DEFAULT_VIDEO_FILE,
      storagePath: "pending/video/whatsapp-video-2026-07-06-18-09-24.mp4",
      languageCode: DEFAULT_LANGUAGE,
      metadata: {
        upload_status: "pending_upload",
        note: "Original video source for RICE-SEED-001",
      },
    });

    const transcriptSource = await upsertSourceDocument(pool, {
      title: "Transcript - Aina za Mbegu za Mpunga na Sifa Zake",
      sourceType: "transcript",
      sourceKind: "transcript",
      fileName: DEFAULT_TRANSCRIPT_FILE,
      storagePath: "pending/transcript/rice-seed-001-transcript.txt",
      languageCode: DEFAULT_LANGUAGE,
      metadata: {
        upload_status: "pending_upload",
        note: "Supporting transcript source for RICE-SEED-001",
      },
    });

    const importRows = buildImportRows({
      csvRows: rows,
      courseCode: DEFAULT_COURSE_CODE,
      courseTitle: DEFAULT_COURSE_TITLE,
      learningPathCode: DEFAULT_LEARNING_PATH_CODE,
      learningPathTitle: DEFAULT_LEARNING_PATH_TITLE,
      videoSourceDocumentId: videoSource.id,
      transcriptSourceDocumentId: transcriptSource.id,
    });

    console.log(`Staging ${importRows.length} rows from ${csvPath}`);
    const stageResponse = await fetch(`${supabaseUrl}/functions/v1/import-notebooklm-curriculum`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${editorJwt}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ rows: importRows }),
    });

    const stagePayload = await parseJson(stageResponse);
    if (!stageResponse.ok) {
      fail(`Staging failed (${stageResponse.status}): ${JSON.stringify(stagePayload)}`);
    }

    const batchId = stagePayload.batch_id;
    if (!batchId) fail(`Staging response missing batch_id: ${JSON.stringify(stagePayload)}`);

    console.log(`Staged batch: ${batchId} (valid=${stagePayload.valid_count}, invalid=${stagePayload.error_count})`);

    const promoteResponse = await fetch(`${supabaseUrl}/functions/v1/promote-staged-curriculum`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${editorJwt}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ batch_id: batchId }),
    });

    const promotePayload = await parseJson(promoteResponse);
    if (!promoteResponse.ok && promoteResponse.status !== 207) {
      fail(`Promotion failed (${promoteResponse.status}): ${JSON.stringify(promotePayload)}`);
    }

    console.log(
      `Promotion complete: promoted=${promotePayload.promoted_count} errors=${promotePayload.promotion_error_count}`,
    );
    console.log(
      `Next: npm run validate:course -- --course ${DEFAULT_COURSE_CODE}`,
    );
  } finally {
    await pool.end();
  }
}

function parseArgs(argv) {
  const parsed = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;
    const key = token.slice(2);
    const value = argv[i + 1];
    if (!value || value.startsWith("--")) {
      parsed[key] = true;
    } else {
      parsed[key] = value;
      i += 1;
    }
  }
  return parsed;
}

function parseCsvRows(text) {
  const lines = text.split(/\r?\n/).filter((line) => line.trim().length > 0);
  const [headerLine, ...bodyLines] = lines;
  if (!headerLine) return [];
  const headers = parseCsvLine(headerLine).map((h) => h.trim());
  return bodyLines.map((line) => {
    const values = parseCsvLine(line);
    const row = {};
    headers.forEach((header, index) => {
      row[header] = values[index]?.trim() ?? "";
    });
    return row;
  });
}

function parseCsvLine(line) {
  const out = [];
  let current = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    const next = line[i + 1];
    if (char === '"' && inQuotes && next === '"') {
      current += '"';
      i += 1;
      continue;
    }
    if (char === '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (char === "," && !inQuotes) {
      out.push(current);
      current = "";
      continue;
    }
    current += char;
  }
  out.push(current);
  return out;
}

async function upsertSourceDocument(pool, doc) {
  const checksumBase = `${doc.storagePath}:${doc.fileName}:${doc.sourceKind}`;
  const checksum = toSha256(checksumBase);
  const result = await pool.query(
    `insert into public.source_documents (
       title,
       language_code,
       source_type,
       source_kind,
       storage_bucket,
       storage_path,
       file_name,
       checksum,
       page_count,
       processing_status,
       metadata
     )
     values ($1, $2, $3, $4, 'source-documents', $5, $6, $7, null, 'draft', $8::jsonb)
     on conflict (storage_bucket, storage_path) do update
     set title = excluded.title,
         source_type = excluded.source_type,
         source_kind = excluded.source_kind,
         file_name = excluded.file_name,
         metadata = excluded.metadata
     returning id, title, storage_path`,
    [
      doc.title,
      doc.languageCode,
      doc.sourceType,
      doc.sourceKind,
      doc.storagePath,
      doc.fileName,
      checksum,
      JSON.stringify(doc.metadata ?? {}),
    ],
  );
  return result.rows[0];
}

function toSha256(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

function buildImportRows({
  csvRows,
  courseCode,
  courseTitle,
  learningPathCode,
  learningPathTitle,
  videoSourceDocumentId,
  transcriptSourceDocumentId,
}) {
  const output = [];

  output.push({
    item_type: "course",
    external_id: `course:${courseCode}`,
    code: courseCode,
    title_sw: courseTitle,
    summary_sw: "Kozi ya video kuhusu aina za mbegu za mpunga na sifa zake.",
    status: "draft",
    risk_level: "normal",
    source_reference: `${DEFAULT_VIDEO_FILE}, Transcript`,
    source_document_ids: [videoSourceDocumentId, transcriptSourceDocumentId],
    sort_order: 10,
  });

  output.push({
    item_type: "learning_path",
    external_id: `learning-path:${learningPathCode}`,
    learning_path_code: learningPathCode,
    code: learningPathCode,
    title_sw: learningPathTitle,
    summary_sw: "Njia ya kujifunza kuchagua mbegu za mpunga.",
    status: "draft",
    sort_order: 10,
  });

  output.push({
    item_type: "learning_path_course",
    external_id: `learning-path-course:${learningPathCode}:${courseCode}`,
    learning_path_code: learningPathCode,
    course_code: courseCode,
    sort_order: 10,
  });

  csvRows.forEach((row, index) => {
    const uniqueCode = String(row.unique_code ?? "").trim();
    const moduleTitle = String(row["title/content"] ?? row.title ?? "").trim();
    if (!uniqueCode || !moduleTitle) return;

    const sourceReference = String(row.source_reference ?? "").trim();
    const riskLevel = normalizeRisk(row.risk_level);
    const moduleCode = uniqueCode.toLowerCase().replace(/[^a-z0-9]+/g, "-");
    const lessonCode = `${moduleCode}-video-01`;
    const sortOrder = (index + 1) * 10;

    output.push({
      item_type: "module",
      external_id: uniqueCode,
      course_code: courseCode,
      module_code: moduleCode,
      code: moduleCode,
      title_sw: moduleTitle,
      summary_sw: moduleTitle,
      status: "draft",
      risk_level: riskLevel,
      source_reference: sourceReference,
      source_document_ids: [videoSourceDocumentId, transcriptSourceDocumentId],
      sort_order: sortOrder,
    });

    output.push({
      item_type: "lesson",
      external_id: `${uniqueCode}:lesson`,
      course_code: courseCode,
      module_code: moduleCode,
      lesson_code: lessonCode,
      code: lessonCode,
      title_sw: moduleTitle,
      lesson_type: "video",
      body_sw: moduleTitle,
      source_reference: sourceReference,
      source_reference_text: sourceReference,
      status: "draft",
      risk_level: riskLevel,
      source_document_ids: [videoSourceDocumentId, transcriptSourceDocumentId],
      video_source_document_id: videoSourceDocumentId,
      transcript_source_document_id: transcriptSourceDocumentId,
      sort_order: 10,
    });
  });

  return output;
}

function normalizeRisk(input) {
  const value = String(input ?? "").trim().toLowerCase();
  if (value === "high" || value === "medium" || value === "normal") return value;
  return "normal";
}

async function parseJson(response) {
  const text = await response.text();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

await main();
