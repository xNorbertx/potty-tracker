import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/baby.dart';
import '../models/caregiver_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_status.dart';

class AccountSettingsScreen extends StatefulWidget {
  final List<Baby> babies;

  const AccountSettingsScreen({super.key, required this.babies});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _deletingAccount = false;

  Future<void> _editName(CaregiverProfile? profile) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final controller = TextEditingController(text: profile?.name ?? '');
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your name'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await context.read<FirestoreService>().saveCaregiverProfile(
                      CaregiverProfile(
                        uid: uid,
                        name: controller.text.trim(),
                        email: auth.currentUserEmail ?? profile?.email ?? '',
                      ),
                    );
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated.')),
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(friendlyError(error)),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPassword,
                  obscureText: true,
                  enabled: !submitting,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your current password'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPassword,
                  obscureText: true,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) => value == null || value.length < 6
                      ? 'Use at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: true,
                  enabled: !submitting,
                  decoration:
                      const InputDecoration(labelText: 'Confirm new password'),
                  validator: (value) => value != newPassword.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await context.read<AuthService>().changePassword(
                              currentPassword: currentPassword.text,
                              newPassword: newPassword.text,
                            );
                        if (!mounted || !dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Password changed.')),
                        );
                      } catch (error) {
                        setDialogState(() => submitting = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(friendlyError(error)),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save password'),
            ),
          ],
        ),
      ),
    );
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
  }

  String _deletionMessage(String uid) {
    if (widget.babies.isEmpty) {
      return 'Your account will be permanently deleted.';
    }
    final shared = widget.babies.where(
      (baby) => baby.memberUids.any((member) => member != uid),
    );
    final sole = widget.babies.where(
      (baby) => !baby.memberUids.any((member) => member != uid),
    );

    if (sole.isEmpty) {
      return 'Your account will be permanently deleted. The other parent will keep access your baby data.';
    }
    final babyNames = sole.map((baby) => baby.name).join(', ');
    if (shared.isEmpty) {
      return 'Your account will be permanently deleted. You are the only parent attached to $babyNames, so all data about ${sole.length == 1 ? 'your baby' : 'your babies'} — including poop logs — will also be permanently deleted.';
    }
    return 'Your account will be permanently deleted. Data for $babyNames will also be permanently deleted because no other parent is attached. Shared baby data will remain available to the other parent.';
  }

  Future<void> _confirmDeleteAccount() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(_deletionMessage(uid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await context.read<FirestoreService>().removeAccountData(
            uid: uid,
            babies: widget.babies,
          );
      await auth.deleteCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Account',
            style: TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (auth.currentUser?.email != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(auth.currentUser!.email!,
                  style: const TextStyle(color: Colors.grey)),
            ),
          StreamBuilder<CaregiverProfile?>(
            stream: auth.currentUserId == null
                ? null
                : context
                    .read<FirestoreService>()
                    .caregiverProfileStream(auth.currentUserId!),
            builder: (context, snapshot) => Card(
              child: ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Color(0xFF4CAF50)),
                title: const Text('Your name'),
                subtitle: Text(snapshot.data?.displayName.isNotEmpty == true
                    ? snapshot.data!.displayName
                    : 'Add your name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editName(snapshot.data),
              ),
            ),
          ),
          if (auth.hasPasswordProvider)
            Card(
              child: ListTile(
                leading: const Icon(Icons.password, color: Color(0xFF4CAF50)),
                title: const Text('Change password'),
                subtitle: const Text('Update the password you use to sign in.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
            ),
          const SizedBox(height: 28),
          const Text(
            'Danger zone',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete account'),
              subtitle: const Text(
                  'Permanently delete your account and relevant baby data.'),
              trailing: _deletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _deletingAccount ? null : _confirmDeleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}
