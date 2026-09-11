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
**Android APK:** https://github.com/xNorbertx/potty-tracker/releases/latest

## Setup

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
