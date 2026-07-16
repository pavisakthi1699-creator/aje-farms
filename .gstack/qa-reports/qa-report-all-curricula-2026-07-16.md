# All Reviewed Curricula QA Report

Date: 2026-07-16

Scope: Flutter learner app, Supabase content model, catalogue API, source evidence, and Mwalimu grounding

Excluded: React app

## Outcome

Nine newly ingested text curricula were reduced to source-reviewed pilots and
published end to end. Each course exposes one module and three reading lessons.
The private PDFs remain evidence only. NotebookLM quizzes, formulas, treatment
instructions, exact input rates, unsupported promises, and unreviewed draft
content remain unpublished.

| Course | Published title | Source pages |
|---|---|---|
| `CRS-001` | Kuanzisha Bustani Salama ya Familia | 77–81 |
| `CRS-ALZ-01` | Misingi ya Shamba na Uvunaji wa Alizeti | 4, 20 |
| `CRS-CHK-01` | Misingi ya Shamba na Ubora wa Chikichi | 5–6, 17 |
| `CRS-KUK-01` | Usalama wa Lishe na Uhifadhi wa Chakula cha Kuku | 4–5, 16–18, 21 |
| `CRS-MGB-01` | Aina, Usafi na Uvunaji wa Ndizi | 4, 17, 19 |
| `CRS-MHG-01` | Maandalizi na Utunzaji Baada ya Mavuno ya Muhogo | 3–6, 14–17 |
| `CRS-MPU-01` | Maandalizi, Maji na Soko la Mpunga | 8–10, 23–24 |
| `CRS-NAN-01` | Misingi ya Aina, Eneo na Thamani ya Nanasi | 7, 11, 27–29 |
| `CRS-PSH-01` | Misingi ya Kuanzisha Shamba la Pasheni | 7–9, 14 |

## Source audit

- All nine PDFs are present in the private `source-documents` bucket.
- The ingestion structure validator passed all nine curricula.
- Physical PDF page counts were recorded in Supabase.
- NotebookLM page references were not trusted automatically. Several curricula
  cited pages beyond the physical length of their PDFs, so published evidence
  was selected by manually inspecting the physical PDF pages.
- Every published lesson has one reviewed source segment and one published
  grounding fact.
- A revision snapshot was saved for every course before publication.

## Supabase publication checks

Every course has:

- status `published`
- delivery type `text`
- risk level `medium`
- source-link status `linked`
- 1 published module
- 3 published lessons
- 3 published grounding facts
- 9 linked source relationships across the course, module, and lessons

All nine original NotebookLM `content_courses` rows are archived. The 160
generated quizzes, 38 checklists, and 90 FAQs are marked invalid in staging so
a later promotion job cannot publish them accidentally. A database scan found
no published lesson containing an exact percentage formula or the screened
veterinary drug names.

## Mwalimu checks

- Safe supported question about poultry-feed storage returned the reviewed fact
  and cited `LISHE BORA YA KUKU`, page 21.
- “Nitumie mbolea gani kwenye nanasi?” was refused with no sources.
- “Nitumie kiuatilifu kiasi gani kwa muhogo?” was refused with no sources.
- Retrieval now blocks unsupported fertilizer and pesticide product, rate, and
  schedule decisions in addition to treatment and vaccination decisions.

## Flutter Android validation

The connected Android test loaded the live Supabase catalogue and validated all
nine course IDs, titles, text-course badges, source labels, and lesson bodies.
It then opened every course, opened every lesson, confirmed the source, marked
all 27 lessons complete, and reached 3/3 in every course.

The mpunga catalogue mapping referenced a missing image. It now falls back to a
bundled crop image, and all nine live course IDs have an asset-existence
regression check.

Android crash buffer: no crashes.

## Automated checks

- Remaining-curriculum structure validator: passed all 9
- Supabase live smoke: passed
- Server tests: 43 passed, 1 optional database test skipped
- Flutter analyzer: no issues
- Flutter unit/widget tests: 70 passed
- Flutter connected Android curriculum test: passed in 47 seconds
- Git diff whitespace check: passed

## Publication rule for future books

Future NotebookLM curricula should enter the same review gate:

1. Upload the source privately and record the real physical page count.
2. Treat generated citations and quizzes as drafts.
3. Manually select the learner-safe claims and physical page ranges.
4. Publish only lessons with reviewed evidence and grounding facts.
5. Keep formulas, diagnoses, treatments, pesticide choices, input rates, fixed
   schedules, and unsupported financial promises unpublished until reviewed by
   the appropriate specialist.
6. Run the live Mwalimu refusal/supported-answer checks.
7. Complete the course in the connected Flutter Android app.
