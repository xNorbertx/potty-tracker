const { test, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { createInvitationService, createAcceptInvitationService } = require('./invitations');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let app, db, time, users, issue, accept;
before(() => {
  if (!enabled) return;
  app = initializeApp({ projectId: 'demo-invitation-tests' }, 'invitation-tests');
  db = getFirestore(app);
});
afterEach(async () => {
  if (enabled) for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
});
after(async () => { if (enabled) await deleteApp(app); });
const integration = (name, run) => test(name, { skip: !enabled }, run);
async function setup() {
  time = Date.now();
  users = { owner: { email: 'owner@example.test' }, guest: { email: 'guest@example.test' }, other: { email: 'other@example.test' } };
  const auth = { getUser: async (uid) => {
    if (!users[uid]) throw Object.assign(new Error('missing'), { code: 'auth/user-not-found' });
    return users[uid];
  } };
  issue = createInvitationService({ db, auth, now: () => time });
  accept = createAcceptInvitationService({ db, auth, now: () => time });
  await db.doc('babies/diary').set({ consentVersion: 1, memberUids: ['owner'], shareCode: '', memberLabels: { owner: 'Owner' } });
  await db.doc('verified_emails/owner').set({ email: users.owner.email });
  await db.doc('caregiver_profiles/guest').set({ name: 'Guest', email: 'spoofed@example.test' });
  return issue('owner', 'diary');
}
integration('unverified caregiver joins once; retry is idempotent and uses the Auth email', async () => {
  const code = await setup();
  assert.equal(await accept('guest', ` ${code.toLowerCase()} `), 'diary');
  assert.equal(await accept('guest', code), 'diary');
  const baby = (await db.doc('babies/diary').get()).data();
  assert.deepEqual(baby.memberUids, ['owner', 'guest']);
  assert.equal(baby.memberEmails.guest, 'guest@example.test');
  await assert.rejects(accept('other', code), /invalid-invitation/);
  await assert.rejects(issue('guest', 'diary'), /not-verified/);
});
integration('concurrent redemptions have only one winner', async () => {
  const code = await setup();
  const result = await Promise.allSettled([accept('guest', code), accept('other', code)]);
  assert.equal(result.filter((r) => r.status === 'fulfilled').length, 1);
  assert.equal((await db.doc('babies/diary').get()).data().memberUids.length, 2);
});
integration('failed and malformed guesses count toward a limit that later resets', async () => {
  const code = await setup();
  for (let i = 0; i < 10; i++) await assert.rejects(accept('guest', i % 2 ? 'ZZZZZZ' : '../bad'), /invalid-invitation/);
  await assert.rejects(accept('guest', code), /too-many-attempts/);
  time += 10 * 60 * 1000;
  assert.equal(await accept('guest', code), 'diary');
});
integration('expired and legacy codes fail; issuance refreshes them', async () => {
  const code = await setup();
  time += 7 * 24 * 60 * 60 * 1000;
  await assert.rejects(accept('guest', code), /invalid-invitation/);
  const renewed = await issue('owner', 'diary');
  assert.notEqual(renewed, code);
  await db.doc(`share_codes/${renewed}`).set({ babyId: 'diary', issuedBy: 'owner', issuerEmail: users.owner.email });
  await assert.rejects(accept('guest', renewed), /invalid-invitation/);
});
integration('issuer email changes, disabled/deleted accounts and diary deletion invalidate invites', async () => {
  const code = await setup();
  users.owner.email = 'changed@example.test';
  await assert.rejects(accept('guest', code), /invalid-invitation/);
  users.owner.email = 'owner@example.test'; users.owner.disabled = true;
  await assert.rejects(accept('guest', code), /invalid-invitation/);
  users.owner.disabled = false;
  await db.doc('deletion_blocks/owner').set({ expiresAt: Timestamp.now() });
  await assert.rejects(accept('guest', code), /invalid-invitation/);
  await db.doc('deletion_blocks/owner').delete();
  await db.doc('babies/diary').update({ diaryDeletionRequested: true });
  await assert.rejects(accept('guest', code), /invalid-invitation/);
});
integration('issuing for a crafted diary cannot delete or reuse another diary invitation', async () => {
  const code = await setup();
  await db.doc('babies/crafted').set({ consentVersion: 1, memberUids: ['owner'], shareCode: code });
  const different = await issue('owner', 'crafted');
  assert.notEqual(different, code);
  assert.equal((await db.doc(`share_codes/${code}`).get()).data().babyId, 'diary');
});
