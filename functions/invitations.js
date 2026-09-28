const { randomInt } = require('node:crypto');
const { Timestamp } = require('firebase-admin/firestore');
const INVITATION_LIFETIME_MS = 7 * 24 * 60 * 60 * 1000;

function createInvitationService({ db, auth, now = Date.now }) {
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
        const blocked = await tx.get(db.collection('deletion_blocks').doc(uid));
        if (blocked.exists) throw new Error('not-verified');
        const babyRef = db.collection('babies').doc(babyId);
        const baby = await tx.get(babyRef);
        const proof = await tx.get(db.collection('verified_emails').doc(uid));
        if (!baby.exists || !baby.data().memberUids.includes(uid)) throw new Error('not-member');
        if (baby.data().diaryDeletionRequested) throw new Error('not-member');
        if (baby.data().consentVersion !== 1) throw new Error('consent-required');
        if (proof.data()?.email !== user.email) throw new Error('not-verified');
        const previousCode = baby.data().shareCode;
        const previousRef = previousCode ? db.collection('share_codes').doc(previousCode) : null;
        const previous = previousRef ? await tx.get(previousRef) : null;
        // Reopening your invitation keeps an already shared code usable.
        if (previous?.data()?.babyId === babyId && previous.data().issuedBy === uid &&
            previous.data().issuerEmail === user.email &&
            previous.data().expiresAt?.toMillis() > now() && !previous.data().consumedBy) {
          return previousCode;
        }
        const ref = db.collection('share_codes').doc(code);
        if ((await tx.get(ref)).exists) return null;
        // A client-created diary may contain a code belonging to another diary.
        if (previous?.data()?.babyId === babyId) tx.delete(previousRef);
        tx.set(ref, { babyId, issuedBy: uid, issuerEmail: user.email,
          expiresAt: Timestamp.fromMillis(now() + INVITATION_LIFETIME_MS) });
        tx.update(babyRef, { shareCode: code });
        return code;
      });
      if (result) return result;
    }
    throw new Error('code-collision');
  };
}

function createAcceptInvitationService({ db, auth, now = Date.now }) {
  return async (uid, input) => {
    const user = await auth.getUser(uid);
    if (user.disabled || !user.email) throw new Error('invalid-invitation');
    // Count failures too, in a separate transaction so a rejected join cannot
    // roll back the limit. Clients cannot read or reset this record.
    await db.runTransaction(async (tx) => {
      const blocked = await tx.get(db.collection('deletion_blocks').doc(uid));
      if (blocked.exists) throw new Error('invalid-invitation');
      const ref = db.collection('invitation_attempts').doc(uid);
      const previous = (await tx.get(ref)).data();
      const time = now();
      const recent = previous?.resetAt?.toMillis() > time;
      if (recent && previous.count >= 10) throw new Error('too-many-attempts');
      tx.set(ref, { count: recent ? previous.count + 1 : 1,
        resetAt: recent ? previous.resetAt : Timestamp.fromMillis(time + 10 * 60 * 1000) });
    });
    const code = typeof input === 'string' ? input.trim().toUpperCase() : '';
    if (!/^[A-Z2-9]{6}$/.test(code)) throw new Error('invalid-invitation');
    return db.runTransaction(async (tx) => {
      const invitationRef = db.collection('share_codes').doc(code);
      const invitation = (await tx.get(invitationRef)).data();
      if (!invitation?.issuedBy || !invitation.expiresAt ||
          invitation.expiresAt.toMillis() <= now()) throw new Error('invalid-invitation');
      const babyRef = db.collection('babies').doc(invitation.babyId);
      const baby = (await tx.get(babyRef)).data();
      const blocked = await tx.get(db.collection('deletion_blocks').doc(uid));
      if (blocked.exists || !baby || baby.diaryDeletionRequested || baby.deletionPending ||
          baby.consentVersion !== 1) throw new Error('invalid-invitation');
      // A lost response can be retried without consuming another invitation.
      if (invitation.consumedBy === uid && baby.memberUids.includes(uid)) return babyRef.id;
      if (invitation.consumedBy || baby.shareCode !== code ||
          !baby.memberUids.includes(invitation.issuedBy)) throw new Error('invalid-invitation');
      const issuerBlocked = await tx.get(db.collection('deletion_blocks').doc(invitation.issuedBy));
      const proof = (await tx.get(db.collection('verified_emails').doc(invitation.issuedBy))).data();
      let issuer;
      try { issuer = await auth.getUser(invitation.issuedBy); } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
      if (issuerBlocked.exists || !issuer || issuer.disabled ||
          issuer.email !== invitation.issuerEmail || proof?.email !== issuer.email) {
        throw new Error('invalid-invitation');
      }
      if (baby.memberUids.includes(uid)) return babyRef.id;
      const profile = (await tx.get(db.collection('caregiver_profiles').doc(uid))).data();
      const name = typeof profile?.name === 'string' && profile.name.trim()
        ? profile.name.trim().slice(0, 120) : 'Caregiver';
      tx.update(babyRef, { memberUids: [...baby.memberUids, uid],
        memberLabels: { ...baby.memberLabels, [uid]: name },
        memberEmails: { ...baby.memberEmails, [uid]: user.email }, shareCode: '' });
      tx.update(invitationRef, { consumedBy: uid });
      return babyRef.id;
    });
  };
}

module.exports = { createInvitationService, createAcceptInvitationService };
