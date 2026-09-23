// Local UI preview using synthetic entries; no Firebase initialization or data.
// flutter run -d web-server -t tool/achievement_preview.dart --web-port 8091
import 'package:flutter/material.dart';
import 'package:potty_tracker/models/achievement.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/theme/app_theme.dart';
import 'package:potty_tracker/widgets/achievement_badges.dart';

void main() =>
    runApp(MaterialApp(theme: AppTheme.theme, home: const Preview()));

class Preview extends StatelessWidget {
  const Preview({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final start in [1, 20, 40])
        for (var i = 0; i < (start == 1 ? 14 : 7); i++)
          PoopEntry(
              id: '$start-$i',
              babyId: 'preview',
              timestamp: DateTime(2026, 1, start + i),
              consistency: Consistency.soft,
              createdAt: DateTime(2026, 1, start + i))
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Ada')),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          AchievementBadges(entries: entries),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => showAchievementCelebration(
                  context, 'Ada', [AchievementAward(7, DateTime(2026, 1, 7))]),
              child: const Text('Preview celebration')),
          const SizedBox(height: 24),
          const AchievementBadges(entries: []),
        ]),
      )),
    );
  }
}
