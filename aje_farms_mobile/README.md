# AJE Farms Mobile

Native Flutter starter for the AJE Farms learner app.

This app currently runs as a local-first Flutter product foundation:

- Onboarding, guest mode, and phone-entry session state
- Learner dashboard with persisted lesson progress
- Course catalog, course detail, saved documents, and completion tracking
- Assessment quiz and field assignment with saved scores
- Mwalimu AI knowledge assistant flow
- Community posts, replies, reporting, and filters persisted locally
- Payment/paywall flow with local subscription state
- Notifications driven by current app state
- Profile, settings, saved documents, and sign-out

## Setup

Run from the Flutter project directory:

```sh
cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
flutter pub get
flutter run
```

This project includes Android and web platform files. To run immediately on
Chrome:

```sh
flutter run -d chrome
```

By default, Mwalimu AI uses the local offline knowledge adapter. To call the
server-side AI endpoint, run the React/Express server from the repo root and
launch Flutter with an API base URL:

```sh
cd /Users/frankmchaina/Downloads/aje-farms
npm run dev

cd /Users/frankmchaina/Downloads/aje-farms/aje_farms_mobile
flutter run -d chrome --dart-define=MWALIMU_API_BASE_URL=http://localhost:3000
```

To run on Android, use an Android emulator or connected Android device:

```sh
flutter devices
flutter run -d <device_id> --dart-define=MWALIMU_API_BASE_URL=http://10.0.2.2:3000
```

macOS desktop is not generated yet. Add it only if you want this repo to support
that platform too.

## Android Release Signing

Debug APKs build without extra setup. For release builds, create
`android/key.properties` locally with:

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=...
keyAlias=...
keyPassword=...
```

`android/key.properties` is ignored by git.

## Next Integrations

- Supabase or Firebase authentication
- Supabase course/content database
- Cloud storage for videos, PDFs, and images
- Server-side Gemini proxy
- Mobile money payment provider and webhook validation
- Push notifications
- Analytics and crash reporting
