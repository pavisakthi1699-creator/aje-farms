# AJE Farms Full Working App Plan

Date: 2026-07-23
Branch: `codex/native-android-release`
Repository: `nurulabsai/aje-farms`

## Outcome

Deliver one native Flutter Android APK that can be acceptance-tested end to end by:

- a learner who signs in, consumes courses, publishes community topics, replies, and reports unsafe content;
- an administrator who signs in with a server-authorized account, manages course and lesson content, publishes learner-visible content, monitors users, and moderates reported community discussions;
- a release operator who can validate the same production API and Supabase-backed data before publishing a signed APK prerelease.

## Confirmed Current State

- The native Android package, course navigation, lessons, and production video playback work on the user's physical Android phone.
- The server already exposes authenticated community post, reply, and report endpoints.
- The server already exposes role-gated admin endpoints for content records, moderation reports, and user monitoring.
- The Flutter app already contains learner community screens and a role-gated admin dashboard.
- Existing admin editing changes only a course/document title and draft/approved status; it is not yet a complete course-and-lesson editor.
- Community requests currently accept client-supplied author identity instead of deriving it exclusively from the authenticated session.
- Uncommitted admin allowlist and `whoami` diagnostics work is present and must be preserved, reviewed, completed, and tested.
- Baseline validation on 2026-07-23: server 54 passed, 0 failed, 2 database-dependent skipped; Flutter 76 passed, 0 failed.

## Product Premises Requiring Confirmation

1. The administrator experience belongs inside the same native Flutter APK, protected by backend authorization; no Vite/web admin panel is required for this test release.
2. A “community topic” is a learner-created community post with tags, replies, reporting, and moderation—not a separate forum taxonomy product.
3. “Content management” for this release means creating and editing a complete course structure (course metadata plus ordered lessons), saving drafts, publishing/unpublishing, and confirming the learner catalog refreshes.
4. Admin authorization remains phone/OTP based, with production admin phone numbers configured server-side; the APK must never contain an admin secret or privileged Supabase key.
5. Moderation scope includes listing reports, reviewing the discussion, hiding unsafe posts, and dismissing invalid reports with auditable moderator/time data.
6. Validation is phase-gated: automated server/Flutter tests, live Supabase/API checks, Android learner/admin E2E, then signed APK and GitHub prerelease.

Confirmed by the user on 2026-07-23.

## Implementation Approaches

### Approach A: Minimal completion

- Complete the existing admin login/role work.
- Secure community author identity and validate reporting/moderation.
- Keep the current admin content editor limited to title and draft/approved status.
- Effort: small.
- Risk: low.
- Completeness: 6/10.
- Tradeoff: fastest APK, but it does not satisfy complete course-and-lesson management.

### Approach B: Complete native test release

- Complete the existing admin login/role work.
- Secure learner topic/reply/report identity and moderation behavior.
- Extend the existing native admin dashboard and APIs to create/edit course metadata and ordered lessons, save drafts, publish, and unpublish.
- Validate learner and admin flows against the production Supabase-backed API before publishing the APK.
- Effort: medium.
- Risk: medium.
- Completeness: 9/10.
- Reuses: existing Flutter admin/community screens, backend services, role guards, content records, Supabase store, and release pipeline.

Recommendation: Approach B. It directly satisfies the confirmed acceptance scope while retaining the current architecture and a realistic test-release boundary.

### Approach C: Versioned content platform

- Everything in Approach B.
- Add content revisions, approval history, rollback, richer RBAC, moderation audit events, and media upload management.
- Effort: extra large.
- Risk: high.
- Completeness: 10/10 for a longer-term operational platform.
- Tradeoff: stronger long-term foundation, but too large for the immediate acceptance APK and substantially increases migration/security testing.

## Proposed Acceptance Matrix

| Role | Flow | Acceptance |
|---|---|---|
| Learner | Sign in and restore session | Correct learner role persists after restart |
| Learner | Publish topic | Authenticated identity is used; topic appears after refresh/restart |
| Learner | Reply | Reply persists and appears to other sessions |
| Learner | Report | One actionable report is available to admins |
| Admin | Sign in | Server and app agree on admin role; non-admin remains blocked |
| Admin | Manage course | Create/edit metadata and ordered lessons; save draft |
| Admin | Publish course | Published content appears in learner catalog after refresh |
| Admin | Unpublish course | Content leaves learner catalog without data loss |
| Admin | Moderate | Review report, hide or dismiss, persist moderator/time |
| Admin | Monitor users | Search and activity summaries load from production data |
| Release | Validate | Production checks and device E2E pass before APK publication |

## Not in This Test Release

- A separate Vite/React web admin application.
- Multi-level enterprise RBAC beyond learner/admin.
- Real-time chat/WebSocket delivery.
- Automated AI publication without human review.
- App-store submission; delivery remains a signed GitHub prerelease APK for acceptance testing.

## Implementation Phases

1. Complete and validate admin identity/authorization.
2. Harden and validate community publishing, replies, reporting, and moderation.
3. Complete course/lesson draft, edit, publish, and unpublish management.
4. Run live production and Android learner/admin E2E validation.
5. Review security/release gates, push commits, and publish a signed APK prerelease.

## Phase Status

### Phase 1: Admin identity and authorization

Status: locally validated; production acceptance blocked by missing SMS provider.

- Server allowlist elevation is now computed at request time rather than persisted into the user role.
- Removing a phone from `AJE_ADMIN_PHONE_NUMBERS` immediately removes its allowlist-based admin access.
- Stored admin roles remain supported independently.
- Production Railway contains `AJE_ADMIN_PHONE_NUMBERS`.
- Validation passed: server tests, targeted Flutter tests, TypeScript check, and Flutter analyzer.
- Live `/api/health` returns HTTP 503 because SMS, payments, and notification providers are not production-ready.
- Fresh learner/admin phone login cannot be validated until a production SMS provider is configured. The current server deliberately refuses its development OTP sender when `NODE_ENV=production`.
- Provider decision: use Africa's Talking instead of Twilio. The adapter keeps
  credentials server-side and preserves the existing Flutter OTP contract.

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|---|---|---|---|---|---|
| 1 | Inventory | Reuse the existing Flutter and Node/Supabase paths | Auto-decided | Existing-code leverage | The main flows already exist and have passing tests | Parallel Vite admin rebuild |
| 2 | Scope | Preserve current uncommitted admin-role work | Auto-decided | Change safety | It appears intentional and directly supports the requested outcome | Revert or overwrite |
| 3 | Premises | Native learner/admin/community scope confirmed | User-confirmed | Premise gate | User replied “confirmed” | Separate Vite admin and ambiguous content scope |
| 4 | Approach | Complete native test release | User-selected | Implementation approach | User selected Approach B | Minimal editor and oversized platform expansion |
| 5 | Admin authorization | Keep allowlist elevation non-persistent | Auto-decided | Least privilege | Removing a phone must revoke access immediately | Persisting allowlist membership as a database admin role |
| 6 | OTP provider | Use Africa's Talking direct HTTPS API | User-selected | Provider fit and dependency safety | User selected Africa's Talking; direct fetch avoids vulnerable SDK dependencies | Twilio and the vulnerable current SDK dependency tree |
