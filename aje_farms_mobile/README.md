# Chuo Kikuu Cha Mtaani Mobile

Native Flutter Android app for the Chuo Kikuu Cha Mtaani learner app.

This app currently runs as a connected Flutter product:

- Onboarding, guest mode, Supabase email/password identity, and staff approval
- Learner dashboard with persisted lesson progress
- Course catalog, course detail, saved documents, and completion tracking
- Unified search across courses, lessons, problem categories, documents, and
  eligible community posts, with account-safe cached fallback
- Assessment quiz and field assignment with saved scores
- Mwalimu AI knowledge assistant flow
- Community posts, replies, reporting, and filters backed by the API
- Staff-approved access and paywall status backed by the API
- Notifications driven by current app state
- Profile, settings, saved documents, and sign-out

## Setup

Run from the Flutter project directory:

```sh
cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
flutter pub get
flutter run --dart-define=AJE_API_BASE_URL=http://localhost:3000
```

This project includes Android and web platform files. To run immediately on
Chrome:

```sh
flutter run -d chrome --dart-define=AJE_API_BASE_URL=http://localhost:3000
```

Run the API from the repo root before launching the connected app:

```sh
cd /Users/frankmchaina/Downloads/aje-farms
npm run dev

cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
flutter run -d chrome --dart-define=AJE_API_BASE_URL=http://localhost:3000
```

To run on Android, use an Android emulator or connected Android device:

```sh
flutter devices
flutter run -d <device_id> --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000
```

Connected Android smoke:

```sh
cd /Users/frankmchaina/Downloads/aje-farms
npm run dev

cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
flutter test integration_test/connected_app_smoke_test.dart \
  -d emulator-5554 \
  --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000
```

Connected Android search journey (requires a disposable, active Supabase
learner account):

```sh
flutter test integration_test/connected_search_e2e_test.dart \
  -d emulator-5554 \
  --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_CLIENT_SAFE_KEY \
  --dart-define=AJE_E2E_STANDARD_EMAIL=test-learner@example.com \
  --dart-define=AJE_E2E_STANDARD_PASSWORD=YOUR_TEST_LEARNER_PASSWORD
```

The app has one connected runtime path. Local/demo services are only used when
tests inject `AppDependencies.demo()`.

macOS desktop is not generated yet. Add it only if you want this repo to support
that platform too.

## Frontend Quality Gate

Run the repeatable frontend gate before merging or cutting a release candidate:

```sh
cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
bash scripts/frontend_quality_gate.sh
```

This checks analyzer cleanliness, all Flutter tests, visual regression goldens,
asset governance, diff whitespace, and backend contract tests.

Golden baselines live in `test/goldens/`. Regenerate them only after intentional
design review:

```sh
flutter test test/visual_regression_test.dart --update-goldens
```

## Android Release Signing

Debug APKs build without extra setup. For release builds, create
`android/key.properties` locally. Start from `android/key.properties.example`
and replace every placeholder:

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=...
keyAlias=...
keyPassword=...
```

`android/key.properties` is ignored by git.

Release builds must pass the real production backend and expert support
number. The native Flutter application is the only supported customer client.

```sh
npm run release:android
```

The release command builds and signs both Android artifacts:

- `aje_farms_mobile/build/app/outputs/flutter-apk/app-release.apk`
- `aje_farms_mobile/build/app/outputs/bundle/release/app-release.aab`

Before the app bundle is built, the generated APK is checked for the
`com.ajefarms.mobile` package, Flutter runtime libraries, Flutter assets, and
the Flutter `MainActivity`. Median/GoNative wrapper assets cause the release to
fail.

You can validate an APK independently:

```sh
npm run validate:android-apk -- /absolute/path/to/app-release.apk
```

## Backend Readiness

The API exposes a non-secret readiness endpoint:

```sh
curl http://localhost:3000/api/health
```

Deployments can use the lightweight liveness endpoint to confirm the API
process is accepting requests without requiring every optional provider to be
production-ready:

```sh
curl http://localhost:3000/api/health/live
# {"status":"ok"}
```

Postgres smoke can run with Docker or any reachable managed Postgres:

```sh
# Docker local Postgres, when Docker Desktop/Colima is installed
npm run smoke:postgres

# Managed/external Postgres
DATABASE_URL=postgresql://user:pass@host:5432/db npm run smoke:postgres
```

Dedicated Supabase backend:

```sh
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.<project-ref>.supabase.co:5432/postgres \
npm run smoke:supabase
```

Non-destructive live readiness check:

```sh
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.<project-ref>.supabase.co:5432/postgres \
npm run smoke:supabase:live
```

Run the backend locally against live Supabase:

```sh
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.<project-ref>.supabase.co:5432/postgres \
npm run dev:supabase
```

Run the connected Flutter smoke against that backend:

```sh
flutter test integration_test/connected_app_smoke_test.dart \
  --dart-define=AJE_API_BASE_URL=http://127.0.0.1:3000
```

Before building a release candidate, run the release preflight from the repo
root. It checks production backend persistence, release URL wiring, disabled
debug OTP, Android signing config, and the WhatsApp support number:

```sh
NODE_ENV=production \
APP_URL=https://api.your-domain.example \
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres \
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=replace-with-server-only-key \
SUPABASE_PUBLISHABLE_KEY=replace-with-client-safe-key \
AJE_ENABLE_DEBUG_OTP=false \
AJE_ENABLE_LEGACY_DEV_PAYMENTS=false \
AJE_ANDROID_API_BASE_URL=https://api.your-domain.example \
AJE_WHATSAPP_EXPERT_PHONE=255700000000 \
AJE_ADMIN_EMAILS=admin@your-domain.example \
AJE_PRIVACY_POLICY_URL=https://api.your-domain.example/privacy \
AJE_ACCOUNT_DELETION_URL=https://api.your-domain.example/delete-account \
AJE_PRIVACY_CONTACT_EMAIL=privacy@your-domain.example \
AJE_ANDROID_APP_SIGNING_SHA256=YOUR_PLAY_APP_SIGNING_SHA256 \
AJE_PLAY_DISTRIBUTION_MODE=consumption_only \
AJE_PUSH_PROVIDER=development \
npm run preflight:release
```

Replace `api.your-domain.example` with the deployed API hostname; preflight
rejects reserved example domains.

Missing Gemini and production push configuration is reported by the preflight.
`npm run release:android`
runs the same preflight, builds and validates the signed native Flutter APK,
and then builds the signed Android App Bundle.

For the current go-live checklist, including signing, production secrets,
Gemini, push, search validation, and content publishing, see
`../docs/go-live-readiness.md`.

## Next Integrations

- Cloud storage for videos, PDFs, and images
- Firebase Messaging delivery in the Android client
- Production search relevance and latency monitoring
- Analytics and crash reporting
