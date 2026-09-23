import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/achievement.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';

PoopEntry entry(DateTime day, {String? id, String? achievementDay}) =>
    PoopEntry(
      id: id ?? PoopEntry.dayKey(day),
      babyId: 'baby',
      timestamp: day,
      achievementDay: achievementDay,
      consistency: Consistency.soft,
      createdAt: day,
    );

List<PoopEntry> streak(int length, {DateTime? start}) => List.generate(
    length,
    (i) => entry(DateTime(
        (start ?? DateTime(2026, 1, 1)).year,
        (start ?? DateTime(2026, 1, 1)).month,
        (start ?? DateTime(2026, 1, 1)).day + i)));

void main() {
  test('empty and six days earn nothing; 7, 14, 30 earn once per streak', () {
    for (final length in [0, 6, 7, 13, 14, 29, 30, 60]) {
      final summary = AchievementSummary.fromEntries(streak(length));
      for (final milestone in achievementMilestones) {
        expect(summary.count(milestone), length >= milestone ? 1 : 0,
            reason: '$length days, milestone $milestone');
      }
    }
  });

  test('a missed day permits repeat badges and keeps previous awards', () {
    final summary = AchievementSummary.fromEntries([
      ...streak(30),
      ...streak(14, start: DateTime(2026, 2, 2)),
    ]);
    expect(summary.count(7), 2);
    expect(summary.count(14), 2);
    expect(summary.count(30), 1);
  });

  test('multiple entries on a day count once, regardless of sort order', () {
    final entries = streak(7);
    entries.add(entry(DateTime(2026, 1, 1, 22), id: 'duplicate'));
    expect(AchievementSummary.fromEntries(entries.reversed).count(7), 1);
  });

  test('backfilling a gap can earn multiple milestones; deletions recalculate',
      () {
    final all = streak(30);
    final missingMiddle = all.where((e) => e.timestamp.day != 15).toList();
    final before = AchievementSummary.fromEntries(missingMiddle);
    final after = AchievementSummary.fromEntries(all);
    expect(before.count(7), 2);
    expect(before.count(30), 0);
    expect(after.count(7), 1);
    expect(after.newlyEarnedSince(before).map((a) => a.days), [30]);
    expect(AchievementSummary.fromEntries(all.take(6)).count(7), 0);
  });

  test('backfilling shifts award dates without celebrating unchanged counts',
      () {
    final all = streak(14);
    final before = AchievementSummary.fromEntries(all.skip(1));
    final completed = AchievementSummary.fromEntries(all);
    expect(completed.newlyEarnedSince(before).map((a) => a.days), [14]);
  });

  test('calendar arithmetic spans month, year, leap day and DST boundaries',
      () {
    for (final start in [
      DateTime(2024, 2, 25),
      DateTime(2026, 3, 26),
      DateTime(2026, 10, 22),
      DateTime(2026, 12, 28)
    ]) {
      expect(
          AchievementSummary.fromEntries(streak(7, start: start)).count(7), 1);
    }
  });

  test('recorded diary day wins over viewing timezone and edited timestamp',
      () {
    final entries = streak(7);
    entries[0] = entry(DateTime.utc(2025, 12, 31, 23, 30),
        id: entries[0].id, achievementDay: '2026-01-01');
    expect(AchievementSummary.fromEntries(entries).count(7), 1);
    entries[0] = entries[0].copyWith(timestamp: DateTime(2026, 6, 1));
    expect(AchievementSummary.fromEntries(entries).count(7), 1);
  });

  test(
      'tracker ignores edit snapshots and recalculates for additions/deletions',
      () {
    final tracker = AchievementTracker();
    final entries = streak(7);
    final initial = tracker.update(entries);
    final edited = [...entries]..[0] = entries[0].copyWith(notes: 'Edited');
    expect(identical(tracker.update(edited), initial), true);
    expect(tracker.update(entries.take(6).toList()).count(7), 0);
    expect(tracker.update(entries).count(7), 1);
  });
}
