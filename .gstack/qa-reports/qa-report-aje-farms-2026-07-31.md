# QA Report: AJE Farms Android release

| Field | Value |
|-------|-------|
| **Date** | 2026-07-31 |
| **Target** | Android release APK and AAB |
| **Commit** | `29b42b6` (`fix: secure learner access and release UX`) |
| **Tier** | Standard release QA |
| **Scope** | First-launch authentication gate, release artifact, automated regressions |
| **Screenshots** | 4 |
| **Framework** | Flutter |

## Health Score: 91/100

| Category | Score |
|----------|-------|
| Functional | 95 |
| Visual | 94 |
| UX | 85 |
| Release artifact | 100 |
| Automated regression | 100 |

## Results

| Check | Result | Evidence |
|-------|--------|----------|
| Server regression suite | PASS | 112 passed; 7 database tests skipped because no local `DATABASE_URL` was supplied |
| Flutter regression suite | PASS | 121 passed |
| Static analysis | PASS | `flutter analyze` reported no issues |
| Production-configured APK build | PASS | Signed APK built (59.0 MB) and native package validation passed for `com.ajefarms.mobile` |
| Production-configured AAB build | PASS | AAB built (57.6 MB) |
| First launch | PASS | Registration/sign-in CTA is the sole primary action |
| Auth navigation | PASS | CTA opens the sign-in/registration form |
| Guest course access | PASS | Selecting the course area redirects a guest to authentication |

## Issues

### ISSUE-001: Guest return state can show a misleading content-sync failure

| Field | Value |
|-------|-------|
| **Severity** | medium |
| **Category** | UX / functional |
| **State** | An unauthenticated user leaves authentication and returns to the home/account areas |

**Description:** The screen can display “Imeshindikana kusasisha maudhui mapya. Unaona taarifa za hivi karibuni.” before sign-in. For a guest, protected content requests are expected to be unavailable, so this wording presents authorization as a sync failure. The account view also labels the visitor `Mgeni` while showing the guest/basic-access state, which is potentially confusing.

**Expected:** Do not fetch protected learning content before authentication, or show the clear registration CTA without an error banner.

**Evidence:** [return state](screenshots/return-state.png)

## Release proof

First launch shows a dedicated onboarding screen with only **Ingia / Jisajili**:

![First launch](screenshots/first-launch.png)

Selecting that CTA opens the sign-in/registration screen:

![Sign in / register](screenshots/sign-in.png)

Selecting the course area while still unauthenticated also returns the user to the authentication form, confirming that courses are gated:

![Guest course gate](screenshots/guest-course-gate.png)

## Ship Readiness

**Verdict: HOLD until ISSUE-001 is fixed.** The security and first-launch authentication gate work; however, a real user can still encounter a misleading error state when unauthenticated. Push notification configuration remains intentionally deferred (`AJE_PUSH_PROVIDER=development`) and should be completed before enabling public push features.
