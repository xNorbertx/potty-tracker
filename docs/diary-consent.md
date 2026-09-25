# Diary consent and deletion

## Product behavior

The diary creator explicitly confirms parent/guardian authority or their explicit
permission, and consents to storing the child's health diary and sharing it with
caregivers invited to it. The checkbox is never preselected. This is a declaration,
not an ID or guardianship check. Version 1 text lives in `diary_consent.dart`.

The baby record stores `consentVersion: 1`, `consentBy` (the signed-in UID), and
`consentAt` (server time). Rules require these on creation and prevent clients
from rewriting consent. Existing diaries require the current owner to confirm
once. If the recorded owner has already left, a remaining member can confirm.
Until then, entry/achievement reads, writes and invitations are blocked; account
settings, leaving a shared diary, deletion and support remain available. The
consent version and time remain on shared diaries after account deletion, but
the deleted account's `consentBy` reference is removed, even on previously left
diaries. Entries do not identify the deleted caregiver afterward.

Any current caregiver may delete the entire diary after verifying their current
email through the app's verification link. Ownership is not required. The app
fetches current membership for the confirmation, which names the diary and the
number of other caregivers. Cancel is a no-op. Verification failures offer
resend/check status and support; support requests do not require app verification.
Delete for everyone is distinct from Leave diary and Delete account.

## Server enforcement and retries

`deleteCaregiverDiary` checks the current Auth user, disabled status, app email
proof, deletion block and current membership. It sets the server-only
`diaryDeletionRequested` flag and a server timestamp transactionally. An accepted
request is idempotent while the diary exists. Missing/departed membership fails.
Neither an SSO email-verified claim nor an old verified email grants permission.

Firestore rules immediately deny entries/achievements and all diary changes
while deletion is pending. They reject new codes and joins. The invitation
function also checks this flag. The parent remains readable to its current
members so the UI can remove the diary from lists and show an unavailable state.
Whole-parent deletion and writing the deletion flag are server-only; old clients
cannot skip verification or delete the parent before nested data is cleaned up.

`finishDiaryDeletion` retries failed update events. It removes every matching
invitation and recursively deletes subcollections before deleting the parent.
This preserves a retry locator after partial failure. It does not delete Auth
accounts, caregiver profiles or other diaries. Existing exported/device-cached
copies cannot be remotely recalled.

## Rollout and operations

- Deploy rules and functions, including `deleteCaregiverDiary` and
  `finishDiaryDeletion`, with the new app. Older clients need updating to create
  diaries or confirm missing consent. Do not backfill consent automatically.
- Monitor pending `diaryDeletionRequested` documents and function failures.
  Retries are finite: investigate requests that do not complete and rerun the
  same cleanup after fixing the failure. Do not delete the parent manually first.
- For support requests, verify account/diary authority proportionately. A From
  header alone is insufficient. Do not routinely collect ID documents. Escalate
  disputed authority for individual review rather than treating an app role as
  proof of guardianship. Never require a requester to delete their entire account
  merely to remove one diary or exercise a child's rights.
- Keep the existing Auth deletion workflow: shared diaries stay without the
  deleted person's identifying details; the last caregiver's account deletion
  removes the diary even if their email is unverified.

## Validation

Flutter tests cover unchecked consent, refusal without writes, invited-caregiver
deletion, cancel, unverified/support UI and retry after failure. Emulator tests
cover server permission checks, consent rules, immediate access/join blocking,
500+ records, nested collections, retries, preservation of unrelated records and
consent-identity cleanup. Finish the signed Android checks with synthetic data
listed in `play-launch-next-steps.md` before Play submission.
