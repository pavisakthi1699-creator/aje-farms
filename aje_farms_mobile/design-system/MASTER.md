# AJE Farms Mobile — Design System (Master)

Source of truth for UI work. Overrides generic ui-ux-pro-max script output (Baloo/Comic Neue is **not** used).

## Product

- **Type:** Agriculture learning & community (Swahili-first)
- **Audience:** Smallholder farmers in Tanzania
- **Tone:** Professional, trustworthy, approachable — not playful/kids
- **Stack:** Flutter (Material 3)

## Style

- **Pattern:** Content-first mobile app with bottom navigation
- **Visual language:** Soft cards, pastel surface tints, teal primary, warm accent CTAs
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

**Usage:** Prefer `context.colors.*` (`AppColorScheme`) in widgets. Use `AppColors.*` only for static/demo data.

Dark mode: paired tokens in `AppColorScheme.dark` — do not invert light hex values.

| Dark token | Hex | Notes |
|------------|-----|-------|
| `textSecondary` | `#A6B3C2` | Body/caption secondary on dark surfaces (≥4.5:1) |
| `borderSubtle` | `#3A4556` | Dividers/chips visible in dark mode |

## Typography

- **Font:** Atkinson Hyperlegible (bundled)
- **Body:** ≥16sp effective on mobile
- **Scale:** Material 3 `textTheme` roles (display → label)
- **Captions:** `accessibleCaption()` — clamps at large text scales (min 12sp)

## Spacing & layout

- **Grid:** 4/8dp via `AppSpacing`
- **Max content width:** 720 (`AppLayout`)
- **Full-bleed headers:** `AppLayoutScroll` / `AppLayoutFullBleed` for heroes on tablet
- **Touch target:** 48×48dp minimum (`AppA11y.minTouchTarget`, `MinTouchTarget`)

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

## Anti-patterns (avoid)

- Raw hex in screen widgets
- Emoji as navigation/settings icons
- Placeholder-only form labels
- Animating width/height (use transform/opacity)
- Ignoring safe areas on fixed bars
- Mixing inconsistent icon stroke styles

## Pre-release QA

See `docs/ui-release-screenshots.md` for golden capture checklist (light + dark + large text).
