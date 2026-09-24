# Account deletion operations

Deleting a Firebase Auth user triggers `deleteEmailVerification` (the existing
deployed name, now responsible for all account cleanup). The app calls Auth
deletion first, so `requires-recent-login` cannot remove diary data beforehand.
The user can sign out, sign back in, and retry after that error.

The retryable server worker removes profiles, email proofs, verification tokens,
personal invitations, membership details, ownership references and entry author
fields, including in diaries previously left. Shared diary contents survive.
Membership/ownership changes use current data in transactions. A last-member
diary is marked with an internal retry locator before its subcollections and
parent are deleted. Retries do not recreate entries or clear new authorship.

`deletion_blocks/{uid}` prevents a deleted account's still-valid ID token from
reading or writing data. Its `expiresAt` is two hours after the worker starts;
Firestore TTL then removes it, generally within a day after expiry (not an exact
deadline). It contains only that expiration and the UID in its document path.
An interrupted retry can extend the period. The public policy discloses this
temporary security record. Clients cannot read, write or delete it.

## Deploy and monitor

1. Deploy `firestore.rules` and `firestore.indexes.json`, including the two
   collection-group indexes and TTL policy, before/with the deletion trigger.
2. Confirm indexes are ready and TTL is enabled in the live Firestore console.
   Index building is asynchronous; the retry policy handles an initial query
   failure but is not a substitute for confirming readiness.
3. Deploy the Auth trigger with retries enabled; keep its existing name to avoid
   duplicate workers. The functions workflow deploys the prerequisite rules and
   indexes before updating it.
4. Test with synthetic accounts. Check both a shared and sole-caregiver diary,
   profile removal and author scrubbing. Monitor errors for this function and
   `deletionPending` records. Escalate any cleanup which does not complete;
   event retries are finite, so failures must not be ignored indefinitely.

## Handling an email request

Verify control of the account's email address; a matching From header alone is
not proof. Use a fresh challenge sent to the registered address or an equivalent
authenticated verification. Never ask for a password. If email access is lost,
handle ownership verification individually and avoid disclosing diary data.

After verification, locate the exact user in Firebase Authentication and delete
that **single user**. The server trigger handles database cleanup. Do not use
Admin SDK `deleteUsers()` bulk deletion: Firebase does not emit per-user deletion
events for that API. Confirm cleanup before telling the requester it is complete.
Respond separately to requests to remove identifying text from retained shared
notes, support emails or provider logs; automated cleanup removes structured
author details, not arbitrary text or previously exported files.

Local test command (Node 20+, Java 21 for the current emulator):

```sh
npx firebase-tools@15.30.1 emulators:exec --only firestore --project demo-potty-tracker "npm --prefix firestore-tests test && npm --prefix functions test"
```

The deletion integration tests skip when no emulator is set. CI runs them inside
the emulator and includes retries, former memberships, 500+ entries, stale-token
blocking and concurrent deletion of both remaining caregivers.
