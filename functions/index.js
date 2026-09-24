const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { createVerificationService, verificationPage } = require('./verification');
const { createInvitationService } = require('./invitations');
const { createAccountDeletionService } = require('./account-deletion');

admin.initializeApp();

const sender = 'Potty Tracker <no_reply@potty-tracker.com>';
const appUrl = 'https://xnorbertx.github.io/potty-tracker/#/home';

const welcomeEmailHtml = (link, welcome) => `
<!doctype html>
<html lang="en">
  <body style="margin:0;padding:0;background:#f6f8f6;font-family:Arial,sans-serif;color:#263238;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="padding:32px 16px;">
      <tr><td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:600px;background:#ffffff;border-radius:16px;overflow:hidden;">
          <tr><td style="background:#4caf50;padding:30px 36px;color:#ffffff;">
            <div style="font-size:30px;line-height:1;">💩</div>
            <div style="font-size:24px;font-weight:700;padding-top:12px;">Potty Tracker</div>
          </td></tr>
          <tr><td style="padding:36px;">
            <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#2e7d32;">${welcome ? 'Welcome to Potty Tracker 👋' : 'Verify your email'}</h1>
            <p style="margin:0 0 16px;font-size:16px;line-height:1.6;">Your account is ready. Create a diary for your little one and keep the important details in one shared place.</p>
            <p style="margin:0 0 28px;font-size:16px;line-height:1.6;">You can start with a first entry whenever you are ready.</p>
            <p>Verify your email to unlock caregiver invitations. This link expires in 24 hours. You can already track poops and accept invitations.</p>
            <a href="${link.replaceAll('&', '&amp;')}" style="display:inline-block;background:#4caf50;color:#ffffff;text-decoration:none;font-weight:700;padding:14px 22px;border-radius:8px;">Verify email</a>
            <p>Need another link? Open Account settings in <a href="${appUrl}">Potty Tracker</a> and choose Resend verification email.</p>
          </td></tr>
          <tr><td style="padding:0 36px 30px;color:#607d8b;font-size:13px;line-height:1.5;">You received this email because a Potty Tracker account was created with this address.</td></tr>
        </table>
      </td></tr>
    </table>
  </body>
</html>`;

const verification = createVerificationService({
  db: admin.firestore(),
  auth: admin.auth(),
  endpoint: `https://us-central1-${process.env.GCLOUD_PROJECT || 'baby-poop-tracker'}.cloudfunctions.net/verifyCaregiverEmail`,
  sendEmail: async ({ to, subject, text, link, welcome }) => {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from: sender, to: [to], subject, text, html: welcomeEmailHtml(link, welcome) }),
    });
    if (!response.ok) throw new Error(`Email delivery failed (${response.status}).`);
  },
});

exports.sendWelcomeEmail = functions
  .runWith({ secrets: ['RESEND_API_KEY'] })
  .auth.user()
  .onCreate(async (user) => {
    if (!user.email) {
      console.log(`Skipping welcome email for ${user.uid}: no email address.`);
      return null;
    }

    await verification.send(user.uid, true);
    return null;
  });

exports.resendVerificationEmail = functions
  .runWith({ secrets: ['RESEND_API_KEY'] })
  .https.onCall(async (_, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
    try {
      await verification.send(context.auth.uid);
      return { sent: true };
    } catch (error) {
      if (error.message === 'resend-too-soon') {
        throw new functions.https.HttpsError('resource-exhausted', 'Please wait one minute before requesting another email.');
      }
      if (error.message === 'no-email') {
        throw new functions.https.HttpsError('failed-precondition', 'Your account needs an email address.');
      }
      throw new functions.https.HttpsError('unavailable', 'Could not send the email. Please try again.');
    }
  });

exports.verifyCaregiverEmail = functions.https.onRequest(async (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.set('Referrer-Policy', 'no-referrer');
  res.set('X-Content-Type-Options', 'nosniff');
  res.set('X-Frame-Options', 'DENY');
  res.set('Content-Security-Policy', "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'");
  if (req.method === 'GET') return res.status(200).type('html').send(verificationPage);
  if (req.method !== 'POST') return res.status(405).send('Method not allowed.');
  try {
    await verification.complete(req.body?.uid, req.body?.token);
    return res.status(200).json({ verified: true });
  } catch (error) {
    if (error.message === 'invalid-link' || error.code === 'auth/user-not-found') {
      return res.status(400).json({ error: 'invalid-link' });
    }
    return res.status(503).json({ error: 'unavailable' });
  }
});

const createInvitation = createInvitationService({ db: admin.firestore(), auth: admin.auth() });
exports.createCaregiverInvitation = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
  try {
    return { code: await createInvitation(context.auth.uid, data?.babyId) };
  } catch (error) {
    if (error.message === 'not-verified') {
      throw new functions.https.HttpsError('failed-precondition', 'Verify your email in Account settings before inviting a caregiver.');
    }
    if (error.message === 'not-member') {
      throw new functions.https.HttpsError('permission-denied', 'You are not a caregiver for this baby.');
    }
    throw new functions.https.HttpsError('unavailable', 'Could not create an invitation. Please try again.');
  }
});

// Keep the existing deployed trigger name to avoid overlapping deletion workers.
const deleteAccountData = createAccountDeletionService({ db: admin.firestore() });
exports.deleteEmailVerification = functions
  .runWith({ failurePolicy: true, timeoutSeconds: 540 })
  .auth.user().onDelete((user) => deleteAccountData(user.uid));
