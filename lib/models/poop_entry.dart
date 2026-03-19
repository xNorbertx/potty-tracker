import 'package:cloud_firestore/cloud_firestore.dart';
import 'consistency.dart';

class PoopEntry {
  final String id;
  final String babyId;
  final DateTime timestamp;
  final Consistency consistency;
  final String? notes;
  final DateTime createdAt;

  PoopEntry({
    required this.id,
    required this.babyId,
    required this.timestamp,
    required this.consistency,
    this.notes,
    required this.createdAt,
  });

  factory PoopEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoopEntry(
      id: doc.id,
      babyId: data['babyId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      consistency: ConsistencyExtension.fromString(
        data['consistency'] as String? ?? 'normal',
      ),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'babyId': babyId,
      'timestamp': Timestamp.fromDate(timestamp),
      'consistency': consistency.value,
      if (notes != null) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PoopEntry copyWith({
    String? id,
    String? babyId,
    DateTime? timestamp,
    Consistency? consistency,
    String? notes,
    DateTime? createdAt,
  }) {
    return PoopEntry(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      timestamp: timestamp ?? this.timestamp,
      consistency: consistency ?? this.consistency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
