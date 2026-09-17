import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/baby.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/services/diary_pdf_export_service.dart';

void main() {
  const service = DiaryPdfExportService();
  final now = DateTime(2026, 9, 16, 12);
  final baby = Baby(
    id: 'baby-1',
    name: 'Ada',
    ownerUid: 'caregiver-1',
    memberUids: const ['caregiver-1'],
    shareCode: 'ABC123',
    createdAt: now,
  );

  PoopEntry entry({
    required String id,
    required DateTime timestamp,
    PoopSize? size,
    PoopColor? color,
  }) =>
      PoopEntry(
        id: id,
        babyId: baby.id,
        timestamp: timestamp,
        consistency: Consistency.formed,
        size: size,
        color: color,
        createdAt: timestamp,
      );

  test('filters entries to the selected inclusive period', () {
    final entries = [
      entry(id: 'old', timestamp: now.subtract(const Duration(days: 7))),
      entry(id: 'start', timestamp: now.subtract(const Duration(days: 6))),
      entry(id: 'today', timestamp: now.subtract(const Duration(hours: 1))),
    ];

    final selected = service.entriesForPeriod(
      entries: entries,
      period: DiaryExportPeriod.week,
      now: now,
    );

    expect(selected.map((item) => item.id), ['start', 'today']);
  });

  test('builds a PDF for an empty period', () async {
    final bytes = await service.build(
      baby: baby,
      entries: const [],
      period: DiaryExportPeriod.week,
      now: now,
    );

    expect(bytes.take(4), [37, 80, 68, 70]);
  });

  test('builds a PDF with optional size and color data', () async {
    final bytes = await service.build(
      baby: baby,
      entries: [
        entry(
          id: 'entry-1',
          timestamp: now.subtract(const Duration(days: 1)),
          size: PoopSize.medium,
          color: PoopColor.brown,
        ),
      ],
      period: DiaryExportPeriod.week,
      now: now,
    );

    expect(bytes.length, greaterThan(1000));
  });

  test('breakdowns include only recorded values and n/a entries', () {
    final entries = [
      entry(id: 'one', timestamp: now, size: PoopSize.small),
      entry(id: 'two', timestamp: now, size: PoopSize.small),
      entry(id: 'three', timestamp: now),
    ];

    final items = service.breakdownItems(
      values: PoopSize.values,
      entries: entries,
      labelFor: (value) => value.label,
      valueFor: (entry) => entry.size,
    );

    expect(items, ['Small: 2', 'n/a: 1']);
  });
}
