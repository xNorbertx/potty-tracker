import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../models/poop_entry.dart';
import '../models/consistency.dart';
import '../models/poop_size.dart';
import '../models/poop_color.dart';

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

  Stream<List<Baby>> babiesStream(String uid) {
    return _babiesRef
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Baby.fromFirestore).toList());
  }

  Future<Baby> addBaby(String uid, String name) async {
    final id = _uuid.v4();
    final shareCode = _generateShareCode();
    final baby = Baby(
      id: id,
      name: name,
      ownerUid: uid,
      memberUids: [uid],
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

  Future<Baby?> joinBabyWithCode(String uid, String code) async {
    final codeDoc = await _db
        .collection('share_codes')
        .doc(code.toUpperCase().trim())
        .get();
    if (!codeDoc.exists) return null;
    final babyId = codeDoc.data()!['babyId'] as String;
    final babyRef = _babiesRef.doc(babyId);

    try {
      await babyRef.update({
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') return null;
      rethrow;
    }

    final updatedDoc = await babyRef.get();
    if (!updatedDoc.exists) return null;
    return Baby.fromFirestore(updatedDoc);
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

  Future<PoopEntry> addEntry({
    required String uid,
    required String babyId,
    required DateTime timestamp,
    required Consistency consistency,
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
      createdAt: DateTime.now(),
    );
    await _entriesRef(babyId).doc(id).set(entry.toFirestore());
    return entry;
  }

  Future<void> deleteEntry(String babyId, String entryId) async {
    await _entriesRef(babyId).doc(entryId).delete();
  }
}
