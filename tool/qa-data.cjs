// Synthetic fixtures only. Must never run against a real Firebase project.
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080' ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099') {
  throw new Error('Local emulators required');
}
const { createRequire } = require('node:module');
const sdk = createRequire(require('node:path').resolve(__dirname, '../functions/package.json'));
const { initializeApp } = sdk('firebase-admin/app');
const { getAuth } = sdk('firebase-admin/auth');
const { getFirestore, Timestamp } = sdk('firebase-admin/firestore');
initializeApp({ projectId: 'demo-potty-tracker' });
async function main() {
  const db = getFirestore();
  const owner = await getAuth().getUserByEmail('qa-owner@example.test');
  if (process.argv[2] === 'extra') {
    let guest;
    try { guest = await getAuth().getUserByEmail('qa-guest@example.test'); }
    catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      guest = await getAuth().createUser({ email: 'qa-guest@example.test', password: 'LocalQa123!' });
    }
    await db.doc(`caregiver_profiles/${guest.uid}`).set({ name: 'QA Alex', email: guest.email });
    await db.doc('babies/qa-long-name').set({
      name: 'Alexandria-Charlotte A Very Long Baby Name For Layout Testing',
      ownerUid: owner.uid, memberUids: [owner.uid], memberLabels: { [owner.uid]: 'QA Sam' },
      memberEmails: { [owner.uid]: owner.email }, createdAt: Timestamp.now(), shareCode: '',
      consentVersion: 1, consentBy: owner.uid, consentAt: Timestamp.now(),
    });
    console.log('Fictional guest and second diary ready');
    return;
  }
  if (process.argv[2] === 'verify') {
    await db.doc(`verified_emails/${owner.uid}`).set({ email: owner.email, verifiedAt: Date.now() });
    console.log('Synthetic owner verified');
    return;
  }
  const diaries = await db.collection('babies').where('memberUids', 'array-contains', owner.uid).get();
  if (process.argv[2] === 'inspect') {
    for (const diary of diaries.docs) {
      const entries = await diary.ref.collection('entries').get();
      console.log(JSON.stringify({ id: diary.id, name: diary.data().name, members: diary.data().memberUids.length, entries: entries.size }));
    }
    return;
  }
  if (process.argv[2] !== 'seed') throw new Error('Use inspect, seed, verify or extra');
  const diary = diaries.docs.find((doc) => doc.data().name === 'QA Ada');
  if (!diary) throw new Error('Create QA Ada through the app first');
  const now = new Date();
  for (let daysAgo = 1; daysAgo <= 6; daysAgo++) {
    const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysAgo, 9);
    const achievementDay = `${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, '0')}-${String(day.getDate()).padStart(2, '0')}`;
    await diary.ref.collection('entries').doc(`fixture-${daysAgo}`).set({
      babyId: diary.id, timestamp: Timestamp.fromDate(day), createdAt: Timestamp.now(),
      achievementDay, consistency: 'soft', loggedBy: owner.uid, loggedByName: 'QA Sam',
    });
  }
  console.log('Six fictional preceding days seeded');
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
