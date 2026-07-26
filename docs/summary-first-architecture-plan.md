# "Summary First, Deep-Dive Second" — Technical Plan

**Status: proposal for approval. No implementation code written.**

Scope: Books→Lessons hierarchy, mobile-first admin CMS, in-app PDF viewer with
"Chanzo" source button, content-visibility audit, pricing.

---

## 0. Read this first — three findings that change the plan

### 0.1 BLOCKER for the next APK: the community PII fix was never implemented

You said you want to fix small issues before cutting a new APK. This is the
biggest one and it is still open. Verified just now:

- `server/store/postgres-store.js:1460` still has `moderatedBy: row.moderated_by ?? null`
- `grep author_phone server/` returns nothing

So `GET /api/community/posts` (unauthenticated) still serves **learner phone
numbers** as `author` and **admin phone numbers** as `moderatedBy`. The staging
work from the other spec did land (`build_flags.dart` is present), but
`docs/community-identity-hardening-spec.md` was not acted on.

Phase 1 of that spec is a few lines and needs no migration. **Do not ship an APK
without at least that.** Everything below assumes it happens first.

### 0.2 The admin CMS is currently disconnected from what learners see

This is the finding that most affects your plan. In `server/store/postgres-store.js`:

| Method | Reads/writes | Supabase branch? |
|---|---|---|
| `contentCoursesForAdmin()` (`:406`) | `content_courses` | **no** |
| `upsertContentCourse()` (`:415`) | `content_courses` | **no** |
| `approvedContentCourses()` (`:107`) | `content_courses` | **yes** → `#publishedStructuredCourses()` (`:122`) |

Production runs `AJE_STORE=supabase`. So the learner catalog is built from the
structured model (`courses` → `course_modules` → `lessons`), while the admin
dashboard reads and writes a completely different table (`content_courses`).

**In production, approving or editing a course in the admin dashboard has no
effect on what learners see.** The Maandishi tab is currently a CMS for a table
nobody reads.

Building a richer mobile CMS on this foundation would compound the problem.
Reconnecting the CMS to the structured model has to be Phase 1 of this work.

Needs live confirmation against staging before we commit to the fix — the code
path is unambiguous, but confirm `content_courses` is genuinely unused in the
production read path.

### 0.3 Most of the Books→Lessons schema already exists

The Supabase content model already implements the hierarchy you described. You
do **not** need new `Books` and `Chapters` tables:

| Your requirement | Existing table | Notes |
|---|---|---|
| Parent "Book" (PDF, title) | `source_documents` | `source_kind='pdf'`, `storage_bucket`, `storage_path`, `page_count`, `title` |
| Chapter / page range | `source_segments` | `page_start`, `page_end`, `section_title`, `segment_order` |
| Lesson ↔ Book link | `content_source_assets` | lesson → whole document |
| Lesson ↔ page range link | `content_source_links` | lesson → `source_segment` → document |
| Video on a lesson | `lesson_resources` | `resource_type='video'`, `external_url`, `duration_seconds` |
| Summary text | `lessons.body_sw` | already the summary field |

`#publishedStructuredCourses()` (`postgres-store.js:122-182`) already joins
lesson → source document to produce `source_title`, and already selects
`video_url` / `video_storage_path` from `lesson_resources`.

**The schema work is small.** The real work is (a) reconnecting the CMS,
(b) exposing source/page data through `/api/catalog`, and (c) new Flutter UI.

---

## 1. Database schema changes

Additive only. No new hierarchy tables.

### 1.1 `source_documents` — make it a presentable "Book"

```sql
alter table public.source_documents
  add column if not exists cover_storage_path text,
  add column if not exists display_title_sw text,
  add column if not exists author_sw text,
  add column if not exists is_learner_visible boolean not null default false;
```

- `cover_storage_path` — book cover for the library UI. Genuinely missing today.
- `display_title_sw` — current `title` holds shouty ingestion titles like
  `KILIMO CHA NYANYA KWA MTAJI KIDOGO`. Keep `title` canonical for ingestion,
  add a presentation title.
- `is_learner_visible` — explicit gate. Do not infer learner visibility from
  `processing_status`; a document can be approved for grounding without being
  something we want to hand a farmer as a whole book.

### 1.2 Lesson → book link with page anchor

`content_source_links` already gives lesson → segment → document with a page
range. What is missing is a *primary* link — a lesson may cite several segments,
but the "Chanzo" button needs one deterministic target.

```sql
alter table public.content_source_links
  add column if not exists is_primary boolean not null default false;

create unique index if not exists content_source_links_primary_unique
  on public.content_source_links (content_type, content_id)
  where is_primary;
```

The "Chanzo" target for a lesson = the primary link's document + its segment's
`page_start`. Falls back to the earliest linked segment if no primary is set.

### 1.3 Do NOT add

- A `books` table — `source_documents` is it.
- A `chapters` table — `source_segments` is it.
- A `summary` column on `lessons` — `body_sw` is it.
- Anything in `server/store/schema.sql` (the Express/JSON model). That model
  stays as-is for the JSON/local dev path; see §2.1 for how the two reconcile.

### 1.4 Pricing (see §7 — blocked on your input)

Prices are currently **hardcoded in the Flutter client** at
`aje_farms_mobile/lib/src/repositories/demo_app_repository.dart:227-246`:
TZS 3,000 (Wiki 1) / TZS 10,000 (Mwezi 1) / TZS 50,000 (Kozi Maalum).

That means **every price change requires an APK rebuild and redistribution.**
If prices are going to move, they should be server-driven:

```sql
create table if not exists public.subscription_plans (
  id text primary key,
  title_sw text not null,
  subtitle_sw text not null,
  price_minor integer not null,       -- TZS cents; never store money as text
  currency text not null default 'TZS',
  interval_days integer,              -- null = one-off (Kozi Maalum)
  is_recommended boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0
);
```
Served via a new `GET /api/plans`, cached client-side with the current hardcoded
list as offline fallback.

---

## 2. Admin CMS updates

### 2.1 Phase 1 is not UI — it is reconnecting the CMS

Before any new form work, `upsertContentCourse` / `contentCoursesForAdmin` must
operate on the model the catalog actually reads. Two options:

**Option A — CMS writes the structured model (recommended).**
Add a `supabase` branch to the admin store methods that reads/writes
`courses`/`course_modules`/`lessons`/`lesson_resources` directly, mirroring how
`approvedContentCourses()` already branches. `content_courses` becomes
JSON/local-dev only.
*Cost:* moderate. *Result:* one source of truth, CMS edits are immediately live.

**Option B — sync `content_courses` → structured model on approve.**
Keep the CMS writing `content_courses`, add a promotion step.
*Cost:* lower initially. *Result:* two models to keep in sync forever, plus a
promotion pipeline that already exists in a different form
(`supabase/functions/promote-staged-curriculum`) and would now have a rival.

**Recommendation: Option A.** Option B institutionalises the split that caused
this bug.

### 2.2 Book upload from a phone

There is **no upload path in the app today** — PDFs enter via
`server/scripts/` ingestion against Supabase storage. This is genuinely new work.

New endpoints, all `requireAuthSession` + `requireAdminSession`:

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/admin/books` | List `source_documents` (id, title, page_count, cover, lesson count) for the linking dropdown |
| `POST` | `/api/admin/books` | Create the record + return a short-lived Supabase signed upload URL |
| `PATCH` | `/api/admin/books/:id` | Edit display title, author, cover, visibility |
| `GET` | `/api/admin/books/:id/segments` | Page ranges, for the chapter dropdown |

**Upload the file directly from the device to Supabase storage using a signed
URL — never proxy a 20 MB PDF through Express on Railway.** The API issues the
signed URL; the client PUTs to storage; the client then confirms so the server
can set `processing_status` and checksum.

### 2.3 Mobile-first form architecture

The existing dashboard (`admin_dashboard_screen.dart`, 1,066 lines) is already a
`DefaultTabController` with three tabs and works on a phone. Extend it to four
tabs (add **Vitabu** / Books) rather than building a parallel surface.

Concrete mobile constraints for the lesson editor:

- **Single-column, one concern per screen.** No side-by-side. The lesson form
  should be a full-screen route, not a dialog — dialogs fight the keyboard.
- **Summary field:** multiline `TextField`, `minLines: 8`, `maxLines: null`,
  `keyboardType: TextInputType.multiline`, `textCapitalization: sentences`.
  Wrap the form body in a `SingleChildScrollView` with
  `Scaffold(resizeToAvoidBottomInset: true)` so the field scrolls above the
  keyboard. This is the single most important detail for paste-from-phone.
- **Paste affordance:** an explicit "Bandika" (paste) icon button calling
  `Clipboard.getData` — long-press-to-paste is unreliable on low-end Android.
- **Book linking:** `DropdownButtonFormField<String>` over `GET /api/admin/books`,
  with a search field when the list exceeds ~10. On selection, load
  `/segments` and show a second dropdown for the chapter/page range.
  Both dropdowns store IDs, never titles.
- **Draft safety:** autosave to `SharedPreferences` on every change, restore on
  reopen. Losing a pasted summary to a phone call is the most likely real-world
  failure and the cheapest to prevent.
- **Explicit save with status feedback.** No silent autosave to the server;
  the admin must know whether content is `draft` or `approved`.

### 2.4 The web-vs-Flutter decision — needs your call, see §7

---

## 3. Frontend UI architecture (user app)

### 3.1 Current state

- **No PDF package. No video player package.** `pubspec.yaml` has only
  `url_launcher: ^6.3.1`.
- Video today opens **externally**, leaving the app:
  `course_widgets.dart:518` → `_openVideo` (`:563`) → `launchUrl` against
  `/api/lessons/:id/video`, which 302-redirects to a signed Supabase URL.
- Documents (`AppDocument`, `models/app_document.dart`) carry a `url` and a
  `sizeLabel` — a download-oriented model, exactly what you want to move away from.

### 3.2 New/changed components

**`LessonView` (rework of `course_detail_screen.dart` lesson section)**
Vertical order, matching "summary first":
1. `LessonVideoPlayer` — inline, 16:9, tap-to-play, **never autoplay**.
2. `LessonSummary` — `body_sw`, generous line height, large type.
3. `SourceButton` — prominent "Chanzo" button.

**`LessonVideoPlayer` (new)**
Requires `video_player` + `chewie`. Must show duration before play, and must not
prefetch. See §5 for the data-usage rules.

**`SourceButton` (new)**
Label "Chanzo", book icon, subtitle showing book title and page range
(`"Bustani ya Eden · uk. 12–18"`). Pushes `BookViewerScreen`.

**`BookViewerScreen` (new)**
In-app PDF viewer. Recommend `pdfrx` (actively maintained, good Android
performance, supports jump-to-page and progressive loading from a URL). `pdfx`
is the fallback. Avoid `flutter_pdfview` — it fetches the whole file first,
which is exactly the behaviour you want to eliminate.

Requirements:
- Opens at the lesson's `page_start`.
- Streams — no blocking full-file download.
- Page indicator, jump-to-page, pinch zoom.
- Explicit "Pakua" (download) as an *option*, never the default.
- Caches to disk so a second open is instant and offline.

**`BooksLibraryScreen` (new, optional)**
Browse `is_learner_visible` books directly. Low priority — the Chanzo button is
the primary entry point.

### 3.3 API surface for the app

Extend the `/api/catalog` lesson payload with:

```jsonc
{
  "id": "…", "title": "…", "body": "…", "type": "video",
  "durationMinutes": 4,
  "video": { "url": "/api/lessons/:id/video", "durationSeconds": 220 },
  "source": {
    "bookId": "…", "bookTitle": "Bustani ya Eden",
    "pageStart": 12, "pageEnd": 18,
    "pdfUrl": "/api/books/:bookId/pdf"
  }
}
```

New `GET /api/books/:bookId/pdf` — 302 to a signed, short-TTL Supabase URL,
mirroring the existing `/api/lessons/:lessonId/video` pattern
(`server/api.js:70`). **Unlike that endpoint, this one must require a session**
and must respect the paywall — see §5.4.

---

## 4. Step-by-step implementation guide

Each phase is independently shippable and independently verifiable.

| Phase | Work | Depends on | Rough size |
|---|---|---|---|
| **0** | Community PII fix (Phase 1 of the other spec) | — | XS |
| **1** | Reconnect CMS to structured model (§2.1 Option A) | — | M |
| **2** | Schema additions (§1.1, §1.2) + backfill `is_primary` | 1 | S |
| **3** | Admin books API + signed upload (§2.2) | 2 | M |
| **4** | Admin CMS mobile UI: Vitabu tab, lesson↔book linking (§2.3) | 3 | M |
| **5** | Catalog API exposes `source` + `video` blocks (§3.3) | 2 | S |
| **6** | `LessonVideoPlayer` — inline video | 5 | M |
| **7** | `SourceButton` + `BookViewerScreen` — in-app PDF | 5 | M |
| **8** | Server-driven pricing (§1.4) | — | S |
| **9** | Content backfill: link every lesson to a primary source | 4 | M |

**Suggested first cut:** 0 → 1 → 2 → 5 → 7. That delivers the headline feature
(Chanzo → in-app PDF) on correct foundations, before the CMS UI work. Phase 6
(inline video) can follow, since video already works via external launch.

Each phase must report: actual command output for its validation, files changed,
and deviations. Do not advance on unverified work.

---

## 5. Potential pitfalls

### 5.1 Mobile data — the dominant constraint

Rural Tanzanian users on metered data. A 20 MB PDF is a real cost.

- **Never auto-download a PDF.** The Chanzo button opens a streaming viewer; the
  first paint should be the target page only.
- **Range requests are essential.** Supabase storage signed URLs support HTTP
  range. Confirm the chosen PDF package issues range requests rather than
  fetching the whole file — **verify this with a network capture before
  committing to the package.** This is the single highest-risk assumption in
  the plan.
- **Show size before commitment:** "Kitabu kizima: 18 MB" on the download option.
- **Cache aggressively.** Once fetched, pages stay on disk.
- **Consider per-chapter PDF extraction** at ingestion time if range requests
  underperform: pre-split each `source_segment` into its own small PDF. More
  storage, far less transfer. Keep as the fallback plan.

### 5.2 Video

- No autoplay, ever. Show duration and a poster frame; the user chooses.
- Cap at the stated 1–5 min. Enforce in the CMS with a warning above ~5 min.
- Signed URL TTL must exceed the longest plausible watch time, or playback dies
  mid-stream on a slow connection. Check the current TTL in the video signing
  config (commit `db5dadc`).

### 5.3 Low-end Android

Test on a 2 GB RAM device, not just an emulator. PDF rendering is memory-hungry;
cap rendering resolution and dispose page controllers aggressively. `pdfrx` on a
1,000-page book will OOM if pages are not recycled.

### 5.4 Paywall leak — pre-existing, gets worse here

`GET /api/lessons/:lessonId/video` (`server/api.js:70`) has **no auth and no
subscription check** — anyone with a lesson ID gets the video. If we add
`/api/books/:id/pdf` on the same pattern, we hand out entire books.

**Decide the paywall rule before Phase 7 ships.** My recommendation: require a
session on both, and gate full-book access on subscription while leaving the
lesson's own page range open.

### 5.5 Content ops

- The CMS reconnection (Phase 1) is a behaviour change on live content. Rehearse
  on staging.
- `is_primary` backfill must be deterministic — pick the earliest linked segment
  and let an admin override.
- 33 published lessons currently have no primary source link. Phase 9 is real
  work, not a migration script afterthought.

---

## 6. Content audit — "are all books visible?"

The QA report at `.gstack/qa-reports/qa-report-course-source-inventory-2026-07-16.md`
(dated 2026-07-16) found **12 PDF sources, 11 published and visible**, each with
3 lessons and 3 grounding facts.

**That report is now stale in at least one respect.** It lists
`KILIMO CHA NYANYA KWA MTAJI KIDOGO` (tomato) as the missing one, but commit
`e5e2679 feat: publish grounded tomato course` landed *after* it, and nyanya
appears in `server/scripts/reviewed-curriculum-pilots.js`. Static evidence says
that gap is closed.

**I cannot confirm live state** — I have not queried the production database, per
your earlier instruction. To close this properly:

```bash
npm run smoke:supabase:live
```
then re-run the inventory that produced the QA report and diff against it.

Known outstanding items from that report, none of which the tomato commit
addresses:

1. **`RICE-SEED-001` (rice seed video) is still not learner-ready** — draft
   course, `delivery_type` incorrectly `text`, 0 published lessons, 0 video
   resources, 0 grounding facts, transcript object missing. This is your only
   video-first course and it does not reach learners.
2. **`MAGONJWA YA KUKU` PDF object is missing from storage** at
   `pending/pdf/magonjwa-ya-kuku-tiba-zake-za-asili-7a4d01d7f718.pdf`. Lessons
   work from extracted segments, but **the Chanzo button will 404 for this
   course** — directly relevant to this plan.
3. **Only narrow 3-lesson pilots are published per book.** The full NotebookLM
   curricula remain `needs_review`. The report is explicit that high-risk
   pesticide/dosage/diagnosis material should not be bulk-published without
   subject-matter approval.

Point 3 is the important one for expectations: "all curriculum for all books" is
**deliberately not published**, and that was a safety decision, not an oversight.
Publishing it is a content-review project with an agronomist in the loop, not an
engineering task. Tell me if you want that scoped separately.

---

## 7. Open questions — I need your input

### 7.1 The prices are missing

Your message ends: *"And these are the prices we want to have in app."* — and
then nothing follows. Nothing was attached or pasted.

Current hardcoded values (`demo_app_repository.dart:227-246`):

| Plan | Current price |
|---|---|
| Wiki 1 | TZS 3,000 |
| Mwezi 1 (recommended) | TZS 10,000 |
| Kozi Maalum | TZS 50,000 |

Send the new prices and I will fold them in. Also tell me whether you want them
server-driven (§1.4) — strongly recommended if they will change again, since
today a price change means a new APK for every user.

### 7.2 Admin CMS: Flutter app or mobile web?

You wrote "optimized for **mobile browsers**/screens", but the admin dashboard
today is **Flutter, inside the APK** — not a browser. The legacy Vite web build
has no admin UI, no auth layer, and no session handling.

| | Flutter (extend existing) | New mobile web admin |
|---|---|---|
| Reuses 1,066 lines of working UI | yes | no |
| New auth surface to build | no | **yes** |
| CMS change requires APK rebuild | **yes** | no |
| PDF upload | file picker package | native `<input type=file>` |
| Non-technical staff onboarding | sideload APK | send a link |

**Recommendation: extend the Flutter admin.** It already runs on their phone, it
already satisfies "mobile screens", and a web admin means building authentication
from scratch on a surface that currently has none.

**Revisit if:** more than ~3 people will do content ops, or they cannot sideload.
The APK-rebuild-per-CMS-change cost is real and will bite during heavy content
build-out.

This decision changes phases 3, 4 and much of §2, so I need it before
implementation starts.

### 7.3 Paywall rule for full-book PDF access

See §5.4. Free, subscriber-only, or lesson-page-range-free-with-full-book-paid?

---

## Approval checklist

- [ ] §0.1 — community PII fix goes in before the next APK
- [ ] §0.2 — confirmed the CMS/catalog disconnect; Option A approved
- [ ] §1 — schema additions approved
- [ ] §7.1 — prices supplied; server-driven or hardcoded
- [ ] §7.2 — Flutter vs web admin decided
- [ ] §7.3 — paywall rule for PDFs decided
- [ ] §6 — live inventory re-run; decision on rice-seed course and missing kuku PDF
- [ ] §4 — phase order approved (suggest 0 → 1 → 2 → 5 → 7 first)
