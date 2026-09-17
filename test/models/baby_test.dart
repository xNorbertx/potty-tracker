import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/baby.dart';

void main() {
  group('Baby', () {
    test('round-trips all persisted fields through Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final createdAt = DateTime(2024, 6, 15, 10, 30);
      final baby = Baby(
        id: 'baby-1',
        name: 'Ada',
        ownerUid: 'owner-1',
        memberUids: ['owner-1', 'parent-2'],
        memberLabels: const {
          'owner-1': 'owner@example.com',
          'parent-2': 'parent@example.com',
        },
        memberEmails: const {
          'owner-1': 'owner@example.com',
          'parent-2': 'parent@example.com',
        },
        shareCode: 'ABC123',
        createdAt: createdAt,
      );

      await firestore.collection('babies').doc(baby.id).set(baby.toFirestore());
      final restored = Baby.fromFirestore(
        await firestore.collection('babies').doc(baby.id).get(),
      );

      expect(restored.id, baby.id);
      expect(restored.name, 'Ada');
      expect(restored.ownerUid, 'owner-1');
      expect(restored.memberUids, ['owner-1', 'parent-2']);
      expect(restored.memberLabels['parent-2'], 'parent@example.com');
      expect(restored.memberEmails['parent-2'], 'parent@example.com');
      expect(restored.shareCode, 'ABC123');
      expect(restored.createdAt, createdAt);
    });

    test('supports legacy babies without members or a share code', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('babies').doc('legacy').set({
        'name': 'Legacy',
        'ownerUid': 'owner-1',
        'createdAt': DateTime(2024, 1, 1),
      });

      final baby = Baby.fromFirestore(
        await firestore.collection('babies').doc('legacy').get(),
      );

      expect(baby.memberUids, isEmpty);
      expect(baby.shareCode, isEmpty);
      expect(baby.memberLabels, isEmpty);
    });

    test('copyWith preserves unspecified data', () {
      final baby = Baby(
        id: 'baby-1',
        name: 'Ada',
        ownerUid: 'owner-1',
        memberUids: const ['owner-1'],
        shareCode: 'ABC123',
        createdAt: DateTime(2024, 1, 1),
      );

      final renamed = baby.copyWith(name: 'Grace');

      expect(renamed.name, 'Grace');
      expect(renamed.id, baby.id);
      expect(renamed.memberUids, baby.memberUids);
      expect(renamed.createdAt, baby.createdAt);
    });
  });
}
