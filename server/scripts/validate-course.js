import "dotenv/config";

import process from "node:process";

import pg from "pg";

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const courseCode = String(args.course ?? "").trim();
  if (!courseCode) {
    fail("Missing --course. Example: npm run validate:course -- --course RICE-SEED-001");
  }

  const databaseUrl = process.env.SUPABASE_DATABASE_URL ?? process.env.DATABASE_URL;
  if (!databaseUrl) fail("SUPABASE_DATABASE_URL (or DATABASE_URL) is required");

  const pool = new pg.Pool({ connectionString: databaseUrl });
  const failures = [];
  const notes = [];

  try {
    const course = await pool.query(
      "select id, code, status from public.courses where code = $1",
      [courseCode],
    );
    if (course.rows.length === 0) {
      failures.push("Course does not exist");
      finish({ failures, notes });
    }

    const courseRow = course.rows[0];
    if (courseRow.status !== "draft") {
      failures.push(`Course status must remain draft (found: ${courseRow.status})`);
    }

    const modules = await pool.query(
      `select id, code, title_sw, status, sort_order, external_id
       from public.course_modules
       where course_id = $1
       order by sort_order asc, created_at asc`,
      [courseRow.id],
    );

    if (modules.rows.length !== 3) {
      failures.push(`Expected exactly 3 modules, found ${modules.rows.length}`);
    }

    const duplicateExternal = await pool.query(
      `select external_id, count(*)::int as count
       from public.course_modules
       where course_id = $1 and external_id is not null
       group by external_id
       having count(*) > 1`,
      [courseRow.id],
    );
    if (duplicateExternal.rows.length > 0) {
      failures.push("Duplicate unique_code values found in imported modules");
      for (const row of duplicateExternal.rows) {
        notes.push(`Duplicate external_id ${row.external_id} appears ${row.count} times`);
      }
    }

    const moduleSorts = modules.rows.map((m) => Number(m.sort_order));
    if (!isAscending(moduleSorts)) {
      failures.push(`Module sort_order is not ascending: ${moduleSorts.join(", ")}`);
    }

    const moduleIds = modules.rows.map((m) => m.id);
    const lessons = await pool.query(
      `select l.id, l.module_id, l.code, l.title_sw, l.lesson_type, l.status, l.source_reference, l.source_link_status
       from public.lessons l
       where l.module_id = any($1::uuid[])
       order by l.module_id, l.sort_order asc, l.created_at asc`,
      [moduleIds.length > 0 ? moduleIds : ["00000000-0000-0000-0000-000000000000"]],
    );

    for (const module of modules.rows) {
      const moduleLessons = lessons.rows.filter((l) => l.module_id === module.id);
      const videoLessons = moduleLessons.filter((l) => l.lesson_type === "video");
      if (videoLessons.length < 1) {
        failures.push(`Module ${module.code} has no video lessons`);
      }
    }

    const videoLessonIds = lessons.rows
      .filter((lesson) => lesson.lesson_type === "video")
      .map((lesson) => lesson.id);

    if (videoLessonIds.length > 0) {
      const videoResourceCoverage = await pool.query(
        `select
           l.id as lesson_id,
           exists (
             select 1 from public.lesson_resources lr
             where lr.lesson_id = l.id and lr.resource_type = 'video'
           ) as has_video_resource,
           exists (
             select 1 from public.content_source_assets csa
             where csa.content_type = 'lesson'
               and csa.content_id = l.id
               and csa.link_status in ('pending_review', 'linked')
           ) as has_pending_or_linked_source
         from public.lessons l
         where l.id = any($1::uuid[])`,
        [videoLessonIds],
      );

      for (const row of videoResourceCoverage.rows) {
        if (!row.has_video_resource && !row.has_pending_or_linked_source) {
          failures.push(`Video lesson ${row.lesson_id} lacks video resource and pending source link`);
        }
      }
    }

    for (const lesson of lessons.rows) {
      const hasReferenceText = Boolean(lesson.source_reference && String(lesson.source_reference).trim().length > 0);
      const hasPendingLink = lesson.source_link_status === "pending_review" || lesson.source_link_status === "linked";
      if (!hasReferenceText && !hasPendingLink) {
        failures.push(`Lesson ${lesson.code} missing source reference and pending source_link_status`);
      }
      if (lesson.status !== "draft") {
        failures.push(`Lesson ${lesson.code} should remain draft (found ${lesson.status})`);
      }
    }

    const publishedCounts = await pool.query(
      `select
         (select count(*) from public.courses where code = $1 and status = 'published') as published_courses,
         (select count(*) from public.course_modules m
            join public.courses c on c.id = m.course_id
           where c.code = $1 and m.status = 'published') as published_modules,
         (select count(*) from public.lessons l
            join public.course_modules m on m.id = l.module_id
            join public.courses c on c.id = m.course_id
           where c.code = $1 and l.status = 'published') as published_lessons`,
      [courseCode],
    );
    const published = publishedCounts.rows[0];
    if (Number(published.published_courses) > 0 || Number(published.published_modules) > 0 || Number(published.published_lessons) > 0) {
      failures.push("Detected published content; import must not auto-publish");
    }

    finish({ failures, notes, modules: modules.rows, lessonCount: lessons.rows.length });
  } finally {
    await pool.end();
  }
}

function finish({ failures, notes, modules = [], lessonCount = 0 }) {
  if (failures.length === 0) {
    console.log("PASS: Course validation successful.");
    if (modules.length > 0) {
      console.log(`Modules: ${modules.length}, Lessons: ${lessonCount}`);
      modules.forEach((module, index) => {
        console.log(`- #${index + 1} ${module.code}: ${module.title_sw}`);
      });
    }
    process.exit(0);
  }

  console.error("FAIL: Course validation failed.");
  failures.forEach((failure) => console.error(`- ${failure}`));
  if (notes.length > 0) {
    console.error("Details:");
    notes.forEach((note) => console.error(`- ${note}`));
  }
  console.error("Next actions:");
  console.error("- Fix staging rows or source links, then rerun import and validation.");
  console.error("- Ensure video/transcript sources are uploaded and linked.");
  process.exit(1);
}

function isAscending(values) {
  for (let i = 1; i < values.length; i += 1) {
    if (values[i] < values[i - 1]) return false;
  }
  return true;
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

function fail(message) {
  console.error(message);
  process.exit(1);
}

await main();
