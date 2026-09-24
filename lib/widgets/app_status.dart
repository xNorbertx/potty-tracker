import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';

String friendlyError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('resource-exhausted')) {
    return 'Please wait one minute before requesting another email.';
  }
  if (raw.contains('failed-precondition')) {
    return 'Verify your email in Account settings before inviting a caregiver.';
  }
  if (raw.contains('network-request-failed') ||
      raw.contains('unavailable') ||
      raw.contains('network')) {
    return 'Check your internet connection and try again.';
  }
  if (raw.contains('permission-denied')) {
    return 'You do not have permission to do that.';
  }
  if (raw.contains('user-not-found') ||
      raw.contains('wrong-password') ||
      raw.contains('invalid-credential')) {
    return 'Invalid email or password.';
  }
  if (raw.contains('email-already-in-use')) {
    return 'An account with this email already exists.';
  }
  if (raw.contains('weak-password')) {
    return 'Password must be at least 6 characters.';
  }
  if (raw.contains('requires-recent-login')) {
    return 'Please sign in again, then try this action.';
  }
  if (raw.contains('invalid-email')) {
    return 'Please enter a valid email address.';
  }
  if (raw.contains('cancelled') || raw.contains('canceled')) {
    return 'Sign-in cancelled.';
  }
  return 'Something went wrong. Please try again.';
}

class ConnectionStatusBanner extends StatelessWidget {
  final Widget child;

  const ConnectionStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connection = context.read<ConnectionService>();
    return StreamBuilder<bool>(
      stream: connection.isOnline,
      initialData: true,
      builder: (context, snapshot) {
        final offline = snapshot.data == false;
        return Column(
          children: [
            if (offline)
              const Material(
                color: Color(0xFFFCE7B2),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "You're offline.",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class AppLoadingView extends StatelessWidget {
  final String message;

  const AppLoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 52, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Could not load your diary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
