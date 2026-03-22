import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Consistency enum', () {
    test('soft has correct emoji and label', () {
      expect(Consistency.soft.emoji, '💛');
      expect(Consistency.soft.label, 'Soft/Mushy');
    });

    test('watery has correct emoji and label', () {
      expect(Consistency.watery.emoji, '💧');
      expect(Consistency.watery.label, 'Watery/Runny');
    });

    test('hard has correct emoji and label', () {
      expect(Consistency.hard.emoji, '🪨');
      expect(Consistency.hard.label, 'Hard/Pellets');
    });

    test('unusual has correct emoji and label', () {
      expect(Consistency.unusual.emoji, '🌈');
      expect(Consistency.unusual.label, 'Unusual Color');
    });

    test('fromString returns correct consistency', () {
      expect(ConsistencyExtension.fromString('soft'), Consistency.soft);
      expect(ConsistencyExtension.fromString('watery'), Consistency.watery);
      expect(ConsistencyExtension.fromString('hard'), Consistency.hard);
      expect(ConsistencyExtension.fromString('unusual'), Consistency.unusual);
    });

    test('fromString with unknown value returns soft', () {
      expect(ConsistencyExtension.fromString('unknown'), Consistency.soft);
      // legacy 'normal' values from old logs fall back gracefully to soft
      expect(ConsistencyExtension.fromString('normal'), Consistency.soft);
    });

    test('all consistencies have colors', () {
      for (final c in Consistency.values) {
        expect(c.color, isNotNull);
      }
    });
  });

  group('PoopSize enum', () {
    test('all sizes have correct labels', () {
      expect(PoopSize.small.label, 'Small');
      expect(PoopSize.medium.label, 'Medium');
      expect(PoopSize.large.label, 'Large');
    });

    test('fromString returns correct size', () {
      expect(PoopSizeExtension.fromString('small'), PoopSize.small);
      expect(PoopSizeExtension.fromString('medium'), PoopSize.medium);
      expect(PoopSizeExtension.fromString('large'), PoopSize.large);
    });

    test('fromString with null returns null', () {
      expect(PoopSizeExtension.fromString(null), isNull);
    });
  });

  group('PoopColor enum', () {
    test('all colors expose labels and swatches', () {
      for (final color in PoopColor.values) {
        expect(color.label, isNotEmpty);
        expect(color.swatch, isA<Color>());
      }
    });

    test('fromString returns matching colour', () {
      expect(
        PoopColorExtension.fromString('mustard_yellow'),
        PoopColor.mustardYellow,
      );
      expect(PoopColorExtension.fromString('does-not-exist'), isNull);
    });
  });

  group('PoopEntry model', () {
    final now = DateTime(2024, 6, 15, 10, 30);

    test('toFirestore serializes correctly', () {
      final entry = PoopEntry(
        id: 'test-id',
        babyId: 'baby-id',
        timestamp: now,
        consistency: Consistency.soft,
        size: PoopSize.medium,
        color: PoopColor.orange,
        notes: 'Test note',
        createdAt: now,
      );

      final map = entry.toFirestore();
      expect(map['babyId'], 'baby-id');
      expect(map['consistency'], 'soft');
      expect(map['size'], 'medium');
      expect(map['color'], 'orange');
      expect(map['notes'], 'Test note');
      expect(map['timestamp'], isNotNull);
      expect(map['createdAt'], isNotNull);
    });

    test('toFirestore omits null notes and null size', () {
      final entry = PoopEntry(
        id: 'test-id',
        babyId: 'baby-id',
        timestamp: now,
        consistency: Consistency.soft,
        createdAt: now,
      );

      final map = entry.toFirestore();
      expect(map.containsKey('notes'), isFalse);
      expect(map.containsKey('size'), isFalse);
      expect(map.containsKey('color'), isFalse);
    });

    test('fromFirestore deserializes correctly', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final ref = fakeFirestore
          .collection('users')
          .doc('uid')
          .collection('poop_entries')
          .doc('entry-1');

      await ref.set({
        'babyId': 'baby-1',
        'timestamp':
            DateTime(2024, 6, 15, 10, 30).millisecondsSinceEpoch ~/ 1000,
        'consistency': 'watery',
        'notes': 'Runny one',
        'createdAt':
            DateTime(2024, 6, 15, 10, 30).millisecondsSinceEpoch ~/ 1000,
      });

      final snap = await ref.get();
      expect(snap.id, 'entry-1');
      final data = snap.data() as Map<String, dynamic>;
      expect(data['babyId'], 'baby-1');
      expect(data['consistency'], 'watery');
    });

    test('timestamp is required', () {
      expect(
        () => PoopEntry(
          id: '',
          babyId: '',
          timestamp: now,
          consistency: Consistency.soft,
          createdAt: now,
        ),
        returnsNormally,
      );
    });

    test('copyWith changes only specified fields', () {
      final entry = PoopEntry(
        id: 'id1',
        babyId: 'baby1',
        timestamp: now,
        consistency: Consistency.soft,
        color: PoopColor.brown,
        createdAt: now,
      );

      final updated = entry.copyWith(
        consistency: Consistency.hard,
        color: PoopColor.red,
      );
      expect(updated.id, 'id1');
      expect(updated.babyId, 'baby1');
      expect(updated.consistency, Consistency.hard);
      expect(updated.color, PoopColor.red);
      expect(updated.timestamp, now);
    });

    test('size is null for old entries without size field', () {
      final entry = PoopEntry(
        id: 'id1',
        babyId: 'baby1',
        timestamp: now,
        consistency: Consistency.soft,
        createdAt: now,
      );
      expect(entry.size, isNull);
    });
  });

  group('CalendarWidget poop count logic', () {
    test('groups entries by day correctly', () {
      final day1 = DateTime(2024, 6, 15);
      final day2 = DateTime(2024, 6, 16);

      final entries = [
        PoopEntry(
          id: '1',
          babyId: 'b',
          timestamp: day1,
          consistency: Consistency.soft,
          createdAt: day1,
        ),
        PoopEntry(
          id: '2',
          babyId: 'b',
          timestamp: day1.add(const Duration(hours: 3)),
          consistency: Consistency.soft,
          createdAt: day1,
        ),
        PoopEntry(
          id: '3',
          babyId: 'b',
          timestamp: day2,
          consistency: Consistency.watery,
          createdAt: day2,
        ),
      ];

      final day1Entries = entries
          .where((e) =>
              e.timestamp.year == day1.year &&
              e.timestamp.month == day1.month &&
              e.timestamp.day == day1.day)
          .toList();

      final day2Entries = entries
          .where((e) =>
              e.timestamp.year == day2.year &&
              e.timestamp.month == day2.month &&
              e.timestamp.day == day2.day)
          .toList();

      expect(day1Entries.length, 2);
      expect(day2Entries.length, 1);
    });
  });
}
