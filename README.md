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
