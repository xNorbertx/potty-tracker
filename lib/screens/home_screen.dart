import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/baby.dart';
import '../models/poop_entry.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/poop_entry_tile.dart';
import 'log_poop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Cache the entries stream so it isn't recreated on every build
  Stream<List<PoopEntry>>? _entriesStream;
  String? _cachedBabyId;
  String? _cachedUid;

  Stream<List<PoopEntry>> _getEntriesStream(
      FirestoreService firestore, String uid, String babyId) {
    if (_entriesStream == null ||
        _cachedBabyId != babyId ||
        _cachedUid != uid) {
      _entriesStream = firestore.entriesStream(uid, babyId);
      _cachedBabyId = babyId;
      _cachedUid = uid;
    }
    return _entriesStream!;
  }

  Future<void> _showRenameBabyDialog(
      BuildContext context, Baby baby, String uid) async {
    final ctrl = TextEditingController(text: baby.name);
    final formKey = GlobalKey<FormState>();
    final firestore = context.read<FirestoreService>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✏️ Edit Baby Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: "Baby's name"),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await firestore.updateBabyName(
                    uid, baby.id, ctrl.text.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baby name updated! 👶')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
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
    ctrl.dispose();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<List<Baby>>(
      stream: firestore.babiesStream(uid),
      builder: (context, babySnap) {
        // While loading, show spinner (prevents flash of setup screen)
        if (babySnap.connectionState == ConnectionState.waiting &&
            babySnap.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final babies = babySnap.data ?? [];

        // Confirmed empty → go to setup
        if (babies.isEmpty) {
          return _SetupScreen(uid: uid, firestore: firestore);
        }

        final baby = babies.first;
        final entriesStream = _getEntriesStream(firestore, uid, baby.id);

        return StreamBuilder<List<PoopEntry>>(
          stream: entriesStream,
          builder: (context, entrySnap) {
            // Use existing data during reloads — prevents flicker
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
                    onSelected: (val) async {
                      if (val == 'rename') {
                        await _showRenameBabyDialog(context, baby, uid);
                      } else if (val == 'signout') {
                        final nav = Navigator.of(context);
                        await auth.signOut();
                        if (!mounted) return;
                        nav.pushReplacementNamed('/login');
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Color(0xFF4CAF50)),
                            SizedBox(width: 8),
                            Text('Edit Baby Name'),
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
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌟',
                                style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            const Text(
                              'No entries for this day',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
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
                                onDelete: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    await firestore.deleteEntry(
                                        uid, dayEntries[i].id);
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error deleting: $e'),
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
                      builder: (_) => LogPoopScreen(baby: baby),
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
  }
}

// ── Inline setup widget (only shown on first use) ──────────────────────────

class _SetupScreen extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;

  const _SetupScreen({required this.uid, required this.firestore});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.firestore.addBaby(widget.uid, _nameCtrl.text.trim());
      // StreamBuilder will automatically show HomeScreen once baby is saved
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving baby: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👶', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                const Text(
                  "What's your baby's name?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "We'll use this to personalize your poop diary 💩",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Baby's name",
                          prefixIcon: Text('👶',
                              style: TextStyle(fontSize: 20)),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 52,
                            minHeight: 52,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Please enter your baby's name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Let's Go! 🚀"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
