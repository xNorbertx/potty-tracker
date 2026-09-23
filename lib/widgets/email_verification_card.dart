import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/verification_service.dart';
import 'app_status.dart';

class EmailVerificationCard extends StatefulWidget {
  const EmailVerificationCard({super.key});

  @override
  State<EmailVerificationCard> createState() => _EmailVerificationCardState();
}

class _EmailVerificationCardState extends State<EmailVerificationCard> {
  bool _busy = false;
  String? _feedback;

  Future<void> _run(bool resend) async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final service = context.read<VerificationService>();
      final auth = context.read<AuthService>();
      String message;
      if (resend) {
        await service.resend();
        message = 'Verification email sent. Check your inbox and spam folder.';
      } else {
        final verified =
            await service.refresh(auth.currentUserId!, auth.currentUserEmail);
        message = verified
            ? 'Email verified. You can now invite caregivers.'
            : 'Not verified yet. Open the link in your email, then check again.';
      }
      if (mounted) setState(() => _feedback = message);
    } catch (error) {
      if (mounted) setState(() => _feedback = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    if (auth.currentUserId == null) return const SizedBox.shrink();
    return StreamBuilder<bool>(
      stream: context.read<VerificationService>().verifiedStream(
            auth.currentUserId!,
            auth.currentUserEmail,
          ),
      builder: (context, snapshot) {
        final verified = snapshot.data == true && !snapshot.hasError;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                      verified
                          ? Icons.verified
                          : Icons.mark_email_unread_outlined,
                      color: const Color(0xFF388E3C)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          verified ? 'Email verified' : 'Verify your email',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 8),
                Text(verified
                    ? 'Caregiver invitations are unlocked.'
                    : 'Verify your email to invite a caregiver. You can already track poops and accept invitations.'),
                if (!verified) ...[
                  TextButton(
                      onPressed: _busy ? null : () => _run(true),
                      child: const Text('Resend verification email')),
                  TextButton(
                      onPressed: _busy ? null : () => _run(false),
                      child: const Text('Check verification status')),
                ],
                if (_busy) const LinearProgressIndicator(),
                if (_feedback != null || snapshot.hasError)
                  Semantics(
                      liveRegion: true,
                      child: Text(_feedback ??
                          'Could not check verification. Please try again.')),
              ],
            ),
          ),
        );
      },
    );
  }
}
