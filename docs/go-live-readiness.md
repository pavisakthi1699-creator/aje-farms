# AJE Farms Go-Live Readiness

Last verified: 2026-07-14.

This checklist tracks the remaining work before a production Android release.
Payment provider integration is intentionally deferred to the final slice.

## Verified Locally

- React production build passes: `npm run build`
- Root TypeScript check passes: `npm run lint`
- Server contract tests pass: `npm run test:server`
- Flutter analyzer, tests, goldens, diff hygiene, and server contracts pass:
  `cd aje_farms_mobile && bash scripts/frontend_quality_gate.sh`
- Live Supabase non-destructive smoke passes:
  `AJE_STORE=supabase npm run smoke:supabase:live`
- `RICE-SEED-001` import validation passes as a draft course:
  `npm run validate:course -- --course RICE-SEED-001`
- Server-side FCM push dispatch is implemented behind `AJE_PUSH_PROVIDER=fcm`.
- Flutter notification services can register a device token with the backend.

## Required Before Release Candidate

1. Configure Android signing.
   - Create `aje_farms_mobile/android/key.properties` from
     `aje_farms_mobile/android/key.properties.example`.
   - Store the referenced keystore outside git.
   - Keep `key.properties`, `*.keystore`, and `*.jks` untracked.

2. Configure production backend secrets.
   - `NODE_ENV=production`
   - `APP_URL=https://<deployed-api-host>`
   - `AJE_STORE=supabase`
   - `SUPABASE_DATABASE_URL=<managed Supabase Postgres URL>`
   - `AJE_OTP_PEPPER=<unique secret, 32+ chars>`
   - `AJE_ENABLE_DEBUG_OTP=false`
   - `AJE_ANDROID_API_BASE_URL=https://<deployed-api-host>`
   - `AJE_WHATSAPP_EXPERT_PHONE=<digits only, country code included>`
   - `AJE_ADMIN_PHONE_NUMBERS=<comma-separated admin phone numbers>`

3. Configure non-payment providers.
   - SMS OTP: set `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and
     `TWILIO_FROM_NUMBER`.
   - Gemini AI: set `GEMINI_API_KEY`, or accept the knowledge-base fallback.
   - Push notifications: set `AJE_PUSH_PROVIDER=fcm` and configure either
     `FCM_SERVICE_ACCOUNT_JSON` or `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, and
     `FCM_PRIVATE_KEY`.

4. Finalize learner-visible content.
   - Confirm which courses should appear in the launch catalog.
   - Review any structured curriculum rows with `needs_review`.
   - Publish approved structured curriculum only after source-link validation.

5. Run release checks with production-shaped values.

```sh
NODE_ENV=production \
APP_URL=https://api.your-domain.example \
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres \
AJE_OTP_PEPPER=<32-plus-character-secret> \
AJE_ENABLE_DEBUG_OTP=false \
AJE_ANDROID_API_BASE_URL=https://api.your-domain.example \
AJE_WHATSAPP_EXPERT_PHONE=255700000000 \
AJE_ADMIN_PHONE_NUMBERS=255700000000 \
TWILIO_ACCOUNT_SID=<twilio-sid> \
TWILIO_AUTH_TOKEN=<twilio-token> \
TWILIO_FROM_NUMBER=<twilio-number> \
GEMINI_API_KEY=<gemini-key> \
AJE_PUSH_PROVIDER=fcm \
FCM_PROJECT_ID=<firebase-project-id> \
FCM_CLIENT_EMAIL=<firebase-service-account-email> \
FCM_PRIVATE_KEY=<firebase-private-key> \
npm run preflight:release
```

Replace `api.your-domain.example` with the deployed API hostname; preflight
rejects reserved example domains.

6. Build and validate the signed native Android artifacts.

```sh
npm run release:android
```

This command must produce the native Flutter package
`com.ajefarms.mobile`. It builds an installable release APK, validates its
package, activity, Flutter runtime, and Flutter assets, and then builds the
Play Store app bundle. Website-to-APK converters are not part of the release
process.

Generated artifacts:

- `aje_farms_mobile/build/app/outputs/flutter-apk/app-release.apk`
- `aje_farms_mobile/build/app/outputs/bundle/release/app-release.aab`

## Deferred Final Payment Slice

- Replace the development payment adapter with the selected mobile money
  provider.
- Validate webhook signatures with provider credentials.
- Confirm paid, pending, failed, retry, and subscription restore flows against
  provider sandbox.

## Remaining Push Client Slice

- Add Firebase config files for the Android app.
- Add Firebase Messaging to the Android app and request runtime notification
  permission where required.
- Retrieve the Android device FCM token and register it through the existing
  notification service.
- Smoke test background and foreground notification receipt on a real device.
