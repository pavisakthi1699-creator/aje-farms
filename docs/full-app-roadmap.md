# AJE Farms Full App Roadmap

This branch starts from the Flutter MVP parity baseline and turns it into the production app in small, shippable slices.

## Current Baseline

- Flutter app matches the MVP flow: onboarding, home, problem intake, topics, topic detail, AI chat, community, paywall, WhatsApp escalation, profile, notifications, and assessments.
- React/Vite demo remains in the repo as the product reference.
- App behavior now uses one connected runtime path. The Android app requires `AJE_API_BASE_URL`; demo/local services are explicit test harnesses only.
- Real external services are not fully wired yet: SMS provider, real mobile money provider, push notifications, and admin workflows.
- Flutter auth, payments, community writes, catalog refresh, and AI call server-side `/api/*` endpoints when launched with `AJE_API_BASE_URL`.

## Build Order

1. App architecture
   - Split the large Flutter app file into feature folders.
   - Add typed models, repositories, and service interfaces.
   - Keep demo repositories so UI can run without backend credentials.

2. Authentication and accounts
   - Local session and phone/guest state are implemented.
   - Backend OTP adapter is implemented for Flutter and Express; SMS provider delivery is still pending.
   - User profile, role, subscription status, and trial state.
   - Roles: learner, expert, admin, content editor.

3. Learning content
   - Local lesson completion and saved documents are implemented.
   - Courses, lessons, PDFs, videos, progress tracking, and locked premium content.
   - Offline-friendly content cache for low-connectivity users.
   - Admin/editor workflow for publishing approved knowledge.

4. AI support
   - Backend endpoint adapter is implemented for Flutter with local fallback.
   - Ground answers in approved knowledge content.
   - Show source cards back to lessons and documents.
   - Escalate uncertain or sensitive cases to a human expert.

5. Problem intake
   - Store selected category, crop/livestock, location, notes, and optional image.
   - Route to AI, community, or expert depending on urgency and subscription.

6. Community
   - Local posts, replies, reporting, filtering, and persisted user posts are implemented.
   - Posts, replies, reactions, related topics, moderation, and reporting.
   - Expert and admin badges.

7. Payments and subscriptions
   - Backend checkout adapter is implemented for Flutter and Express; real mobile money provider/webhooks are still pending.
   - Local plan selection, checkout confirmation, receipts, and subscription status are implemented.
   - Plan selection, payment status, receipts, subscription expiry, and retry states.

8. Expert support
   - WhatsApp deep link for MVP.
   - Later: in-app case queue, assignment, and response tracking.

9. Admin and operations
   - Content management.
   - User management.
   - Audit logs, backup policy, and basic analytics.

## Engineering Standards

- Keep features modular and testable.
- Use repository interfaces so demo data and production services can coexist.
- Avoid adding new dependencies until a feature needs them.
- Every feature slice should pass:
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`

## Next Slice

Replace sprint-grade backend adapters with provider-backed implementations:

- SMS OTP provider or Firebase/Supabase auth behind the existing auth API.
- Backend content store for courses and progress sync is implemented.
- Document/PDF storage remains deferred.
- Server-side AI endpoint grounded in approved content.
- Backend moderation queue and admin report actions are implemented.
- Backend notification inbox, preferences, and device registration are implemented.
- Mobile money provider checkout and webhook validation.
- Push provider integration and in-app admin UI workflows.
