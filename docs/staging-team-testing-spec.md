# Staging Team-Testing Environment — Implementation Spec

**Goal:** let the AJE Farms team log in on their own Android devices and exercise
admin/content-moderation features, without waiting for Africa's Talking Tanzania
Sender ID approval.

**Strategy:** stand up a dedicated Railway staging backend running in a
non-production `NODE_ENV` where OTPs are returned in the API response instead of
being sent by SMS, grant admin via the existing `AJE_ADMIN_PHONE_NUMBERS`
allowlist, and distribute a profile-mode APK pointed at it.

**Non-goals:** changing production, changing the OTP verification algorithm,
adding a role-management UI, or replacing the SMS provider.

---

## Guiding constraints (do not violate)

1. **Never modify the production Railway service or the production Supabase
   database.** Staging is an additive, separate service with its own database.
2. **The release build path must remain incapable of exposing OTPs.**
   `npm run release:android` must continue to fail preflight if debug-OTP
   settings are present. Phase 2 adds a test that proves this.
3. **Do not weaken `verify-otp`.** The OTP is still randomly generated, hashed
   with a pepper, and compared server-side. We are changing *disclosure*, not
   *verification*.
4. `AJE_OTP_PEPPER` on staging must be a distinct secret from production, never
   the built-in fallback in `server/store/utils.js:133`.

---

## Background: why this specific configuration

The relevant code path is `DevelopmentOtpSender` in `server/sms.js:113-133`:

```js
async sendOtp({ phoneNumber, otp }) {
  if (this.env.NODE_ENV === 'production') {
    throw new Error('SMS provider is not configured.');
  }
  console.log(`[AJE OTP] ${phoneNumber}: ${otp}`);
  return { provider: 'development',
    debugOtp: this.env.NODE_ENV === 'development' ||
              this.env.AJE_ENABLE_DEBUG_OTP === 'true' ? otp : undefined };
}
```

Three conditions must all hold for a team member to receive an OTP without SMS:

| Condition | Mechanism | Setting |
|---|---|---|
| The development sender is selected at all | `configuredSmsProvider` (`server/sms.js:26-30`) returns `development` only when `AJE_SMS_PROVIDER` is unset/`development` **and** no `AFRICASTALKING_*` credentials are present | Leave all AT vars unset |
| The sender does not throw | `NODE_ENV !== 'production'` | `NODE_ENV=staging` |
| `debugOtp` is populated | `NODE_ENV === 'development'` **or** `AJE_ENABLE_DEBUG_OTP === 'true'` | `AJE_ENABLE_DEBUG_OTP=true` |

`NODE_ENV=staging` is chosen over `development` deliberately: `server/index.js:13`
only defaults (`??=`) so an explicit value survives, and `staging` avoids
accidentally matching other `=== 'development'` branches while keeping the
debug-OTP intent explicit and greppable via the flag.

Admin access comes from `userHasAdminAccess` (`server/auth.js:14`), which grants
admin when `user.role === 'admin'` **or** the phone number is in
`AJE_ADMIN_PHONE_NUMBERS`. The allowlist requires no database write, which
matters because **no API endpoint anywhere writes `users.role`** — `/api/admin/users`
(`server/api.js:159`) is read-only.

---

## Phase 0 — Baseline

**Objective:** establish a known-green starting point so later failures are
attributable.

**Changes:** none.

**Steps:**
1. Confirm a clean working tree, or note pre-existing modifications.
2. Run the existing suites.

**Validation:**
```bash
npm run test:server
```
```bash
cd aje_farms_mobile && flutter analyze && flutter test
```

**Acceptance criteria:**
- Both suites pass, or every failure is recorded as pre-existing before any
  change is made in Phase 1.
- Record the current `git rev-parse HEAD` in the phase report.

**Rollback:** n/a.

---

## Phase 1 — Shared internal-build flag + OTP visibility in profile builds

**Objective:** make the development OTP visible on-screen in profile (internal)
builds, so testers can self-serve their code, while guaranteeing release builds
never show it.

**Background:** `auth_screen.dart:184` currently gates the OTP hint on
`kDebugMode`, which is `false` in profile builds. The codebase already has the
correct idiom for "internal build" at `profile_screen.dart:7`:

```dart
const _showAdminAccessDiagnostics =
    !kReleaseMode || bool.fromEnvironment('AJE_INTERNAL_BUILD');
```

Reuse that predicate rather than inventing a second one.

### 1.1 Create the shared constant

Create `aje_farms_mobile/lib/src/app/build_flags.dart`:

```dart
import 'package:flutter/foundation.dart';

/// True for debug and profile builds, and for release builds explicitly marked
/// internal with `--dart-define=AJE_INTERNAL_BUILD=true`.
///
/// Gates internal-only affordances (development OTP hint, admin access
/// diagnostics). The release build script never passes AJE_INTERNAL_BUILD, so
/// store builds always evaluate this to false.
const kInternalBuild =
    !kReleaseMode || bool.fromEnvironment('AJE_INTERNAL_BUILD');
```

### 1.2 Use it in the auth screen

In `aje_farms_mobile/lib/src/features/auth/auth_screen.dart`, replace the
`kDebugMode` gate at line ~184:

```dart
// before
if (kDebugMode && _challenge?.debugOtp != null) ...[

// after
if (kInternalBuild && _challenge?.debugOtp != null) ...[
```

Add the import, and remove the now-unused
`import 'package:flutter/foundation.dart';` **only if** `kDebugMode` is not
referenced elsewhere in the file — verify with grep before removing.

### 1.3 Collapse the duplicate predicate in the profile screen

In `aje_farms_mobile/lib/src/features/profile/profile_screen.dart`, delete the
local `_showAdminAccessDiagnostics` constant (line 7) and use `kInternalBuild`
at its two usage sites. This keeps one definition of "internal build".

### 1.4 Tests

Add `aje_farms_mobile/test/auth_screen_debug_otp_test.dart` following the
conventions in the existing `test/` directory (see `widget_test.dart` and
`admin_dashboard_widget_test.dart` for setup patterns):

- Pump `AuthScreen` with `AppDependencies.demo()` (its `LocalAuthService`
  returns a fixed `debugOtp` of `'1234'` — see `local_auth_service.dart:6`).
- Drive the "Tuma OTP" flow.
- Assert `find.textContaining('OTP ya majaribio')` is found — tests run in
  debug mode, where `kInternalBuild` is `true`.

The predicate's release behaviour is a compile-time constant and cannot be
exercised by a widget test; Phase 2 covers that side with a build-script
guardrail instead.

**Validation:**
```bash
cd aje_farms_mobile && flutter analyze && flutter test
```

**Acceptance criteria:**
- `flutter analyze` reports no new issues (in particular, no unused-import
  warning from step 1.2).
- The new test passes.
- `grep -rn "kDebugMode" lib/src/features/auth/auth_screen.dart` returns nothing.
- `grep -rn "_showAdminAccessDiagnostics" lib/` returns nothing.
- `grep -rn "kInternalBuild" lib/` returns the definition plus exactly three
  usages (auth screen ×1, profile screen ×2).

**Rollback:** revert the commit. No runtime or data dependency.

---

## Phase 2 — Release-path guardrail

**Objective:** prove, in CI, that the internal-build flag and debug-OTP settings
cannot reach a store release.

**Background:** `server/scripts/build-android-release.js:36-39` builds its
`--dart-define` list from exactly two variables and never forwards
`AJE_INTERNAL_BUILD`. `server/preflight.js:43` already blocks
`AJE_ENABLE_DEBUG_OTP=true`. Both properties are currently accidental — this
phase makes them asserted.

### 2.1 Extend preflight

In `server/preflight.js`, alongside the existing `AJE_ENABLE_DEBUG_OTP` check,
add:

```js
if (String(env.AJE_INTERNAL_BUILD ?? '').toLowerCase() === 'true') {
  blockers.push('AJE_INTERNAL_BUILD must not be true for release.');
}
```

### 2.2 Tests

In `server/tests/preflight.test.js`, following the existing test style
(`node:test` + `node:assert/strict`), add cases asserting:
- A config that is otherwise release-valid becomes `ok: false` when
  `AJE_INTERNAL_BUILD=true`, with the exact blocker string present.
- The same config with `AJE_ENABLE_DEBUG_OTP=true` is `ok: false` (regression
  lock on the existing rule).

Add `server/tests/build-android-release.test.js` asserting that the dart-define
list produced for a release build contains no `AJE_INTERNAL_BUILD` entry. This
requires extracting the dart-define construction from
`build-android-release.js` into an exported pure function, e.g.:

```js
export function releaseDartDefines(env) {
  return [
    `--dart-define=AJE_API_BASE_URL=${env.AJE_ANDROID_API_BASE_URL}`,
    `--dart-define=AJE_WHATSAPP_EXPERT_PHONE=${env.AJE_WHATSAPP_EXPERT_PHONE}`,
  ];
}
```
Move it to `server/android-release.js` (already the home for release helpers and
already unit-tested) and import it in the script. Keep the script's behaviour
byte-identical.

**Validation:**
```bash
npm run test:server
```

**Acceptance criteria:**
- New tests pass; all pre-existing server tests still pass.
- `npm run release:android` still refuses to run when preflight has blockers
  (do **not** run a full release build to check this — assert via the unit
  tests).

**Rollback:** revert the commit.

---

## Phase 3 — Railway staging service

**Objective:** an always-on staging backend with its own database, admin
allowlist, and SMS-free OTP.

**⚠️ This phase touches infrastructure. Do not reuse the production service,
database, or `AJE_OTP_PEPPER`.**

### 3.1 Provision

1. Create a **new Railway service** from the same repo. Deploy from `main`, or
   from a dedicated `staging` branch if the team prefers to decouple.
   `railway.json` is picked up as-is: start `npm run start`, healthcheck
   `/api/health/live`.
2. Add a **Railway Postgres plugin** to that service. It injects `DATABASE_URL`
   automatically.

### 3.2 Environment variables

| Variable | Value | Why |
|---|---|---|
| `NODE_ENV` | `staging` | Non-production, so `DevelopmentOtpSender` does not throw (`sms.js:119`) |
| `AJE_ENABLE_DEBUG_OTP` | `true` | Populates `debugOtp` in the response (`sms.js:127`) |
| `AJE_STORE` | `postgres` | Real persistence; the default `json` store loses data on redeploy |
| `DATABASE_URL` | *(injected by Railway Postgres)* | `resolveStoreConfig`, `server/store/index.js:35-42` |
| `AJE_OTP_PEPPER` | **new** ≥32-char random secret, distinct from prod | Avoids the public fallback at `store/utils.js:133` |
| `AJE_ADMIN_PHONE_NUMBERS` | comma-separated team numbers | Grants admin with no DB write (`auth.js:3-8`) |
| `APP_URL` | the staging Railway URL | Self-referential links |
| `GEMINI_API` | staging-scoped key, or omit | Omitting falls back to the approved knowledge base |
| `AJE_PUSH_PROVIDER` | `development` | No FCM setup needed |

**Explicitly leave unset:** `AFRICASTALKING_USERNAME`, `AFRICASTALKING_API_KEY`,
`AFRICASTALKING_ENVIRONMENT`, `AFRICASTALKING_SENDER_ID`, `AJE_SMS_PROVIDER`.
Setting any of the first two flips `configuredSmsProvider` to `africas_talking`
and OTPs will go back to failing SMS delivery.

Phone numbers in `AJE_ADMIN_PHONE_NUMBERS` are normalised by
`normalizePhoneNumber` (`server/store/utils.js:124-130`), so `0712345678`,
`712345678`, `+255712345678`, and `255712345678` are all equivalent. Prefer the
`+255…` form for readability.

### 3.3 Migrate

Run once against the staging database (from a shell with staging `DATABASE_URL`
in the environment — Railway's `railway run` or a one-off command):

```bash
npm run db:migrate
```

`server/scripts/migrate.js` applies `server/store/schema.sql` wholesale. The
schema is idempotent (`CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`,
`DROP POLICY IF EXISTS` + `CREATE POLICY`), so re-running is safe.

### 3.4 Validation

Replace `$STAGING` with the Railway URL.

```bash
curl -sS "$STAGING/api/health" | jq
```
Expect HTTP 200, `"status":"ok"`, `"environment":"staging"`,
`checks.store.mode == "postgres"`, `checks.store.ready == true`,
`checks.sms.provider == "development"`.

```bash
curl -sS -X POST "$STAGING/api/auth/request-otp" \
  -H 'Content-Type: application/json' \
  -d '{"phoneNumber":"712345678"}' | jq
```
Expect `challengeId`, and **`debugOtp` present as a 6-digit string**. If
`debugOtp` is `null`/absent, one of the three conditions in the Background table
is unmet — check `NODE_ENV` and that no `AFRICASTALKING_*` var is set.

```bash
curl -sS -o /dev/null -w '%{http_code}\n' "$STAGING/api/admin/users"
```
Expect `401`.

Then verify the full admin path with a number that **is** in the allowlist:
request an OTP, verify it, and use the returned `sessionToken`:

```bash
curl -sS "$STAGING/api/auth/whoami" -H "Authorization: Bearer $TOKEN" | jq
```
Expect `"hasAdminAccess": true`, `"allowlistedAdmin": true`,
`"source": "phone_allowlist"`.

```bash
curl -sS -o /dev/null -w '%{http_code}\n' "$STAGING/api/admin/users" \
  -H "Authorization: Bearer $TOKEN"
```
Expect `200`.

Repeat the last two with a number **not** in the allowlist: expect
`hasAdminAccess: false` and `403`.

**Acceptance criteria:** all seven checks above produce the expected result.
Note that `/api/auth/request-otp` is rate-limited to one request per phone
number per 60s (`api.js:198`) — use distinct numbers rather than retrying.

**Rollback:** delete the Railway service and its Postgres plugin. Nothing in
production references it.

---

## Phase 4 — Staging APK

**Objective:** an installable APK pointed at staging that shows the OTP on
screen.

**Background:** `_apiBaseUrl` is a compile-time constant
(`app_dependencies.dart:137`), so the URL is baked in at build time. Profile
builds are signed with Flutter's debug key — `android/app/build.gradle.kts`
only configures a `release` signing config, and only when `key.properties`
exists — so **no upload keystore is required** for this build.

### 4.1 Build

```bash
cd aje_farms_mobile && flutter build apk --profile \
  --dart-define=AJE_API_BASE_URL=https://<staging>.up.railway.app \
  --dart-define=AJE_WHATSAPP_EXPERT_PHONE=255700000000
```

Output: `build/app/outputs/flutter-apk/app-profile.apk`.

Use the **HTTPS** Railway URL. The release manifest does not set
`usesCleartextTraffic`, and profile builds merge
`android/app/src/profile/AndroidManifest.xml`, which does — but relying on that
is unnecessary and would not survive a later release build. Keep it HTTPS.

### 4.2 Validation

Automated:
```bash
cd aje_farms_mobile && unzip -l build/app/outputs/flutter-apk/app-profile.apk \
  | grep -E 'libapp\.so|libflutter\.so|AssetManifest\.bin'
```
All three must be present — this is the same native-Flutter assertion
`validateAndroidArtifactMetadata` (`server/android-release.js:11`) makes for
release artifacts, confirming it is a real Flutter build and not a WebView
wrapper.

Manual, on a device (do this yourself before distributing — do not delegate
first-run verification to the team):
1. Install the APK and open it.
2. The app must **not** crash on launch. A `StateError` at startup
   (`app_dependencies.dart:80`) means `AJE_API_BASE_URL` was empty or malformed.
3. Tap "Ingia / Jisajili", enter an **allowlisted** number, tap "Tuma OTP".
4. The OTP appears on screen as "OTP ya majaribio: NNNNNN". If it does not,
   Phase 1 did not take effect in this build.
5. Enter it, tap "Endelea". You reach the main shell.
6. Open Profile. "Dashibodi ya Admin" is listed, and the internal
   "Debug: Hali ya Admin" diagnostics card is visible.
7. Open the dashboard. All three tabs load: **Maandishi** (content),
   **Usimamizi** (moderation), **Watumiaji** (users).
8. Approve or revert one course in Maandishi; confirm the status pill changes
   and survives a pull-to-refresh.
9. Log out. Log in with a **non-allowlisted** number. Confirm
   "Dashibodi ya Admin" is absent from Profile.

**Acceptance criteria:** steps 1-9 pass. Step 9 is the security check — do not
skip it.

**Rollback:** discard the APK. No server state changes.

---

## Phase 5 — Distribution and runbook

**Objective:** the team can install and use this without asking how.

### 5.1 Distribute

Upload `app-profile.apk` to the team's Drive or Slack. For a small team this is
lower-friction than a Play Console internal testing track; revisit if the tester
list grows or sideloading becomes a support burden.

### 5.2 Write `docs/staging-team-testing.md`

Cover:
- The staging URL, and an explicit statement that **this is not production and
  contains no real user data**.
- Install steps, including enabling "install unknown apps" for the source app.
- Login: enter your number, read the OTP shown on screen, continue. No SMS is
  sent — this is expected.
- Which numbers have admin (point at the Railway variable, do not list personal
  numbers in the repo).
- That the backend is **shared**: approving or hiding content affects what every
  other tester sees.
- The 60-second per-number OTP rate limit.
- Where to file findings.

**Acceptance criteria:** a team member who has not seen this thread can install,
log in, and reach the admin dashboard using only the doc.

---

## Appendix A — Fallback: promote a user via SQL

Only needed if the allowlist is unsuitable (e.g. testing the `stored_role` code
path specifically). The user row must already exist — it is created on first
successful `verify-otp` (`postgres-store.js:491`).

Run against **staging** only, as the database owner (the `users` table has an
RLS policy denying direct client access, `schema.sql:194`).

```sql
SELECT id, phone_number, role, display_name, created_at
FROM users
WHERE phone_number = '+255712345678';

UPDATE users
   SET role = 'admin', updated_at = NOW()
 WHERE phone_number = '+255712345678';

-- revert
UPDATE users
   SET role = 'learner', updated_at = NOW()
 WHERE phone_number = '+255712345678';
```

`users.role` has no CHECK constraint (`schema.sql:4`), so a typo fails closed
(no admin) but silently. Verify with `/api/auth/whoami`, which reports
`"source": "stored_role"` when the grant came from the database rather than the
allowlist.

---

## Appendix B — Known issues surfaced during investigation

Not blockers for this work; flagged so the agent does not "fix" them mid-phase
or mistake them for regressions it introduced.

1. **Community post/reply `author` is client-supplied** (`api.js:540`, `api.js:562`)
   rather than derived from `req.authPhoneNumber`, which the handler already
   has. An authenticated user can post under any author string, and can
   misdirect moderation notifications (which route on
   `post.author.startsWith('+')`). **This is a real production bug** and
   deserves its own fix, separate from this spec.
2. **`GET /api/lessons/:lessonId/video` is unauthenticated** (`api.js:70`) and
   302-redirects to a signed Supabase URL — no session or subscription check,
   despite the Paywall screen existing. Needs a product decision.
3. **No role-management endpoint exists.** `/api/admin/users` is read-only; the
   Watumiaji tab cannot promote or demote. The allowlist is the intended
   bootstrap (`.env.example:49`).
4. **`userWithEffectiveRole` collapses every non-admin role to `'learner'`**
   (`auth.js:18-24`). The Supabase RLS layer understands `'editor'`
   (`migrations/20260707000100_content_ingestion_foundation.sql:446`) but the
   Express API would report such a user as `learner`. A trap if roles expand.
5. **`AJE_OTP_PEPPER` falls back silently** to a hardcoded string
   (`store/utils.js:133`) when unset. Preflight covers release; a misconfigured
   non-release deploy would hash OTPs with a public constant without warning.
   Phase 3 sets it explicitly for this reason.

---

## Phase completion report format

For each phase, report:

- **Phase / status:** complete | blocked | complete-with-deviations
- **Commands run and their actual output** (not a paraphrase) for every
  validation step
- **Deviations** from this spec and why
- **Files changed**, with a one-line rationale each
- For Phase 3: the staging URL, and confirmation that **no production
  service, variable, or database was touched**

Do not proceed to the next phase until the current one's acceptance criteria
are met, or the deviation is explicitly approved.
