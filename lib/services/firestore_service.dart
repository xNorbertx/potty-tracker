import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../models/caregiver_profile.dart';
import '../models/poop_entry.dart';
import '../models/consistency.dart';
import '../models/poop_size.dart';
import '../models/poop_color.dart';
import '../models/achievement.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  final Uuid _uuid;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // ── Share code generation ─────────────────────────────────────────────────

  String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Babies ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _babiesRef =>
      _db.collection('babies');

  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      _db.collection('caregiver_profiles');

  Future<({String name, String email})> _caregiverDetails(
    String uid,
    String? email,
  ) async {
    final profile = await getCaregiverProfile(uid);
    return (
      name: profile?.name.trim().isNotEmpty == true
          ? profile!.name.trim()
          : 'Caregiver',
      email: profile?.email.trim().isNotEmpty == true
          ? profile!.email.trim()
          : email?.trim() ?? '',
    );
  }

  Stream<CaregiverProfile?> caregiverProfileStream(String uid) =>
      _profilesRef.doc(uid).snapshots().map(
            (snapshot) => snapshot.exists
                ? CaregiverProfile.fromFirestore(snapshot)
                : null,
          );

  Future<CaregiverProfile?> getCaregiverProfile(String uid) async {
    final snapshot = await _profilesRef.doc(uid).get();
    return snapshot.exists ? CaregiverProfile.fromFirestore(snapshot) : null;
  }

  Future<void> saveCaregiverProfile(CaregiverProfile profile) =>
      _profilesRef.doc(profile.uid).set(profile.toFirestore());

  Stream<List<Baby>> babiesStream(String uid) {
    return _babiesRef
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Baby.fromFirestore).toList());
  }

  Future<Baby> addBaby(String uid, String name,
      {String? caregiverLabel}) async {
    final caregiver = await _caregiverDetails(uid, caregiverLabel);
    final id = _uuid.v4();
    final shareCode = _generateShareCode();
    final baby = Baby(
      id: id,
      name: name,
      ownerUid: uid,
      memberUids: [uid],
      memberLabels: {uid: caregiver.name},
      memberEmails: {uid: caregiver.email},
      shareCode: shareCode,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    batch.set(_babiesRef.doc(id), baby.toFirestore());
    batch.set(_db.collection('share_codes').doc(shareCode), {'babyId': id});
    await batch.commit();
    return baby;
  }

  Future<void> updateBabyName(String babyId, String newName) async {
    await _babiesRef.doc(babyId).update({'name': newName});
  }

  Future<Baby?> joinBabyWithCode(
    String uid,
    String code, {
    String? caregiverLabel,
  }) async {
    final caregiver = await _caregiverDetails(uid, caregiverLabel);
    final codeDoc = await _db
        .collection('share_codes')
        .doc(code.toUpperCase().trim())
        .get();
    if (!codeDoc.exists) return null;
    // Legacy and automatically rotated placeholders have no verified issuer.
    if (!codeDoc.data()!.containsKey('issuedBy')) return null;
    final babyId = codeDoc.data()!['babyId'] as String;
    final babyRef = _babiesRef.doc(babyId);

    try {
      // A prospective caregiver cannot read a private diary before joining it.
      // Use atomic field transforms instead; the rules validate the resulting
      // membership and code rotation in the same batch.
      final nextShareCode = _generateShareCode();
      final batch = _db.batch();
      batch.set(
          babyRef,
          {
            'memberUids': FieldValue.arrayUnion([uid]),
            'memberLabels': {
              uid: caregiver.name,
            },
            'memberEmails': {uid: caregiver.email},
            'shareCode': nextShareCode,
          },
          SetOptions(merge: true));
      batch.delete(codeDoc.reference);
      batch.set(
        _db.collection('share_codes').doc(nextShareCode),
        {'babyId': babyId},
      );
      await batch.commit();

      final joinedBaby = await babyRef.get();
      if (!joinedBaby.exists) return null;
      return Baby.fromFirestore(joinedBaby);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found' || e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Stream<Baby?> babyStream(String babyId) =>
      _babiesRef.doc(babyId).snapshots().map(
            (snapshot) => snapshot.exists ? Baby.fromFirestore(snapshot) : null,
          );

  Future<void> updateCaregiverDetails({
    required Baby baby,
    required String uid,
    required String name,
    required String email,
  }) async {
    if (baby.memberLabels[uid] == name && baby.memberEmails[uid] == email) {
      return;
    }
    await _babiesRef.doc(baby.id).update({
      'memberLabels': {...baby.memberLabels, uid: name},
      'memberEmails': {...baby.memberEmails, uid: email},
    });
  }

  /// Removes the signed-in caregiver from a shared diary without affecting the
  /// remaining caregivers or the diary's entries.
  Future<void> leaveBaby({required Baby baby, required String uid}) async {
    final otherMembers = baby.memberUids.where((id) => id != uid).toList();
    if (otherMembers.isEmpty) {
      throw StateError('The last caregiver cannot leave this diary.');
    }
    final updates = <String, dynamic>{
      'memberUids': otherMembers,
      'memberLabels.$uid': FieldValue.delete(),
    };
    if (baby.memberEmails.containsKey(uid)) {
      updates['memberEmails.$uid'] = FieldValue.delete();
    }
    await _babiesRef.doc(baby.id).update(updates);
  }

  Future<void> deleteBaby(Baby baby) async {
    final entryDocs = await _entriesRef(baby.id).get();
    final celebrationDocs = await _babiesRef
        .doc(baby.id)
        .collection('achievement_celebrations')
        .get();
    final operations = <DocumentReference<Map<String, dynamic>>>[
      ...entryDocs.docs.map((doc) => doc.reference),
      ...celebrationDocs.docs.map((doc) => doc.reference),
      if (baby.shareCode.isNotEmpty)
        _db.collection('share_codes').doc(baby.shareCode),
      _babiesRef.doc(baby.id),
    ];

    // Firestore batches allow a maximum of 500 writes.
    for (var start = 0; start < operations.length; start += 500) {
      final batch = _db.batch();
      for (final reference in operations.skip(start).take(500)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  // ── Poop Entries ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _entriesRef(String babyId) =>
      _babiesRef.doc(babyId).collection('entries');

  Stream<List<PoopEntry>> entriesStream(String babyId) {
    return _entriesRef(babyId).snapshots().map((snap) {
      final list = snap.docs.map(PoopEntry.fromFirestore).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<List<PoopEntry>> getEntries(String babyId) async {
    final snapshot = await _entriesRef(babyId).get(
      const GetOptions(source: Source.server),
    );
    return snapshot.docs.map(PoopEntry.fromFirestore).toList();
  }

  Future<List<AchievementAward>> claimAchievementCelebrations(
      String babyId, String uid, List<AchievementAward> awards) async {
    if (awards.isEmpty) return [];
    final collection =
        _babiesRef.doc(babyId).collection('achievement_celebrations');
    return _db.runTransaction((tx) async {
      final snapshots = await Future.wait(
          awards.map((award) => tx.get(collection.doc(award.id))));
      final fresh = <AchievementAward>[];
      for (var i = 0; i < awards.length; i++) {
        if (!snapshots[i].exists) {
          fresh.add(awards[i]);
          tx.set(snapshots[i].reference, {
            'days': awards[i].days,
            'loggedBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return fresh;
    });
  }

  Future<PoopEntry> addEntry({
    required String uid,
    required String babyId,
    required DateTime timestamp,
    required Consistency consistency,
    String? loggedByName,
    String? loggedByEmail,
    PoopSize? size,
    PoopColor? color,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final entry = PoopEntry(
      id: id,
      babyId: babyId,
      timestamp: timestamp,
      consistency: consistency,
      size: size,
      color: color,
      notes: notes,
      loggedBy: uid,
      loggedByName: loggedByName,
      loggedByEmail: loggedByEmail,
      createdAt: DateTime.now(),
    );
    await _entriesRef(babyId).doc(id).set(entry.toFirestore());
    return entry;
  }

  Future<void> deleteEntry(String babyId, String entryId) async {
    await _entriesRef(babyId).doc(entryId).delete();
  }

  Future<void> updateEntry({
    required String uid,
    required String babyId,
    required String entryId,
    required DateTime timestamp,
    required Consistency consistency,
    String? loggedByName,
    String? loggedByEmail,
    PoopSize? size,
    PoopColor? color,
    String? notes,
  }) async {
    final reference = _entriesRef(babyId).doc(entryId);
    final original = PoopEntry.fromFirestore(await reference.get());
    await reference.update({
      // Freeze the existing day for legacy entries too: editing never moves
      // their contribution between achievement streaks.
      'achievementDay': original.achievementDay,
      'timestamp': Timestamp.fromDate(timestamp),
      'consistency': consistency.value,
      'size': size?.value ?? FieldValue.delete(),
      'color': color?.value ?? FieldValue.delete(),
      'notes': notes ?? FieldValue.delete(),
      'loggedBy': uid,
      'loggedByName': loggedByName ?? FieldValue.delete(),
      'loggedByEmail': loggedByEmail ?? FieldValue.delete(),
    });
  }
}
