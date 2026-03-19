import 'package:cloud_firestore/cloud_firestore.dart';

class Baby {
  final String id;
  final String name;
  final DateTime createdAt;

  Baby({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Baby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Baby(
      id: doc.id,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Baby copyWith({String? id, String? name, DateTime? createdAt}) {
    return Baby(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
