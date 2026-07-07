# AJE Farms Android Backend Sprint

Goal: ship one connected Android app path in five days. The installed app must
use backend truth for auth, payments, AI, community, catalog, and subscriptions.
No runtime app modes and no silent local success fallbacks.

## Day 1: Connected Runtime Foundation

- [x] Android release builds have network permission.
- [x] Default Flutter app dependencies require `AJE_API_BASE_URL`.
- [x] Runtime auth, payment, community, and AI services call backend directly.
- [x] Demo services remain explicit test/dev harnesses only.
- [x] Backend mutable state persists to `server/data.local.json`.

Verification:

- [x] `npm run lint`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter build apk --debug --dart-define=AJE_API_BASE_URL=http://10.0.2.2:3000`

## Day 2: Durable Accounts and Subscriptions

- [x] Add backend user records keyed by verified phone number.
- [x] Return session/user/subscription payload from OTP verification.
- [x] Persist subscription activation on the server, not only device storage.
- [x] Add `/api/users/by-phone/:phoneNumber` as a sprint-grade profile lookup.

Acceptance:

- A signed-in user survives app restart and server restart.
- Subscription state comes from backend after login.

## Day 3: Real OTP Delivery

- [x] Add provider interface for SMS OTP delivery.
- [x] Configure one provider-backed implementation.
- [x] Remove debug OTP from non-development server responses.
- [x] Add resend/rate-limit behavior.

Acceptance:

- User can request and verify OTP on an Android device with a real phone number.
- Wrong/expired OTP fails visibly.

## Day 4: Payment Lifecycle

- [x] Change checkout to create `pending` transactions.
- [x] Add provider adapter and webhook-shaped confirmation endpoint.
- [x] Activate subscription only after server-confirmed `paid` status.
- [x] Add failed/retry states in Android paywall.

Acceptance:

- Paid transaction activates subscription from backend truth.
- Pending/failed transaction does not unlock premium access.

## Day 5: End-to-End Android Hardening

- [x] Run local backend plus Android emulator smoke test.
- [x] Verify auth, catalog load, AI chat, community create/reply/report, payment,
      subscription restore, and sign-out.
- [x] Build release APK.
- [ ] Sign release APK/AAB once signing credentials are available.
- [x] Add release preflight for backend URL, Postgres, debug OTP, signing config,
      and WhatsApp support number.
- [x] Fix top failure states and copy polish from smoke test.

Acceptance:

- One Android build connects to backend and completes the core farmer journey.
- No critical flow depends on a local-only success path.
