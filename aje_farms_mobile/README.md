# AJE Farms Mobile

Native Flutter starter for the AJE Farms learner app.

This app currently mirrors the React demo as a production-ready Flutter foundation:

- Onboarding and learner dashboard
- Course catalog and course detail screens
- Assessment placeholder
- AI chat placeholder
- Payment/paywall placeholder
- Notifications placeholder
- Profile and subscription status placeholder

## Setup

Flutter is not installed on this machine yet. After installing Flutter, run:

```sh
cd aje_farms_mobile
flutter pub get
flutter run
```

If platform folders are missing, generate them with:

```sh
flutter create .
```

## Next Integrations

- Supabase or Firebase authentication
- Supabase course/content database
- Cloud storage for videos, PDFs, and images
- Server-side Gemini proxy
- Mobile money payment provider and webhook validation
- Push notifications
- Analytics and crash reporting
