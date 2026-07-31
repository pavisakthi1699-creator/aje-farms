# Flutter Content Inventory — 2026-07-15

## Decision

The Flutter content pipeline is corrected, but the current curriculum is **not
ready to share with a customer yet** because no course or grounding fact has
completed source review and publication.

Flutter, the Node API used by Flutter, and the linked Supabase content store
were reviewed and corrected. The retired React reference application has since
been removed from the repository.

## Live status — 2026-07-16

- 0 published courses and 0 published grounding facts are customer-visible.
- All 14 legacy catalogue payloads and 18 learner documents are held in draft.
- All 25 staged quiz rows are explicitly ignored.
- 19 PDF source segments and 6 NotebookLM facts are held in `needs_review`.
- The Ushuhuda PDF and rice course video are stored in the private
  `source-documents` bucket.
- The linked Supabase migration history now matches the workspace.
- Flutter supports only the intended learner formats: text lessons and video
  lessons. Source PDFs remain private evidence for reviewers and Mwalimu AI.
- A course can reach Flutter only after the course, module, lesson, source
  page/timecode, source document, and at least one non-high-risk grounding fact
  are all linked, reviewed, and published.

Remaining publication work:

1. Manually review the six Ushuhuda fact-to-page matches.
2. Supply or generate a timestamped transcript for the rice video.
3. Review the resulting video segments and facts.
4. Publish the approved source records and course hierarchy.

## Correction pass — completed after inventory

The following repository corrections were completed after the inventory was approved:

- Replaced unsupported video/PDF/quiz claims in the built-in catalog with honest reading lessons.
- Removed pre-completed lessons and hardcoded 65% progress; Flutter now derives progress from completed lesson records.
- Limited Flutter learner lessons to reading and video; quiz, checklist, FAQ,
  PDF, audio, and practical-task curriculum rows cannot become course lessons.
- Removed fabricated community identities, engagement counts, relative times, member counts, and the unsourced tomato-price claim.
- Replaced high-risk AI quick prompts and fallback answers with observation, record-keeping, source-checking, and expert-escalation guidance.
- Removed visible demo/sample labels, corrected `Ujasiriamali`, and removed unsupported 24/7, unlimited-AI, and blanket payment-security claims.
- Versioned the built-in server catalog and added a safe seed migration that upgrades stale seed content without overwriting later editor changes.
- Changed the Ushuhuda import to draft/needs-review and added a catalog guard that hides high-risk, unreviewed, or gap-containing imported courses even if their outer record is mistakenly marked approved.

Still external/unverified: subject-matter approval of course facts, the video
transcript, payment pricing/provider terms, support hours, production API
configuration, and media usage rights.

## Scope and verification limits

- Reviewed the Flutter-visible local catalog, course and assessment content, AI fallback answers, community seeds, plans, onboarding and screen copy, media assets, backend catalog adapter, local JSON state, Supabase curriculum migrations, and curriculum import artifacts.
- Used the connected Flutter QA evidence from the same date to cross-check what the Android app renders.
- The linked Supabase project was queried directly and its publication states,
  source records, private Storage objects, and migration history were verified.
- The repository contains no current production API URL or production content credential. A release build would require those values.

## What Flutter can show

### Runtime content path

1. Flutter production starts immediately with `DemoAppRepository` as its cached seed.
2. It requests `/api/catalog` in the background.
3. If that request fails, is incomplete, or times out, Flutter silently keeps the demo seed.
4. The UI does not clearly tell the customer that fallback/demo content is being shown.

This means a production-looking app can display sample content even when the production catalog is unavailable.

### Flutter lesson-type support

Flutter currently understands only:

- Text (`reading`)
- Video

Unknown lesson types safely fall back to text at the wire boundary, while the
server publication guard rejects unsupported learner lesson types.

## Current launch/demo catalog

The same three-course seed exists in both Flutter and the Node catalog.

| Course | Outcomes | Visible lessons | Current payload | Readiness |
|---|---:|---:|---|---|
| Kilimo cha Pasheni | 4 | 3 | 1 video label, 1 PDF label, 1 premium quiz label | Not ready |
| Ufugaji wa Kuku | 4 | 3 | 1 video label, 1 PDF label, 1 premium quiz label | Not ready |
| Kilimo cha Nyanya | 4 | 3 | 1 video label, 1 PDF label, 1 premium quiz label | Not ready |

### Course-detail inventory

#### Kilimo cha Pasheni

- Description: one sentence covering preparation, planting, care, diseases, and markets.
- Lessons:
  - `Maandalizi ya shamba` — marked as a five-minute video and pre-completed in the seed.
  - `Mwongozo mfupi wa pasheni` — marked as a 2 MB PDF.
  - `Jaribio la maarifa` — says “Maswali 10” and is premium.
- The separate hardcoded assessment contains **5**, not 10, pasheni questions.
- The course card hardcodes 65% progress while the detail view derives progress from three lesson records. The connected Android run displayed contradictory progress values.

#### Ufugaji wa Kuku

- Description: one sentence covering housing, feed, vaccination, hygiene, and business.
- Lessons:
  - `Misingi ya ufugaji wa kuku` — marked as a six-minute video.
  - `Ratiba ya chanjo` — marked as a 1 MB PDF.
  - `Biashara ya kuku` — premium quiz.
- No actual video stream, vaccine-schedule document, or course-specific quiz payload exists in the Flutter course model.
- Vaccine guidance is a high-risk subject and needs named source, jurisdiction/date, and expert approval.

#### Kilimo cha Nyanya

- Description: one sentence covering nursery, planting, fertilizer, pests, and market preparation.
- Lessons:
  - `Kuandaa kitalu` — marked as a four-minute video.
  - `Udhibiti wa wadudu` — marked as a 2 MB PDF.
  - `Maandalizi ya soko` — premium quiz.
- No actual video, PDF document URL, or tomato quiz payload exists in the Flutter course model.
- Pest, disease, fertilizer, and price content needs source and expert review.

### What “opening a lesson” currently does

- Every lesson opens the same text preview sheet.
- Video lessons do not play a video.
- PDF lessons do not open a PDF.
- Course quiz lessons do not open their stated quiz.
- A user can mark the short preview description as completed.
- The large course play button is labeled `Cheza somo la mfano` (play a sample lesson).

### Documents

Three document cards are generated from the three PDF-labeled lessons:

- Mwongozo mfupi wa pasheni
- Ratiba ya chanjo
- Udhibiti wa wadudu

The seed documents have labels and descriptions but no document URL. The production ingestion design requires signed URLs, but Flutter has no verified live document to open in this inventory.

## Assessments and assignments

- One hardcoded five-question pasheni quiz exists outside the course catalog.
- The questions cover drainage, root rot, supports, crop care, and a safe first response to unknown symptoms.
- The catalog promises a ten-question quiz, creating a count/content mismatch.
- One generic field assignment asks for crop/livestock, observation, and next action.
- Submission is considered complete when all three text fields contain at least four characters; it is saved as a fixed 5/5 score without expert review.
- Imported quiz questions are not connected to this Flutter assessment screen.

## Mwalimu AI content

### Local Flutter fallback

The demo AI has fixed answers for:

- Pasheni
- Nyanya/ukungu
- Kuku/ufugaji
- Wadudu/viwavi
- Mbolea/udongo
- Maji/umwagiliaji
- Soko/bei

These answers contain agronomic, disease, fertilizer, animal-health, and market guidance. Only three answers attach a source card, and those cards point back to the same short demo lesson descriptions rather than a reviewed external source.

### Backend fallback

- Without Gemini, the backend searches the small approved course payload by overlapping words.
- It can select content based on generic word overlap rather than agronomic meaning.
- The grounding corpus is only as complete and reliable as the approved course payload.
- The local three-course catalog is too thin to support the broad promises made by the AI UI.

### Risky customer prompts currently encouraged by the UI

- `Dawa ya kuanza`
- `Dawa gani kwa ukungu?`
- `Nitumie mbolea gani?`
- `Kipimo kwa shimo`
- `Mbolea ya DAP`
- `Bei ya leo`

These prompts imply specific treatment, dosage, and current-market answers. They require reviewed sources, location/crop context, dates, and safety boundaries before customer use.

## Problem categories

Six hardcoded categories are shown:

1. Magonjwa ya mimea
2. Wadudu na Visumbufu
3. Mbolea na Udongo
4. Maji / Umwagiliaji
5. Soko na Bei
6. Ufugaji

Each category has only one short summary and two examples. The breadth advertised is much larger than the reviewed course corpus.

## Community content

Three seed posts and five seed replies are bundled into the catalog:

| Post | Main concern | Readiness |
|---|---|---|
| Joseph M., Morogoro — pasheni leaves changing color | Synthetic identity/time/engagement; expert reply gives disease-management advice without a source | Not ready |
| Mama Asha, Mbeya — starting broilers | Synthetic identity/time/engagement; reply claims a checklist and vaccine schedule that the visible Flutter course does not contain | Not ready |
| Mtaalamu AJE, Arusha — tomato prices have risen | Undated, unsourced, time-sensitive market claim presented as expert content | Blocker |

Additional issues:

- Synthetic relative times such as “Saa 2 zilizopita” and “Leo” never age correctly.
- Synthetic likes/comments can be mistaken for real customer engagement.
- The dashboard claims `Wakulima 1,200+` without a verified source.
- The UI uses the English word `likes` inside otherwise Swahili content.
- The production store seeds these posts into the database if their IDs do not already exist.

## Plans, payment, trial, and support claims

Hardcoded plans:

- Wiki 1 — TZS 3,000
- Mwezi 1 — TZS 10,000 — recommended
- Kozi Maalum — TZS 50,000

Customer-facing claims that are not yet production-backed:

- `24h Jaribio la bure`
- `Jaribio linaendelea`
- M-Pesa, Tigo, and Airtel payment choices
- `Malipo yako ni salama. Tunalinda taarifa zako zote.`
- `Tupo kwa ajili yako 24/7`
- Premium access promises covering lessons, AI, and community

The release checklist states that the real mobile-money provider is deferred. These prices, trial rules, payment methods, security language, refund/renewal behavior, and 24/7 support claim require commercial approval before customer sharing.

## General UI copy inventory

- Approximately 240 literal customer-facing text declarations occur across 20 Flutter feature files.
- Major copy areas: profile (34), courses (54 across course files), community (32), assessments (17), notifications (15), home (27), paywall (22), AI chat (16), onboarding (9), expert support (8), problem reporting (13), and authentication (7).
- Demo language remains visible: `kozi za mfano`, `Cheza somo la mfano`, `Mgeni wa demo`, and `Mgeni wa Demo`.
- The profile hardcodes `Toleo la App 2.4.0` instead of reading the installed build version.
- Onboarding contains the spelling `Kilimo na Ujasiliamali`; the standard spelling is `Ujasiriamali`.
- Copy mixes Swahili and English terms including `Trial`, `premium`, and `likes`.

## Local media assets

| Asset | Dimensions | Size | Inventory result |
|---|---:|---:|---|
| kuku.jpg | 900×1350 | 172 KB | Present |
| nyanya.jpg | 900×1295 | 256 KB | Present |
| pasheni.jpg | 900×600 | 96 KB | Present |
| farm-field.jpg | 834×1200 | 244 KB | Present |
| AJE sprout SVG | Vector | — | Present |

The images load locally, but source ownership, usage rights, crop accuracy, alt-description policy, and customer approval are not documented in the repository.

## Structured curriculum inventory in the repository

These are source-linked editorial artifacts, not verified customer-ready Flutter content.

### RICE-SEED-001 — Aina za Mbegu za Mpunga na Sifa Zake

- 27 imported rows total.
- 1 course, 3 modules, 5 lessons, 3 checklists, 5 quizzes, 5 FAQs, 3 content gaps, 1 learning path, and 1 learning-path link.
- Statuses: 23 draft, 3 needs-review, 1 unset.
- Risk: 3 high-risk, 22 normal, 2 unset.
- Named gaps include missing disease/pesticide/fertilizer detail, missing cost/profit estimates, and missing exact planting measurements.
- One high-risk FAQ asks which pesticide to use and explicitly has `SOURCE_MISSING`.
- Repository documentation says this course must remain draft and must not auto-publish.

### CRS-USH-01 — Ushuhuda Wangu: Chuo Kikuu cha Mtaani

- 37 imported rows total.
- 1 course, 4 modules, 6 lessons, 4 checklists, 10 quizzes, 10 FAQs, and 2 content gaps.
- Statuses: 17 draft and 20 needs-review.
- Risk: 17 normal and 20 high-risk.
- High-risk topics include borrowing, investing TZS 10,000,000, financial literacy, and starting a business with limited money.
- The ingestion script creates an `approved` customer catalog payload even though many underlying structured rows remain high-risk and need review. This bypass between structured review state and Flutter-visible approval is a release blocker.

### CRS-KUK-02 — Magonjwa ya Kuku na Tiba za Asili

- The ingestion script expects a source Markdown file outside the repository and a matching source PDF in Supabase.
- The script forces course, module, and lesson rows to high-risk/needs-review and keeps the generated Flutter catalog payload as draft.
- Exact row counts and live source linkage could not be verified because the source file is outside the workspace and live database authentication failed.
- Natural remedies and poultry disease treatment require veterinary review and prominent safety limits.

## Catalog and publication inconsistencies

There are two separate publication systems:

- Structured Supabase curriculum uses statuses such as draft, needs-review, approved, and published with source validation.
- The Flutter API reads `content_courses` and exposes only records whose status is exactly `approved`.

Consequences:

- Publishing structured curriculum does not automatically prove the Flutter payload is approved and compatible.
- Approving a Flutter payload can expose content whose underlying structured rows are still high-risk or need review.
- The three demo courses are automatically seeded as approved in a production Postgres/Supabase store.
- Imported reading/checklist/FAQ content is incompatible with the current Flutter lesson model.

## Readiness blockers

### P0 — Must be resolved before any customer share

1. Confirm the actual launch catalog from the live database; current live contents are unverified.
2. Prevent silent demo fallback from appearing as real production content.
3. Replace lesson labels/previews with real playable/readable/answerable lesson payloads.
4. Reconcile structured review state with the `content_courses` approval state.
5. Remove or formally approve all high-risk disease, pesticide, fertilizer, dosage, animal-health, price, and financial advice.
6. Remove or clearly label synthetic community activity and eliminate the unsourced current-price claim.
7. Confirm commercial terms before showing prices, payment security, trial, premium, and 24/7 support claims.
8. Resolve Flutter incompatibility with reading, checklist, and FAQ lesson types.

### P1 — Content consistency and trust

1. Reconcile 65% / completed lesson / course detail progress.
2. Reconcile the promised 10-question pasheni quiz with the actual 5-question assessment.
3. Remove remaining demo/sample labels from customer builds.
4. Correct Swahili spelling and mixed-language copy.
5. Replace hardcoded version, follower/member, time, like, and comment claims with verified data.
6. Document media rights and content ownership.

## Inventory conclusion

The app has a strong visual shell and working navigation, but most learning content is still a thin demo layer. The repository also contains richer curriculum candidates, yet they are largely draft/high-risk and are not safely connected to Flutter. Content correction should begin only after the launch catalog and authority for agronomic, veterinary, financial, pricing, and commercial claims are confirmed.
