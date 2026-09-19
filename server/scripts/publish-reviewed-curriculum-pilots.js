import "dotenv/config";

import crypto from "node:crypto";
import process from "node:process";

import pg from "pg";

import {
  EXCLUDED_STAGING_ITEM_TYPES,
  REVIEWED_CURRICULUM_PILOTS,
} from "./reviewed-curriculum-pilots.js";

const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
if (!databaseUrl) throw new Error("SUPABASE_DATABASE_URL (or DATABASE_URL) is required");

const selectedCode = process.argv
  .find((argument) => argument.startsWith("--course="))
  ?.slice("--course=".length);
const selectedCourses = selectedCode
  ? REVIEWED_CURRICULUM_PILOTS.filter((course) => course.code === selectedCode)
  : REVIEWED_CURRICULUM_PILOTS;
if (selectedCourses.length === 0) throw new Error(`Unknown course ${selectedCode}`);

const pool = new pg.Pool({ connectionString: databaseUrl });

function hashContent(content) {
  return crypto.createHash("sha256").update(content, "utf8").digest("hex");
}

async function snapshotCourse(client, course) {
  const modules = await client.query(
    "select * from public.course_modules where course_id = $1 order by sort_order, created_at",
    [course.id],
  );
  const lessons = await client.query(
    `select l.*
     from public.lessons l
     join public.course_modules m on m.id = l.module_id
     where m.course_id = $1
     order by m.sort_order, l.sort_order, l.created_at`,
    [course.id],
  );
  const groundingFacts = await client.query(
    "select * from public.grounding_facts where course_id = $1 order by external_id",
    [course.id],
  );
  const reason = `2026-07-16: before publishing reviewed curriculum pilot ${course.code}`;
  await client.query(
    `insert into public.content_course_revisions (
       course_id, previous_status, previous_payload, reason
     )
     select $1, $2, $3::jsonb, $4
     where not exists (
       select 1
       from public.content_course_revisions
       where course_id = $1 and reason = $4
     )`,
    [
      course.code,
      course.status,
      JSON.stringify({
        course,
        modules: modules.rows,
        lessons: lessons.rows,
        grounding_facts: groundingFacts.rows,
      }),
      reason,
    ],
  );
}

async function publishCourse(client, definition) {
  const courseResult = await client.query(
    "select * from public.courses where code = $1 for update",
    [definition.code],
  );
  if (courseResult.rowCount !== 1) throw new Error(`Course ${definition.code} was not found`);
  const course = courseResult.rows[0];

  const sourceResult = await client.query(
    `select sd.*
     from public.source_documents sd
     join public.content_source_assets csa on csa.source_document_id = sd.id
     where csa.content_type = 'course'
       and csa.content_id = $1
       and sd.file_name = $2
     order by sd.created_at
     limit 1`,
    [course.id, definition.sourceFile],
  );
  if (sourceResult.rowCount !== 1) {
    throw new Error(`Source document ${definition.sourceFile} was not found`);
  }
  const source = sourceResult.rows[0];

  const moduleResult = await client.query(
    `select *
     from public.course_modules
     where course_id = $1
     order by sort_order, created_at
     limit 1`,
    [course.id],
  );
  if (moduleResult.rowCount !== 1) throw new Error(`Course ${definition.code} has no module`);
  const module = moduleResult.rows[0];

  const lessonResult = await client.query(
    `select l.*
     from public.lessons l
     join public.course_modules m on m.id = l.module_id
     where m.course_id = $1
     order by m.sort_order, l.sort_order, l.created_at
     limit 3`,
    [course.id],
  );
  if (lessonResult.rowCount !== 3) {
    throw new Error(`Course ${definition.code} needs at least three existing lessons`);
  }
  const lessons = lessonResult.rows;

  await snapshotCourse(client, course);

  await client.query(
    `delete from public.content_source_links
     where (content_type = 'course' and content_id = $1)
        or (content_type = 'module' and content_id in (
          select id from public.course_modules where course_id = $1
        ))
        or (content_type = 'lesson' and content_id in (
          select l.id
          from public.lessons l
          join public.course_modules m on m.id = l.module_id
          where m.course_id = $1
        ))`,
    [course.id],
  );
  await client.query("delete from public.grounding_facts where course_id = $1", [course.id]);
  await client.query(
    `delete from public.source_segments
     where source_document_id = $1
       and extraction_method = 'manual_pdf_review'`,
    [source.id],
  );

  await client.query(
    `update public.source_documents
     set page_count = $2,
         processing_status = 'approved',
         updated_at = now()
     where id = $1`,
    [source.id, definition.pageCount],
  );

  await client.query(
    `update public.course_modules
     set status = 'archived', published_at = null, updated_at = now()
     where course_id = $1`,
    [course.id],
  );
  await client.query(
    `update public.course_modules
     set title_sw = $2,
         summary_sw = $3,
         status = 'published',
         risk_level = 'medium',
         source_link_status = 'linked',
         published_at = now(),
         updated_at = now()
     where id = $1`,
    [module.id, definition.moduleTitle, definition.moduleSummary],
  );

  await client.query(
    `update public.lessons l
     set status = 'archived', published_at = null, updated_at = now()
     from public.course_modules m
     where m.id = l.module_id and m.course_id = $1`,
    [course.id],
  );

  const segmentIds = [];
  for (let index = 0; index < definition.lessons.length; index += 1) {
    const reviewedLesson = definition.lessons[index];
    const existingLesson = lessons[index];
    const contentHash = hashContent(reviewedLesson.evidence);
    const segmentResult = await client.query(
      `insert into public.source_segments (
         source_document_id, page_start, page_end, section_title, segment_order,
         content_sw, content_hash, extraction_method, review_status, risk_level,
         reviewed_at, updated_at
       )
       values ($1, $2, $3, $4, $5, $6, $7, 'manual_pdf_review',
               'published', 'medium', now(), now())
       returning id`,
      [
        source.id,
        reviewedLesson.pageStart,
        reviewedLesson.pageEnd,
        reviewedLesson.sectionTitle,
        index + 1,
        reviewedLesson.evidence,
        contentHash,
      ],
    );
    const segmentId = segmentResult.rows[0].id;
    segmentIds.push(segmentId);

    await client.query(
      `update public.lessons
       set module_id = $2,
           title_sw = $3,
           body_sw = $4,
           lesson_type = 'reading',
           duration_minutes = 5,
           status = 'published',
           risk_level = 'medium',
           source_reference = $5,
           source_link_status = 'linked',
           sort_order = $6,
           published_at = now(),
           updated_at = now()
       where id = $1`,
      [
        existingLesson.id,
        module.id,
        reviewedLesson.title,
        reviewedLesson.body,
        `${definition.sourceFile}, PDF physical pages ${reviewedLesson.pageStart}-${reviewedLesson.pageEnd}`,
        (index + 1) * 10,
      ],
    );

    await client.query(
      `insert into public.content_source_links (
         content_type, content_id, source_segment_id, source_document_id,
         link_status, evidence_note, updated_at
       )
       values ('lesson', $1, $2, $3, 'linked', $4, now())`,
      [
        existingLesson.id,
        segmentId,
        source.id,
        `Manually reviewed against PDF physical pages ${reviewedLesson.pageStart}-${reviewedLesson.pageEnd}.`,
      ],
    );

    const externalId = `SAFE-${definition.code.replace(/^CRS-/, "")}-${String(index + 1).padStart(3, "0")}`;
    await client.query(
      `insert into public.grounding_facts (
         course_id, module_id, lesson_id, source_segment_id, code, fact_sw,
         question_sw, status, risk_level, import_source, external_id,
         reviewed_at, updated_at
       )
       values ($1, $2, $3, $4, $5, $6, $7, 'published', 'medium',
               'manual_pdf_review', $8, now(), now())`,
      [
        course.id,
        module.id,
        existingLesson.id,
        segmentId,
        `${definition.code.toLowerCase()}-${index + 1}`,
        reviewedLesson.fact,
        reviewedLesson.question,
        externalId,
      ],
    );
  }

  for (const contentType of ["course", "module"]) {
    const contentId = contentType === "course" ? course.id : module.id;
    for (const segmentId of segmentIds) {
      await client.query(
        `insert into public.content_source_links (
           content_type, content_id, source_segment_id, source_document_id,
           link_status, evidence_note, updated_at
         )
         values ($1, $2, $3, $4, 'linked',
                 'Reviewed evidence for the published three-lesson pilot.', now())`,
        [contentType, contentId, segmentId, source.id],
      );
    }
  }

  await client.query(
    `update public.courses
     set title_sw = $2,
         summary_sw = $3,
         description_sw = $4,
         delivery_type = 'text',
         status = 'published',
         risk_level = 'medium',
         source_link_status = 'linked',
         published_at = now(),
         updated_at = now()
     where id = $1`,
    [course.id, definition.title, definition.summary, definition.description],
  );

  await client.query(
    `update public.learning_paths
     set status = 'archived', published_at = null, updated_at = now()
     where id in (
       select lpc.learning_path_id
       from public.learning_path_courses lpc
       where lpc.course_id = $1
         and not exists (
           select 1
           from public.learning_path_courses other_course
           where other_course.learning_path_id = lpc.learning_path_id
             and other_course.course_id <> lpc.course_id
         )
     )`,
    [course.id],
  );
  await client.query(
    `update public.content_courses
     set status = 'archived', updated_at = now()
     where id = $1 or payload ->> 'sourceCourseCode' = $2`,
    [definition.contentCourseId, definition.code],
  );
  await client.query(
    `update public.curriculum_staging_rows
     set validation_status = 'invalid',
         error_code = 'excluded_from_reviewed_pilot',
         error_message =
           'Generated quiz, checklist, or FAQ intentionally excluded from the reviewed learner pilot.',
         updated_at = now()
     where row_data ->> 'course_code' = $1
       and item_type = any($2::text[])
       and validation_status = 'valid'`,
    [definition.code, EXCLUDED_STAGING_ITEM_TYPES],
  );
}

const client = await pool.connect();
try {
  await client.query("begin");
  for (const course of selectedCourses) await publishCourse(client, course);
  await client.query("commit");
  for (const course of selectedCourses) {
    console.log(`Published ${course.code}: ${course.title}`);
  }
  console.log(`PASS: published ${selectedCourses.length} reviewed curriculum pilot(s).`);
} catch (error) {
  await client.query("rollback");
  throw error;
} finally {
  client.release();
  await pool.end();
}
