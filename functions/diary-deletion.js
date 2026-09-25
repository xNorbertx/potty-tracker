const { FieldValue } = require('firebase-admin/firestore');

function createDiaryDeletionService({ db, auth }) {
  return async (uid, babyId) => {
    if (typeof babyId !== 'string' || !babyId || babyId.length > 128 || babyId.includes('/')) {
      throw new Error('invalid-baby');
    }
    const user = await auth.getUser(uid);
    if (user.disabled || !user.email) throw new Error('not-verified');
    await db.runTransaction(async (tx) => {
      const blocked = await tx.get(db.collection('deletion_blocks').doc(uid));
      const ref = db.collection('babies').doc(babyId);
      const baby = await tx.get(ref);
      const proof = await tx.get(db.collection('verified_emails').doc(uid));
      if (blocked.exists || proof.data()?.email !== user.email) throw new Error('not-verified');
      if (!baby.exists || !baby.data().memberUids.includes(uid)) throw new Error('not-member');
      if (baby.data().diaryDeletionRequested) return;
      // Rules immediately stop diary access and joining. Keep membership until
      // cleanup completes so a retried request from the same caregiver is safe.
      tx.update(ref, { diaryDeletionRequested: true, deletionRequestedAt: FieldValue.serverTimestamp() });
    });
  };
}

async function deleteRequestedDiary(db, ref) {
  const current = await ref.get();
  if (!current.exists || !current.data().diaryDeletionRequested) return;
  while (true) {
    const codes = await db.collection('share_codes').where('babyId', '==', ref.id).limit(200).get();
    if (codes.empty) break;
    const batch = db.batch();
    for (const code of codes.docs) batch.delete(code.ref);
    await batch.commit();
  }
  // Preserve the retry locator if any child deletion fails. Repeated/concurrent
  // deliveries, including account deletion, only repeat idempotent deletes.
  for (const collection of await ref.listCollections()) await db.recursiveDelete(collection);
  await ref.delete();
}

module.exports = { createDiaryDeletionService, deleteRequestedDiary };
