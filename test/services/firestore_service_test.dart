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
    test('addBaby creates a baby document', () async {
      final baby = await service.addBaby('user1', 'Alice');
      expect(baby.name, 'Alice');
      expect(baby.id, isNotEmpty);
    });

    test('babiesStream emits added baby', () async {
      await service.addBaby('user1', 'Bob');

      final babies = await service.babiesStream('user1').first;
      expect(babies.length, 1);
      expect(babies.first.name, 'Bob');
    });

    test('deleteBaby removes the document', () async {
      final baby = await service.addBaby('user1', 'Charlie');
      await service.deleteBaby('user1', baby.id);

      final babies = await service.babiesStream('user1').first;
      expect(babies, isEmpty);
    });

    test('babies are isolated by user', () async {
      await service.addBaby('user1', 'Alice');
      await service.addBaby('user2', 'Other');

      final user1Babies = await service.babiesStream('user1').first;
      final user2Babies = await service.babiesStream('user2').first;

      expect(user1Babies.length, 1);
      expect(user1Babies.first.name, 'Alice');
      expect(user2Babies.length, 1);
      expect(user2Babies.first.name, 'Other');
    });
  });

  group('FirestoreService - poop entries', () {
    test('addEntry creates an entry', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 10, 30),
        consistency: Consistency.normal,
      );

      expect(entry.babyId, baby.id);
      expect(entry.consistency, Consistency.normal);
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

      final entries = await service.entriesStream('user1', baby.id).first;
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

      await service.deleteEntry('user1', entry.id);
      final entries = await service.entriesStream('user1', baby.id).first;
      expect(entries, isEmpty);
    });

    test('multiple entries are returned ordered by timestamp desc', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final t1 = DateTime(2024, 6, 15, 8, 0);
      final t2 = DateTime(2024, 6, 15, 12, 0);
      final t3 = DateTime(2024, 6, 15, 16, 0);

      await service.addEntry(
          uid: 'user1', babyId: baby.id, timestamp: t1,
          consistency: Consistency.normal);
      await service.addEntry(
          uid: 'user1', babyId: baby.id, timestamp: t2,
          consistency: Consistency.soft);
      await service.addEntry(
          uid: 'user1', babyId: baby.id, timestamp: t3,
          consistency: Consistency.hard);

      final entries = await service.entriesStream('user1', baby.id).first;
      expect(entries.length, 3);
      // Should be descending (most recent first)
      expect(entries[0].timestamp.compareTo(entries[1].timestamp),
          greaterThanOrEqualTo(0));
    });
  });
}
