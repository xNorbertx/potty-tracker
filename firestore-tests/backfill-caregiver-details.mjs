import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const apply = process.argv.includes('--apply');
const serviceAccount = process.env.FIREBASE_RULES_SERVICE_ACCOUNT;
if (!serviceAccount) {
  throw new Error('FIREBASE_RULES_SERVICE_ACCOUNT is required.');
}

initializeApp({ credential: cert(JSON.parse(serviceAccount)) });
const db = getFirestore();
const babies = await db.collection('babies').get();
let changedBabies = 0;
let updatedCaregivers = 0;
let missingProfiles = 0;
let batch = db.batch();
let batchWrites = 0;

async function commitBatch() {
  if (!apply || batchWrites == 0) return;
  await batch.commit();
  batch = db.batch();
  batchWrites = 0;
}

for (const baby of babies.docs) {
  const data = baby.data();
  const memberUids = Array.isArray(data.memberUids) ? data.memberUids : [];
  const profileRefs = memberUids.map((uid) => db.collection('caregiver_profiles').doc(uid));
  const profiles = profileRefs.length == 0 ? [] : await db.getAll(...profileRefs);
  const updates = {};

  for (let index = 0; index < memberUids.length; index++) {
    const uid = memberUids[index];
    const profile = profiles[index];
    if (!profile.exists) {
      missingProfiles++;
      continue;
    }
    const profileData = profile.data();
    const name = String(profileData.name ?? '').trim();
    const email = String(profileData.email ?? '').trim();
    const labels = data.memberLabels ?? {};
    const emails = data.memberEmails ?? {};

    if (name && labels[uid] !== name) {
      updates[`memberLabels.${uid}`] = name;
      updatedCaregivers++;
    }
    if (email && emails[uid] !== email) {
      updates[`memberEmails.${uid}`] = email;
    }
  }

  if (Object.keys(updates).length > 0) {
    changedBabies++;
    if (apply) {
      batch.update(baby.ref, updates);
      batchWrites++;
      if (batchWrites == 450) await commitBatch();
    }
  }
}

await commitBatch();
console.log(`${apply ? 'Updated' : 'Would update'} ${changedBabies} baby documents and ${updatedCaregivers} caregiver names.`);
if (missingProfiles > 0) {
  console.log(`${missingProfiles} caregiver profiles were unavailable and left unchanged.`);
}