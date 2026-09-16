import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/baby.dart';
import '../models/caregiver_profile.dart';
import '../models/poop_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/poop_entry_tile.dart';
import '../widgets/app_status.dart';
import 'log_poop_screen.dart';
import 'profile_setup_screen.dart';
import 'account_settings_screen.dart';
import 'baby_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String? _selectedBabyId;

  // Cache the entries stream so it isn't recreated on every build
  Stream<List<PoopEntry>>? _entriesStream;
  String? _cachedBabyId;

  Stream<List<PoopEntry>> _getEntriesStream(
      FirestoreService firestore, String babyId) {
    if (_entriesStream == null || _cachedBabyId != babyId) {
      _entriesStream = firestore.entriesStream(babyId);
      _cachedBabyId = babyId;
    }
    return _entriesStream!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final uid = auth.currentUserId;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: AppLoadingView(message: 'Checking your account...'),
      );
    }

    return StreamBuilder<CaregiverProfile?>(
      stream: firestore.caregiverProfileStream(uid),
      builder: (context, profileSnap) {
        if (profileSnap.connectionState == ConnectionState.waiting &&
            profileSnap.data == null) {
          return const Scaffold(
            body: AppLoadingView(message: 'Loading your account...'),
          );
        }
        if (profileSnap.hasError) {
          return Scaffold(
            body: AppErrorView(
              message: friendlyError(profileSnap.error!),
              onRetry: () => setState(() {}),
            ),
          );
        }
        if (profileSnap.data == null) return const ProfileSetupScreen();

        return StreamBuilder<List<Baby>>(
          stream: firestore.babiesStream(uid),
          builder: (context, babySnap) {
            // While loading, show spinner (prevents flash of setup screen)
            if (babySnap.connectionState == ConnectionState.waiting &&
                babySnap.data == null) {
              return const Scaffold(
                body: AppLoadingView(message: 'Loading your diary...'),
              );
            }

            if (babySnap.hasError && babySnap.data == null) {
              return Scaffold(
                body: AppErrorView(
                  message: friendlyError(babySnap.error!),
                  onRetry: () => setState(() {}),
                ),
              );
            }

            final babies = babySnap.data ?? [];

            // Confirmed empty → go to setup
            if (babies.isEmpty) {
              return _NoBabiesHome(uid: uid, firestore: firestore, auth: auth);
            }

            final baby = babies.firstWhere(
              (candidate) => candidate.id == _selectedBabyId,
              orElse: () => babies.first,
            );
            final entriesStream = _getEntriesStream(firestore, baby.id);

            return StreamBuilder<List<PoopEntry>>(
              stream: entriesStream,
              builder: (context, entrySnap) {
                if (entrySnap.connectionState == ConnectionState.waiting &&
                    entrySnap.data == null) {
                  return Scaffold(
                    appBar:
                        AppBar(title: Text('👶 ${baby.name}\'s Poop Diary 💩')),
                    body: const AppLoadingView(
                        message: 'Loading poop entries...'),
                  );
                }

                if (entrySnap.hasError && entrySnap.data == null) {
                  return Scaffold(
                    appBar:
                        AppBar(title: Text('👶 ${baby.name}\'s Poop Diary 💩')),
                    body: AppErrorView(
                      message: friendlyError(entrySnap.error!),
                      onRetry: () => setState(() {
                        _entriesStream = null;
                        _cachedBabyId = null;
                      }),
                    ),
                  );
                }

                final entries = entrySnap.data ?? [];

                final dayEntries = entries
                    .where((e) => isSameDay(e.timestamp, _selectedDay))
                    .toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return Scaffold(
                  appBar: AppBar(
                    title: Text('👶 ${baby.name}\'s Poop Diary 💩'),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: 'Switch baby',
                        icon: const Icon(Icons.switch_account),
                        onSelected: (babyId) => setState(() {
                          _selectedBabyId = babyId;
                          _entriesStream = null;
                          _cachedBabyId = null;
                        }),
                        itemBuilder: (_) => babies
                            .map(
                              (candidate) => PopupMenuItem(
                                value: candidate.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      candidate.id == baby.id
                                          ? Icons.check
                                          : Icons.child_care,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(candidate.name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'baby') {
                            final selectedBabyId =
                                await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (_) => BabySettingsScreen(
                                  babies: babies,
                                  selectedBabyId: baby.id,
                                ),
                              ),
                            );
                            if (selectedBabyId != null && mounted) {
                              setState(() {
                                _selectedBabyId = selectedBabyId;
                                _entriesStream = null;
                                _cachedBabyId = null;
                              });
                            }
                          } else if (val == 'account') {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AccountSettingsScreen(babies: babies),
                              ),
                            );
                          } else if (val == 'signout') {
                            final nav = Navigator.of(context);
                            await auth.signOut();
                            if (!mounted) return;
                            nav.pushReplacementNamed('/login');
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'baby',
                            child: Row(
                              children: [
                                Icon(Icons.child_care,
                                    color: Color(0xFF4CAF50)),
                                SizedBox(width: 8),
                                Text('Your babies'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'account',
                            child: Row(
                              children: [
                                Icon(Icons.manage_accounts,
                                    color: Color(0xFF4CAF50)),
                                SizedBox(width: 8),
                                Text('Account settings'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'signout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Sign Out'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      CalendarWidget(
                        entries: entries,
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        onDaySelected: (day) => setState(() {
                          _selectedDay = day;
                          _focusedDay = day;
                        }),
                        onPageChanged: (day) =>
                            setState(() => _focusedDay = day),
                      ),
                      const Divider(height: 1),
                      if (dayEntries.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🌟', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 8),
                                Text(
                                  'No entries for this day',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap 💩 to log one!',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            children: [
                              DayEntriesHeader(
                                day: _selectedDay,
                                count: dayEntries.length,
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  itemCount: dayEntries.length,
                                  itemBuilder: (ctx, i) => PoopEntryTile(
                                    entry: dayEntries[i],
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LogPoopScreen(
                                            baby: baby,
                                            entry: dayEntries[i],
                                          ),
                                        ),
                                      );
                                    },
                                    onDelete: () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      try {
                                        await firestore.deleteEntry(
                                            baby.id, dayEntries[i].id);
                                      } catch (e) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(friendlyError(e)),
                                            backgroundColor:
                                                Colors.red.shade400,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LogPoopScreen(
                            baby: baby,
                            initialDate: _selectedDay,
                          ),
                        ),
                      );
                    },
                    icon: const Text('💩', style: TextStyle(fontSize: 20)),
                    label: const Text('Log Poop'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Empty home (shown when no baby is assigned) ─────────────────────────────

class _NoBabiesHome extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final AuthService auth;

  const _NoBabiesHome({
    required this.uid,
    required this.firestore,
    required this.auth,
  });

  @override
  State<_NoBabiesHome> createState() => _NoBabiesHomeState();
}

class _NoBabiesHomeState extends State<_NoBabiesHome> {
  bool _addingBaby = false;

  Future<void> _showAddBabyDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a baby'),
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
              setState(() => _addingBaby = true);
              try {
                await widget.firestore.addBaby(
                  widget.uid,
                  controller.text.trim(),
                  caregiverLabel: widget.auth.currentUserEmail,
                );
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(friendlyError(error)),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              } finally {
                if (mounted) setState(() => _addingBaby = false);
              }
            },
            child: const Text('Add baby'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showJoinBabyDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a shared baby'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'ABC123',
            ),
            validator: (value) => value == null || value.trim().length != 6
                ? 'Enter the 6-character invite code'
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
                final baby = await widget.firestore.joinBabyWithCode(
                  widget.uid,
                  controller.text,
                  caregiverLabel: widget.auth.currentUserEmail,
                );
                if (!mounted || !dialogContext.mounted) return;
                if (baby == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Invite code not found or already used.'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
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
            child: const Text('Join baby'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await widget.auth.signOut();
    if (!mounted) return;
    navigator.pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Potty Tracker'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'account') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen(babies: []),
                    ),
                  );
                } else if (value == 'signout') {
                  await _signOut();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'account',
                  child: Row(
                    children: [
                      Icon(Icons.manage_accounts, color: Color(0xFF4CAF50)),
                      SizedBox(width: 8),
                      Text('Account settings'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👶', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                const Text(
                  'No babies yet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add a baby to start their poop diary.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addingBaby ? null : _showAddBabyDialog,
                  icon: _addingBaby
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Add a baby'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _addingBaby ? null : _showJoinBabyDialog,
                  child: const Text('Have an invite code? Join a shared baby'),
                ),
              ],
            ),
          ),
        ),
      );
}
