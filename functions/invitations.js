const { randomInt } = require('node:crypto');

function createInvitationService({ db, auth }) {
  return async (uid, babyId) => {
    if (typeof babyId !== 'string' || !babyId || babyId.length > 128 || babyId.includes('/')) {
      throw new Error('invalid-baby');
    }
    const user = await auth.getUser(uid);
    if (!user.email || user.disabled) throw new Error('not-verified');
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join('');
      const result = await db.runTransaction(async (tx) => {
        const babyRef = db.collection('babies').doc(babyId);
        const baby = await tx.get(babyRef);
        const proof = await tx.get(db.collection('verified_emails').doc(uid));
        if (!baby.exists || !baby.data().memberUids.includes(uid)) throw new Error('not-member');
        if (proof.data()?.email !== user.email) throw new Error('not-verified');
        const previousCode = baby.data().shareCode;
        const previousRef = previousCode ? db.collection('share_codes').doc(previousCode) : null;
        const previous = previousRef ? await tx.get(previousRef) : null;
        // Reopening your invitation keeps an already shared code usable.
        if (previous?.data()?.issuedBy === uid && previous.data().issuerEmail === user.email) {
          return previousCode;
        }
        const ref = db.collection('share_codes').doc(code);
        if ((await tx.get(ref)).exists) return null;
        if (previousRef) tx.delete(previousRef);
        tx.set(ref, { babyId, issuedBy: uid, issuerEmail: user.email });
        tx.update(babyRef, { shareCode: code });
        return code;
      });
      if (result) return result;
    }
    throw new Error('code-collision');
  };
}

module.exports = { createInvitationService };
