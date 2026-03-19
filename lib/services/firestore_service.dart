import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/baby.dart';
import '../models/poop_entry.dart';
import '../models/consistency.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  final Uuid _uuid;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // ── Baby ──────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _babiesRef(String uid) =>
      _db.collection('users').doc(uid).collection('babies');

  Stream<List<Baby>> babiesStream(String uid) {
    return _babiesRef(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(Baby.fromFirestore).toList());
  }

  Future<Baby> addBaby(String uid, String name) async {
    final id = _uuid.v4();
    final baby = Baby(id: id, name: name, createdAt: DateTime.now());
    await _babiesRef(uid).doc(id).set(baby.toFirestore());
    return baby;
  }

  Future<void> deleteBaby(String uid, String babyId) async {
    await _babiesRef(uid).doc(babyId).delete();
  }

  Future<void> updateBabyName(String uid, String babyId, String newName) async {
    await _babiesRef(uid).doc(babyId).update({'name': newName});
  }

  // ── Poop Entries ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _entriesRef(String uid) =>
      _db.collection('users').doc(uid).collection('poop_entries');

  Stream<List<PoopEntry>> entriesStream(String uid, String babyId) {
    return _entriesRef(uid)
        .where('babyId', isEqualTo: babyId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PoopEntry.fromFirestore).toList());
  }

  Future<PoopEntry> addEntry({
    required String uid,
    required String babyId,
    required DateTime timestamp,
    required Consistency consistency,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final entry = PoopEntry(
      id: id,
      babyId: babyId,
      timestamp: timestamp,
      consistency: consistency,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _entriesRef(uid).doc(id).set(entry.toFirestore());
    return entry;
  }

  Future<void> deleteEntry(String uid, String entryId) async {
    await _entriesRef(uid).doc(entryId).delete();
  }
}
