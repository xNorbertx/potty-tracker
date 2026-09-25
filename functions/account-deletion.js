const { FieldValue, Timestamp } = require('firebase-admin/firestore');

// The Auth deletion event is retried on failure. Every step must be repeatable,
// including a crash after detaching the last member but before deleting a diary.
function createAccountDeletionService({ db, now = Date.now }) {
  async function drain(query, operation) {
    while (true) {
      const page = await query.limit(200).get();
      if (page.empty) return;
      const batch = db.batch();
      for (const doc of page.docs) operation(batch, doc.ref);
      await batch.commit();
    }
  }

  async function detach(ref, uid) {
    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      const baby = snapshot.data();
      const members = (baby.memberUids || []).filter((id) => id !== uid);
      const labels = { ...baby.memberLabels };
      const emails = { ...baby.memberEmails };
      delete labels[uid];
      delete emails[uid];
      tx.update(ref, {
        memberUids: members,
        memberLabels: labels,
        memberEmails: emails,
        ownerUid: baby.ownerUid === uid ? (members[0] || '') : baby.ownerUid,
        // Keep a retry locator until recursive deletion has completed.
        ...(members.length === 0 ? { deletionPending: uid, shareCode: '' } : {}),
      });
    });
  }

  return async function deleteAccountData(uid) {
    // A deleted Auth user's previously issued ID token can still be valid for
    // an hour. Block it before removing data; TTL discards this security record.
    await db.collection('deletion_blocks').doc(uid).set({
      expiresAt: Timestamp.fromMillis(now() + 2 * 60 * 60 * 1000),
    });
    const privateData = db.batch();
    for (const collection of ['caregiver_profiles', 'verification_requests', 'verified_emails']) {
      privateData.delete(db.collection(collection).doc(uid));
    }
    await privateData.commit();

    await drain(db.collection('share_codes').where('issuedBy', '==', uid),
      (batch, ref) => batch.delete(ref));

    // Query live membership, not the possibly stale list on the settings screen.
    // Also repair ownership left behind by a caregiver who previously left.
    for (const query of [
      db.collection('babies').where('memberUids', 'array-contains', uid),
      db.collection('babies').where('ownerUid', '==', uid),
    ]) {
      while (true) {
        const page = await query.limit(100).get();
        if (page.empty) break;
        for (const baby of page.docs) await detach(baby.ref, uid);
      }
    }

    while (true) {
      const pending = await db.collection('babies')
        .where('deletionPending', '==', uid).limit(100).get();
      if (pending.empty) break;
      for (const baby of pending.docs) {
        await drain(db.collection('share_codes').where('babyId', '==', baby.id),
          (batch, ref) => batch.delete(ref));
        // recursiveDelete(document) may delete the parent even if children fail.
        // Preserve our retry locator until every subcollection is gone.
        for (const collection of await baby.ref.listCollections()) {
          await db.recursiveDelete(collection);
        }
        await baby.ref.delete();
      }
    }

    // Keep consent version/date on shared diaries without the deleted identity.
    await drain(db.collection('babies').where('consentBy', '==', uid),
      (batch, ref) => batch.update(ref, { consentBy: FieldValue.delete() }));

    // Collection-group queries include diaries the caregiver left earlier.
    // Transactions avoid recreating a concurrently deleted entry or erasing a
    // new attribution after another caregiver edits it.
    for (const collection of ['entries', 'achievement_celebrations']) {
      while (true) {
        const page = await db.collectionGroup(collection)
          .where('loggedBy', '==', uid).limit(100).get();
        if (page.empty) break;
        for (const doc of page.docs) {
          await db.runTransaction(async (tx) => {
            const latest = await tx.get(doc.ref);
            if (!latest.exists || latest.data().loggedBy !== uid) return;
            tx.update(doc.ref, {
              loggedBy: FieldValue.delete(),
              loggedByName: FieldValue.delete(),
              loggedByEmail: FieldValue.delete(),
            });
          });
        }
      }
    }
  };
}

module.exports = { createAccountDeletionService };
