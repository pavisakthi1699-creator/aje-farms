# AJE Farms Go-Live Readiness

Last verified: 2026-08-11.

This checklist tracks the remaining work before a production Android release.
The Google Play build is consumption-only. Learners cannot purchase or be
directed to purchase digital access in the app. This does not change the
existing access gate: new accounts remain locked until an administrator grants
access through the admin panel. The repository blocks a release with incomplete
policy, identity, signing, or App Link configuration.

## Verified Locally

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
   - `SUPABASE_URL=<Supabase project URL>`
   - `SUPABASE_SERVICE_ROLE_KEY=<server-only service role key>`
   - `SUPABASE_PUBLISHABLE_KEY=<client-safe publishable key>`
   - `AJE_ENABLE_DEBUG_OTP=false`
   - `AJE_ENABLE_LEGACY_DEV_PAYMENTS=false`
   - `AJE_ANDROID_API_BASE_URL=https://<deployed-api-host>`
   - `AJE_WHATSAPP_EXPERT_PHONE=<digits only, country code included>`
   - `AJE_ADMIN_EMAILS=<comma-separated admin emails>`
   - `AJE_PRIVACY_POLICY_URL=<public HTTPS privacy page>`
   - `AJE_ACCOUNT_DELETION_URL=<public HTTPS deletion page>`
   - `AJE_PRIVACY_CONTACT_EMAIL=<monitored privacy mailbox>`
   - `AJE_ANDROID_APP_SIGNING_SHA256=<fingerprint from Play App Signing>`
   - `AJE_PLAY_DISTRIBUTION_MODE=consumption_only`

3. Configure non-payment providers.
   - Authentication and email confirmation are provided by Supabase Auth.
     Add both verified HTTPS callback URLs to the Supabase redirect allowlist:
     `https://aje-farms-api-production.up.railway.app/auth` and
     `https://aje-farms-api-production.up.railway.app/login-callback`.
   - Gemini AI: set `GEMINI_API`, or accept the knowledge-base fallback.
   - Push notifications: set `AJE_PUSH_PROVIDER=fcm` and configure either
     `FCM_SERVICE_ACCOUNT_JSON` or `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, and
     `FCM_PRIVATE_KEY`.

4. Finalize learner-visible content.
   - Confirm which courses should appear in the launch catalog.
   - The trusted admin can save a draft or publish a complete course directly.
   - Publishing applies to the course, modules, lessons, and resources in one
     transaction. Source documents are optional attribution metadata and do
     not block publication.

5. Run release checks with production-shaped values.

```sh
NODE_ENV=production \
APP_URL=https://api.your-domain.example \
AJE_STORE=supabase \
SUPABASE_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres \
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVER_ONLY_SERVICE_ROLE_KEY \
SUPABASE_PUBLISHABLE_KEY=YOUR_CLIENT_SAFE_PUBLISHABLE_KEY \
AJE_ENABLE_DEBUG_OTP=false \
AJE_ENABLE_LEGACY_DEV_PAYMENTS=false \
AJE_ANDROID_API_BASE_URL=https://api.your-domain.example \
AJE_WHATSAPP_EXPERT_PHONE=255700000000 \
AJE_ADMIN_EMAILS=admin@your-domain.example \
AJE_PRIVACY_POLICY_URL=https://aje-farms-api-production.up.railway.app/privacy \
AJE_ACCOUNT_DELETION_URL=https://aje-farms-api-production.up.railway.app/delete-account \
AJE_PRIVACY_CONTACT_EMAIL=privacy@your-domain.example \
AJE_ANDROID_APP_SIGNING_SHA256=YOUR_PLAY_APP_SIGNING_SHA256 \
AJE_PLAY_DISTRIBUTION_MODE=consumption_only \
GEMINI_API=YOUR_GEMINI_KEY \
AJE_PUSH_PROVIDER=fcm \
FCM_PROJECT_ID=YOUR_FIREBASE_PROJECT_ID \
FCM_CLIENT_EMAIL=YOUR_FIREBASE_SERVICE_ACCOUNT_EMAIL \
FCM_PRIVATE_KEY=YOUR_FIREBASE_PRIVATE_KEY \
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

## Staff-Approved Access Validation

- Confirm staff can record, approve, and reverse payments from the admin panel.
- Confirm only approval creates learner entitlement and every transition writes
  an audit event.
- Confirm the learner app shows access status without purchase instructions or
  external-payment steering.

## Remaining Push Client Slice

- Add Firebase config files for the Android app.
- Add Firebase Messaging to the Android app and request runtime notification
  permission where required.
- Retrieve the Android device FCM token and register it through the existing
  notification service.
- Smoke test background and foreground notification receipt on a real device.
