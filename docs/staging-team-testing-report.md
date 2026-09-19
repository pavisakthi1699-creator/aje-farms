# Staging team-testing implementation report

Date: 2026-07-25
Baseline commit: `db5dadc826d632655593063546fbc827af9ba5fe`

## Phase 0 / complete

The working tree already contained unrelated modifications before this work.
They were preserved.

Command:

```text
npm run test:server
```

Baseline output:

```text
tests 62
pass 60
fail 0
skipped 2
```

Command:

```text
cd aje_farms_mobile && flutter analyze && flutter test
```

Baseline output:

```text
No issues found! (ran in 2.8s)
+76: All tests passed!
```

## Phase 1 / complete-with-deviation

Implemented:

- Shared `kInternalBuild` constant.
- Profile-build development OTP hint.
- Shared internal-build gate for admin diagnostics.
- Widget test for the exact `OTP ya majaribio: 1234` hint.

Validation:

```text
flutter analyze
No issues found! (ran in 3.2s)

flutter test
+77: All tests passed!
```

Search checks:

```text
kDebugMode in auth_screen.dart: no matches
_showAdminAccessDiagnostics in lib/: no matches
kInternalBuild: one definition, one auth use, one profile use
```

Deviation: the checked-out profile screen had one local predicate use rather
than the two stated in the spec. No duplicate predicate remains.

Files:

- `aje_farms_mobile/lib/src/app/build_flags.dart` — shared internal-build flag.
- `aje_farms_mobile/lib/src/features/auth/auth_screen.dart` — profile-visible
  OTP hint.
- `aje_farms_mobile/lib/src/features/profile/profile_screen.dart` — shared
  diagnostics gate.
- `aje_farms_mobile/test/auth_screen_debug_otp_test.dart` — regression test.

## Phase 2 / complete

Implemented:

- Release preflight blocker for `AJE_INTERNAL_BUILD=true`.
- Regression coverage for both internal builds and debug OTP disclosure.
- Pure `releaseDartDefines` helper.
- Test proving the release build does not forward `AJE_INTERNAL_BUILD`.

Validation:

```text
npm run test:server
tests 65
pass 63
fail 0
skipped 2
```

Files:

- `server/preflight.js` — release blocker.
- `server/android-release.js` — pure release define construction.
- `server/scripts/build-android-release.js` — consumes the tested helper.
- `server/tests/preflight.test.js` — release guardrail tests.
- `server/tests/build-android-release.test.js` — define allowlist test.

## Phase 3 / complete

Created:

```text
Railway project: aje-farms-staging
Project ID: 7e1c0bfc-5f2a-4bde-b607-1147a42d3168
API service: aje-farms-api-staging
API service ID: 7fbb18a6-ca9a-48ff-b74c-6fe57ce530b1
Postgres service ID: 1dcd3316-b91e-47b0-bb42-304ded8b9bc3
URL: https://aje-farms-api-staging-production.up.railway.app
```

Safe configuration readback:

```json
{
  "NODE_ENV": "staging",
  "AJE_ENABLE_DEBUG_OTP": "true",
  "AJE_STORE": "postgres",
  "AJE_PUSH_PROVIDER": "development",
  "APP_URL": "https://aje-farms-api-staging-production.up.railway.app",
  "databaseConfigured": true,
  "otpPepperLength": 64,
  "adminAllowlistConfigured": true,
  "expertPhoneConfigured": true,
  "forbiddenSmsVarsPresent": []
}
```

Deployment:

```text
Deployment ID: f19bf4a1-417e-43b3-965e-4553177d91c3
Status: SUCCESS
```

Migration:

```text
> react-example@0.0.0 db:migrate
> node server/scripts/migrate.js

AJE Farms database schema applied.
```

The documented `railway run` path could not resolve Railway's private database
hostname from the local machine. Container SSH was unavailable because the
account had no registered SSH key. The successful migration used only the new
staging database's Railway public proxy URL, without displaying the credential.

Health output:

```json
{
  "status": "ok",
  "environment": "staging",
  "checks": {
    "store": {"mode": "postgres", "schema": "public", "ready": true},
    "sms": {"provider": "development", "ready": true},
    "payments": {"provider": "development", "ready": true},
    "notifications": {"provider": "development", "ready": true},
    "ai": {"provider": "knowledge-base", "ready": true}
  }
}
```

Authorization validation:

```json
{
  "unauthenticatedAdminHttp": 401,
  "allowlistedPath": {
    "requestOtpHttp": 200,
    "challengeIdPresent": true,
    "debugOtpIsSixDigits": true,
    "verifyOtpHttp": 200,
    "whoamiHttp": 200,
    "hasAdminAccess": true,
    "allowlistedAdmin": true,
    "source": "phone_allowlist",
    "adminUsersHttp": 200
  },
  "nonAllowlistedPath": {
    "requestOtpHttp": 200,
    "challengeIdPresent": true,
    "debugOtpIsSixDigits": true,
    "verifyOtpHttp": 200,
    "whoamiHttp": 200,
    "hasAdminAccess": false,
    "allowlistedAdmin": false,
    "source": "learner",
    "adminUsersHttp": 403
  }
}
```

Production safety readback:

```json
{
  "project": "aje-farms",
  "environment": "production",
  "service": "aje-farms-api",
  "latestDeploymentId": "cc07dea9-e8be-4e68-87cc-18d165d1ba71",
  "latestDeploymentCreatedAt": "2026-07-23T09:08:47.167Z",
  "latestDeploymentStatus": "SUCCESS",
  "domain": "aje-farms-api-production.up.railway.app"
}
```

No production service, variable, deployment, or database was modified.

## Phase 4 / complete-with-deviations

Build output:

```text
Running Gradle task 'assembleProfile'... 183.9s
Built build/app/outputs/flutter-apk/app-profile.apk (77.4MB)
```

Artifact validation:

```text
lib/arm64-v8a/libapp.so
lib/arm64-v8a/libflutter.so
lib/armeabi-v7a/libapp.so
lib/armeabi-v7a/libflutter.so
lib/x86_64/libapp.so
lib/x86_64/libflutter.so
assets/flutter_assets/AssetManifest.bin
size_bytes=77419159
sha256=a6862b4da9299fba20bfcb9037362bd6717dec5d5a62c3fbe6a862bc860e341e
```

Emulator validation:

```text
Install: Success
Launch activity: com.ajefarms.mobile/.MainActivity
Profile OTP hint: visible as a six-digit "OTP ya majaribio"
Synthetic learner login: success
Learner diagnostics: admin HAPANA, allowlist HAPANA, source learner
Learner dashboard entry: absent
Synthetic admin login: success
Admin diagnostics: admin NDIYO, source stored_role
Dashboard tabs: Maandishi, Usimamizi, Watumiaji all loaded
Course status: Imeidhinishwa -> Rasimu
After pull-to-refresh: Rasimu persisted
Cleanup: course restored to Imeidhinishwa
Cleanup: synthetic stored role restored to learner
```

Evidence:

- `staging-admin-dashboard.png` in the task visualization directory.

Deviations:

- Device validation used the existing Android emulator rather than a physical
  phone.
- The connected API's real allowlist was validated through HTTP. Emulator admin
  UI validation used Appendix A with a synthetic stored-role user, then reverted
  it, so no personal phone number appeared in automation output.
- The APK uses the spec's non-sensitive WhatsApp test value `255700000000`
  because protected tooling blocked embedding the copied phone value.

## Phase 5 / handoff-ready; APK upload intentionally pending

Completed:

- `docs/staging-team-testing.md`
- Google Drive folder:
  <https://drive.google.com/drive/folders/1H2zF2Sp4UndTZWsEzxlTg_vS4FlngEHb>

The Drive folder was rechecked on 2026-07-25 and remains accessible. It is
empty because no APK has been approved for distribution yet.

## Pre-build revalidation / 2026-07-25

Scope: validate every pre-build gate with the team-testing number ending in
`2853`, without creating or uploading a new APK.

Local validation:

```text
npm run test:server
tests 65
pass 63
fail 0
skipped 2

flutter analyze
No issues found! (ran in 5.0s)

flutter test
+77: All tests passed!
```

Staging configuration:

```json
{
  "allowlistCount": 1,
  "providedNumberPresent": true,
  "nodeEnv": "staging",
  "debugOtp": "true",
  "store": "postgres",
  "productionSmsProviderConfigured": false,
  "africasTalkingCredentialsConfigured": false
}
```

Live staging API:

```json
{
  "healthHttp": 200,
  "environment": "staging",
  "storeReady": true,
  "unauthenticatedAdminHttp": 401,
  "providedNumber": {
    "requestOtpHttp": 200,
    "debugOtpIsSixDigits": true,
    "verifyOtpHttp": 200,
    "whoamiHttp": 200,
    "hasAdminAccess": true,
    "allowlistedAdmin": true,
    "source": "phone_allowlist",
    "adminUsersHttp": 200
  },
  "nonAllowlistedNumber": {
    "hasAdminAccess": false,
    "source": "learner",
    "adminUsersHttp": 403
  }
}
```

Production safety readback remained unchanged:

```text
Deployment ID: cc07dea9-e8be-4e68-87cc-18d165d1ba71
Created: 2026-07-23T09:08:47.167Z
Status: SUCCESS
```

Existing APK validation:

```text
Artifact: app-profile.apk
SHA-256: a6862b4da9299fba20bfcb9037362bd6717dec5d5a62c3fbe6a862bc860e341e
Install: Success
Provided-number OTP login: Success
Admin access (server): NDIYO
Allowlist: NDIYO
Source: phone_allowlist
Admin access (app): NDIYO
Maandishi tab: loaded
Usimamizi tab: loaded
Watumiaji tab: loaded
AJE Farms crash/ANR signals: none
```

Evidence:

- `staging-real-number-admin-validation.png` in the task visualization
  directory.

Decision: all pre-build validation gates pass. A new APK may be created next.
Phase 5 distribution remains intentionally pending until that new artifact is
built, verified, and explicitly approved for upload.

The Drive connector requires explicit authorization before uploading the
proprietary APK and its embedded staging URL to that folder. No APK bytes were
uploaded.

Files:

- `docs/staging-team-testing.md` — tester-facing runbook.
- `docs/staging-team-testing-report.md` — implementation and validation record.
