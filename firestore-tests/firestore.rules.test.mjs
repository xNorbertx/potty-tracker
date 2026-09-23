import { after, afterEach, before, test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-potty-tracker';
const babyId = 'baby-1';
const originalCode = 'ABC123';
let testEnv;

const baby = {
  name: 'Ada',
  ownerUid: 'caregiver-a',
  memberUids: ['caregiver-a'],
  memberLabels: { 'caregiver-a': 'Ada parent' },
  memberEmails: { 'caregiver-a': 'ada@example.com' },
  shareCode: originalCode,
  createdAt: new Date('2026-01-01T00:00:00Z'),
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

async function seedDiary({ legacy = false } = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const seededBaby = { ...baby };
    if (legacy) delete seededBaby.memberEmails;
    await setDoc(doc(db, 'babies', babyId), seededBaby);
    await setDoc(doc(db, 'babies', babyId, 'entries', 'entry-1'), {
      babyId,
      timestamp: new Date('2026-01-02T10:00:00Z'),
      consistency: 'soft',
      loggedBy: 'caregiver-a',
      createdAt: new Date('2026-01-02T10:00:00Z'),
    });
    await setDoc(doc(db, 'share_codes', originalCode), {
      babyId, issuedBy: 'caregiver-a', issuerEmail: 'ada@example.com',
    });
    await setDoc(doc(db, 'verified_emails', 'caregiver-a'), { email: 'ada@example.com' });
  });
}

test('a caregiver can list and open their diary and entries', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-a').firestore();

  await assertSucceeds(
    getDocs(query(collection(db, 'babies'), where('memberUids', 'array-contains', 'caregiver-a'))),
  );
  await assertSucceeds(getDoc(doc(db, 'babies', babyId)));
  await assertSucceeds(getDocs(collection(db, 'babies', babyId, 'entries')));
});

test('someone outside the diary cannot open it or its entries', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('stranger').firestore();

  await assertFails(getDoc(doc(db, 'babies', babyId)));
  await assertFails(getDocs(collection(db, 'babies', babyId, 'entries')));
});

test('a caregiver cannot add another caregiver directly', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-a').firestore();

  await assertFails(
    updateDoc(doc(db, 'babies', babyId), {
      memberUids: ['caregiver-a', 'stranger'],
    }),
  );
});

test('a valid invite atomically joins a caregiver and rotates its code', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b').firestore();
  const nextCode = 'DEF456';
  const batch = writeBatch(db);

  batch.update(doc(db, 'babies', babyId), {
    memberUids: ['caregiver-a', 'caregiver-b'],
    memberLabels: {
      'caregiver-a': 'Ada parent',
      'caregiver-b': 'Other parent',
    },
    memberEmails: {
      'caregiver-a': 'ada@example.com',
      'caregiver-b': 'other@example.com',
    },
    shareCode: nextCode,
  });
  batch.delete(doc(db, 'share_codes', originalCode));
  batch.set(doc(db, 'share_codes', nextCode), { babyId });

  await assertSucceeds(batch.commit());
});

test('a valid invite can add an email map to a legacy diary', async () => {
  await seedDiary({ legacy: true });
  const db = testEnv.authenticatedContext('caregiver-b').firestore();
  const nextCode = 'DEF456';
  const batch = writeBatch(db);

  batch.update(doc(db, 'babies', babyId), {
    memberUids: ['caregiver-a', 'caregiver-b'],
    memberLabels: {
      'caregiver-a': 'Ada parent',
      'caregiver-b': 'Other parent',
    },
    memberEmails: { 'caregiver-b': 'other@example.com' },
    shareCode: nextCode,
  });
  batch.delete(doc(db, 'share_codes', originalCode));
  batch.set(doc(db, 'share_codes', nextCode), { babyId });

  await assertSucceeds(batch.commit());
});

test('an invite cannot be used without consuming and replacing its code', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b').firestore();

  await assertFails(
    updateDoc(doc(db, 'babies', babyId), {
      memberUids: ['caregiver-a', 'caregiver-b'],
    }),
  );
});

function joinBatch(db) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'babies', babyId), {
    memberUids: ['caregiver-a', 'caregiver-b'],
    memberLabels: { ...baby.memberLabels, 'caregiver-b': 'Other parent' },
    memberEmails: { ...baby.memberEmails, 'caregiver-b': 'other@example.com' },
    shareCode: 'DEF456',
  });
  batch.delete(doc(db, 'share_codes', originalCode));
  batch.set(doc(db, 'share_codes', 'DEF456'), { babyId });
  return batch;
}

test('legacy codes cannot join, even when the owner has verified', async () => {
  await seedDiary();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'share_codes', originalCode), { babyId });
  });
  await assertFails(joinBatch(testEnv.authenticatedContext('caregiver-b').firestore()).commit());
});

test('SSO email_verified claim cannot replace app verification or forge an invitation', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b', { email_verified: true }).firestore();
  await assertFails(setDoc(doc(db, 'verified_emails', 'caregiver-b'), { email: 'other@example.com' }));
  await assertFails(setDoc(doc(db, 'share_codes', 'NEW123'), {
    babyId, issuedBy: 'caregiver-a', issuerEmail: 'ada@example.com',
  }));
  await assertFails(getDoc(doc(db, 'verification_requests', 'caregiver-b')));
  await assertFails(getDoc(doc(db, 'verified_emails', 'caregiver-a')));
});

test('mismatched proof and issuers who left the baby cannot authorize a join', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b').firestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'verified_emails', 'caregiver-a'), { email: 'changed@example.com' });
  });
  await assertFails(joinBatch(db).commit());
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'verified_emails', 'caregiver-a'), { email: 'ada@example.com' });
    await updateDoc(doc(context.firestore(), 'share_codes', originalCode), { issuedBy: 'departed' });
    await setDoc(doc(context.firestore(), 'verified_emails', 'departed'), { email: 'ada@example.com' });
  });
  await assertFails(joinBatch(db).commit());
});

test('an unverified joiner can accept a valid invite but cannot reissue its replacement', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b').firestore();
  await assertSucceeds(joinBatch(db).commit());
  await assertFails(updateDoc(doc(db, 'share_codes', 'DEF456'), {
    issuedBy: 'caregiver-b', issuerEmail: 'other@example.com',
  }));
  const stranger = testEnv.authenticatedContext('stranger').firestore();
  const batch = writeBatch(stranger);
  batch.update(doc(stranger, 'babies', babyId), {
    memberUids: ['caregiver-a', 'caregiver-b', 'stranger'],
    memberLabels: { ...baby.memberLabels, 'caregiver-b': 'Other parent', stranger: 'Stranger' },
    memberEmails: { ...baby.memberEmails, 'caregiver-b': 'other@example.com', stranger: 's@example.com' },
    shareCode: 'GHI789',
  });
  batch.delete(doc(stranger, 'share_codes', 'DEF456'));
  batch.set(doc(stranger, 'share_codes', 'GHI789'), { babyId });
  await assertFails(batch.commit());
});

test('achievement days survive edits; caregivers can create one celebration claim', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  const entryRef = doc(db, 'babies', babyId, 'entries', 'entry-1');
  await assertSucceeds(updateDoc(entryRef, { achievementDay: '2026-01-02' }));
  await assertSucceeds(updateDoc(entryRef, { timestamp: new Date('2026-01-03T10:00:00Z') }));
  await assertFails(updateDoc(entryRef, { achievementDay: '2026-01-03' }));
  const claim = doc(db, 'babies', babyId, 'achievement_celebrations', '7-2026-01-07');
  const data = { days: 7, loggedBy: 'caregiver-a', createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(claim, data));
  await assertFails(setDoc(claim, data));
  const stranger = testEnv.authenticatedContext('stranger').firestore();
  await assertFails(getDoc(doc(stranger, 'babies', babyId, 'achievement_celebrations', '7-2026-01-07')));
  await assertFails(setDoc(doc(stranger, 'babies', babyId, 'achievement_celebrations', '14-2026-01-14'), {
    ...data, loggedBy: 'stranger',
  }));
});
