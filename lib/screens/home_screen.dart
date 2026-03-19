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
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final babies = snapshot.data ?? [];

        // No baby set up yet → go to setup
        if (babies.isEmpty) {
          return const SetupScreen();
        }

        final baby = babies.first;

        return StreamBuilder<List<PoopEntry>>(
          stream: firestore.entriesStream(uid, baby.id),
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
                      if (val == 'signout') {
                        final nav = Navigator.of(context);
                        await auth.signOut();
                        if (!mounted) return;
                        nav.pushReplacementNamed('/login');
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
