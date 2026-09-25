import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VerificationService {
  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;

  VerificationService({FirebaseFirestore? db, FirebaseFunctions? functions})
      : _db = db ?? FirebaseFirestore.instance,
        _functions = functions;

  FirebaseFunctions get _client => _functions ?? FirebaseFunctions.instance;

  Stream<bool> verifiedStream(String uid, String? email) => _db
      .collection('verified_emails')
      .doc(uid)
      .snapshots()
      .map((snapshot) => email != null && snapshot.data()?['email'] == email);

  Future<bool> refresh(String uid, String? email) async {
    final proof = await _db.collection('verified_emails').doc(uid).get(
          const GetOptions(source: Source.server),
        );
    return email != null && proof.data()?['email'] == email;
  }

  Future<void> resend() async {
    await _client.httpsCallable('resendVerificationEmail').call<void>();
  }

  Future<void> deleteDiary(String babyId) async {
    await _client
        .httpsCallable('deleteCaregiverDiary')
        .call<void>({'babyId': babyId});
  }

  Future<String> createInvitation(String babyId) async {
    final result = await _client
        .httpsCallable('createCaregiverInvitation')
        .call<Map<String, dynamic>>({'babyId': babyId});
    return result.data['code'] as String;
  }
}
