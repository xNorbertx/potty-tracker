import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeFirestore);
  });

  group('FirestoreService - babies', () {
    test('addBaby creates a baby document with share code', () async {
      final baby = await service.addBaby('user1', 'Alice');
      expect(baby.name, 'Alice');
      expect(baby.id, isNotEmpty);
      expect(baby.ownerUid, 'user1');
      expect(baby.memberUids, contains('user1'));
      expect(baby.shareCode, isNotEmpty);
      expect(baby.shareCode.length, 6);
    });

    test('babiesStream emits added baby', () async {
      await service.addBaby('user1', 'Bob');

      final babies = await service.babiesStream('user1').first;
      expect(babies.length, 1);
      expect(babies.first.name, 'Bob');
    });

    test('babies are isolated by user (memberUids)', () async {
      await service.addBaby('user1', 'Alice');
      await service.addBaby('user2', 'Other');

      final user1Babies = await service.babiesStream('user1').first;
      final user2Babies = await service.babiesStream('user2').first;

      expect(user1Babies.length, 1);
      expect(user1Babies.first.name, 'Alice');
      expect(user2Babies.length, 1);
      expect(user2Babies.first.name, 'Other');
    });

    test('joinBabyWithCode adds user to memberUids', () async {
      final baby = await service.addBaby('user1', 'Charlie');
      final joined =
          await service.joinBabyWithCode('user2', baby.shareCode);

      expect(joined, isNotNull);
      expect(joined!.memberUids, containsAll(['user1', 'user2']));
    });

    test('joinBabyWithCode returns null for invalid code', () async {
      final result = await service.joinBabyWithCode('user2', 'XXXXXX');
      expect(result, isNull);
    });
  });

  group('FirestoreService - poop entries', () {
    test('addEntry creates an entry', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 10, 30),
        consistency: Consistency.soft,
      );

      expect(entry.babyId, baby.id);
      expect(entry.consistency, Consistency.soft);
      expect(entry.loggedBy, 'user1');
    });

    test('addEntry with notes saves notes', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime.now(),
        consistency: Consistency.soft,
        notes: 'Yellow and mushy',
      );

      expect(entry.notes, 'Yellow and mushy');
    });

    test('entriesStream emits entries for baby', () async {
      final baby = await service.addBaby('user1', 'Alice');
      await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime.now(),
        consistency: Consistency.watery,
      );

      final entries = await service.entriesStream(baby.id).first;
      expect(entries.length, 1);
      expect(entries.first.consistency, Consistency.watery);
    });

    test('deleteEntry removes entry', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime.now(),
        consistency: Consistency.hard,
      );

      await service.deleteEntry(baby.id, entry.id);
      final entries = await service.entriesStream(baby.id).first;
      expect(entries, isEmpty);
    });

    test('multiple entries are returned ordered by timestamp desc', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final t1 = DateTime(2024, 6, 15, 8, 0);
      final t2 = DateTime(2024, 6, 15, 12, 0);
      final t3 = DateTime(2024, 6, 15, 16, 0);

      await service.addEntry(
          uid: 'user1',
          babyId: baby.id,
          timestamp: t1,
          consistency: Consistency.soft);
      await service.addEntry(
          uid: 'user1',
          babyId: baby.id,
          timestamp: t2,
          consistency: Consistency.soft);
      await service.addEntry(
          uid: 'user1',
          babyId: baby.id,
          timestamp: t3,
          consistency: Consistency.hard);

      final entries = await service.entriesStream(baby.id).first;
      expect(entries.length, 3);
      // Should be descending (most recent first)
      expect(entries[0].timestamp.compareTo(entries[1].timestamp),
          greaterThanOrEqualTo(0));
    });
  });
}
