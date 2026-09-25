# Google Play disclosure worksheet

Updated 25 September 2026. These are reviewable answers based on the repository,
not a submitted Play Console declaration or a guarantee of approval.

## Identity and links

- App: **Potty Tracker**
- Operator: **Norbert Bakker**, an individual operating from **Sweden**
- Contact: **support@potty-tracker.com**
- Privacy: https://xnorbertx.github.io/potty-tracker/privacy/
- Account/data deletion: https://xnorbertx.github.io/potty-tracker/delete-account/

Use the existing GitHub Pages host until the custom domain has web hosting and
HTTPS configured. The email domain alone does not host a website. Both pages are
plain public HTML, require no account, and are included in the web deployment.

## Data Safety draft

Data leaves the device and is stored in Firebase. Answer **Yes** to collection.
Do not mark stored account or diary records as ephemeral. Encryption in transit:
**Yes**, for the app/backend connections. Account deletion: **Yes**, using both
the in-app option and the public request page after the cleanup deployment is verified.
The app does not have an independent security review certification.

| Data type | Evidence | Required/optional | Purposes |
| --- | --- | --- | --- |
| Personal info → Name | Caregiver profile; child diary name; SSO display name | Required to set up the diary; a nickname can be used | App functionality, account management |
| Personal info → Email address | Firebase Auth, caregiver membership, entry attribution, verification emails | Required for an account | Account management, app functionality, developer communications, fraud prevention/security |
| Personal info → User IDs | Auth UID, SSO identifiers, membership, ownership, entry/celebration attribution | Required | Account management, app functionality, security |
| Health and fitness → Health info | Poop dates/times, consistency, optional colour/size and health notes | Optional: users choose to add diary entries; note mandatory fields within an entry | App functionality |
| App activity → Other user-generated content | Optional free-text notes | Optional | App functionality |
| App activity → App interactions | Backend function name/request information for verification and invitations; celebration records | Some generated automatically when using the relevant feature | App functionality, security |
| Device or other IDs | SDK/security identifiers, Firebase callable messaging token if available | Verify the final native SDK's actual behaviour; do not assert absence just because FCM is not directly declared | App functionality, security |

Firebase also receives IP addresses and SDK/platform/user-agent information.
Resolve the final form mapping for these fields against installed SDK versions;
an IP address does not mean the app requests GPS or derives location. Do not
check approximate location solely because a connection has an IP address.
Check whether federated profile-photo URLs or other optional provider fields
are retained by Firebase Auth even though the app does not display them.
Passwords are handled by Firebase Authentication, not stored in diary documents.

### Collection versus sharing

The privacy policy names Firebase/Google, Resend, Zoho and GitHub Pages regardless
of how Play's sharing exceptions apply. Transfers to processors acting on the
operator's behalf may qualify for the service-provider exception. Caregiver
access and PDF export are user-initiated features, but confirm that the disclosure
and consent requirements for that exception are met before answering **No** to
sharing. If they are not met, declare the corresponding shared data types. Never
describe the app as having no third-party processing.

Email sent to support is an external support channel, not an in-app email reader.
Do not declare access to users' mailboxes, contacts or SMS on that basis. No
advertising, payments, analytics or crash-reporting SDK is declared in pubspec.
This does not exclude infrastructure/security logs or automatic SDK metadata.

## Target audience and content rating

- Intended audience: **18 and over**, adult parents/caregivers. Data *about* a
  child does not mean the app is designed for the child to use.
- Do not enable the separate Restrict Minor Access setting merely because the
  target audience is adult. Check current category-specific requirements.
- Complete the IARC questionnaire; do not manually promise Everyone or PEGI 3.
- No violence, sexual content, gambling, purchases or advertisements in the app.
- There is private exchange of user-written diary notes among invited caregivers.
  Answer any user-interaction/content-sharing question according to its exact
  wording; do not answer "no user-generated content" simply because it is private.
- Poop illustrations and bodily-function references must be assessed using the
  actual questionnaire's wording. Never hide them to obtain a lower rating.

## Health declaration and launch decisions still requiring review

The app records health information even though its store category is Parenting.
Complete the Health apps declaration; do not select "no health features" without
resolving Google's classification. It records observations and does not diagnose,
recommend treatment or connect to a medical device. Confirm the appropriate
record-keeping category with Play support if the form has no matching option.

**Account-type gate:** Google's account-type guidance says developers providing
health apps should choose an organization account. Norbert operates from Sweden as
an individual and has created a **personal** developer account. Obtain clarification from Google on this app's classification
before committing to a personal-account Play launch; a Parenting category is not
an exemption. No organization or D-U-N-S details have been invented or submitted.

**Privacy/legal review before public Play launch:** confirm the lawful bases for
account/support processing and the appropriate condition and explicit consent
for a child's health data, including who can authorise it. The app now has an affirmative, per-diary health-data consent flow with version,
account ID and server time, including a one-time confirmation for existing diaries.
It records a declaration, not verified guardianship. The Delete diary action is
available to every current caregiver with app email proof; support remains
available without that proof. Review the wording and legal bases before launch. Also review applicable country requirements;
"all available countries" is the intended distribution, not completed clearance.

**Retention review:** the operator approved 90 days after closure for support
mail and 30 days for configurable technical logs. This is a policy decision, not
evidence that provider settings have been changed. See `data-retention.md` for
the operating procedure and provider exceptions. Verify Firestore region, backups/PITR, Cloud Logging retention,
Firebase Auth security retention, Resend delivery retention and Zoho support-mail
retention against the actual accounts. The public policy describes these without
inventing exact deletion deadlines. Set and document an operational support-mail
retention period and request handling procedure before submission. Check data-
processing terms and international-transfer arrangements for each provider.

## Android permissions and SDK audit

Source manifest requests INTERNET. connectivity_plus observes network state;
printing uses Android's print/share UI; url_launcher opens the public policy.
No camera, microphone, contacts, SMS, precise location, advertising ID, Health
Connect, photo-library or broad storage access is intentionally used. Inspect
the **merged release manifest**, not just source, for transitive permissions.
The Android CI artifact `android-permission-audit` contains the built APK's
permissions and badging. Repeat this check after dependency changes.

The release-mode PR build at commit `da2ff6f` was inspected on 24 September 2026
(CI run 36055891578). Its merged manifest requests INTERNET, ACCESS_NETWORK_STATE,
WAKE_LOCK, com.google.android.c2dm.permission.RECEIVE,
com.google.android.providers.gsf.permission.READ_GSERVICES, and the app's own
DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. The exact output is retained in
`store/android-permissions.txt`. The Google messaging/service permissions are
transitive SDK permissions, despite the absence of an app notification feature;
include this evidence in the Firebase identifier/token review. No dangerous
runtime permission or advertising-ID permission appears in that manifest.

Before Play submission, verify actual Google and Microsoft sign-in on a signed
Android build, including Play signing fingerprints, and verify deletion with a
dedicated synthetic account. Do not test deletion against a real family diary.

## Operator follow-up

See `play-launch-next-steps.md` for the unsent Google support draft and weekend
Android test checklist. The operator approved deletion by any current caregiver
with a verified email, with explicit confirmation that it removes the diary for
everyone. See `diary-consent.md` for behavior and rollout checks.

## Sources

- [User data and privacy policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Data Safety definitions](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Firebase Android data disclosure](https://firebase.google.com/docs/android/play-data-disclosure)
- [Target audience](https://support.google.com/googleplay/android-developer/answer/9867159)
- [Content ratings](https://support.google.com/googleplay/android-developer/answer/9898843)
- [Health declaration](https://support.google.com/googleplay/android-developer/answer/14738291)
- [Developer account types](https://support.google.com/googleplay/android-developer/answer/13634885)
