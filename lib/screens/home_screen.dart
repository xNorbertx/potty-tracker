import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Stream<List<PoopEntry>> _getEntriesStream(
      FirestoreService firestore, String babyId) {
    if (_entriesStream == null || _cachedBabyId != babyId) {
      _entriesStream = firestore.entriesStream(babyId);
      _cachedBabyId = babyId;
    }
    return _entriesStream!;
  }

  Future<void> _showRenameBabyDialog(
      BuildContext context, Baby baby) async {
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
                await firestore.updateBabyName(baby.id, ctrl.text.trim());
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

  void _showShareDialog(BuildContext context, Baby baby) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Baby 👶'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give this code to your partner:'),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Code'),
            ),
            const SizedBox(height: 4),
            const Text(
              'They enter this code when setting up the app.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done')),
        ],
      ),
    );
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
        final entriesStream = _getEntriesStream(firestore, baby.id);

        return StreamBuilder<List<PoopEntry>>(
          stream: entriesStream,
          builder: (context, entrySnap) {
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
                        await _showRenameBabyDialog(context, baby);
                      } else if (val == 'share') {
                        _showShareDialog(context, baby);
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
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, color: Color(0xFF4CAF50)),
                            SizedBox(width: 8),
                            Text('Share Baby'),
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
                                        baby.id, dayEntries[i].id);
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
  }
}

// ── Inline setup widget (shown on first use or when no baby assigned) ──────

class _SetupScreen extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;

  const _SetupScreen({required this.uid, required this.firestore});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Create tab
  final _createFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // Join tab
  final _codeCtrl = TextEditingController();
  String? _joinError;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createBaby() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.firestore.addBaby(widget.uid, _nameCtrl.text.trim());
      // StreamBuilder will auto-update to show HomeScreen
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

  Future<void> _joinBaby() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _joinError = 'Please enter a share code.');
      return;
    }
    setState(() {
      _loading = true;
      _joinError = null;
    });
    try {
      final baby =
          await widget.firestore.joinBabyWithCode(widget.uid, code);
      if (!mounted) return;
      if (baby == null) {
        setState(() {
          _joinError = 'Code not found. Check the code and try again.';
          _loading = false;
        });
        return;
      }
      // StreamBuilder will auto-update to show HomeScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining baby: $e'),
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
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('👶', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            const Text(
              'Welcome to Potty Tracker',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF388E3C),
              indicatorColor: const Color(0xFF4CAF50),
              tabs: const [
                Tab(text: 'Create Baby'),
                Tab(text: 'Join with Code'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Create tab ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _createFormKey,
                      child: Column(
                        children: [
                          const Text(
                            "What's your baby's name?",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "We'll use this to personalize your poop diary 💩",
                            style:
                                TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
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
                              onPressed: _loading ? null : _createBaby,
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
                  ),

                  // ── Join tab ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text(
                          'Join an existing baby',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the 6-character share code from your partner\'s app.',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                letterSpacing: 6),
                            errorText: _joinError,
                            counterText: '',
                          ),
                          onChanged: (_) {
                            if (_joinError != null) {
                              setState(() => _joinError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _joinBaby,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Join Baby 🤝'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
