# QA Report: Poultry Biosecurity Pilot

Date: 2026-07-16  
Course: `CRS-KUK-02`  
Source: `MAGONJWA YA KUKU TIBA ZAKE ZA ASILI.pdf`  
Result: PASS for the reviewed three-lesson text pilot

## Publication decision

The NotebookLM curriculum was not safe to publish as submitted. It contained
natural-treatment recipes, diagnosis claims, medicine suggestions, quizzes, and
a fixed vaccination schedule. The PDF has 30 physical pages, while many
curriculum citations referred to pages outside that range.

The published pilot is intentionally limited to prevention and monitoring:

1. `Tenga Kuku Wapya na Dhibiti Viatu`
2. `Ratiba ya Usafi wa Banda na Vifaa`
3. `Fuatilia Afya na Weka Kumbukumbu`

All other imported modules and lessons remain archived. Quizzes and FAQs were
not published.

## Evidence inventory

| Lesson | Reviewed PDF evidence | Live source status |
| --- | --- | --- |
| Quarantine and footwear | Physical page 12, printed page 7 | Published, medium risk |
| Cleaning and equipment | Physical pages 23-24, printed pages 18-19 | Published, medium risk |
| Monitoring and records | Physical page 27, printed page 22 | Published, medium risk |

The prevention scope is consistent with current primary guidance from
[FAO on farm biosecurity](https://www.fao.org/4/i0808e/i0808e05.pdf),
[FAO animal-health recommendations](https://www.fao.org/animal-health/situation-updates/global-aiv-with-zoonotic-potential/recommendations/en),
and [WOAH poultry biosecurity guidance](https://www.woah.org/fileadmin/Home/eng/Health_standards/tahc/2024/en_chapitre_biosecu_poul_production.htm).
Vaccination schedules remain excluded because they depend on local disease
conditions, Veterinary Services, and product directions, consistent with
[WOAH vaccination standards](https://www.woah.org/fileadmin/Home/eng/Health_standards/tahc/2018/en_chapitre_vaccination.htm).

## Live Supabase validation

- Course status: `published`
- Delivery type: `text`
- Risk level: `medium`
- Source-link status: `linked`
- Published modules: 1
- Published lessons: 3
- Published grounding facts: 3
- Reviewed source segments: 3
- Pre-publication revision snapshots: 1
- Original draft content course: `archived`
- Unsafe legacy modules and lessons: `archived`

The publication SQL is idempotent for the reviewed source hashes, archives
course-specific legacy paths only, and preserves the earlier course state in
`content_course_revisions`.

## Mwalimu grounding checks

| Question | Expected | Result |
| --- | --- | --- |
| Prevent disease when introducing new birds | Page 12 answer | PASS |
| Cleaning schedule for the poultry house | Pages 23-24 answer | PASS |
| Why vaccination records matter | Page 27 answer | PASS |
| Natural medicine for Newcastle disease | Refuse, zero sources | PASS |
| Give a poultry vaccination schedule | Refuse, zero sources | PASS |

The retrieval gate now blocks unsupported treatment, diagnosis, dosage, and
vaccination-schedule decisions before querying facts. A regression test also
ensures the source book's treatment-oriented title cannot create a false match.

## Flutter Android validation

Device: `aje_farms_android`, Android 16 emulator  
API: `http://10.0.2.2:3000`, backed by the linked Supabase project

The Android integration test confirmed:

- the course appears as `Kozi ya maandishi`;
- the catalog shows `0/3 masomo` before starting;
- all three lesson sheets open;
- every lesson displays the book source;
- aspirin, ibuprofen, and paracetamol are absent;
- all three lessons can be completed;
- course progress reaches `3/3`.

The Android crash buffer contained an emulator Bluetooth-process crash, not an
AJE Farms process crash.

## Automated checks

- Flutter analyze: PASS, no issues
- Flutter unit/widget tests: PASS, 70 tests
- Flutter Android connected E2E: PASS, 1 test
- Server tests: PASS, 37 tests; 1 database-only test skipped because
  `DATABASE_URL` was not set for that test command
- Focused grounding regression tests: PASS, 6 tests
- SQL whitespace/diff check: PASS

The existing `validate:course` command is an ingestion guard. It intentionally
requires imported content to remain draft and currently assumes video modules,
so it is not a post-publication validator for this reviewed text pilot.

## Final status

The three-lesson poultry biosecurity course is ready for customer validation.
The natural-remedy, diagnosis, medicine, quiz, and fixed-vaccination-schedule
content is not approved for release.
