# Community Identity Hardening — Implementation Spec

**Severity: high. Two of the three defects below are live PII disclosures on an
unauthenticated endpoint.**

What started as "the community `author` field is client-supplied" turned out to
be three defects sharing one root cause: the community surface has no boundary
between *public display identity* and *private account identity*. The `author`
TEXT column does double duty as the name shown in the feed **and** the
notification-routing key, and `GET /api/community/posts` (`server/api.js:183`)
serves the whole row to anyone, with no authentication.

**Goal:** make post/reply authorship server-derived and non-spoofable, and stop
serving phone numbers to unauthenticated callers.

**Non-goals:** redesigning the community feature, adding profiles/avatars,
changing moderation workflow, or adding authentication to the public feed
(the feed being public is a product decision; leaking phone numbers through it
is not).

---

## The three defects

### D1 — Author spoofing (integrity)

`POST /api/community/posts` (`api.js:536`) and
`POST /api/community/posts/:postId/replies` (`api.js:561`) take `author` from
the request body and store it verbatim (`json-store.js:37`,
`postgres-store.js:1079`), despite `requireAuthSession` having already resolved
the caller's real identity into `req.authPhoneNumber`.

Any authenticated user can post as any string, including another user's phone
number. Because moderation notifications route on
`post.author.startsWith('+')` (`api.js:585`, `api.js:641`), a forged author also
misdirects the "your post was hidden" notification to whoever's number was
forged.

### D2 — Author phone numbers served publicly (PII)

The real client sends `session.phoneNumber` as `author` when signed in
(`community_screen.dart:182` and `:345`):

```dart
final author = session.isSignedIn ? session.phoneNumber! : 'Wewe';
```

That phone number is stored raw and rendered raw in the feed
(`community_widgets.dart:51`, replies at `:432`; the avatar initial at `:40`
is `post.author.substring(0, 1)`, which renders `+` for every phone-authored
post — a visible symptom of this bug that is already shipping).

`GET /api/community/posts` has **no auth middleware**. Every phone number that
has ever posted is readable by anyone who can reach the URL. In this market a
phone number is also a mobile-money identity, so treat this as a serious
disclosure, not a cosmetic issue.

### D3 — Moderator phone numbers served publicly (PII)

`communityPostFromRow` (`postgres-store.js:1441-1461`) serialises
`moderatedBy: row.moderated_by`, which `resolveCommunityReport` populates with
the acting admin's phone number (`api.js:632`). `communityPosts()` selects that
column (`postgres-store.js:858`) and the public endpoint returns it.

Dismissing a report leaves the post visible with `moderated_by` set, so this
leaks the **admin team's** personal numbers through an unauthenticated endpoint.

---

## Root cause and target design

One column cannot be both a public label and a private key. Split it:

| Concern | Today | Target |
|---|---|---|
| Who wrote this (private, server-derived) | `author` when it looks like a phone | new `author_phone` column, never serialised to clients |
| What to show in the feed (public) | `author` | `author` — display name only, never a phone number |
| Who moderated this (admin-only) | `moderatedBy`, public | `moderatedBy`, admin responses only |

Display name resolution, server-side, in priority order:
1. `users.display_name` if set (the column already exists, `schema.sql:154`).
2. Otherwise a stable pseudonymous handle: `Mkulima {suffix}` where `suffix` is
   the first 4 hex chars of `sha256(phone + AJE_OTP_PEPPER)`. Stable per user,
   non-reversible, distinguishable between users. `server/store/utils.js`
   already imports `crypto` and has the pepper accessor (`utils.js:132`).

Do **not** fall back to last-N-digits of the phone; in a small local community
that is often re-identifying.

---

## Constraints

1. **Rehearse the Phase 3 data migration on staging first.** If the staging
   environment from `docs/staging-team-testing-spec.md` exists, use it. Do not
   run the backfill against production until it has run clean once elsewhere.
2. **`author_phone` must never appear in any client-facing response**, including
   admin responses — admins need it for moderation routing, but it should not
   be sent to the app unless a concrete UI needs it. Default to omitting.
3. Keep both store backends (`json-store.js`, `postgres-store.js`) behaviourally
   identical. `server/tests/store-api.test.js` and
   `server/tests/store-api-postgres.test.js` run the same expectations against
   each; keep it that way.
4. Do not change the OTP/auth path. This spec touches community and
   serialisation only.

---

## Phase 0 — Reproduce, with failing tests

**Objective:** encode all three defects as tests that fail now and pass at the
end. Do not fix anything in this phase.

Add to `server/tests/store-api.test.js` (and mirror into
`store-api-postgres.test.js`, following how existing cases are shared):

- **D1:** authenticate as user A, `POST /api/community/posts` with
  `author: '+255799999999'`, then `GET /api/community/posts` and assert the
  returned post is **not** attributed to `+255799999999`.
- **D2:** authenticate as user A (phone `+255712345678`), create a post with no
  `author` field at all, fetch the public feed, and assert
  `JSON.stringify(feed)` does **not** contain `'+255712345678'`.
- **D3:** as an admin, resolve a report with `action: 'dismiss'`, then fetch the
  **unauthenticated** feed and assert the response contains no `moderatedBy`
  value and no `+` -prefixed string.

**Validation:**
```bash
npm run test:server
```

**Acceptance criteria:** exactly the three new tests fail, each for the stated
reason. All pre-existing tests still pass. Paste the failure output into the
phase report — this is the evidence the bugs are real.

**Rollback:** revert; tests only.

---

## Phase 1 — Stop leaking `moderatedBy` (D3)

**Objective:** ship the fastest high-value fix. No schema change, no migration,
independently deployable.

**Changes:**

1. In `server/store/postgres-store.js`, make `communityPostFromRow` omit
   `moderatedBy` (and `moderatedAt`, which is only meaningful alongside it) from
   its default output. Add an explicit opt-in for admin paths, e.g.
   `communityPostFromRow(row, { includeModeration = false } = {})`.
2. Pass `includeModeration: true` from `reportedCommunityPosts()`
   (`postgres-store.js:1149`) and from `resolveCommunityReport`'s return value,
   which feed the admin-only routes `GET /api/admin/moderation/reports`
   (`api.js:612`) and `POST /api/admin/moderation/posts/:postId/resolve`
   (`api.js:621`).
3. Apply the equivalent change in `server/store/community-json-store.js` so both
   backends match.
4. Check the Flutter client does not depend on the removed fields:
   `grep -rn "moderatedBy\|moderatedAt" aje_farms_mobile/lib`. If the admin
   models consume them, they must keep working through the admin routes.

**Validation:**
```bash
npm run test:server
```
```bash
cd aje_farms_mobile && flutter analyze && flutter test
```

**Acceptance criteria:**
- The D3 test from Phase 0 passes; D1 and D2 still fail.
- Admin moderation tests still see `moderatedBy` on the admin routes.
- No Flutter analyzer or test regressions.

**Rollback:** revert the commit. No data or schema impact.

---

## Phase 2 — Server-derived authorship (D1, D2)

**Objective:** authorship comes from the session; the feed shows display names.

### 2.1 Schema

Append to `server/store/schema.sql` (idempotent, matching the file's existing
style):

```sql
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS author_phone TEXT;

ALTER TABLE community_replies
  ADD COLUMN IF NOT EXISTS author_phone TEXT;

CREATE INDEX IF NOT EXISTS idx_community_posts_author_phone
  ON community_posts (author_phone);
```

`server/scripts/migrate.js` applies the whole file, so no separate migration
runner is needed. Add the matching statements to `supabase/migrations/` as a new
timestamped file, consistent with the existing naming.

### 2.2 Display-name resolution

Add to `server/store/utils.js`, beside the existing pepper helpers:

```js
export function communityDisplayName(user, phoneNumber) {
  const displayName = String(user?.displayName ?? '').trim();
  if (displayName) return displayName;
  const suffix = crypto
    .createHash('sha256')
    .update(`${normalizePhoneNumber(phoneNumber)}:${otpPepper()}`)
    .digest('hex')
    .slice(0, 4);
  return `Mkulima ${suffix}`;
}
```

Note this makes handles pepper-dependent: rotating `AJE_OTP_PEPPER` reshuffles
pseudonyms for users without a `display_name`. Acceptable, but record it in the
phase report.

### 2.3 Route changes

In `server/api.js`, for both `POST /api/community/posts` (`:536`) and
`POST /api/community/posts/:postId/replies` (`:561`):

- **Ignore `req.body.author` entirely.** Do not validate it, do not read it.
- Resolve the caller: `const user = await store.getUser(req.authPhoneNumber)`.
- Pass to the store: `authorPhone: req.authPhoneNumber` and
  `author: communityDisplayName(user, req.authPhoneNumber)`.
- Update the request validation to no longer require `author` in the body.

### 2.4 Store changes

In both `community-json-store.js` and `postgres-store.js`:

- `createCommunityPost` / `addCommunityReply` accept `authorPhone` and persist
  it to the new column, keeping `author` as the display name.
- Row mappers (`communityPostFromRow`, `replyFromRow`,
  `postgres-store.js:1441` and `:1464`) must **not** include `author_phone` in
  output. Add it only behind the same `includeModeration` opt-in from Phase 1 if
  an admin path needs it.

### 2.5 Notification routing

Replace the `startsWith('+')` heuristic at `api.js:585` and `api.js:641` with
the explicit field. The moderation handler needs the post's `authorPhone`, so
`resolveCommunityReport` should return it (admin-side, not serialised onward):

```js
// before
if (post.author?.startsWith('+')) { ... }

// after
if (post.authorPhone) { ... }
```

Same at the reply-notification site, including the existing
`post.author !== req.authPhoneNumber` self-notification guard, which becomes
`post.authorPhone !== req.authPhoneNumber`.

**Validation:**
```bash
npm run test:server
```
```bash
npm run db:up && npm run db:migrate && npm run test:server:postgres
```

**Acceptance criteria:**
- All three Phase 0 tests pass.
- Moderation and reply notifications still fire, verified by the existing cases
  in `server/tests/notifications.test.js`.
- `grep -rn "startsWith('+')" server/` returns nothing.
- Both store backends pass the shared suite.

**Rollback:** revert code. The added columns are additive and nullable — leaving
them in place is harmless.

---

## Phase 3 — Backfill existing rows

**Objective:** move phone numbers already sitting in `author` into
`author_phone`, and replace them with display names.

Existing production rows are a mix: seeded rows carry human names
(`'Timu ya AJE Farms'`, asserted in
`server/tests/catalog-content-readiness.test.js:69`), user rows carry `+255…`
phone numbers. Only the latter need migrating.

**Write `server/scripts/backfill-community-authors.js`**, following the style of
the existing `server/scripts/*.js` (dotenv, `pg.Pool`, explicit failure exit).
It must:

1. Support `--dry-run` (default) and require an explicit `--apply`.
2. Select rows from `community_posts` and `community_replies` where
   `author LIKE '+%'`.
3. For each: set `author_phone = author`, and `author =
   communityDisplayName(<users row for that phone>, author)` — reusing the exact
   helper from Phase 2.2, not a reimplementation.
4. Run in a transaction; report counts of rows scanned, migrated, and skipped.
5. Be idempotent — a second run must migrate zero rows.

Add `server/tests/backfill-community-authors.test.js` covering: a phone-authored
row migrates, a human-named row is untouched, a user with `display_name` gets
that name, a user without one gets the `Mkulima …` handle, and a second pass is
a no-op.

**Validation:**

Dry run first, on staging:
```bash
node server/scripts/backfill-community-authors.js --dry-run
```
Then apply, then verify nothing phone-shaped remains:
```sql
SELECT COUNT(*) FROM community_posts  WHERE author LIKE '+%';
SELECT COUNT(*) FROM community_replies WHERE author LIKE '+%';
```
Both must return `0`. Then confirm the public feed is clean:
```bash
curl -sS "$STAGING/api/community/posts" | grep -c '+255' || echo "clean"
```

**Acceptance criteria:**
- Dry run output reviewed before `--apply`.
- Both counts are `0`; feed check prints `clean`.
- Re-running with `--apply` migrates 0 rows.
- Run on staging first, then production, with output from **both** in the report.

**Rollback:** take a database snapshot before `--apply` on production. The
transform is lossy in one direction only (the original `author` is preserved in
`author_phone`), so a reverse script is possible but a snapshot is simpler.

---

## Phase 4 — Client

**Objective:** stop sending `author`, and render the server's display name.

**Changes:**

1. `aje_farms_mobile/lib/src/services/community_service.dart` and
   `backend_community_service.dart`: drop the `author` parameter from
   `createPost` and `addReply`, and stop putting it in the request body
   (`backend_community_service.dart:30` and `:47`). Update
   `local_community_service.dart` to match the interface.
2. `community_screen.dart:182` and `:345`: delete the
   `session.isSignedIn ? session.phoneNumber! : 'Wewe'` lines and the argument.
   Both call sites are behind a signed-in check already; confirm and preserve
   the unauthenticated path's behaviour.
3. `community_widgets.dart:40`: `post.author.substring(0, 1)` crashes on an
   empty author and produced `+` for phone authors. Guard it and derive the
   initial from the display name.
4. Update `aje_farms_mobile/test/` community cases and any golden that renders a
   post author. `visual_regression_test.dart` and `goldens/` may need
   regeneration — regenerate deliberately and eyeball the diff, do not blanket
   `--update-goldens`.

**Validation:**
```bash
cd aje_farms_mobile && flutter analyze && flutter test
```

**Acceptance criteria:**
- No analyzer issues; all tests pass.
- `grep -rn "phoneNumber" lib/src/features/community/` returns nothing.
- Golden diffs reviewed and intentional.

**Rollback:** revert. Server tolerates a client still sending `author` — it is
ignored after Phase 2 — so client and server can deploy independently. **Deploy
the server first.**

---

## Phase 5 — End-to-end verification

Run against staging, with a real device or the integration test.

1. Sign in as user A. Create a post. The feed shows a display name, never a
   phone number.
2. Set a display name in Profile, create another post, confirm the new name is
   used and the old post keeps its previous handle (expected — historical rows
   are not retroactively renamed).
3. Attempt the spoof directly, since the UI no longer offers it:
   ```bash
   curl -sS -X POST "$STAGING/api/community/posts" \
     -H "Authorization: Bearer $TOKEN_A" -H 'Content-Type: application/json' \
     -d '{"author":"+255799999999","content":"spoof attempt test post","location":"Arusha","tags":[]}'
   ```
   The created post must be attributed to user A's display name, **not**
   `+255799999999`.
4. As an admin, hide one of user A's posts. User A receives the moderation
   notification; the forged number's owner does not.
5. Fetch the feed **unauthenticated** and assert no `+255`, no `moderatedBy`,
   no `authorPhone` anywhere:
   ```bash
   curl -sS "$STAGING/api/community/posts" \
     | grep -oE '\+255[0-9]+|moderatedBy|authorPhone' | sort -u
   ```
   Must print nothing.
6. As an admin, confirm `GET /api/admin/moderation/reports` still returns the
   moderation fields the dashboard needs.

**Acceptance criteria:** all six pass on staging before production deploy.

---

## Deploy order

1. Phase 1 (independently shippable — do it first, it is the cheapest PII fix).
2. Phase 2 server deploy.
3. Phase 3 backfill: staging → verify → production.
4. Phase 4 client, in the next APK.

Server-before-client is required: after Phase 2 the server ignores a
client-supplied `author`, so an old client keeps working. The reverse is not
true.

---

## Notes and open items

- **Historical handles are frozen.** A user who later sets a `display_name` will
  not have past posts renamed. Retroactive renaming is possible but is a product
  decision, not a security requirement — leaving it out.
- **`isExpert` is hardcoded `false`** on every created post and reply
  (`json-store.js:47`, `postgres-store.js:1089`, `:1104`) while the UI renders an
  expert badge. There is no path to set it. Out of scope here; worth its own
  ticket.
- **The feed remains unauthenticated** after this work. That is now defensible
  because it serves only display names and public content, but confirm it is
  intentional.
- **This does not fix `GET /api/lessons/:lessonId/video`** (`api.js:70`), which
  is unauthenticated and 302s to a signed video URL with no subscription check.
  Separate issue, separate decision.

---

## Phase completion report format

Per phase: status; every validation command with **actual** output; deviations
and why; files changed with one-line rationale. For Phase 3, include dry-run and
apply output from staging **and** production separately, plus confirmation a
snapshot was taken before the production apply.

Do not advance a phase until its acceptance criteria are met.
