import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/poop_entry.dart';

class AchievementBadges extends StatefulWidget {
  final List<PoopEntry> entries;
  const AchievementBadges({super.key, required this.entries});

  @override
  State<AchievementBadges> createState() => _AchievementBadgesState();
}

class _AchievementBadgesState extends State<AchievementBadges> {
  final _tracker = AchievementTracker();

  @override
  Widget build(BuildContext context) {
    final summary = _tracker.update(widget.entries);
    return Card(
      color: const Color(0xFFF1F8F1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Achievements',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF285E2B))),
            const SizedBox(height: 6),
            const Text('Streaks'),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final days in achievementMilestones)
                Expanded(
                    child: AchievementBadge(
                        days: days, count: summary.count(days))),
            ]),
          ],
        ),
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final int days;
  final int count;
  final bool showCount;
  const AchievementBadge(
      {super.key,
      required this.days,
      required this.count,
      this.showCount = true});

  @override
  Widget build(BuildContext context) {
    final earned = count > 0;
    final label =
        '$days consecutive days: ${earned ? 'earned $count ${count == 1 ? 'time' : 'times'}' : 'not yet earned'}';
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Column(children: [
          Stack(children: [
            AspectRatio(
                aspectRatio: 1,
                child: Opacity(
                  opacity: earned ? 1 : 0.25,
                  child: ColorFiltered(
                    colorFilter: earned
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Image.asset('assets/achievements/streak-$days.png',
                        cacheWidth: 480, fit: BoxFit.contain),
                  ),
                )),
            if (earned && showCount)
              Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0EEDB),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('×$count',
                        style: const TextStyle(
                            color: Color(0xFF285E2B),
                            fontWeight: FontWeight.bold)),
                  )),
          ]),
        ]),
      ),
    );
  }
}

Future<void> showAchievementCelebration(BuildContext context, String babyName,
    List<AchievementAward> awards) async {
  if (awards.isEmpty) return;
  final milestones = awards.map((award) => award.days).toSet().toList()..sort();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
          milestones.length == 1 ? 'New achievement!' : 'New achievements!',
          textAlign: TextAlign.center),
      content: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFE9B83D), size: 28),
          const SizedBox(height: 8),
          SizedBox(
              width: 300,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final days in milestones)
                  Expanded(
                      child: AchievementBadge(
                          days: days, count: 1, showCount: false)),
              ])),
          const SizedBox(height: 16),
          Text('$babyName reached ${milestones.join(', ')} days in a row!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF285E2B), fontWeight: FontWeight.w600)),
        ],
      )),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lovely!'))
      ],
    ),
  );
}
