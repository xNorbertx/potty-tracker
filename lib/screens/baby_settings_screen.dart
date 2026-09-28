import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_status.dart';
import '../widgets/diary_consent.dart';
import '../widgets/join_diary_dialog.dart';
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
  StreamSubscription<List<Baby>>? _subscription;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _babies = [...widget.babies];
    final uid = context.read<AuthService>().currentUserId;
    if (uid != null) {
      _subscription =
          context.read<FirestoreService>().babiesStream(uid).listen((babies) {
        if (mounted) {
          setState(() {
            _babies = babies;
            _loadError = null;
          });
        }
      }, onError: (Object error) {
        if (mounted) setState(() => _loadError = friendlyError(error));
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
            maxLength: 120,
            decoration: const InputDecoration(
                labelText: "Baby's name", counterText: ''),
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
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
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
    final baby = await showAddBabyDialog(context);
    if (baby != null && mounted) {
      setState(
          () => _babies = [..._babies.where((b) => b.id != baby.id), baby]);
    }
  }

  Future<void> _joinBaby() async {
    final baby = await showJoinDiaryDialog(context);
    if (baby != null && mounted) {
      setState(
          () => _babies = [..._babies.where((b) => b.id != baby.id), baby]);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You joined ${baby.name}\'s diary.')));
    }
  }

  Future<void> _leaveBaby(Baby baby) async {
    final uid = context.read<AuthService>().currentUserId;
    if (uid == null || baby.memberUids.length < 2) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("Leave ${baby.name}'s diary?"),
              content: const Text(
                  'You will lose access. Other caregivers will keep this diary and its entries.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Leave diary')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      await context.read<FirestoreService>().leaveBaby(baby: baby, uid: uid);
      if (mounted) {
        setState(() => _babies.removeWhere((item) => item.id == baby.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your babies')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loadError != null) Text(_loadError!),
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
                    if (baby.memberUids.length > 1)
                      SlidableAction(
                        onPressed: (_) => _leaveBaby(baby),
                        backgroundColor: const Color(0xFFF44336),
                        foregroundColor: Colors.white,
                        icon: Icons.logout,
                        label: 'Leave',
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
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _joinBaby,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join with invite code'),
            ),
          ],
        ),
      );
}
