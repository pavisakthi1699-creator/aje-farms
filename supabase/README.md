# Supabase Content Ingestion Foundation

This folder contains the first production-ready content ingestion and course-catalogue layer for AJE Farms.

Core rule: PDF source documents are evidence. NotebookLM exports are editorial drafts until source-linked, reviewed, and published.

## Layout

- `migrations/20260707000100_content_ingestion_foundation.sql`: storage bucket, enums, tables, RLS, validation/publish SQL, and seed catalogue data.
- `migrations/20260708000100_curriculum_staging_promotion.sql`: staging rows table and policies for import-then-promote flow.
- `migrations/20260708000200_video_source_resources.sql`: video/transcript source kinds, `content_source_assets`, and `lesson_resources`.
- `migrations/20260716000100_video_text_grounding_model.sql`: text/video-only delivery, PDF-page or video-timecode segments, reviewed grounding facts, private source storage, and reversible catalogue revisions.
- `maintenance/20260716_customer_content_safety_cleanup.sql`: one-time reversible quarantine of unverified learner content and quizzes.
- `functions/import-notebooklm-curriculum`: CSV/JSON NotebookLM draft importer.
- `functions/promote-staged-curriculum`: promotes validated staging rows into the live catalogue tables.
- `functions/queue-document-ingestion`: retry-safe source document ingestion queue endpoint.
- `functions/generate-course-draft`: Gemini-backed draft generator from reviewed source segments.
- `functions/validate-course-sources`: HTTP wrapper around `public.validate_course_sources`.
- `functions/publish-course`: HTTP wrapper around `public.publish_course`.
- `tests/*.sql`: SQL checks for RLS, import contracts, and publish validation.
- `tests/video_resource_validation.sql`: video resource + source-asset linkage checks.
- `samples/notebooklm-curriculum-sample.csv`: sample NotebookLM-style import.
- `types/content.ts`: shared TypeScript domain types.

## Local Setup

Install the Supabase CLI, then from the repository root:

```sh
supabase start
supabase db reset
```

Run SQL tests:

```sh
supabase test db
```

If testing against a linked remote project, review the SQL first and run migrations through your normal release flow.

## Required Secrets

Set Edge Function secrets with the Supabase CLI or dashboard:

```sh
supabase secrets set GEMINI_API_KEY=<server-side-gemini-key>
```

The Edge Functions also expect the standard Supabase runtime values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Never expose `SUPABASE_SERVICE_ROLE_KEY` or `GEMINI_API_KEY` to Flutter or any browser/mobile client.

## Roles

RLS uses `auth.users.raw_app_meta_data.role` or `app_role`.

Supported content roles:

- `learner`: can read only published catalogue content.
- `editor`: can upload sources, import drafts, link sources, review, validate, and publish.
- `admin`: editor permissions plus delete access for source document storage objects.

Example app metadata:

```json
{ "role": "editor" }
```

Do not put authorization roles in `user_metadata`.

## Source Documents

Upload original PDFs and source materials to the private `source-documents` bucket. Create a matching `source_documents` row with bucket/path, checksum, file name, page count, and processing status.

Learners cannot list or read raw PDFs. Editors/admins can access the private bucket, and learner-facing PDF access should be mediated through backend-created signed URLs only when entitlement rules allow it.

For video courses, classify source documents with `source_kind`:

- `video`
- `transcript`
- `pdf`
- `document`
- `audio`
- `image`

Video/transcript lesson attachments are stored in `lesson_resources`.
Page/timecode evidence is stored in `source_segments` and linked through
`content_source_links`. `grounding_facts` contains the reviewed statements
available to Mwalimu AI.

Only `reading` and `video` lessons are learner-facing. PDFs are private source
evidence, not course downloads.

## NotebookLM Imports

NotebookLM CSV/JSON imports stage rows first:

- rows are stored in `curriculum_staging_rows`
- each row gets `validation_status = valid|invalid`
- invalid rows are copied to `curriculum_import_errors`
- nothing is written to `courses/course_modules/lessons/...` until promotion

Import sample CSV:

```sh
curl -X POST "$SUPABASE_URL/functions/v1/import-notebooklm-curriculum" \
  -H "Authorization: Bearer <editor-jwt>" \
  -H "Content-Type: text/csv" \
  --data-binary @supabase/samples/notebooklm-curriculum-sample.csv
```

Promote one staged batch into live catalogue tables:

```sh
curl -X POST "$SUPABASE_URL/functions/v1/promote-staged-curriculum" \
  -H "Authorization: Bearer <editor-jwt>" \
  -H "Content-Type: application/json" \
  -d '{ "batch_id": "<uuid>" }'
```

Repeated imports are idempotent at batch level (`batch_hash`) and promotion is idempotent at row level (`import_source + external_id` or natural keys).

Legacy quiz rows remain importable but are explicitly ignored. Checklist and
FAQ rows can become grounding facts only when they include a valid
`source_segment_id`; they do not become learner lesson types.

### Extract PDF Evidence

Generate reviewed-draft segments and NotebookLM fact links from a PDF whose
curriculum rows contain printed page references such as `Uk. 14-16`:

```sh
PYTHONPYCACHEPREFIX=/tmp/aje-pycache python3 \
  server/scripts/extract-pdf-grounding.py \
  --pdf "/absolute/path/book.pdf" \
  --curriculum "/absolute/path/curriculum.json" \
  --source-document-id "<uuid>" \
  --course-code "<course-code>" \
  --printed-page-offset 1 > /tmp/course-grounding.sql
```

Review the generated SQL and overlap diagnostics before applying it. Extracted
segments and facts remain `needs_review`; this command never publishes them.

### Swahili Video Course Import (RICE-SEED-001)

Run the controlled import:

```sh
npm run import:notebooklm -- --file imports/rice-seed-video-course/rice_seed_video_course.csv
```

This flow stages rows first, then promotes only valid rows. It also:

- auto-creates draft course `RICE-SEED-001` if missing
- treats each CSV row as a `module` by default
- creates one default `video` lesson per module
- registers/links video + transcript source documents with `pending_review` when upload/segment verification is pending
- creates/updates draft learning path `Uchaguzi wa Mbegu za Mpunga` and places the course first

Validate after import:

```sh
npm run validate:course -- --course RICE-SEED-001
```

Validation checks include module order/count, required video lessons, resource/source-link coverage, duplicate import codes, and no accidental publishing.

### Rerun + Pending Review Corrections

Reruns are safe (idempotent) with the same CSV. To resolve `pending_review` links:

1. upload the original video/transcript into `source-documents`
2. update `storage_path`/metadata if needed
3. attach transcript segments where available
4. move relevant links from `pending_review` to `linked`
5. rerun `npm run validate:course -- --course RICE-SEED-001`

## Gemini Draft Generation

`generate-course-draft` accepts:

```json
{ "source_document_id": "<uuid>" }
```

It loads extracted `source_segments`, asks Gemini for strict JSON, and saves generated content as drafts with `import_source = gemini_api`.

High-risk topics are automatically marked:

- `status = needs_review`
- `risk_level = high`

High-risk terms include pesticide/herbicide, fertilizer dosage, disease treatment, livestock medicine, prices, costs, profit, and financial advice.

## Validation and Publishing

Validate a course:

```sh
curl -X POST "$SUPABASE_URL/functions/v1/validate-course-sources" \
  -H "Authorization: Bearer <editor-jwt>" \
  -H "Content-Type: application/json" \
  -d '{ "course_id": "<uuid>" }'
```

Publish a course:

```sh
curl -X POST "$SUPABASE_URL/functions/v1/publish-course" \
  -H "Authorization: Bearer <editor-jwt>" \
  -H "Content-Type: application/json" \
  -d '{ "course_id": "<uuid>" }'
```

Publishing is blocked when:

- any text/video lesson lacks a linked, approved/published source segment
- any source link is `source_missing` or `pending_review`
- high-risk content remains `needs_review`
- grounding facts or their cited source pages/timecodes are not reviewed
- a required prerequisite course is not published

Successful publishes write to `content_change_log`.

## Deployment

```sh
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy import-notebooklm-curriculum
supabase functions deploy promote-staged-curriculum
supabase functions deploy queue-document-ingestion
supabase functions deploy generate-course-draft
supabase functions deploy validate-course-sources
supabase functions deploy publish-course
```

After deployment, run a small editor-authenticated import and a validation check before connecting the learner app.
