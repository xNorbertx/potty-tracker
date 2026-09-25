# Retention operations

Policy approved by Norbert Bakker on 25 September 2026. Provider account settings
have **not yet been inspected or changed** as part of this record. Documented
provider defaults are not evidence of this project's actual configuration.

## Support mail: 90 days after closure

Owner: Norbert Bakker. Applies to support@potty-tracker.com in Zoho EU, including
sent replies and attachments, not only Inbox messages.

- Mark the conversation closed with its closure date and deletion due date
  (closure + 90 days). Reopening a case establishes a new closure date.
- Use a dedicated closed-support folder and a due-date register with only the
  minimum identifier needed to find the conversation. Do not copy message bodies
  or health information into the register.
- Delete due conversations and their attachments from Inbox/archive, Sent and
  Trash. Account for mailbox exports and any separately saved attachments.
- If the current Zoho plan supports suitable retention rules, configure and
  verify them. Otherwise this requires manual processing by the due date;
  merely moving mail to a folder does not implement retention.
- Remove unnecessary child-health details as soon as practical rather than
  waiting for the maximum period. Ask users not to email full diaries unless
  necessary for the particular request.
- For a legal exception, record the specific obligation, minimum records needed,
  access restriction and a review/end date. Do not retain every case indefinitely
  under a general “legal reasons” label.
- A resolved deletion request may retain only the minimum necessary resolution
  record for its applicable period; do not keep a copy of the deleted diary.

No mailbox purge or automatic rule has been performed. The operator must put
this process into operation; app deployment does not configure Zoho.

## Technical and provider records

| System | Agreed treatment / documented provider behavior | Account audit still needed |
| --- | --- | --- |
| Google Cloud Logging | Set configurable application log buckets to 30 days. Google's `_Default` bucket defaults to 30 days; `_Required` audit logs use a nonconfigurable 400 days. | List all buckets and sinks for `baby-poop-tracker`, actual retention, locks and exports. Check exported destinations separately. |
| Firebase Authentication | Google documents logged IP addresses retained for a few weeks; other authentication information is removed from live and backup systems within 180 days after customer-initiated user deletion. | Confirm services used and reflect this exception accurately; a 30-day application-log setting does not override it. |
| Resend | Published Free/Pro/Scale retention is 30 days for email/log data while the account is active. | Confirm the actual plan/settings and any webhook/archive copies; do not send diary content in verification emails. |
| Firestore | Live data follows diary/account deletion. Temporary deleted-user token blocks expire after two hours plus asynchronous TTL removal. | Record database region, PITR setting, backup schedules/retention and exports. Do not assume none exist from repository configuration. |
| Zoho Mail | Support mailbox follows the 90-day closure rule above. | Verify available retention controls, Trash behavior, backups and provider deletion terms. |
| GitHub Pages | Hosts public assets/policies, not the Firestore diary database. | Record applicable hosting access/security-log terms; avoid a blanket 30-day promise about provider records. |

Do not log diary contents, email-verification tokens, credentials or support
messages. Review logging whenever adding a backend feature. For each provider,
record the audit date, verified settings, data-processing terms and applicable
international-transfer safeguards in restricted operator records, without secrets.

The public policy must distinguish the operator's retention policy from provider
exceptions and pending configuration. Do not claim a completed audit or automatic
90-day deletion until evidenced.

Sources checked 25 September 2026:
- [Cloud Logging: buckets and retention](https://docs.cloud.google.com/logging/docs/store-log-entries)
- [Firebase privacy: Authentication](https://firebase.google.com/support/privacy)
- [Resend GDPR and retention](https://resend.com/security/gdpr)
- [IMY: sensitive personal data](https://www.imy.se/verksamhet/dataskydd/det-har-galler-enligt-gdpr/introduktion-till-gdpr/personuppgifter/kansliga-personuppgifter/nar-far-ni-behandla-kansliga-personuppgifter/)
