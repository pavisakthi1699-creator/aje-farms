# AJE Farms

Swahili-language farming education app for Tanzania. Native Flutter Android
client (`aje_farms_mobile/`) against a Node/Express API (`server/`), backed by
Postgres/Supabase.

## Architecture notes that are easy to get wrong

- **The Android client is native Flutter.** The unauthenticated Vite/React
  prototype was removed; the API does not serve a customer web client. Release
  builds enforce the native runtime — see `server/android-release.js`.
- **There are two content models.** `server/store/schema.sql` defines a simple
  `content_courses`/`content_documents` model used by the JSON and Postgres
  stores. `supabase/migrations/` defines the rich
  `source_documents` → `courses` → `course_modules` → `lessons` model used by
  the ingestion pipeline. When `AJE_STORE=supabase`, `approvedContentCourses()`
  reads the **structured** model, not `content_courses`.
- **The admin dashboard lives only in Flutter**
  (`lib/src/features/admin/admin_dashboard_screen.dart`), reached from Profile
  when `session.isAdmin`.
- **Identity is email/password via Supabase Auth, not phone/OTP.** The Flutter
  client calls the Supabase SDK directly for sign-up/sign-in/sign-out/password
  reset (`BackendAuthService`); the AJE API only verifies the resulting
  Supabase JWT (`server/auth.js`, `requireAuthSession`) and owns
  role/accountStatus/profile. `phone_number` is now optional contact info on
  `users`, never the identity key. In `NODE_ENV=development` only, a
  `POST /api/auth/dev-session` bypass exists for local/test sign-in without a
  real Supabase project.
- **Admin access has two sources:** a stored `users.role = 'admin'`, or the
  `AJE_ADMIN_EMAILS` env allowlist. See `server/auth.js`. There is no API
  endpoint that writes `users.role`.
- **Paid access is staff-approved, not self-service.** There is no in-app
  checkout. Staff record a cash/bank-transfer payment against a server-owned
  plan id (`plans` table) from the admin dashboard's "Malipo" tab, then
  approve it — only approval creates an `entitlements` row, which is the only
  thing `hasActiveAccess`/`accountStatus` gate on. Every approval/reversal
  writes an immutable `audit_events` row. See `server/store/schema.sql` and
  `POST /api/admin/payments*`. The Flutter paywall screen (`PaywallScreen`)
  shows status and a refresh button only — never payment instructions or bank
  details, per Google Play policy for digital access.
- **Community `author` is a public display label, never an internal id.**
  `/api/community/posts` is unauthenticated. Authorship is derived server-side
  from the session into the private `author_user_id` column. See
  `communityDisplayName` in `server/store/utils.js`.
- **Subscription plans come from the server** (`plans` table via
  `GET /api/admin/plans` / `catalogSnapshot().plans`), not the Flutter
  constants in `demo_app_repository.dart` — those are only an offline seed.
  Price changes ship without an APK rebuild.
- **`AJE_API_BASE_URL` and Supabase project config are compile-time
  constants** (`--dart-define`; see `lib/main.dart` for the Supabase
  URL/publishable-key defaults). Pointing the app at a different backend or
  Supabase project requires a rebuild.

- **Interface language is Kiswahili-first with an English option.** UI text
  is written in Kiswahili and translated through one dictionary:
  `AppTranslations` (`lib/src/l10n/app_translations.dart`) plus the extra
  entries in `strings_en.dart`. Screens call either `'…'.tr(context)` or the
  context-free `tr('…')` (`app_strings.dart`, exact matches only, supports
  `{placeholder}` args). Add an English entry whenever you wrap a new string —
  `test/l10n_test.dart` fails otherwise. Don't wrap values that are compared,
  stored or sent to the API (topic names, filter sentinels like `'Zote'`,
  audit reasons); translate them where they are displayed. The choice lives in
  `AppSessionState.languagePreference`, survives sign-out, and is sent to
  `/api/mwalimu-chat` as `language` so Gemini answers in English.

## Commands

```bash
npm run dev                 # API server (JSON store, NODE_ENV=development)
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

- Auth verification always calls Supabase (`SUPABASE_URL` /
  `SUPABASE_SERVICE_ROLE_KEY` must be set), regardless of `AJE_STORE` — the
  Postgres/JSON store choice is independent of where identity is verified.
- The `POST /api/auth/dev-session` bypass is gated on `NODE_ENV=development`
  or `AJE_ENABLE_DEBUG_OTP=true`; release preflight blocks the latter.
- Video and PDF endpoints require a session. External viewers cannot send an
  `Authorization` header, so clients resolve `/api/lessons/:id/video-url` over
  an authenticated call and then open the returned URL.
- Supabase Auth's Redirect URLs allowlist (dashboard → Authentication → URL
  Configuration) must include `ajefarms://login-callback`, or password-reset
  links silently fall back to the default Site URL instead of deep-linking
  into the app.

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
