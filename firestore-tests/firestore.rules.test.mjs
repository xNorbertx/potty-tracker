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

async function seedDiary() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'babies', babyId), baby);
    await setDoc(doc(db, 'babies', babyId, 'entries', 'entry-1'), {
      babyId,
      timestamp: new Date('2026-01-02T10:00:00Z'),
      consistency: 'soft',
      loggedBy: 'caregiver-a',
      createdAt: new Date('2026-01-02T10:00:00Z'),
    });
    await setDoc(doc(db, 'share_codes', originalCode), { babyId });
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

test('an invite cannot be used without consuming and replacing its code', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-b').firestore();

  await assertFails(
    updateDoc(doc(db, 'babies', babyId), {
      memberUids: ['caregiver-a', 'caregiver-b'],
    }),
  );
});
