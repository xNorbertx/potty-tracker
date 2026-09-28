// Local QA only. Never send email or connect to production from this harness.
if (process.env.FUNCTIONS_EMULATOR !== 'true' || process.env.GCLOUD_PROJECT !== 'demo-potty-tracker') {
  throw new Error('This harness requires the demo-potty-tracker emulators.');
}
const app = require('../../functions/index');
for (const name of ['createCaregiverInvitation', 'acceptCaregiverInvitation',
  'deleteCaregiverDiary', 'finishDiaryDeletion', 'deleteEmailVerification', 'verifyCaregiverEmail']) {
  if (app[name]) exports[name] = app[name];
}


