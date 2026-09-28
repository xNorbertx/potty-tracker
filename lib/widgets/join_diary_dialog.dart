import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'app_status.dart';

Future<Baby?> showJoinDiaryDialog(BuildContext context) => showDialog<Baby>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _JoinDiaryDialog());

class _JoinDiaryDialog extends StatefulWidget {
  const _JoinDiaryDialog();
  @override
  State<_JoinDiaryDialog> createState() => _JoinDiaryDialogState();
}

class _JoinDiaryDialogState extends State<_JoinDiaryDialog> {
  final _code = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_saving) return;
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-character invite code');
      return;
    }
    final auth = context.read<AuthService>();
    if (auth.currentUserId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final baby = await context.read<FirestoreService>().joinBabyWithCode(
          auth.currentUserId!, code,
          caregiverLabel: auth.currentUserEmail);
      if (!mounted) return;
      if (baby == null) {
        setState(() => _error = 'Invite code unavailable. Ask for a new one.');
      } else {
        Navigator.pop(context, baby);
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: const Text('Join a shared baby'),
          content: SizedBox(
              width: 320,
              child: TextField(
                controller: _code,
                autofocus: true,
                enabled: !_saving,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'ABC234',
                    errorText: _error,
                    errorMaxLines: 3),
                onSubmitted: (_) => _join(),
              )),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _saving ? null : _join,
                child: Text(_saving ? 'Joining…' : 'Join baby')),
          ],
        ),
      );
}
