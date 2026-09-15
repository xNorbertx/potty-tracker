import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeFirestore);
  });

  group('FirestoreService - caregiver profiles', () {
    test('saves and reads a caregiver profile', () async {
      const profile = CaregiverProfile(
        uid: 'user1',
        name: 'Norbert',
        email: 'norbert@example.com',
      );

      await service.saveCaregiverProfile(profile);

      final saved = await service.getCaregiverProfile('user1');
      expect(saved?.name, 'Norbert');
      expect(saved?.email, 'norbert@example.com');
    });
  });

  group('FirestoreService - babies', () {
    test('addBaby creates a baby document with share code', () async {
      final baby = await service.addBaby(
        'user1',
        'Alice',
        caregiverLabel: 'parent@example.com',
      );
      expect(baby.name, 'Alice');
      expect(baby.id, isNotEmpty);
      expect(baby.ownerUid, 'user1');
      expect(baby.memberUids, contains('user1'));
      expect(baby.shareCode, isNotEmpty);
      expect(baby.shareCode.length, 6);
      expect(baby.memberLabels, {'user1': 'parent@example.com'});
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
      final joined = await service.joinBabyWithCode(
        'user2',
        baby.shareCode,
        caregiverLabel: 'other@example.com',
      );

      expect(joined, isNotNull);
      expect(joined!.memberUids, containsAll(['user1', 'user2']));
      expect(joined.memberLabels['user2'], 'other@example.com');
    });

    test('joinBabyWithCode ignores casing and surrounding whitespace',
        () async {
      final baby = await service.addBaby('user1', 'Charlie');

      final joined = await service.joinBabyWithCode(
        'user2',
        '  ${baby.shareCode.toLowerCase()}  ',
      );

      expect(joined?.id, baby.id);
      expect(joined?.memberUids, contains('user2'));
    });

    test('joinBabyWithCode returns null for invalid code', () async {
      final result = await service.joinBabyWithCode('user2', 'XXXXXX');
      expect(result, isNull);
    });

    test('updateBabyName updates only the requested baby', () async {
      final first = await service.addBaby('user1', 'Alice');
      final second = await service.addBaby('user1', 'Bea');

      await service.updateBabyName(first.id, 'Alicia');
      final babies = await service.babiesStream('user1').first;

      expect(babies.singleWhere((baby) => baby.id == first.id).name, 'Alicia');
      expect(babies.singleWhere((baby) => baby.id == second.id).name, 'Bea');
    });

    test('removeAccountData removes a user from a shared baby', () async {
      final baby = await service.addBaby('parent-1', 'Alice');
      final sharedBaby =
          await service.joinBabyWithCode('parent-2', baby.shareCode);

      await service.removeAccountData(
        uid: 'parent-2',
        babies: [sharedBaby!],
      );

      final saved = await fakeFirestore.collection('babies').doc(baby.id).get();
      expect(saved.exists, isTrue);
      expect(saved.data()?['memberUids'], ['parent-1']);
    });

    test('removeAccountData deletes a sole-member baby and its data', () async {
      final baby = await service.addBaby('parent-1', 'Alice');
      final entry = await service.addEntry(
        uid: 'parent-1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 10),
        consistency: Consistency.soft,
      );

      await service.removeAccountData(uid: 'parent-1', babies: [baby]);

      expect(
        (await fakeFirestore.collection('babies').doc(baby.id).get()).exists,
        isFalse,
      );
      expect(
        (await fakeFirestore
                .collection('share_codes')
                .doc(baby.shareCode)
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await fakeFirestore
                .collection('babies')
                .doc(baby.id)
                .collection('entries')
                .doc(entry.id)
                .get())
            .exists,
        isFalse,
      );
    });

    test('deleteBaby removes its poop logs and share code', () async {
      final baby = await service.addBaby('parent-1', 'Alice');
      final entry = await service.addEntry(
        uid: 'parent-1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 10),
        consistency: Consistency.soft,
      );

      await service.deleteBaby(baby);

      expect(
        (await fakeFirestore.collection('babies').doc(baby.id).get()).exists,
        isFalse,
      );
      expect(
        (await fakeFirestore
                .collection('babies')
                .doc(baby.id)
                .collection('entries')
                .doc(entry.id)
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await fakeFirestore
                .collection('share_codes')
                .doc(baby.shareCode)
                .get())
            .exists,
        isFalse,
      );
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

    test('addEntry persists optional size, colour and logging user', () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 10),
        consistency: Consistency.soft,
      );

      final saved = await fakeFirestore
          .collection('babies')
          .doc(baby.id)
          .collection('entries')
          .doc(entry.id)
          .get();
      expect(saved.data()?['loggedBy'], 'user1');
      expect(saved.data(), isNot(contains('size')));
      expect(saved.data(), isNot(contains('color')));
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

    test('updateEntry changes editable fields and clears removed options',
        () async {
      final baby = await service.addBaby('user1', 'Alice');
      final entry = await service.addEntry(
        uid: 'user1',
        babyId: baby.id,
        timestamp: DateTime(2024, 6, 15, 9),
        consistency: Consistency.soft,
        size: PoopSize.large,
        color: PoopColor.brown,
        notes: 'Original note',
      );

      await service.updateEntry(
        babyId: baby.id,
        entryId: entry.id,
        timestamp: DateTime(2024, 6, 16, 10, 30),
        consistency: Consistency.watery,
      );

      final updated = (await service.entriesStream(baby.id).first).single;
      expect(updated.id, entry.id);
      expect(updated.timestamp, DateTime(2024, 6, 16, 10, 30));
      expect(updated.consistency, Consistency.watery);
      expect(updated.size, isNull);
      expect(updated.color, isNull);
      expect(updated.notes, isNull);
      expect(updated.loggedBy, 'user1');
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
