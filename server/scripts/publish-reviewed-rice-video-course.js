import "dotenv/config";

import crypto from "node:crypto";
import process from "node:process";

import pg from "pg";

import { REVIEWED_RICE_VIDEO_COURSE as definition } from "./reviewed-rice-video-course.js";

const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
if (!databaseUrl) throw new Error("SUPABASE_DATABASE_URL (or DATABASE_URL) is required");

const pool = new pg.Pool({ connectionString: databaseUrl });

function hashContent(content) {
  return crypto.createHash("sha256").update(content, "utf8").digest("hex");
}

async function one(client, sql, values, message) {
  const result = await client.query(sql, values);
  if (result.rowCount !== 1) throw new Error(message);
  return result.rows[0];
}

async function snapshotCourse(client, course) {
  const modules = await client.query(
    "select * from public.course_modules where course_id = $1 order by sort_order, created_at",
    [course.id],
  );
  const lessons = await client.query(
    `select l.* from public.lessons l
     join public.course_modules m on m.id = l.module_id
     where m.course_id = $1 order by m.sort_order, l.sort_order, l.created_at`,
    [course.id],
  );
  const resources = await client.query(
    `select lr.* from public.lesson_resources lr
     join public.lessons l on l.id = lr.lesson_id
     join public.course_modules m on m.id = l.module_id
     where m.course_id = $1 order by lr.created_at`,
    [course.id],
  );
  const reason = "2026-07-17: before publishing reviewed rice seed video course";
  await client.query(
    `insert into public.content_course_revisions
       (course_id, previous_status, previous_payload, reason)
     select $1, $2, $3::jsonb, $4
     where not exists (
       select 1 from public.content_course_revisions where course_id = $1 and reason = $4
     )`,
    [
      course.code,
      course.status,
      JSON.stringify({ course, modules: modules.rows, lessons: lessons.rows, resources: resources.rows }),
      reason,
    ],
  );
}

async function publish(client) {
  const course = await one(
    client,
    "select * from public.courses where code = $1 for update",
    [definition.code],
    `Course ${definition.code} was not found`,
  );
  const videoSource = await one(
    client,
    "select * from public.source_documents where file_name = $1 for update",
    [definition.videoFile],
    `Video source ${definition.videoFile} was not found`,
  );
  const transcriptSource = await one(
    client,
    "select * from public.source_documents where file_name = $1 for update",
    [definition.transcriptFile],
    `Transcript source ${definition.transcriptFile} was not found`,
  );

  for (const [path, label] of [
    [definition.videoStoragePath, "video"],
    [definition.transcriptStoragePath, "transcript"],
  ]) {
    await one(
      client,
      `select name from storage.objects
       where bucket_id = 'source-documents' and name = $1`,
      [path],
      `Uploaded ${label} object ${path} was not found`,
    );
  }

  const rows = await client.query(
    `select m.id module_id, m.code module_code, l.id lesson_id, l.code lesson_code
     from public.course_modules m
     join public.lessons l on l.module_id = m.id
     where m.course_id = $1
     order by m.sort_order, l.sort_order`,
    [course.id],
  );
  if (rows.rowCount !== definition.lessons.length) {
    throw new Error(`Expected ${definition.lessons.length} module lessons, found ${rows.rowCount}`);
  }
  const contentRows = definition.lessons.map((lesson) => {
    const row = rows.rows.find(
      (candidate) =>
        candidate.module_code === lesson.moduleCode && candidate.lesson_code === lesson.lessonCode,
    );
    if (!row) throw new Error(`Missing ${lesson.moduleCode}/${lesson.lessonCode}`);
    return { ...lesson, ...row };
  });

  await snapshotCourse(client, course);

  await client.query(
    `delete from public.content_source_links
     where (content_type = 'course' and content_id = $1)
        or (content_type = 'module' and content_id in (
          select id from public.course_modules where course_id = $1
        ))
        or (content_type = 'lesson' and content_id in (
          select l.id from public.lessons l
          join public.course_modules m on m.id = l.module_id where m.course_id = $1
        ))`,
    [course.id],
  );
  await client.query("delete from public.grounding_facts where course_id = $1", [course.id]);
  await client.query(
    "delete from public.source_segments where source_document_id = $1 and extraction_method = 'user_provided_video_transcript'",
    [transcriptSource.id],
  );
  await client.query(
    `delete from public.lesson_resources where lesson_id in (
       select l.id from public.lessons l
       join public.course_modules m on m.id = l.module_id where m.course_id = $1
     )`,
    [course.id],
  );

  await client.query(
    `update public.source_documents
     set source_type = 'video/mp4', source_kind = 'video', storage_bucket = 'source-documents',
         storage_path = $2, processing_status = 'approved',
         metadata = coalesce(metadata, '{}'::jsonb) || $3::jsonb, updated_at = now()
     where id = $1`,
    [videoSource.id, definition.videoStoragePath, JSON.stringify({ upload_status: "uploaded" })],
  );
  await client.query(
    `update public.source_documents
     set title = 'Transcript - Aina za Mbegu za Mpunga na Sifa Zake',
         source_type = 'transcript', source_kind = 'transcript', storage_bucket = 'source-documents',
         storage_path = $2, processing_status = 'approved',
         metadata = coalesce(metadata, '{}'::jsonb) || $3::jsonb, updated_at = now()
     where id = $1`,
    [
      transcriptSource.id,
      definition.transcriptStoragePath,
      JSON.stringify({ upload_status: "uploaded", transcript_kind: "user_provided_full_transcript", verbatim: true }),
    ],
  );

  const segmentIds = [];
  for (let index = 0; index < contentRows.length; index += 1) {
    const item = contentRows[index];
    const segment = await one(
      client,
      `insert into public.source_segments (
         source_document_id, time_start_seconds, time_end_seconds,
         section_title, segment_order, content_sw, content_hash,
         extraction_method, review_status, risk_level, reviewed_at, updated_at
       ) values ($1, 0, $2, $3, $4, $5, $6, 'user_provided_video_transcript',
                 'published', 'medium', now(), now()) returning id`,
      [
        transcriptSource.id,
        definition.videoDurationSeconds,
        item.sectionTitle,
        index + 1,
        item.evidence,
        hashContent(item.evidence),
      ],
      `Could not create source segment ${index + 1}`,
    );
    segmentIds.push(segment.id);

    await client.query(
      `update public.course_modules
       set title_sw = $2, summary_sw = $3, status = 'published', risk_level = 'medium',
           source_reference = $4, source_link_status = 'linked', sort_order = $5,
           published_at = now(), updated_at = now()
       where id = $1`,
      [
        item.module_id,
        item.moduleTitle,
        item.moduleSummary,
        `${definition.videoFile}; user-provided full transcript`,
        (index + 1) * 10,
      ],
    );
    await client.query(
      `update public.lessons
       set title_sw = $2, body_sw = $3, lesson_type = 'video', duration_minutes = 5,
           status = 'published', risk_level = 'medium', source_reference = $4,
           source_link_status = 'linked', sort_order = 10, published_at = now(), updated_at = now()
       where id = $1`,
      [item.lesson_id, item.lessonTitle, item.body, `${definition.videoFile}; user-provided full transcript`],
    );
    await client.query(
      `insert into public.lesson_resources (
         lesson_id, resource_type, storage_path, title_sw, duration_seconds,
         transcript_source_document_id, status, updated_at
       ) values ($1, 'video', $2, $3, $4, $5, 'published', now())`,
      [
        item.lesson_id,
        definition.videoStoragePath,
        item.lessonTitle,
        definition.videoDurationSeconds,
        transcriptSource.id,
      ],
    );
    await client.query(
      `insert into public.content_source_links (
         content_type, content_id, source_segment_id, source_document_id,
         link_status, evidence_note, updated_at
       ) values ('lesson', $1, $2, $3, 'linked',
                 'Grounded in the user-provided full transcript tied to the original uploaded video.', now())`,
      [item.lesson_id, segment.id, transcriptSource.id],
    );
    await client.query(
      `insert into public.grounding_facts (
         course_id, module_id, lesson_id, source_segment_id, code, fact_sw,
         question_sw, status, risk_level, import_source, external_id,
         reviewed_at, updated_at
       ) values ($1, $2, $3, $4, $5, $6, $7, 'published', 'medium',
                 'user_provided_video_transcript', $8, now(), now())`,
      [
        course.id,
        item.module_id,
        item.lesson_id,
        segment.id,
        `rice-seed-video-${index + 1}`,
        item.fact,
        item.question,
        `SAFE-RICE-VIDEO-${String(index + 1).padStart(3, "0")}`,
      ],
    );
  }

  for (const item of contentRows) {
    for (const sourceId of [videoSource.id, transcriptSource.id]) {
      await client.query(
        `update public.content_source_assets set link_status = 'linked', updated_at = now()
         where source_document_id = $1 and (
           (content_type = 'course' and content_id = $2) or
           (content_type = 'module' and content_id = $3) or
           (content_type = 'lesson' and content_id = $4)
         )`,
        [sourceId, course.id, item.module_id, item.lesson_id],
      );
    }
  }
  for (const [contentType, contentId] of [
    ["course", course.id],
    ...contentRows.map((item) => ["module", item.module_id]),
  ]) {
    for (const segmentId of segmentIds) {
      await client.query(
        `insert into public.content_source_links (
           content_type, content_id, source_segment_id, source_document_id,
           link_status, evidence_note, updated_at
         ) values ($1, $2, $3, $4, 'linked',
                   'Reviewed evidence for the published rice seed video course.', now())`,
        [contentType, contentId, segmentId, transcriptSource.id],
      );
    }
  }

  await client.query(
    `update public.courses
     set title_sw = $2, summary_sw = $3, description_sw = $4, delivery_type = 'video',
         status = 'published', risk_level = 'medium', source_link_status = 'linked',
         published_at = now(), updated_at = now()
     where id = $1`,
    [course.id, definition.title, definition.summary, definition.description],
  );
  await client.query(
    `update public.learning_paths set status = 'published', published_at = now(), updated_at = now()
     where code = $1 and exists (
       select 1 from public.learning_path_courses lpc
       where lpc.learning_path_id = learning_paths.id and lpc.course_id = $2
     )`,
    [definition.learningPathCode, course.id],
  );
  await client.query(
    `update public.curriculum_import_batches
     set status = 'published', completed_at = coalesce(completed_at, now()),
         metadata = coalesce(metadata, '{}'::jsonb) || $2::jsonb
     where metadata ->> 'course_code' = $1`,
    [definition.code, JSON.stringify({ publication_mode: "reviewed_video_course" })],
  );
}

const client = await pool.connect();
try {
  await client.query("begin");
  await publish(client);
  await client.query("commit");
  console.log(`PASS: published ${definition.code} as a reviewed video course.`);
} catch (error) {
  await client.query("rollback");
  throw error;
} finally {
  client.release();
  await pool.end();
}
