const functions = require('firebase-functions/v1');

const sender = 'Potty Tracker <no_reply@potty-tracker.com>';

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
        text: 'Welcome to Potty Tracker! Your account is ready. Create a baby diary and start logging whenever you are ready.',
      }),
    });

    if (!response.ok) {
      throw new Error(`Resend rejected welcome email: ${response.status} ${await response.text()}`);
    }
    console.log(`Sent welcome email to ${user.email}.`);
    return null;
  });
