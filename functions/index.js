const functions = require('firebase-functions/v1');

const sender = 'Potty Tracker <no_reply@potty-tracker.com>';
const appUrl = 'https://xnorbertx.github.io/potty-tracker/#/home';

const welcomeEmailHtml = `
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
            <h1 style="margin:0 0 16px;font-size:26px;line-height:1.25;color:#2e7d32;">Welcome to Potty Tracker 👋</h1>
            <p style="margin:0 0 16px;font-size:16px;line-height:1.6;">Your account is ready. Create a diary for your little one and keep the important details in one shared place.</p>
            <p style="margin:0 0 28px;font-size:16px;line-height:1.6;">You can start with a first entry whenever you are ready.</p>
            <a href="${appUrl}" style="display:inline-block;background:#4caf50;color:#ffffff;text-decoration:none;font-weight:700;padding:14px 22px;border-radius:8px;">Open Potty Tracker</a>
          </td></tr>
          <tr><td style="padding:0 36px 30px;color:#607d8b;font-size:13px;line-height:1.5;">You received this email because a Potty Tracker account was created with this address.</td></tr>
        </table>
      </td></tr>
    </table>
  </body>
</html>`;

exports.sendWelcomeEmail = functions
  .runWith({ secrets: ['RESEND_API_KEY'] })
  .auth.user()
  .onCreate(async (user) => {
    if (!user.email) {
      console.log(`Skipping welcome email for ${user.uid}: no email address.`);
      return null;
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: sender,
        to: [user.email],
        subject: 'Welcome to Potty Tracker',
        text: `Welcome to Potty Tracker! Your account is ready. Create a diary for your little one and start logging whenever you are ready. Open Potty Tracker: ${appUrl}`,
        html: welcomeEmailHtml,
      }),
    });

    if (!response.ok) {
      throw new Error(`Resend rejected welcome email: ${response.status} ${await response.text()}`);
    }
    console.log(`Sent welcome email to ${user.email}.`);
    return null;
  });
