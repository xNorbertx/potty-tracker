const { randomBytes, createHash } = require('node:crypto');

const APP_URL = 'https://xnorbertx.github.io/potty-tracker/';
const hash = (token) => createHash('sha256').update(token).digest('hex');

// This proof is deliberately independent of Firebase's emailVerified flag:
// an SSO provider's assertion must not skip our own email-link verification.
function createVerificationService({ db, auth, sendEmail, endpoint, now = Date.now }) {
  async function send(uid, welcome = false) {
    const user = await auth.getUser(uid);
    if (!user.email || user.disabled) throw new Error('no-email');
    const ref = db.collection('verification_requests').doc(uid);
    const token = randomBytes(32).toString('base64url');
    const tokenHash = hash(token);
    const sentAt = now();
    await db.runTransaction(async (tx) => {
      const previous = await tx.get(ref);
      if (previous.exists && sentAt - previous.data().sentAt < 60000) {
        throw new Error('resend-too-soon');
      }
      tx.set(ref, { email: user.email, tokenHash, sentAt, expiresAt: sentAt + 86400000 });
    });
    // Fragments are not sent to HTTP access logs or in referrer headers.
    const link = `${endpoint}#uid=${encodeURIComponent(uid)}&token=${token}`;
    try {
      await sendEmail({
        to: user.email,
        link,
        welcome,
        subject: welcome ? 'Welcome to Potty Tracker' : 'Verify your Potty Tracker email',
        text: `${welcome ? 'Welcome to Potty Tracker! Your account is ready. Create a baby diary and start logging whenever you are ready.\n\n' : ''}Verify your email to unlock caregiver invitations:\n${link}\n\nThis link expires in 24 hours and can be used once. You can already track poops and accept invitations. To request a new link, open Account settings in Potty Tracker. If you did not request this email, you can ignore it.`,
      });
    } catch (error) {
      // Permit retry after a failed delivery, without removing a newer request.
      await db.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        if (current.data()?.tokenHash === tokenHash) tx.delete(ref);
      });
      throw error;
    }
  }

  async function complete(uid, token) {
    if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/') ||
        typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) {
      throw new Error('invalid-link');
    }
    const user = await auth.getUser(uid);
    const ref = db.collection('verification_requests').doc(uid);
    await db.runTransaction(async (tx) => {
      const request = await tx.get(ref);
      const data = request.data();
      if (!data || data.tokenHash !== hash(token) || data.expiresAt <= now() ||
          user.disabled || !user.email || user.email !== data.email) {
        throw new Error('invalid-link');
      }
      tx.set(db.collection('verified_emails').doc(uid), {
        email: user.email, verifiedAt: now(),
      });
      tx.delete(ref);
    });
  }

  return { send, complete };
}

// GET only displays the confirmation page. Link previews cannot consume proof.
const verificationPage = `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="no-referrer"><title>Verify email · Potty Tracker</title>
<style>body{font:18px system-ui;background:#f1f8f1;color:#212121;margin:0;padding:24px}main{max-width:440px;margin:10vh auto;background:white;padding:32px;border-radius:20px}button,a{font:inherit}button{background:#388e3c;color:white;border:0;border-radius:12px;padding:14px 22px;cursor:pointer}button:disabled{opacity:.6}a{color:#28722b}p{line-height:1.6}</style>
<main><h1>Verify your email</h1><p id="status" role="status">Confirm your email to unlock caregiver invitations in Potty Tracker.</p><button id="verify">Verify email</button><p><a href="${APP_URL}">Open Potty Tracker</a></p><p>Need another link? Open Account settings and choose Resend verification email.</p></main>
<script>
const params = new URLSearchParams(location.hash.slice(1));
const uid = params.get('uid'), token = params.get('token');
history.replaceState(null, '', location.pathname);
const button = document.getElementById('verify'), statusText = document.getElementById('status');
if (!uid || !token) { button.hidden = true; statusText.textContent = 'This link is invalid. Request another email in Account settings.'; }
button.onclick = async () => {
  button.disabled = true;
  try {
    const response = await fetch(location.pathname, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({uid,token})});
    if (response.status >= 500) throw new Error('unavailable');
    if (!response.ok) { statusText.textContent = 'This link has expired or was already used. Check your verification status in Account settings, or request a new email.'; button.hidden = true; return; }
    statusText.textContent = 'Email verified! You can return to Potty Tracker and invite a caregiver.';
    button.hidden = true;
  } catch (_) { statusText.textContent = 'Could not connect. Check your connection and try again.'; button.disabled = false; }
};
</script></html>`;

module.exports = { createVerificationService, verificationPage };
