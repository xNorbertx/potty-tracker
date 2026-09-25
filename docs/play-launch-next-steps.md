# Play launch: remaining operator steps

Updated 25 September 2026.

## Confirmed decisions

- Norbert Bakker operates Potty Tracker as an individual from Sweden.
- A personal Google Play developer account has been created.
- Add affirmative, recorded consent for each child's health diary, including
  existing diary owners. A privacy-policy link alone is not consent.
- Support correspondence: delete 90 days after the conversation closes, unless
  a specific legal obligation requires a documented exception.
- Configurable technical logs: 30 days. Separately document provider exceptions.
- Real Android testing is deferred until the weekend; no reminder is scheduled.

## Draft message for Google Play support — not sent

Subject: Account type and health declaration for a caregiver diary

Hello,

I am Norbert Bakker, an individual developer operating from Sweden. I have a
personal Play Console developer account and am preparing a free app called
Potty Tracker for adult parents and caregivers, in the Parenting category.

The app records a child's bowel movements (date, time, consistency, optional
colour, size and notes), shows a calendar and streaks, and allows invited
caregivers to share the diary. Data is stored using Firebase Authentication and
Firestore. It does not diagnose conditions, recommend treatment, conduct human
subjects research, connect to medical devices or use Health Connect.

Your account-type guidance says health apps should use an organization account.
Does this observational caregiver diary require an organization account, or
can it be published through my personal account? Which category should I select
in the Health apps declaration for these features and health data?

If an organization account is required, what is the appropriate route for an
individual developer in Sweden who is not operating a company?

Thank you,
Norbert Bakker

Send through Play Console → Help. Keep Google's answer with the launch records.
Do not classify the app as having no health data to avoid this question.

## Weekend Android check

Use a dedicated test account and a fictional child; never use a real family
diary to test deletion. Use the final signed build intended for Play testing.

1. Install and launch; check Google and Microsoft sign-in and email/password.
   Test the build delivered by Play as well: its signing certificate can differ
   from a locally installed APK.
2. Create a diary, check consent is initially unselected, and read the policy
   link. Confirm creation records consent only after an affirmative action.
3. Log/edit/delete entries, navigate calendar months/years and switch diaries.
   Compare the store screenshot drafts with the actual Android appearance.
4. Receive the verification email. Before verification, invitations must fail;
   after verification, invite a second test caregiver and join from their account.
5. Check sharing and a PDF export. Make sure no unexpected permission prompts
   appear. Keep the merged-manifest audit with this build.
6. Delete one shared caregiver account: preserve the diary for the other
   caregiver and remove the deleted caregiver's identifying fields. Test a
   stale sign-in session too: a reauthentication failure must not delete data.
7. Delete the last caregiver account: confirm the diary and nested data disappear.
8. Test the agreed consent-withdrawal flow after its implementation is approved
   and deployed; verify both caregivers' access and server cleanup.

Record build/version, device/Android version, date, pass/fail and any screenshots
using fictional data. Resolve failures before completing the Play forms.

## Submission status

Nothing in this document submits a listing, opens a support ticket, changes the
developer account type or completes provider settings. The account-type answer,
actual provider retention audit, consent rollout and native Android checks remain
launch prerequisites. Check the Console's testing/identity requirements for this
particular personal account before estimating a production release date.

Sources:
- [Google: account types](https://support.google.com/googleplay/android-developer/answer/13634885)
- [Google: health declaration](https://support.google.com/googleplay/android-developer/answer/14738291)
