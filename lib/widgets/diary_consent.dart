import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'app_status.dart';
import 'privacy_policy_link.dart';
import 'delete_diary_button.dart';

// Keep this text versioned alongside the server rules and consent runbook.
const diaryConsentText =
    'I am this child’s parent or legal guardian, or have their explicit permission. '
    'I consent on their behalf to Potty Tracker storing this child’s health diary '
    'and sharing it with caregivers invited to this diary.';

class DiaryConsentFields extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const DiaryConsentFields({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v == true),
            title: const Text(diaryConsentText),
          ),
          const Text(
              'You can withdraw consent by deleting the diary, or contacting support. '),
          const PrivacyPolicyLink(),
        ],
      );
}

Future<Baby?> showAddBabyDialog(BuildContext context) => showDialog<Baby>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddBabyDialog(),
    );

class _AddBabyDialog extends StatefulWidget {
  const _AddBabyDialog();
  @override
  State<_AddBabyDialog> createState() => _AddBabyDialogState();
}

class _AddBabyDialogState extends State<_AddBabyDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _consent = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_consent || !_form.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final baby = await context.read<FirestoreService>().addBaby(
            uid,
            _name.text.trim(),
            consentGiven: true,
            caregiverLabel: auth.currentUserEmail,
          );
      if (mounted) Navigator.pop(context, baby);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: const Text('Add a baby'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: "Baby's name"),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DiaryConsentFields(
                      value: _consent,
                      onChanged:
                          _saving ? null : (v) => setState(() => _consent = v)),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _consent && !_saving ? _save : null,
                child: Text(_saving ? 'Saving…' : 'Add baby')),
          ],
        ),
      );
}

class DiaryConsentPanel extends StatefulWidget {
  final Baby baby;
  final Widget? footer;
  const DiaryConsentPanel({super.key, required this.baby, this.footer});
  @override
  State<DiaryConsentPanel> createState() => _DiaryConsentPanelState();
}

class _DiaryConsentPanelState extends State<DiaryConsentPanel> {
  bool _checked = false;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUserId;
    final canConsent = widget.baby.ownerUid == uid ||
        !widget.baby.memberUids.contains(widget.baby.ownerUid);
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text(
          widget.baby.diaryDeletionRequested
              ? 'This diary is being deleted.'
              : 'Permission to keep this diary',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      if (!widget.baby.diaryDeletionRequested && canConsent) ...[
        DiaryConsentFields(
            value: _checked,
            onChanged: _saving ? null : (v) => setState(() => _checked = v)),
        FilledButton(
            onPressed: !_checked || _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    try {
                      await context
                          .read<FirestoreService>()
                          .acceptDiaryConsent(widget.baby.id, uid!);
                    } catch (error) {
                      if (mounted) {
                        setState(() => _error = friendlyError(error));
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Saving…' : 'Continue')),
      ] else if (!widget.baby.diaryDeletionRequested)
        const Text(
            'The caregiver who manages this diary needs to confirm permission before it can be used.'),
      const DiarySupportLink(),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      if (widget.footer != null) ...[
        const SizedBox(height: 28),
        widget.footer!,
      ],
    ]);
  }
}
