const { test, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { createAccountDeletionService } = require('./account-deletion');
const { createDiaryDeletionService, deleteRequestedDiary } = require('./diary-deletion');
const { createInvitationService } = require('./invitations');

const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let app, db, remove;
before(() => {
  if (!enabled) return;
  app = initializeApp({ projectId: 'demo-potty-tracker' }, 'deletion-tests');
  db = getFirestore(app);
  remove = createAccountDeletionService({ db });
});
afterEach(async () => {
  if (!enabled) return;
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
});
after(async () => { if (enabled) await deleteApp(app); });
const integration = (name, run) => test(name, { skip: !enabled }, run);

integration('diary deletion requires current app proof and current membership, not ownership or an SSO flag', async () => {
  const ref = await diary('shared', ['gone', 'stays']);
  const user = { email: 'stays@example.com', emailVerified: true };
  const request = createDiaryDeletionService({ db, auth: { getUser: async () => user } });
  await assert.rejects(request('stays', ref.id), /not-verified/);
  await db.collection('verified_emails').doc('stays').set({ email: 'old@example.com' });
  await assert.rejects(request('stays', ref.id), /not-verified/);
  await db.collection('verified_emails').doc('stays').set({ email: user.email });
  user.disabled = true;
  await assert.rejects(request('stays', ref.id), /not-verified/);
  user.disabled = false;
  await db.collection('deletion_blocks').doc('stays').set({ blocked: true });
  await assert.rejects(request('stays', ref.id), /not-verified/);
  await db.collection('deletion_blocks').doc('stays').delete();
  await db.collection('verified_emails').doc('stranger').set({ email: user.email });
  await assert.rejects(request('stranger', ref.id), /not-member/);
  await assert.rejects(request('stays', '../bad'), /invalid-baby/);
  assert.equal((await ref.get()).data().diaryDeletionRequested, undefined);
  await request('stays', ref.id); // Invited caregiver, not the owner.
  const first = (await ref.get()).data();
  assert.equal(first.diaryDeletionRequested, true);
  assert.ok(first.deletionRequestedAt.toMillis());
  await request('stays', ref.id);
  assert.deepEqual((await ref.get()).data(), first);
  await assert.rejects(createInvitationService({ db, auth: { getUser: async () => user } })('stays', ref.id), /not-member/);
});

integration('requested deletion removes every nested record and code but keeps accounts and other diaries', async () => {
  const ref = await diary('delete', ['gone', 'stays']);
  const other = await diary('keep', ['gone', 'stays']);
  await db.collection('caregiver_profiles').doc('gone').set({ name: 'Test' });
  await ref.update({ diaryDeletionRequested: true });
  const writer = db.bulkWriter();
  for (let i = 0; i < 510; i++) writer.set(ref.collection('entries').doc(`many-${i}`), { notes: 'Test' });
  writer.set(ref.collection('future').doc('nested').collection('children').doc('one'), { test: true });
  writer.set(db.collection('share_codes').doc('EXTRA1'), { babyId: ref.id });
  await writer.close();
  await deleteRequestedDiary(db, ref);
  await deleteRequestedDiary(db, ref);
  assert.equal((await ref.get()).exists, false);
  for (const name of ['entries', 'achievement_celebrations', 'future']) {
    assert.equal((await ref.collection(name).get()).size, 0);
  }
  assert.equal((await ref.collection('future').doc('nested').collection('children').get()).size, 0);
  assert.equal((await db.collection('share_codes').where('babyId', '==', ref.id).get()).size, 0);
  assert.equal((await other.get()).exists, true);
  assert.equal((await db.collection('caregiver_profiles').doc('gone').get()).exists, true);
});

integration('cleanup ignores active diaries and resumes after interrupted recursive deletion', async () => {
  const ref = await diary('retry', ['gone', 'stays']);
  await deleteRequestedDiary(db, ref);
  assert.equal((await ref.get()).exists, true);
  await ref.update({ diaryDeletionRequested: true });
  const failing = new Proxy(db, { get(target, key) {
    if (key === 'recursiveDelete') return async () => { throw new Error('interrupted'); };
    const value = Reflect.get(target, key);
    return typeof value === 'function' ? value.bind(target) : value;
  } });
  await assert.rejects(deleteRequestedDiary(failing, ref), /interrupted/);
  assert.equal((await ref.get()).data().diaryDeletionRequested, true);
  await deleteRequestedDiary(db, ref);
  assert.equal((await ref.get()).exists, false);
});

async function diary(id, members, owner = 'gone') {
  const ref = db.collection('babies').doc(id);
  await ref.set({ name: 'Ada', ownerUid: owner, memberUids: members,
    memberLabels: Object.fromEntries(members.map((uid) => [uid, uid])),
    memberEmails: Object.fromEntries(members.map((uid) => [uid, `${uid}@example.com`])),
    shareCode: id, consentVersion: 1, consentBy: 'gone' });
  await db.collection('share_codes').doc(id).set({ babyId: id, issuedBy: 'gone', issuerEmail: 'gone@example.com' });
  await ref.collection('entries').doc('poop').set({ loggedBy: 'gone',
    loggedByName: 'Parent', loggedByEmail: 'gone@example.com', notes: 'After breakfast', consistency: 'soft' });
  await ref.collection('achievement_celebrations').doc('7').set({ loggedBy: 'gone', days: 7 });
  return ref;
}

integration('preserves shared diaries, removes identity even in previously left diaries, and is idempotent', async () => {
  const shared = await diary('shared', ['gone', 'stays']);
  const left = await diary('left', ['stays']);
  for (const name of ['caregiver_profiles', 'verified_emails', 'verification_requests']) {
    await db.collection(name).doc('gone').set({ email: 'gone@example.com' });
  }
  await shared.collection('entries').doc('other').set({ loggedBy: 'stays', loggedByName: 'Other' });
  await remove('gone');
  await remove('gone');
  for (const ref of [shared, left]) {
    const baby = (await ref.get()).data();
    assert.deepEqual(baby.memberUids, ['stays']);
    assert.equal(baby.ownerUid, 'stays');
    assert.equal(baby.consentBy, undefined);
    assert.equal(baby.consentVersion, 1);
    assert.equal(baby.memberLabels.gone, undefined);
    assert.equal(baby.memberEmails.gone, undefined);
    assert.deepEqual((await ref.collection('entries').doc('poop').get()).data(),
      { notes: 'After breakfast', consistency: 'soft' });
    assert.deepEqual((await ref.collection('achievement_celebrations').doc('7').get()).data(), { days: 7 });
  }
  assert.equal((await shared.collection('entries').doc('other').get()).data().loggedByName, 'Other');
  assert.equal((await db.collection('share_codes').get()).size, 0);
  for (const name of ['caregiver_profiles', 'verified_emails', 'verification_requests']) {
    assert.equal((await db.collection(name).doc('gone').get()).exists, false);
  }
  assert.ok((await db.collection('deletion_blocks').doc('gone').get()).data().expiresAt.toMillis() > Date.now());
});

integration('deletes sole-caregiver diaries and all nested data, including more than one batch', async () => {
  const sole = await diary('sole', ['gone']);
  const writer = db.bulkWriter();
  for (let i = 0; i < 510; i++) writer.set(sole.collection('entries').doc(`entry-${i}`), { loggedBy: 'gone' });
  writer.set(sole.collection('future_nested_data').doc('one'), { value: true });
  await writer.close();
  await remove('gone');
  assert.equal((await sole.get()).exists, false);
  assert.equal((await sole.collection('entries').get()).size, 0);
  assert.equal((await sole.collection('future_nested_data').get()).size, 0);
  assert.equal((await db.collection('share_codes').get()).size, 0);
});

integration('a retry resumes a diary that was detached before recursive deletion failed', async () => {
  const sole = await diary('interrupted', ['gone']);
  const failingDb = new Proxy(db, {
    get(target, property) {
      if (property === 'recursiveDelete') return async () => { throw new Error('interrupted'); };
      const value = Reflect.get(target, property);
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
  await assert.rejects(createAccountDeletionService({ db: failingDb })('gone'), /interrupted/);
  assert.equal((await sole.get()).data().deletionPending, 'gone');
  await remove('gone');
  assert.equal((await sole.get()).exists, false);
  assert.equal((await sole.collection('entries').get()).size, 0);
});

integration('simultaneous deletion of the last two caregivers leaves no orphan diary', async () => {
  const shared = await diary('concurrent', ['gone', 'stays']);
  await Promise.all([remove('gone'), remove('stays')]);
  assert.equal((await shared.get()).exists, false);
  assert.equal((await shared.collection('entries').get()).size, 0);
});
