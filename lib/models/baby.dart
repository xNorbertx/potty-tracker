import 'package:cloud_firestore/cloud_firestore.dart';

class Baby {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  final Map<String, String> memberLabels;
  final Map<String, String> memberEmails;
  final String shareCode;
  final DateTime createdAt;
  final int? consentVersion;
  final String? consentBy;
  final DateTime? consentAt;
  final bool diaryDeletionRequested;
  // A pending server timestamp is null in Firestore's local snapshots. Wait
  // for it to resolve before subscribing to entries protected by consent rules.
  bool get hasDiaryConsent =>
      consentVersion == 1 && consentAt != null && !diaryDeletionRequested;

  Baby({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    this.memberLabels = const {},
    this.memberEmails = const {},
    required this.shareCode,
    required this.createdAt,
    this.consentVersion,
    this.consentBy,
    this.consentAt,
    this.diaryDeletionRequested = false,
  });

  factory Baby.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Baby(
      id: doc.id,
      name: d['name'] as String,
      ownerUid: d['ownerUid'] as String,
      memberUids: List<String>.from(d['memberUids'] ?? []),
      memberLabels: Map<String, String>.from(d['memberLabels'] ?? {}),
      memberEmails: Map<String, String>.from(d['memberEmails'] ?? {}),
      shareCode: d['shareCode'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      consentVersion: d['consentVersion'] as int?,
      consentBy: d['consentBy'] as String?,
      consentAt: (d['consentAt'] as Timestamp?)?.toDate(),
      diaryDeletionRequested: d['diaryDeletionRequested'] == true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        if (consentVersion != null) 'consentVersion': consentVersion,
        if (consentBy != null) 'consentBy': consentBy,
        if (consentAt != null) 'consentAt': Timestamp.fromDate(consentAt!),
        if (diaryDeletionRequested) 'diaryDeletionRequested': true,
        'name': name,
        'ownerUid': ownerUid,
        'memberUids': memberUids,
        'memberLabels': memberLabels,
        'memberEmails': memberEmails,
        'shareCode': shareCode,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Baby copyWith({
    String? id,
    String? name,
    String? ownerUid,
    List<String>? memberUids,
    Map<String, String>? memberLabels,
    Map<String, String>? memberEmails,
    String? shareCode,
    DateTime? createdAt,
  }) {
    return Baby(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid ?? this.ownerUid,
      memberUids: memberUids ?? this.memberUids,
      memberLabels: memberLabels ?? this.memberLabels,
      memberEmails: memberEmails ?? this.memberEmails,
      shareCode: shareCode ?? this.shareCode,
      createdAt: createdAt ?? this.createdAt,
      consentVersion: consentVersion,
      consentBy: consentBy,
      consentAt: consentAt,
      diaryDeletionRequested: diaryDeletionRequested,
    );
  }
}
