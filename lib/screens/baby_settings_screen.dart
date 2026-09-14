import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_status.dart';

class BabySettingsScreen extends StatefulWidget {
  final List<Baby> babies;
  final String selectedBabyId;

  const BabySettingsScreen({
    super.key,
    required this.babies,
    required this.selectedBabyId,
  });

  @override
  State<BabySettingsScreen> createState() => _BabySettingsScreenState();
}

class _BabySettingsScreenState extends State<BabySettingsScreen> {
  late List<Baby> _babies;

  @override
  void initState() {
    super.initState();
    _babies = widget.babies;
  }

  Future<void> _renameBaby(Baby baby) async {
    final controller = TextEditingController(text: baby.name);
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit baby name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: "Baby's name"),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter a name'
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
                await context
                    .read<FirestoreService>()
                    .updateBabyName(baby.id, controller.text.trim());
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                setState(() {
                  _babies = _babies
                      .map((item) => item.id == baby.id
                          ? item.copyWith(name: controller.text.trim())
                          : item)
                      .toList();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baby name updated.')),
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

  void _shareBaby(Baby baby) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share baby'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give this code to the other parent:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Text(
                baby.shareCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: baby.shareCode));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard.')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy code'),
            ),
            const SizedBox(height: 4),
            const Text(
              'They can enter it when setting up the app.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBaby() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add another baby'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: "Baby's name"),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter a name'
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
              final uid = context.read<AuthService>().currentUserId;
              if (uid == null) return;
              try {
                final baby = await context
                    .read<FirestoreService>()
                    .addBaby(uid, controller.text.trim());
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                setState(() => _babies = [..._babies, baby]);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baby added.')),
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
            child: const Text('Add baby'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Baby settings')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your babies',
              style: TextStyle(
                color: Color(0xFF388E3C),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._babies.map(
              (baby) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Text('👶')),
                  title: Text(baby.name),
                  subtitle: baby.id == widget.selectedBabyId
                      ? const Text('Current diary')
                      : const Text('Open this diary'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, baby.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addBaby,
              icon: const Icon(Icons.add),
              label: const Text('Add another baby'),
            ),
            const SizedBox(height: 28),
            const Text(
              'Current baby',
              style: TextStyle(
                color: Color(0xFF388E3C),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._babies.where((baby) => baby.id == widget.selectedBabyId).map(
                  (baby) => Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          title: const Text('Edit baby name'),
                          onTap: () => _renameBaby(baby),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading:
                              const Icon(Icons.share, color: Color(0xFF4CAF50)),
                          title: const Text('Share baby'),
                          subtitle:
                              const Text('Give another parent a share code.'),
                          onTap: () => _shareBaby(baby),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      );
}
