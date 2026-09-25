const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createVerificationService, verificationPage } = require('./verification');
const { createInvitationService } = require('./invitations');

function fixture() {
  const records = new Map();
  const db = {
    collection: (name) => ({ doc: (id) => `${name}/${id}` }),
    runTransaction: async (run) => {
      const writes = [];
      const result = await run({
        get: async (ref) => ({ exists: records.has(ref), data: () => records.get(ref) }),
        set: (ref, data) => writes.push(() => records.set(ref, data)),
        update: (ref, data) => writes.push(() => records.set(ref, { ...records.get(ref), ...data })),
        delete: (ref) => writes.push(() => records.delete(ref)),
      });
      writes.forEach((write) => write());
      return result;
    },
  };
  const user = { uid: 'parent', email: 'parent@example.com', emailVerified: true };
  const auth = { getUser: async () => user };
  const emails = [];
  let time = 100000;
  let failDelivery = false;
  const service = createVerificationService({ db, auth, endpoint: 'https://example.com/verify',
    now: () => time,
    sendEmail: async (mail) => { if (failDelivery) throw new Error('delivery'); emails.push(mail); },
  });
  return { records, db, user, auth, emails, service,
    advance: (ms) => { time += ms; }, fail: (value) => { failDelivery = value; },
    token: () => new URL(emails.at(-1).link).hash.split('token=')[1],
  };
}

test('welcome contains a one-use link, SSO verification alone gives no app proof', async () => {
  const f = fixture();
  await f.service.send('parent', true);
  assert.equal(f.emails[0].subject, 'Welcome to Potty Tracker');
  assert.match(f.emails[0].text, /Verify your email/);
  assert.equal(f.records.has('verified_emails/parent'), false);
  assert.equal(f.records.get('verification_requests/parent').token, undefined);
  await f.service.complete('parent', f.token());
  assert.equal(f.records.get('verified_emails/parent').email, f.user.email);
  await assert.rejects(f.service.complete('parent', f.token()), /invalid-link/);
});

test('expired, malformed, wrong-user and wrong tokens never verify', async () => {
  const f = fixture();
  await f.service.send('parent');
  await assert.rejects(f.service.complete('other', f.token()), /invalid-link/);
  await assert.rejects(f.service.complete('parent', 'x'.repeat(43)), /invalid-link/);
  await assert.rejects(f.service.complete('../parent', f.token()), /invalid-link/);
  f.advance(86400000);
  await assert.rejects(f.service.complete('parent', f.token()), /invalid-link/);
  assert.equal(f.records.has('verified_emails/parent'), false);
});

test('resends are throttled and replace the old token after one minute', async () => {
  const f = fixture();
  await f.service.send('parent');
  const oldToken = f.token();
  await assert.rejects(f.service.send('parent'), /resend-too-soon/);
  f.advance(60000);
  await f.service.send('parent');
  await assert.rejects(f.service.complete('parent', oldToken), /invalid-link/);
  await f.service.complete('parent', f.token());
});

test('email changes and disabled accounts cannot redeem an old link', async () => {
  for (const changes of [{ email: 'changed@example.com' }, { disabled: true }]) {
    const f = fixture();
    await f.service.send('parent');
    Object.assign(f.user, changes);
    await assert.rejects(f.service.complete('parent', f.token()), /invalid-link/);
  }
});

test('failed delivery permits a retry and accounts without email cannot request links', async () => {
  const f = fixture();
  f.fail(true);
  await assert.rejects(f.service.send('parent'), /delivery/);
  f.fail(false);
  await f.service.send('parent');
  f.user.email = null;
  await assert.rejects(f.service.send('parent'), /no-email/);
});

test('link preview is passive and redemption requires an explicit button press', () => {
  assert.match(verificationPage, /button.onclick = async/);
  assert.match(verificationPage, /method:'POST'/);
  assert.match(verificationPage, /history.replaceState/);
});

test('in-flight verification and invitations cannot recreate deleted account data', async () => {
  const f = fixture();
  await f.service.send('parent');
  const token = f.token();
  f.advance(60000);
  f.records.set('deletion_blocks/parent', { expiresAt: 10000000 });
  await assert.rejects(f.service.send('parent'), /account-deleted/);
  await assert.rejects(f.service.complete('parent', token), /invalid-link/);
  await assert.rejects(createInvitationService(f)('parent', 'baby'), /not-verified/);
  assert.equal(f.records.has('verified_emails/parent'), false);
});

test('only members with app email proof can issue invites; legacy code is replaced', async () => {
  const f = fixture();
  f.records.set('babies/baby', { consentVersion: 1, memberUids: ['parent'], shareCode: 'OLD123' });
  f.records.set('share_codes/OLD123', { babyId: 'baby' });
  const create = createInvitationService(f);
  await assert.rejects(create('parent', 'baby'), /not-verified/);
  await f.service.send('parent');
  await f.service.complete('parent', f.token());
  const code = await create('parent', 'baby');
  assert.equal(code.length, 6);
  assert.equal(f.records.has('share_codes/OLD123'), false);
  assert.equal(f.records.get(`share_codes/${code}`).issuedBy, 'parent');
  assert.equal(await create('parent', 'baby'), code);
  await assert.rejects(create('stranger', 'baby'), /not-member/);
  f.user.email = 'new@example.com';
  await assert.rejects(create('parent', 'baby'), /not-verified/);
});
