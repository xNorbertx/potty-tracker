import 'package:cloud_firestore/cloud_firestore.dart';

class Baby {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  final Map<String, String> memberLabels;
  final String shareCode;
  final DateTime createdAt;

  Baby({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    this.memberLabels = const {},
    required this.shareCode,
    required this.createdAt,
  });

  factory Baby.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Baby(
      id: doc.id,
      name: d['name'] as String,
      ownerUid: d['ownerUid'] as String,
      memberUids: List<String>.from(d['memberUids'] ?? []),
      memberLabels: Map<String, String>.from(d['memberLabels'] ?? {}),
      shareCode: d['shareCode'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ownerUid': ownerUid,
        'memberUids': memberUids,
        'memberLabels': memberLabels,
        'shareCode': shareCode,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Baby copyWith({
    String? id,
    String? name,
    String? ownerUid,
    List<String>? memberUids,
    Map<String, String>? memberLabels,
    String? shareCode,
    DateTime? createdAt,
  }) {
    return Baby(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid ?? this.ownerUid,
      memberUids: memberUids ?? this.memberUids,
      memberLabels: memberLabels ?? this.memberLabels,
      shareCode: shareCode ?? this.shareCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
