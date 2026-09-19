# Chuo Kikuu Cha Mtaani Mobile — Design System (Master)

Source of truth for UI work. Overrides generic ui-ux-pro-max script output (Baloo/Comic Neue is **not** used).

## Product

- **Type:** Agriculture learning & community (Swahili-first)
- **Audience:** Smallholder farmers in Tanzania
- **Tone:** Professional, trustworthy, approachable — not playful/kids
- **Stack:** Flutter (Material 3)

## Style

- **Pattern:** Content-first mobile app with bottom navigation (labels always visible)
- **Visual language:** Neutral white cards on soft background; teal primary; pastel tints only for semantic meaning (AI mint, premium charcoal)
- **Brand mark:** `BrandMark` — crop-row + sprout (`brand_mark.dart`); used in header, onboarding, dashboard hero watermark
- **Dashboard hero:** Full-width teal gradient (`primary` → `primaryDark`), warm accent pill, white CTA button
- **Icons:** Material Icons (outlined/filled by hierarchy) — **no emoji as icons**
- **Effects:** Rounded corners (`AppRadius`), theme-aware elevation (`AppElevation`), subtle ink + haptics

## Colors (light baseline)

| Role | Token | Hex |
|------|-------|-----|
| Primary | `primary` | `#1B6B7A` |
| Primary dark | `primaryDark` | `#145A66` |
| Background | `background` | `#F0F4F8` |
| Surface | `surface` | `#FFFFFF` |
| Text primary | `textPrimary` | `#1A1F2C` |
| Text secondary | `textSecondary` | `#64748B` |
| Success | `success` | `#2F8F5B` |
| Warning | `warning` | `#D4A03A` |
| Error / warm accent | `error` / `accentWarm` | `#C85A3C` |
| Charcoal (premium only) | `charcoal` | `#1A1F2C` |

**Usage:** Prefer `context.colors.*` (`AppColorScheme`) in widgets. Use `AppColors.*` only for static/demo data.

**Card surfaces:** Default to `surface`. Use tinted surfaces sparingly:
- `surfaceAqua` (`mint`) — AI / Mwalimu shortcuts
- `charcoal` — premium / paywall emphasis
- `primaryContainer` — subtle emphasis chips/icons
- Avoid stacking multiple pastels on one screen

**Buttons:**
- `FilledButton` — `primary` background (default CTAs)
- Charcoal — premium card, snackbars, locked-lesson states only
- Hero CTA on gradient — white `surface` button with `primary` text

Dark mode: paired tokens in `AppColorScheme.dark` — do not invert light hex values.

| Dark token | Hex | Notes |
|------------|-----|-------|
| `textSecondary` | `#A6B3C2` | Body/caption secondary on dark surfaces (≥4.5:1) |
| `borderSubtle` | `#3A4556` | Dividers/chips visible in dark mode |

## Typography

- **Font:** Atkinson Hyperlegible through `google_fonts`; visual baselines use
  the same type scale with platform fonts via `AppTheme.light/dark(useGoogleFonts: false)`
- **Body:** ≥16sp effective on mobile
- **Scale:** Material 3 `textTheme` roles (display → label)
- **Weights:** Headlines w700, titles w600, labels w600–w700; avoid w800 outside paywall prices
- **Case:** Sentence case for UI copy and pills — no `.toUpperCase()` on labels
- **Captions:** `accessibleCaption()` — clamps at large text scales (min 12sp)

## Spacing & layout

- **Grid:** 4/8dp via `AppSpacing`
- **Max content width:** 720 (`AppLayout`)
- **Full-bleed headers:** `AppLayoutScroll` / `AppLayoutFullBleed` for heroes on tablet
- **Touch target:** 48×48dp minimum (`AppA11y.minTouchTarget`, `MinTouchTarget`)
- **Bottom nav:** 80dp height, 22dp icons, 10sp labels — tested down to 320dp width

## Personalization

- **Dashboard greeting:** `AppSessionState.dashboardGreeting` (`dashboard_greeting.dart`)
  - With `displayName` → `Karibu, {name}`
  - Guest → `Karibu, Mkulima`
  - Signed in → `Karibu tena`
  - With `preferredLocation` → `Karibu, mkulima wa {location}`
- **Profile fields:** `displayName` and `preferredLocation` in settings; synced via `POST /api/users/by-phone/:phone/profile` when signed in

## Photography

- **Bundled assets:** `assets/images/courses/` and `assets/images/hero/`
- **Widget:** `AppPhoto` loads assets or remote URLs (`NetworkPhoto` alias)
- **Hero:** dashboard problem card uses `farm-field.jpg` under teal scrim
- **Asset gate:** curated photos must be registered in `pubspec.yaml`, JPEG,
  ≤400KB, at least 800×600, and the hero image must not duplicate a course
  photo (`test/asset_governance_test.dart`)

## Motion

| Token | Duration |
|-------|----------|
| `quick` | 140ms |
| `standard` | 220ms |
| `enter` | 320ms |
| `skeleton` | 1400ms |

- Curves: `easeOutCubic` / `easeOutQuart` enter, `easeInCubic` exit
- **Reduced motion:** `AppMotion.reduceMotionOf(context)` — skip fades, shimmer, scale, tab transitions
- Press scale: `0.985` (`InteractiveInk`) when motion allowed

## Accessibility

- Screen reader labels on icon-only controls (`tooltip` + `Semantics`)
- Decorative icons: `ExcludeSemantics`
- Offline banner: `Semantics(liveRegion: true)`
- Theme: Mfumo / Mwanga / Giza (`AppThemePreference`)
- Dynamic type: test at 2.0× on dashboard before release
- `BrandHeader` text uses `Flexible` + ellipsis at large text scales

## Anti-patterns (avoid)

- Raw hex in screen widgets
- Emoji as navigation/settings icons
- Placeholder-only form labels
- Animating width/height (use transform/opacity)
- Ignoring safe areas on fixed bars
- Mixing inconsistent icon stroke styles
- Uppercase micro-labels on pills and badges
- Multiple pastel card colors on a single scroll view

## Pre-release QA

See `docs/ui-release-screenshots.md` for golden capture checklist (light + dark + large text).

Run the enterprise frontend gate before release:

```sh
bash scripts/frontend_quality_gate.sh
```

The gate covers:
- `flutter analyze`
- full Flutter widget/service tests
- visual regression baselines in `test/goldens/`
- asset governance checks
- `git diff --check`
- backend contract tests from the repo root

Update visual baselines only after intentional design review:

```sh
flutter test test/visual_regression_test.dart --update-goldens
```
