import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/verification_service.dart';
import 'app_status.dart';
import 'email_verification_card.dart';

class DiarySupportLink extends StatelessWidget {
  const DiarySupportLink({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () async {
          try {
            if (await launchUrl(Uri.parse(
                'mailto:support@potty-tracker.com?subject=Diary%20privacy%20request'))) {
              return;
            }
          } catch (_) {/* Show the address if no email app is available. */}
          if (!context.mounted) return;
          await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: const Text('Contact support'),
                    content: const SelectableText('support@potty-tracker.com'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'))
                    ],
                  ));
        },
        child: const Text('Contact support'),
      );
}

class DeleteDiaryButton extends StatefulWidget {
  final Baby baby;
  const DeleteDiaryButton({super.key, required this.baby});
  @override
  State<DeleteDiaryButton> createState() => _DeleteDiaryButtonState();
}

class _DeleteDiaryButtonState extends State<DeleteDiaryButton> {
  bool _busy = false;

  Future<void> _delete() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId;
    if (uid == null || _busy) return;
    setState(() => _busy = true);
    try {
      final service = context.read<VerificationService>();
      final verified = await service.refresh(uid, auth.currentUserEmail);
      if (!mounted) return;
      if (!verified) {
        await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Verify your email first'),
                  content: const SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Verify your email to delete a diary. You can also request deletion through support.'),
                          EmailVerificationCard(),
                          DiarySupportLink(),
                        ],
                      ))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'))
                  ],
                ));
        return;
      }
      final baby =
          await context.read<FirestoreService>().getBaby(widget.baby.id);
      if (!mounted) return;
      if (baby == null ||
          baby.diaryDeletionRequested ||
          !baby.memberUids.contains(uid)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This diary is no longer available.')));
        return;
      }
      final others = baby.memberUids.length - 1;
      final audience = others == 0
          ? 'you'
          : 'you and the other $others ${others == 1 ? 'caregiver' : 'caregivers'}';
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text("Delete ${baby.name}'s diary?"),
                content: Text(
                    'This permanently deletes all entries and achievements for $audience. '
                    'This cannot be undone. Your accounts and other diaries stay.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete for everyone')),
                ],
              ));
      if (confirmed != true || !mounted) return;
      // The callable rechecks verification and membership; UI checks are not authority.
      await service.deleteDiary(baby.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary deletion started.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.baby.diaryDeletionRequested) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Danger zone',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete diary'),
            subtitle: const Text('This deletes the diary for everyone.'),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _busy ? null : _delete,
          ),
        ),
      ],
    );
  }
}
