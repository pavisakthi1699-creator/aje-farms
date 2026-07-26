# AJE Farms staging team testing

Use this environment to test Android login, content administration, and
moderation before a production release.

## Important: this is not production

- Staging API: <https://aje-farms-api-staging-production.up.railway.app>
- Railway project: `aje-farms-staging`
- Staging has its own Postgres database.
- It contains test data only. Do not enter real customer data or rely on it as
  a permanent record.
- Changes made here do not change the production service or production
  database.

The word `production` in the generated Railway hostname is Railway's default
environment label inside the separate `aje-farms-staging` project. The backend
itself runs with `NODE_ENV=staging`.

## Install the Android app

The testing file is named `app-profile.apk`.

1. Download `app-profile.apk` to your Android phone.
2. Open the downloaded file.
3. If Android blocks installation, open the prompt for **Settings** and enable
   **Allow from this source** or **Install unknown apps** for the app you used
   to download it, such as Chrome, Drive, or Files.
4. Return to the download and tap **Install**.
5. If an older AJE Farms test build is installed, Android may offer **Update**.
   If the update fails because its signature differs, uninstall the older test
   build and install this APK again.
6. Open **AJE Farms**.

This is a profile-mode internal test build. Do not upload it to the Play Store.
Its SHA-256 checksum is:

```text
a6862b4da9299fba20bfcb9037362bd6717dec5d5a62c3fbe6a862bc860e341e
```

## Log in

1. Tap **Ingia / Jisajili**.
2. Enter your Tanzanian phone number without the `+255` prefix. Example:
   `712345678`.
3. Tap **Tuma OTP**.
4. Read the six-digit code shown in the app as
   **OTP ya majaribio: NNNNNN**.
5. Enter that code and tap **Endelea**.

No SMS is sent in staging. Seeing the OTP inside the app is expected.

You can request one OTP per phone number every 60 seconds. If you request
another too soon, wait for the displayed delay instead of repeatedly tapping
the button.

## Admin access

Admin phone numbers come from the staging Railway service variable
`AJE_ADMIN_PHONE_NUMBERS`. Personal phone numbers must not be added to this
repository or to screenshots.

If your number is configured:

1. Log in and open **Akaunti**.
2. Confirm **Dashibodi ya Admin** is visible.
3. Internal builds also show **Debug: Hali ya Admin**. It should report
   **Admin access (server): NDIYO**.
4. Open the dashboard and test:
   - **Maandishi** for course and document status.
   - **Usimamizi** for reported community content.
   - **Watumiaji** for user monitoring.

If your number is not configured, **Dashibodi ya Admin** must not appear.
Report it as a security issue if it does.

## Shared staging data

The staging backend is shared by the whole testing team. Publishing, reverting,
hiding, or approving content changes what every other tester sees.

- Use clearly recognizable test content.
- Tell the team before changing content someone else may be testing.
- Restore important seeded content when your test is finished.
- Never add real customer or payment information.

## Known test-build limitation

The APK uses the placeholder WhatsApp expert number `255700000000`. Login,
learning, content administration, and moderation are connected to staging, but
WhatsApp escalation is not part of this test build.

## Report findings

File findings in the
[AJE Farms GitHub issue tracker](https://github.com/nurulabsai/aje-farms/issues).

Include:

- A short title and whether it blocks testing.
- Phone model and Android version.
- The screen and exact steps that produced the issue.
- Expected and actual behaviour.
- A screenshot or screen recording when useful.
- The time of the test, including timezone.

Do not include phone numbers, OTPs, session tokens, database URLs, or Railway
secrets in an issue.
