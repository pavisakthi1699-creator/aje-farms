

# Chuo Kikuu Cha Mtaani API and Native Android App

The customer product is the native Flutter Android app in `aje_farms_mobile/`.
This repository's Node service is its API; it does not host a web client.

## Run Locally

**Prerequisites:** Node.js

1. Install dependencies: `npm install`
2. Set the required backend variables in `.env`.
3. Run the API: `npm run dev`

Gemini calls are handled by the Express API at `/api/mwalimu-chat`; no API key
is shipped in an application bundle.

## Learner Search

Signed-in learners can search courses, lessons, problem categories, documents,
and eligible community posts from the main Flutter tabs. The app uses the
authenticated `POST /api/search` endpoint when connected and falls back to the
current account's cached, viewer-safe content when the service is unavailable.

Run the connected Android search journey against a local backend with a
disposable, active Supabase learner account:

```sh
cd aje_farms_mobile
flutter test integration_test/connected_search_e2e_test.dart \
  -d emulator-5554 \
  --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_CLIENT_SAFE_KEY \
  --dart-define=AJE_E2E_STANDARD_EMAIL=test-learner@example.com \
  --dart-define=AJE_E2E_STANDARD_PASSWORD=YOUR_TEST_LEARNER_PASSWORD
```

See the [search design](docs/unified-learner-search-design-2026-08-15.md) and
[offline index test plan](docs/offline-search-index-test-plan-2026-08-16.md)
for scope, authorization, ranking, fallback, and validation details.

## Dedicated Supabase Backend

AJE Farms has its own Supabase project/database:

- Project: `AJE Farms`
- Project ref: `iufjpfyozeuulzjscdoq`
- Region: `eu-west-1`
- API URL: `https://iufjpfyozeuulzjscdoq.supabase.co`

The Express API keeps the same mobile contract and can run against Supabase by
using the Postgres connection string from that project:

```sh
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.<project-ref>.supabase.co:5432/postgres \
npm run smoke:supabase
```

For a non-destructive live readiness check, use:

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

Then run the connected Flutter smoke against that backend:

```sh
cd aje_farms_mobile
flutter test integration_test/connected_app_smoke_test.dart \
  --dart-define=AJE_API_BASE_URL=http://127.0.0.1:3000
```

Use `SUPABASE_DATABASE_URL` as a secret in deployed environments. Do not commit
database credentials.

## Supabase Content Ingestion

The production content-ingestion foundation lives in `supabase/`. It includes
migrations, private PDF storage policies, Edge Functions for NotebookLM/Gemini
draft ingestion, SQL validation/publish guards, tests, TypeScript types, and a
sample import file. See `supabase/README.md` for setup, secrets, import, test,
and deployment instructions.

## Go-Live Readiness

The release checklist lives in `docs/go-live-readiness.md`. It tracks the
remaining launch work: Android signing, production Supabase and policy
configuration, Gemini, push notifications, content publishing, search
validation, and release verification.
