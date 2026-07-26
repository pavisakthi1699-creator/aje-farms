# Course Source Inventory QA — 2026-07-16

Status: DONE_WITH_CONCERNS

Scope: Live Supabase source documents, storage objects, curriculum imports, published course records, grounding facts, lesson resources, and the Flutter-facing `/api/catalog` response. React was not tested.

## Result

- 12 PDF source records exist.
- 11 PDF courses are published and visible to Flutter.
- Each visible PDF course has 3 published reading lessons and 3 published grounding facts: 33 lessons and 33 facts total.
- 1 PDF source, `KILIMO CHA NYANYA KWA MTAJI KIDOGO`, has no curriculum import, no course, no source segments, no facts, and no storage object.
- 1 uploaded video, `WhatsApp Video 2026-07-06 at 18.09.24.mp4`, has an imported curriculum and a draft course (`RICE-SEED-001`), but it is not learner-ready: delivery type is text, no lessons are published, no video lesson resource exists, no grounding facts exist, and its transcript object is missing.
- `MAGONJWA YA KUKU TIBA ZAKE ZA ASILI` has a published safe 3-lesson course, but its canonical PDF object is missing from the configured storage path.
- The full NotebookLM curricula are not all published. Most import batches remain `needs_review`; only the narrowed, reviewed 3-lesson pilots are exposed to learners.

## Published and Flutter-visible

| Source | Course | Material |
|---|---|---:|
| Bustani ya Eden | CRS-001 | 3 lessons / 3 facts |
| Kilimo cha Alizeti | CRS-ALZ-01 | 3 lessons / 3 facts |
| Kilimo cha Chikichi | CRS-CHK-01 | 3 lessons / 3 facts |
| Kilimo cha Nanasi | CRS-NAN-01 | 3 lessons / 3 facts |
| Kilimo cha Pasheni | CRS-PSH-01 | 3 lessons / 3 facts |
| Kilimo cha Migomba | CRS-MGB-01 | 3 lessons / 3 facts |
| Kilimo cha Mpunga | CRS-MPU-01 | 3 lessons / 3 facts |
| Kilimo cha Muhogo | CRS-MHG-01 | 3 lessons / 3 facts |
| Lishe Bora ya Kuku | CRS-KUK-01 | 3 lessons / 3 facts |
| Magonjwa ya Kuku | CRS-KUK-02 | 3 lessons / 3 facts |
| Ushuhuda Wangu | CRS-USH-01 | 3 lessons / 3 facts |

## Missing or incomplete

### KILIMO CHA NYANYA KWA MTAJI KIDOGO

- Source status: draft
- Storage object: missing
- Curriculum import: missing
- Course: missing
- Published learner material: none

### Rice seed WhatsApp video

- Video object: present
- Curriculum batch: imported/approved
- Course: `RICE-SEED-001`, draft
- Delivery type: incorrectly text
- Published lessons: 0
- Published video resources: 0
- Published grounding facts: 0
- Transcript source record: present, but transcript storage object and source segments are missing

### MAGONJWA YA KUKU TIBA ZAKE ZA ASILI

- Safe course material is published and visible.
- The source PDF object is missing at `pending/pdf/magonjwa-ya-kuku-tiba-zake-za-asili-7a4d01d7f718.pdf`.
- Existing extracted segments and facts allow the current lessons to work, but the source archive is incomplete.

## Publication interpretation

“Published” currently means a reviewed safe pilot of 3 lessons per PDF course, not the entire NotebookLM curriculum. High-risk treatment, pesticide, fertilizer, diagnosis, dosage, and fixed-schedule material remains held for review and should not be bulk-published without subject-matter approval.
