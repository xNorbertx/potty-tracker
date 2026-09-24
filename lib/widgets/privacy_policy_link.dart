import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://xnorbertx.github.io/potty-tracker/privacy/';

Future<void> openPrivacyPolicy(BuildContext context) async {
  try {
    if (await launchUrl(Uri.parse(privacyPolicyUrl),
        mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // Keep the public address available even if there is no browser handler.
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy policy'),
      content: const SelectableText(privacyPolicyUrl),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => openPrivacyPolicy(context),
        child: const Text('Privacy policy'),
      );
}
