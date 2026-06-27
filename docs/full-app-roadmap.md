# AJE Farms Full App Roadmap

This branch starts from the Flutter MVP parity baseline and turns it into the production app in small, shippable slices.

## Current Baseline

- Flutter app matches the demo MVP flow: onboarding, home, problem intake, topics, topic detail, AI chat, community, paywall, WhatsApp escalation, profile, notifications, and assessments.
- React/Vite demo remains in the repo as the product reference.
- All app behavior is currently local demo data. Real services are not wired yet.

## Build Order

1. App architecture
   - Split the large Flutter app file into feature folders.
   - Add typed models, repositories, and service interfaces.
   - Keep demo repositories so UI can run without backend credentials.

2. Authentication and accounts
   - Phone OTP login for farmers.
   - User profile, role, subscription status, and trial state.
   - Roles: learner, expert, admin, content editor.

3. Learning content
   - Courses, lessons, PDFs, videos, progress tracking, and locked premium content.
   - Offline-friendly content cache for low-connectivity users.
   - Admin/editor workflow for publishing approved knowledge.

4. AI support
   - Replace the local canned response with a backend endpoint.
   - Ground answers in approved knowledge content.
   - Show source cards back to lessons and documents.
   - Escalate uncertain or sensitive cases to a human expert.

5. Problem intake
   - Store selected category, crop/livestock, location, notes, and optional image.
   - Route to AI, community, or expert depending on urgency and subscription.

6. Community
   - Posts, replies, reactions, related topics, moderation, and reporting.
   - Expert and admin badges.

7. Payments and subscriptions
   - Mobile money checkout flow.
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

Refactor Flutter into a production-friendly structure:

- `lib/src/features/...` for screens and widgets.
- `lib/src/models/...` for shared typed entities.
- `lib/src/repositories/...` for demo and future backend data access.
- `lib/src/services/...` for auth, AI, payments, and expert support interfaces.
