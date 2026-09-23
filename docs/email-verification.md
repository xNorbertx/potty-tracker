# Email verification and caregiver invitations

Every caregiver, including Google and Microsoft users, must open the Potty
Tracker verification email and confirm before issuing invitations. Firebase's
provider-supplied `emailVerified` flag does not satisfy this requirement.

The welcome email contains the link. Account settings and the locked invitation
area offer resend and status-check actions. Server-owned verification records
stream into the app; no sign-out is required. Logging and accepting an invitation
remain available to unverified accounts.

Links expire after 24 hours, are single-use, and are replaced by a resend. A
server-enforced one-minute cooldown prevents accidental resend bursts. A GET or
email preview does not verify an account: the confirmation button submits the
token. Tokens travel in the URL fragment and request body, not the URL query;
only their SHA-256 hashes are stored. Changed email addresses and disabled
accounts cannot redeem an older link. Verification records are removed by an
Auth deletion trigger when an account is deleted individually.

Legacy invite codes have no recorded sender and are no longer usable. Existing
diary membership is preserved. A verified member opens Invite a caregiver to
issue a fresh code bound to that caregiver. There is one active invitation per
baby; reopening one's own invitation retains its code, while issuance by a
different caregiver replaces it. Joining consumes the code. The automatically
rotated placeholder cannot invite anyone until a verified member issues it.
The Firestore rules also require the issuer still to be a member of the baby.

## Deployment and verification

The existing functions workflow deploys the welcome sender, resend callable,
verification HTTPS endpoint, invitation callable, and deletion trigger. It uses
the existing Resend secret. The runtime service account needs Firebase Auth
user-read and Firestore data permissions; no client can write verification
proofs or invitation issuer fields. Deploy both the functions and Firestore
rules before considering the feature operational. Separate web/rules/functions
workflows may briefly finish in different orders; invitation requests fail
closed while backend dependencies are unavailable.

Automated checks cover token expiry/replay, resend failure/throttling, SSO bypass,
issuer membership, legacy invitations, unverified joins, and live UI unlocking.
A production smoke test still needs a real mailbox: create an account, open the
welcome link, confirm, and observe invitations unlock on web/Android. Automated
tests do not send real emails or use production diary data.
