# 💩 Potty Tracker

A baby poop tracking app built with Flutter + Firebase. Track consistency, view a calendar history, and share access with your partner via a share code.

## Features

- 📅 Monthly calendar with poop indicators per day
- 💩 5 consistency types (Normal, Soft, Watery, Hard, Unusual)
- 👫 Shared baby — invite your partner with a 6-character code
- 🔐 Login with Google, Microsoft (Hotmail/Outlook), or email/password
- 🌐 Web + Android support

## Live App

**Web:** https://xnorbertx.github.io/potty-tracker/
**Android releases:** https://github.com/xNorbertx/potty-tracker/releases/latest

## Pull requests and automatic web deployment

Work on a feature branch and open a PR against `main`. The **Web checks and
deployment** workflow runs the existing tests and compiles a release web build
for each PR. PR checks use the example Firebase configuration and never deploy.
The browser-only authentication test is skipped by the standard test command;
the workflow does not claim browser integration-test coverage.

After a PR is merged into `main`, the workflow tests again, builds with the
production Firebase configuration, and publishes to GitHub Pages. A merge starts
the process; the site changes only when the deployment job succeeds. A failed
test or build prevents that run from deploying. Check the repository's Actions
tab or the `github-pages` deployment for progress and errors.

One-time repository configuration:

- Set the repository Actions secret `FIREBASE_OPTIONS_DART` to the contents of
  the configured local `lib/firebase_options.dart`. Keep that file out of Git.
- Under Settings > Pages, choose **GitHub Actions** as the publishing source.
- Allow branch `main` to deploy to the `github-pages` environment.

The workflow uses Flutter 3.27.4 and the committed dependency lockfile. Production
builds fail if the Firebase secret is missing. Firebase client settings are
necessarily embedded in the published web app; this is not a service-account
credential. Firebase security rules still control access to stored data.

After deployment, `/potty-tracker/version.txt` contains the deployed commit SHA.
Reload the app on your phone to pick up a new version. You can manually rerun the
workflow on `main` from Actions. To roll back, revert the problematic PR through
a new PR and merge it; the same pipeline then publishes the reverted code.

This pipeline deploys the web app only. It does not release Android APKs, change
Firebase Authentication settings, or change database contents. Firestore rules
have their own deployment workflow, described below.

## Setup

### Android release pipeline

The **Android checks and releases** workflow is independent of web deployment.
PRs run the tests and compile signed release APK and App Bundle (`.aab`) files
using placeholder Firebase settings and an ephemeral CI certificate. Those PR
builds are not published. After each successful build of merged `main`, the
production-signed APK, Play-uploadable AAB, and SHA-256 checksums are attached
to a new GitHub Release. Install the `.apk` directly on a phone; upload the
`.aab` to a Google Play test or production release. An AAB is not installed
directly and Play Store publishing does not automatically update sideloaded APKs.

The readable version comes from `pubspec.yaml` (starting at **1.3.0**, following
the existing 1.2.x releases). Android's numeric version code is
**100000 + this workflow's run number**. Each new run therefore has a higher
build number, including gaps caused by PR checks. Reruns retain the same number
and do not overwrite an existing release. Tags and filenames include both,
for example `android-v1.3.0-build.100007`. Do not delete/recreate this workflow or
change its counter scheme without preserving monotonically increasing codes.

Production builds require these repository Actions secrets:

| Secret | Contents |
| --- | --- |
| `FIREBASE_OPTIONS_DART` | Existing configured Dart Firebase options |
| `ANDROID_GOOGLE_SERVICES_JSON` | Firebase Android `google-services.json` |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded PKCS12 release keystore |
| `ANDROID_SIGNING_PASSWORD` | Keystore and key password (same value) |

The release key alias is `potty-tracker`. Missing secrets fail the production
build. Release builds never fall back to a debug signing key. Signing files are
ignored by Git and must not be committed. Keep a separate secure backup of the
keystore **and its password**: losing them prevents updates signed with this key.

This introduces a new release certificate. Uninstall the old debug-signed APK
once before installing the first new release. Future APKs use this stable key
and can update each other. Only cloud-synced diary entries survive reinstalling;
any unsynced local data may be lost.

For Google sign-in, register the release certificate's SHA-1 (and SHA-256) under
Firebase Project settings > Android app > SHA certificate fingerprints, then
download updated `google-services.json` and update its Actions secret. An APK
build passing does not verify real-device sign-in.

For a local signed release, create ignored `android/key.properties`:

```properties
storeFile=/absolute/path/to/release-v1.p12
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=potty-tracker
```

Then build with an explicit version code higher than any APK it must update:

```bash
flutter build apk --release --build-name 1.3.0 --build-number 100007
```

The pipeline verifies the APK signature, package ID, version code, launch
activity and internet permission. Each bundle has the same signing certificate
and version code as its paired APK. Device installation and authentication still
need a real-phone smoke test. Failed Android builds do not block web deployment.

### Prerequisites
- Flutter SDK 3.27+
- Firebase project with Firestore + Authentication enabled

### Firebase config

1. Copy `lib/firebase_options.dart.example` → `lib/firebase_options.dart` and fill in your values
2. Copy `android/app/google-services.json.example` → `android/app/google-services.json` and fill in your values
3. Get values from: [Firebase Console](https://console.firebase.google.com) → Project Settings → Your apps

### Auth providers to enable in Firebase

- Email/Password
- Google
- Microsoft

### Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /babies/{babyId} {
      allow read, update: if request.auth != null &&
        request.auth.uid in resource.data.memberUids;
      allow create: if request.auth != null;

      match /entries/{entryId} {
        allow read, write: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/babies/$(babyId)).data.memberUids;
      }
    }

    match /share_codes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

#### Automatic rule deployment

The **Deploy Firestore rules** workflow first compiles rule changes in the
Firestore Emulator for every PR. After a PR is merged into `main`, it deploys
the committed rules whenever `firestore.rules`, `firebase.json`, or `.firebaserc`
changes. It deploys rules only; it does not alter Firestore data.

One-time repository configuration is required. Create a service account in the
`baby-poop-tracker` Google Cloud project with the **Firebase Rules Admin** role,
create a JSON key for it, and store the complete key file as the repository
Actions secret `FIREBASE_RULES_SERVICE_ACCOUNT`. Do not commit that key file.
The workflow fails clearly, leaving the currently deployed rules unchanged, until
the secret is configured.

For an emergency manual deployment from an authenticated Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

### Run

```bash
flutter pub get
flutter run
```

### Build web

```bash
flutter build web --release --base-href /potty-tracker/
```

### Build Android APK

```bash
flutter build apk --release
```

## Local preview on Windows

The app can run directly from source in a desktop browser. Android Studio and
the Windows native build tools are not needed for this workflow.

### Start the preview

Double-click `start-local.cmd` in the project folder. It installs any missing
project dependencies, starts Flutter, and opens an available browser (Edge, then Chrome) at
**http://localhost:8080**. Keep the terminal window open while using the preview.
The first compilation takes longer than subsequent starts.
If neither browser is detected by Flutter, the launcher uses web-server mode and
prints the URL to open manually. To force a browser, pass `-Device edge` or
`-Device chrome`.

After saving source changes, focus the terminal and press **Shift+R** (capital
`R`) to hot restart the app. Press **q** to stop the preview. This project uses
Flutter 3.27.4, whose web workflow uses hot restart rather than state-preserving
hot reload.

The preview uses the Firebase project in your local `lib/firebase_options.dart`.
With the existing configuration, this is the same backend used by the deployed
app: signing in uses your normal account, and additions/deletions affect the
shared diary. Local preview does not deploy any code.

### Other browsers and ports

From PowerShell in the project directory:

```powershell
.\start-local.cmd -Device chrome
.\start-local.cmd -Device web-server
.\start-local.cmd -Device web-server -Port 8081
```

`web-server` lets you open the printed URL in your normal browser profile or
Codex's browser panel. After a source change, press `R` in the terminal and
refresh that browser tab. Edge/Chrome debug mode opens a separate browser session.
In Edge or Chrome, press F12 and then Ctrl+Shift+M to inspect a phone-sized layout.

### Flutter installation

The initial Windows setup uses Flutter **3.27.4** at `C:\repos\flutter-sdk`,
matching the revision recorded in this project's `.metadata`. The launcher looks
for the SDK next to the project in `flutter-sdk`, so no global PATH change is
required. You can also set `FLUTTER_ROOT`, use Flutter on PATH, or pass an explicit
SDK directory:

```powershell
.\start-local.cmd -FlutterSdk C:\tools\flutter
```

Keep `lib/firebase_options.dart` local and untracked. On another machine, follow
the Firebase configuration instructions above before starting the preview.

If port 8080 is already in use, open the existing preview or choose another port.
If Firebase sign-in reports `unauthorized-domain`, add `localhost` to the intended
Firebase project's Authentication > Settings > Authorized domains. This is a
Firebase configuration step, not a reason to change application code.

Flutter's browser development workflow is documented at
https://docs.flutter.dev/platform-integration/web/setup.

For browser-only development, you can disable Flutter's native Windows target
to avoid requiring Developer Mode for plugin symlinks:

```powershell
C:\repos\flutter-sdk\bin\flutter.bat config --no-enable-windows-desktop --enable-web
```

This is already configured on the initial Windows machine. If you later develop
a native Windows build, enable Developer Mode and run
`flutter config --enable-windows-desktop`.
