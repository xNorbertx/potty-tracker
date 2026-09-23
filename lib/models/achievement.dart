import 'poop_entry.dart';

const achievementMilestones = [7, 14, 30];

class AchievementAward {
  final int days;
  final DateTime completedOn;
  const AchievementAward(this.days, this.completedOn);

  String get id => '$days-${PoopEntry.dayKey(completedOn)}';
}

class AchievementSummary {
  final List<AchievementAward> awards;
  const AchievementSummary(this.awards);

  int count(int days) => awards.where((award) => award.days == days).length;

  factory AchievementSummary.fromEntries(Iterable<PoopEntry> entries) {
    // UTC here is calendar arithmetic only. The date key represents the diary
    // day at creation, so DST never creates a 23/25-hour gap between days.
    final days = entries
        .map((entry) {
          final date = DateTime.parse(entry.achievementDay);
          return DateTime.utc(date.year, date.month, date.day);
        })
        .toSet()
        .toList()
      ..sort();
    final awards = <AchievementAward>[];
    var length = 0;
    DateTime? previous;
    for (final day in days) {
      length = previous != null && day.difference(previous).inDays == 1
          ? length + 1
          : 1;
      if (achievementMilestones.contains(length)) {
        awards.add(AchievementAward(length, day));
      }
      previous = day;
    }
    return AchievementSummary(List.unmodifiable(awards));
  }

  List<AchievementAward> newlyEarnedSince(AchievementSummary before) {
    final previousIds = before.awards.map((award) => award.id).toSet();
    return awards
        .where((award) =>
            count(award.days) > before.count(award.days) &&
            !previousIds.contains(award.id))
        .toList();
  }
}

/// Keep the previous result on edit-only snapshots; additions/deletions are
/// the only triggers. Stored achievement days preserve this across restarts.
class AchievementTracker {
  final Map<String, PoopEntry> _entries = {};
  AchievementSummary _summary = const AchievementSummary([]);

  AchievementSummary update(List<PoopEntry> entries) {
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length == _entries.length && ids.every(_entries.containsKey)) {
      return _summary;
    }
    _entries.removeWhere((id, _) => !ids.contains(id));
    for (final entry in entries) {
      _entries.putIfAbsent(entry.id, () => entry);
    }
    return _summary = AchievementSummary.fromEntries(_entries.values);
  }
}
