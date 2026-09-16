import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_status.dart';
import 'baby_overview_screen.dart';

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
                final baby = await context.read<FirestoreService>().addBaby(
                      uid,
                      controller.text.trim(),
                      caregiverLabel:
                          context.read<AuthService>().currentUserEmail,
                    );
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

  Future<void> _deleteBaby(Baby baby) async {
    final uid = context.read<AuthService>().currentUserId;
    if (uid == null) return;
    final isShared = baby.memberUids.any((member) => member != uid);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isShared ? 'Leave ${baby.name}\'s diary?' : 'Remove ${baby.name}?'),
        content: Text(
          isShared
              ? 'You will lose access to this diary. The other caregivers and all poop logs will remain.'
              : 'This will permanently remove this baby and all poop logs for them. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isShared ? 'Leave diary' : 'Remove baby'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      if (isShared) {
        await context.read<FirestoreService>().leaveBaby(baby: baby, uid: uid);
      } else {
        await context.read<FirestoreService>().deleteBaby(baby);
      }
      if (!mounted) return;
      setState(
          () => _babies = _babies.where((item) => item.id != baby.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShared
              ? 'You no longer have access to this diary.'
              : 'Baby and poop logs removed.'),
        ),
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
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your babies')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choose a diary',
              style: TextStyle(
                color: Color(0xFF388E3C),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._babies.map(
              (baby) => Slidable(
                key: ValueKey(baby.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _renameBaby(baby),
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _deleteBaby(baby),
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Remove',
                    ),
                  ],
                ),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Text('👶')),
                    title: Text(baby.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selectedBabyId =
                          await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => BabyOverviewScreen(baby: baby),
                        ),
                      );
                      if (selectedBabyId != null && context.mounted) {
                        Navigator.pop(context, selectedBabyId);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addBaby,
              icon: const Icon(Icons.add),
              label: const Text('Add another baby'),
            ),
          ],
        ),
      );
}
