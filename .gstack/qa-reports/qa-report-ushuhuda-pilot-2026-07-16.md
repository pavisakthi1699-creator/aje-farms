# Ushuhuda Pilot Course QA Report

Date: 2026-07-16  
Scope: Flutter learner app, Supabase content model, catalogue API, and Mwalimu grounding  
Excluded: React app

## Publication result

- Course: `CRS-USH-01` — `Misingi ya Ujasiriamali wa Kilimo`
- Status: published
- Format: text
- Published structure: 1 module, 3 lessons, 3 reviewed grounding facts
- Public documents: 0; the source PDF remains private evidence
- Source: `Ushuhuda Wangu Toleo La 4 . DR MDASHIRU NURU IBRAHIM`
- A revision snapshot was stored before publication.

## Published lessons and evidence

1. `Anza Kidogo na Ujifunze Biashara` — pages 80–81
2. `Kilimo Mseto na Mapato ya Nyakati Tofauti` — pages 82–84
3. `Nguzo Tatu: Mfumo, Watu na Bidhaa` — pages 151–155

Each lesson was opened in the Android Flutter build, its source label was
confirmed, and its completion state was saved. The final course state reached
3/3.

## Issues found and fixed

1. Unrelated questions could match weak common terms and misuse book facts.
   Retrieval now ignores weak/common terms and refuses unsupported questions.
2. The entrepreneurship course used an unrelated tomato image. It now uses a
   suitable field/workers image.
3. A text course displayed a video play icon. Reading courses now display a
   book icon; video lessons retain the play icon.
4. Partial progress incorrectly said the core lessons were finished and
   suggested a quiz. Progress guidance now distinguishes 0/3, partial, and 3/3
   states without quiz language.
5. A grounded answer could include a lower-relevance lesson. Mwalimu now
   returns only facts tied for the strongest match.
6. The reusable SQL selected some lesson and module codes without also
   constraining them to the pilot course. Every publication update is now
   explicitly scoped to `CRS-USH-01`.

## Validation evidence

- Supabase: published, 1 module, 3 lessons, 3 grounding facts
- Catalogue API: exactly 1 published course, 3 reading lessons, 0 public PDFs
- Supported AI question: returned the correct three business pillars and
  cited pages 151–155
- Unsupported poultry-medicine question: refused with no sources
- Flutter analyzer: no issues
- Flutter tests: 70 passed
- Server tests: 34 passed, 1 skipped because the optional test database URL
  was not set
- Android crash log after the complete flow: no fatal exceptions

Screenshots:

- `/private/tmp/aje_ushuhuda_courses_final.png`
- `/private/tmp/aje_ushuhuda_lesson_source.png`
- `/private/tmp/aje_ushuhuda_e2e_final.png`

## Reusable gate for the next books

Do not publish a new course until:

1. The PDF is stored as private source evidence.
2. Every lesson is explicitly text or video.
3. Every factual claim is linked to an approved page range or video timestamp.
4. Unsupported, duplicate, weak, and high-risk facts remain unpublished.
5. The catalogue exposes only the intended course content, not the private PDF.
6. Mwalimu answers a supported question with the right citation and refuses an
   unrelated question.
7. The Flutter course opens, renders the correct media icon, saves progress,
   and reaches completion on Android.

## Commits

- `1b49a00` publish source-reviewed Ushuhuda pilot course
- `026a843` refuse unrelated AI grounding
- `eb02fff` use correct course artwork
- `ddbdb66` distinguish text course hero
- `74e0180` correct text course progress guidance
- `53b257d` prefer strongest AI grounding facts
- `c012b34` scope publication updates and preserve unrelated course artwork
