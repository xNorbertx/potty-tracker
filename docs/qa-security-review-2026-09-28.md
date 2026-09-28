# App QA and security review — 28 September 2026

Testing uses fictional accounts and diaries in local Firebase Auth, Firestore
and Functions emulators. No production diary was created, edited or deleted.
This is an application review and regression pass, not a guarantee against all
attacks or an independent penetration-test certification.

## Findings fixed

| Finding | Evidence and correction |
| --- | --- |
| A leaving caregiver could remove another member | Reproduced a rules write changing `[a,b,c]` to `[b,b]`. Rules now require exactly the other members, preserve their metadata, and remove only the caller's metadata. The client uses atomic removal, avoiding stale membership overwrites. |
| Malformed shared records could crash another caregiver's view | Reproduced an object written into a diary's name. Rules now validate names, profile fields, entry types/enums, dates and text limits. Normal/legacy updates have positive regression coverage. |
| Direct invitation lookup exposed records and permitted unlimited guesses | Acceptance now runs in an authenticated callable. Records are private, codes expire after seven days, and failed attempts count toward ten attempts per account per ten minutes. Atomic consumption prevents two winners; a lost-response retry is safe. |
| Old invitation proof could outlive the issuer's email/account status | Acceptance checks live Auth email, enabled status, verification proof, deletion block and membership. Unverified recipients can still join. |
| Crafted diary code could affect another diary's invitation | Issuance only reuses/deletes a previous code whose record belongs to that diary. New diaries have no client-created invitation. |
| Joining the first diary could replace the dialog's launching widget before completion | A dedicated dialog owns its pending/error state and closes independently. Repeated taps are ignored; throttling is shown inline. |
| Native Microsoft sign-in used a web-only method | Native sign-in now uses Firebase's provider flow. Real-device OAuth testing remains required. |
| Future-time saves and asynchronous dialog errors | Future timestamps are rejected in the form and constrained by rules. Password submission cannot be dismissed mid-flight; reset-email continuation checks whether its screen still exists. |
| Outdated backend dependencies | Updated Firebase Admin/Functions and the Node runtime to 22. A scoped compatible uuid override removes the remaining transitive advisory. Production npm audit reports zero known vulnerabilities at review time. |

## Manual browser coverage

The actual Flutter app ran at a 360 × 780 viewport with the local backend.

- Sign-in required-field validation, registration password mismatch, successful
  registration, profile validation/setup, and persistence after reload.
- Empty home, consent required before creation, successful first diary creation
  and immediate loading without refresh.
- Calendar previous-month navigation, month/year chooser, previous-year jump,
  February selection, Today return, disabled future month/year/day navigation.
- Missing-consistency validation; logging consistency, size, colour and notes;
  literal HTML-like text and accented text remain plain diary content.
- Saving the seventh consecutive day displays the achievement celebration only
  after saving. Overview shows one earned 7-day badge and locked 14/30 badges.
- Editing a saved log changes its content without another entry or celebration.
- Baby list has no delete action; detail contains its danger zone. Unverified
  deletion opens verification guidance; verified deletion shows a warning.
  Cancellation preserves the diary. Account deletion cancellation also works.
- Profile name cannot be empty and a successful name change updates the screen.
- Multiple diaries and a long baby name: fixed centered switcher, truncated
  title, wrapped list label and correct empty state after switching diaries.
- Verified invitation creation and one-use/expiry notice; invalid-code feedback;
  successful acceptance with a lowercase code surrounded by spaces. The
  unverified guest sees the shared calendar/badge immediately, with invitations
  still verification-gated. The dialog closes without a refresh.
- Weekly PDF downloaded and visually rendered: seven daily bars, seven logs,
  expected consistency/size/colour counts and legible page layout.

Permanent deletion and credential changes are exercised programmatically with
synthetic data rather than confirming destructive actions in the browser.

## Automated and protocol coverage

- Flutter suite: 94 passed, one existing browser-only test skipped. Includes
  7/14/30-day thresholds, repeated streaks, backfills/deletions, DST/leap/year
  boundaries, consent acknowledgement races, permissions, navigation, loading
  failures, save/celebration failure separation and the new join-dialog cases.
- Firestore emulator: 19 permission tests passed, including outsiders, deleted
  tokens, forged verification, invalid fields, direct joins, concurrent-safe
  leave constraints and normal/legacy data compatibility.
- Backend suite with Firestore emulator: 21 passed, including token expiry and
  replay, resend throttling, invitation expiry/guess limits/concurrency,
  shared-account anonymization, last-caregiver deletion, multi-batch cleanup,
  interrupted deletion retries and simultaneous caregiver deletion.
- Local unauthenticated HTTP requests to invitation issuance, acceptance and
  diary deletion all return 401. Production email delivery was not invoked.

## Limits and follow-up

- Android installation, microphone/voice commands, real Google/Microsoft OAuth,
  native sharing and real-mailbox delivery remain device/provider smoke tests.
  The local harness deliberately excludes email-sending functions.
- Per-account invitation limits do not prevent an attacker creating many
  accounts. App Check/provider anti-abuse settings and usage/billing alerts
  require a separate deployment configuration review; they are not claimed as
  enabled. No high-volume or denial-of-service test was run.
- PDFs still use the existing built-in Latin font. Non-Latin baby names need a
  bundled Unicode font before full international text coverage can be claimed.
- Old invitation codes without an expiry must be regenerated. Older clients
  must refresh/update for server-based joining and new-diary creation. Existing
  membership is preserved. Deploy app, rules/indexes and functions together;
  mismatched versions fail closed while the separate workflows finish.

## Reproduce the isolated manual environment

Use Node 22+, Java 21, Flutter 3.27.4 and the Firebase CLI. Install dependencies
in `functions`, `firestore-tests`, and `tool/qa-functions` (`npm install` for the
small QA harness). On Windows a node_modules junction from the harness to the
installed functions dependencies also works.

```sh
firebase emulators:start --config firebase.qa.json --project demo-potty-tracker --only auth,firestore,functions
flutter run -d web-server -t tool/security_preview.dart --web-port 8096
```

The harness refuses non-emulator/non-demo execution. Create
`qa-owner@example.test` and `QA Ada` through the app. The optional `qa-data.cjs`
fixture helper requires both `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` and
`FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`; commands are `inspect`, `seed`
(six preceding days), `verify` (synthetic proof) and `extra` (guest/long name).
Unit-test projects are separate from manual fixtures.
