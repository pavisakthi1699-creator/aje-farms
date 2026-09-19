# UI release screenshot checklist

Golden reference captures for **AJE Farms mobile** before each store release.  
Scope: visual QA only — no copy, navigation, or backend changes required during capture.

## Setup

| Setting | Light pass | Dark pass |
|---------|------------|-----------|
| Theme | Profile → Mipangilio → **Mwanga** | Profile → Mipangilio → **Giza** |
| Device | Phone (~390×844) + tablet/wide (~800×1200) | Same |
| Text scale | Default (1.0) | **2.0** on phone (one screen smoke) |
| Network | Online demo | Offline banner visible (airplane mode once) |

**Output folder:** `docs/release-screenshots/YYYY-MM-DD/{light\|dark}/`

Name files: `{screen}-{variant}.png` (e.g. `dashboard-phone-light.png`).

---

## Required screens (both themes unless noted)

### Shell & home
- [ ] **Onboarding** — hero gradient, CTA buttons, value rows
- [ ] **Dashboard** — trial card, hero problem intake, mini actions, course progress
- [ ] **Offline banner** — stale or offline message on dashboard (dark + light)

### Learning
- [ ] **Courses catalog** — skeleton (optional) + loaded list
- [ ] **Course detail** — full-bleed hero + **play button** visible
- [ ] **Lesson sheet** — modal open from play or lesson tile
- [ ] **Paywall** — **full-width hero** above constrained plans/payment block

### Community & support
- [ ] **Community feed** — filters + at least one post card
- [ ] **Post detail** — replies + composer bar
- [ ] **AI chat** — bubbles, suggestion chips (first message state)
- [ ] **WhatsApp escalation** — message preview bubble

### Account
- [ ] **Profile** — member card, subscription state
- [ ] **Settings** — **segmented theme control** (Mwanga / Giza / Mfumo)
- [ ] **Notifications** — local reminders list
- [ ] **Auth** — OTP flow first step (optional if unchanged)

### Payments
- [ ] **Paywall** — plan selected + M-Pesa chip selected
- [ ] **Payment success** — success status screen
- [ ] **Payment pending/failure** — retry state (staging/demo)

---

## Pass criteria

Each screenshot should confirm:

1. **Contrast** — card borders and chips readable in dark mode (no muddy edges).
2. **Layout** — list content centered ≤720px on wide; heroes edge-to-edge (course detail, paywall).
3. **Touch targets** — no clipped buttons at 2.0 text scale on dashboard + profile.
4. **Semantics** — spot-check with TalkBack/VoiceOver on: play button (`Cheza somo la mfano`), chat send (`Tuma`), theme segments.
5. **Motion** — push transition on one sub-screen (fade + slight slide); skeleton shimmer visible on catalog refresh.

---

## Quick capture commands

```bash
# Automated tour (Android emulator/device required)
cd aje_farms_mobile
./scripts/capture_release_screenshots.sh              # today’s date
./scripts/capture_release_screenshots.sh 2026-07-07     # explicit folder

# Or run the integration test directly
flutter test integration_test/release_screenshot_tour_test.dart

# Manual spot checks
cd aje_farms_mobile && flutter run

# Integration smoke (automated, not screenshots)
flutter test integration_test/connected_app_smoke_test.dart
flutter test
```

**Automated tour output:** `build/integration_test_screenshots/release_screenshot_tour_test/*.png`  
The script copies PNGs into `docs/release-screenshots/YYYY-MM-DD/light/`.

**Manual-only captures:** offline banner (airplane mode), payment success/pending states, 2.0× text scale smoke.

---

## Sign-off

| Role | Name | Date | Build |
|------|------|------|-------|
| UI / design | | | |
| Mobile dev | | | |
| QA | | | |

**Notes:**

- Swahili strings are frozen for this release — flag copy issues separately.
- Compare against prior release folder; regressions get a linked issue before ship.
