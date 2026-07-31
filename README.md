<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://ai.google.dev/static/site-assets/images/share-ais-513315318.png" />
</div>

# AJE Farms API and Native Android App

The customer product is the native Flutter Android app in `aje_farms_mobile/`.
This repository's Node service is its API; it does not host a web client.

## Run Locally

**Prerequisites:** Node.js

1. Install dependencies: `npm install`
2. Set the required backend variables in `.env`.
3. Run the API: `npm run dev`

Gemini calls are handled by the Express API at `/api/mwalimu-chat`; no API key
is shipped in an application bundle.

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
remaining non-payment launch work: Android signing, production secrets, SMS OTP,
Gemini, push notifications, content publishing, and release verification.
