# AJE Farms Mobile

Native Flutter Android app for the AJE Farms learner app.

This app currently runs as a connected Flutter product foundation:

- Onboarding, guest mode, and phone-entry session state
- Learner dashboard with persisted lesson progress
- Course catalog, course detail, saved documents, and completion tracking
- Assessment quiz and field assignment with saved scores
- Mwalimu AI knowledge assistant flow
- Community posts, replies, reporting, and filters backed by the API
- Payment/paywall flow backed by the API
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

Run the React/Express server from the repo root before launching the connected
app:

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

Release builds should pass the production backend and expert support number:

```sh
npm run release:android
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
APP_URL=https://api.example.com \
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.<project-ref>.supabase.co:5432/postgres \
AJE_OTP_PEPPER=replace-with-secret \
AJE_ENABLE_DEBUG_OTP=false \
AJE_ANDROID_API_BASE_URL=https://api.example.com \
AJE_WHATSAPP_EXPERT_PHONE=255700000000 \
AJE_ADMIN_PHONE_NUMBERS=255700000000 \
AJE_PUSH_PROVIDER=development \
npm run preflight:release
```

SMS, Gemini, and payment provider gaps are reported as warnings while those
provider integrations are intentionally deferred. `npm run release:android`
runs the same preflight and then builds the signed Android App Bundle.

For the current go-live checklist, including signing, production secrets, SMS,
Gemini, push, and content publishing, see
`../docs/go-live-readiness.md`.

## Next Integrations

- Cloud storage for videos, PDFs, and images
- Server-side Gemini proxy
- Mobile money payment provider and webhook validation
- Push notifications
- Analytics and crash reporting
