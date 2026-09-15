import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverProfile {
  final String uid;
  final String name;
  final String email;

  const CaregiverProfile({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory CaregiverProfile.fromFirestore(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    return CaregiverProfile(
      uid: document.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
      };

  String get displayName => name.isNotEmpty ? name : email;
}
