# AJE Farms

Swahili-language farming education app for Tanzania. Native Flutter Android
client (`aje_farms_mobile/`) against a Node/Express API (`server/`), backed by
Postgres/Supabase.

## Architecture notes that are easy to get wrong

- **The Android client is native Flutter.** The root Vite/React build (`src/`)
  is a legacy demo shell with no auth and no admin UI. It is not the Android
  runtime. Release builds enforce this — see `server/android-release.js`.
- **There are two content models.** `server/store/schema.sql` defines a simple
  `content_courses`/`content_documents` model used by the JSON and Postgres
  stores. `supabase/migrations/` defines the rich
  `source_documents` → `courses` → `course_modules` → `lessons` model used by
  the ingestion pipeline. When `AJE_STORE=supabase`, `approvedContentCourses()`
  reads the **structured** model, not `content_courses`.
- **The admin dashboard lives only in Flutter**
  (`lib/src/features/admin/admin_dashboard_screen.dart`), reached from Profile
  when `session.isAdmin`.
- **Admin access has two sources:** a stored `users.role = 'admin'`, or the
  `AJE_ADMIN_PHONE_NUMBERS` env allowlist. See `server/auth.js`. There is no
  API endpoint that writes `users.role`.
- **Community `author` is a public display label, never a phone number.**
  `/api/community/posts` is unauthenticated. Authorship is derived server-side
  from the session into the private `author_phone` column. See
  `communityDisplayName` in `server/store/utils.js`.
- **Subscription plans come from the server** (`server/catalog.js`), not the
  Flutter constants in `demo_app_repository.dart` — those are only an offline
  seed. Price changes ship without an APK rebuild.
- **`AJE_API_BASE_URL` is a compile-time constant** (`--dart-define`). Pointing
  the app at a different backend requires a rebuild.

## Commands

```bash
npm run dev                 # API + Vite dev server (JSON store, NODE_ENV=development)
npm run test:server         # node --test server/tests/*.test.js
npm run db:migrate          # apply server/store/schema.sql
npm run smoke:supabase:live # non-destructive Supabase readiness check
```

```bash
cd aje_farms_mobile && flutter analyze && flutter test
```

Local device build against a local backend (debug allows cleartext; release
does not):

```bash
cd aje_farms_mobile && flutter run --debug --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000
```

## Gotchas

- `.env` holds live Africa's Talking credentials. Any local run that exercises
  OTP must set `AJE_SMS_PROVIDER=development`, or it sends **real SMS**.
- OTP requests are rate limited to one per phone number per 60s.
- `debugOtp` is only returned when `NODE_ENV=development` or
  `AJE_ENABLE_DEBUG_OTP=true`, and only by the development SMS sender.
- Video and PDF endpoints require a session. External viewers cannot send an
  `Authorization` header, so clients resolve `/api/lessons/:id/video-url` over
  an authenticated call and then open the returned URL.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
