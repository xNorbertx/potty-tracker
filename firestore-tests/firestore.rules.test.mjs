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
  deleteDoc,
  deleteField,
  getDoc,
  getDocs,
  query,
  setDoc,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-rules-tests';
const babyId = 'baby-1';
const originalCode = 'ABC123';
let testEnv;

test('new diaries require attributable server-timed consent; clients cannot forge deletion requests', async () => {
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  const ref = doc(db, 'babies', babyId);
  const data = { ...baby, shareCode: '', consentAt: serverTimestamp() };
  const { consentVersion, consentBy, consentAt, ...legacy } = data;
  await assertFails(setDoc(ref, legacy));
  await assertFails(setDoc(ref, { ...data, consentBy: 'stranger' }));
  await assertFails(setDoc(ref, { ...data, consentAt: new Date('2020-01-01') }));
  await assertSucceeds(setDoc(ref, data));
  await assertFails(deleteDoc(ref));
  await assertFails(updateDoc(ref, { diaryDeletionRequested: true }));
  await assertFails(updateDoc(ref, { consentVersion: 0 }));
});

test('legacy consent is confirmed once by its owner, or a member if the owner has left', async () => {
  await seedDiary();
  const owner = testEnv.authenticatedContext('caregiver-a').firestore();
  const member = testEnv.authenticatedContext('caregiver-b').firestore();
  const ref = doc(owner, 'babies', babyId);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'babies', babyId), {
      consentVersion: deleteField(), consentBy: deleteField(), consentAt: deleteField(),
      memberUids: ['caregiver-a', 'caregiver-b'],
    });
  });
  await assertFails(getDocs(collection(owner, 'babies', babyId, 'entries')));
  await assertFails(updateDoc(doc(member, 'babies', babyId), { consentVersion: 1, consentBy: 'caregiver-b', consentAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { consentVersion: 1, consentBy: 'caregiver-a', consentAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { consentAt: serverTimestamp() }));
  await assertSucceeds(getDocs(collection(owner, 'babies', babyId, 'entries')));
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'babies', babyId), {
      consentVersion: deleteField(), consentBy: deleteField(), consentAt: deleteField(), ownerUid: 'departed',
    });
  });
  await assertSucceeds(updateDoc(doc(member, 'babies', babyId), { consentVersion: 1, consentBy: 'caregiver-b', consentAt: serverTimestamp() }));
});

test('pending diary deletion blocks reads, changes, joining and new codes immediately', async () => {
  await seedDiary();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'babies', babyId), { diaryDeletionRequested: true });
  });
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  await assertFails(getDocs(collection(db, 'babies', babyId, 'entries')));
  await assertFails(getDocs(collection(db, 'babies', babyId, 'achievement_celebrations')));
  await assertFails(updateDoc(doc(db, 'babies', babyId, 'entries', 'entry-1'), { notes: 'New' }));
  await assertFails(updateDoc(doc(db, 'babies', babyId), { diaryDeletionRequested: false }));
  await assertFails(updateDoc(doc(db, 'babies', babyId), { name: 'New' }));
  await assertFails(setDoc(doc(db, 'share_codes', 'NEW123'), { babyId }));
  await assertFails(joinBatch(testEnv.authenticatedContext('caregiver-b').firestore()).commit());
});

const baby = {
  name: 'Ada',
  consentVersion: 1,
  consentBy: 'caregiver-a',
  consentAt: new Date('2026-01-01T00:00:00Z'),
  ownerUid: 'caregiver-a',
  memberUids: ['caregiver-a'],
  memberLabels: { 'caregiver-a': 'Ada parent' },
  memberEmails: { 'caregiver-a': 'ada@example.com' },
  shareCode: originalCode,
  createdAt: new Date('2026-01-01T00:00:00Z'),
};

test('leaving cannot remove a different caregiver using duplicate members', async () => {
  await seedDiary();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'babies', babyId), {
      memberUids: ['caregiver-a', 'caregiver-b', 'caregiver-c'],
    });
  });
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  await assertFails(updateDoc(doc(db, 'babies', babyId), {
    memberUids: ['caregiver-b', 'caregiver-b'],
  }));
});

test('malformed entries and diary names cannot break another caregiver\'s app', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  await assertFails(updateDoc(doc(db, 'babies', babyId), { name: { attack: true } }));
  await assertFails(updateDoc(doc(db, 'babies', babyId, 'entries', 'entry-1'), { timestamp: 'not-a-date' }));
  await assertFails(updateDoc(doc(db, 'babies', babyId, 'entries', 'entry-1'), { notes: 'x'.repeat(10001) }));
});

test('leaving removes only your membership and metadata, including legacy diaries', async () => {
  for (const legacy of [false, true]) {
    await seedDiary({ legacy });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies', babyId), {
        memberUids: ['caregiver-a', 'caregiver-b'],
        'memberLabels.caregiver-b': 'Other parent',
        ...(legacy ? {} : { 'memberEmails.caregiver-b': 'other@example.com' }),
      });
    });
    const db = testEnv.authenticatedContext('caregiver-a').firestore();
    const ref = doc(db, 'babies', babyId);
    const leave = {
      memberUids: ['caregiver-b'],
      'memberLabels.caregiver-a': deleteField(),
      'memberEmails.caregiver-a': deleteField(),
    };
    await assertFails(updateDoc(ref, { ...leave, 'memberLabels.caregiver-b': 'Forged' }));
    if (!legacy) {
      const { 'memberEmails.caregiver-a': omitted, ...withoutEmailPath } = leave;
      await assertFails(updateDoc(ref, { ...withoutEmailPath, memberEmails: deleteField() }));
    }
    await assertSucceeds(updateDoc(ref, leave));
    await assertFails(getDoc(ref));
    await assertSucceeds(getDoc(doc(testEnv.authenticatedContext('caregiver-b').firestore(), 'babies', babyId)));
  }
});

test('normal profile, diary and optional entry edits remain valid; invalid types and future dates fail', async () => {
  await seedDiary();
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  await assertSucceeds(setDoc(doc(db, 'caregiver_profiles', 'caregiver-a'), { name: 'Sam', email: 'sam@example.com' }));
  await assertSucceeds(updateDoc(doc(db, 'babies', babyId), { name: 'Ada Rose', 'memberLabels.caregiver-a': 'Sam' }));
  const ref = doc(db, 'babies', babyId, 'entries', 'entry-1');
  await assertSucceeds(updateDoc(ref, { size: 'large', color: 'brown', notes: '<script>literal</script>' }));
  await assertSucceeds(updateDoc(ref, { size: deleteField(), color: deleteField(), notes: deleteField() }));
  for (const invalid of [
    { consistency: 'unknown' }, { size: 5 }, { color: {} }, { notes: null },
    { timestamp: new Date(Date.now() + 86400000) }, { createdAt: 'bad' },
    { loggedByName: 'x'.repeat(121) }, { unexpected: true },
  ]) await assertFails(updateDoc(ref, invalid));
});

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

test('clients cannot bypass server invitation checks with a valid code', async () => {
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

  await assertFails(batch.commit());
});

test('legacy diaries cannot bypass server invitation checks', async () => {
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

  await assertFails(batch.commit());
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

test('a deleted account cannot reuse an unexpired token or recreate its profile', async () => {
  await seedDiary();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'deletion_blocks', 'caregiver-a'), {
      expiresAt: new Date(Date.now() + 7200000),
    });
  });
  const db = testEnv.authenticatedContext('caregiver-a').firestore();
  await assertFails(getDoc(doc(db, 'babies', babyId)));
  await assertFails(setDoc(doc(db, 'caregiver_profiles', 'caregiver-a'), { name: 'Back' }));
  await assertFails(setDoc(doc(db, 'deletion_blocks', 'caregiver-a'), {}));
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

test('invitation records cannot be read, listed, forged or consumed by clients', async () => {
  await seedDiary();
  for (const uid of ['caregiver-a', 'stranger']) {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(getDoc(doc(db, 'share_codes', originalCode)));
    await assertFails(getDocs(collection(db, 'share_codes')));
    await assertFails(deleteDoc(doc(db, 'share_codes', originalCode)));
    await assertFails(setDoc(doc(db, 'invitation_attempts', uid), { count: 0 }));
  }
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
