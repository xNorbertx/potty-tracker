import 'package:cloud_firestore/cloud_firestore.dart';
import 'consistency.dart';
import 'poop_size.dart';
import 'poop_color.dart';

class PoopEntry {
  final String id;
  final String babyId;
  final DateTime timestamp;
  final Consistency consistency;
  final PoopSize? size;
  final PoopColor? color;
  final String? notes;
  final String? loggedBy;
  final DateTime createdAt;

  PoopEntry({
    required this.id,
    required this.babyId,
    required this.timestamp,
    required this.consistency,
    this.size,
    this.color,
    this.notes,
    this.loggedBy,
    required this.createdAt,
  });

  factory PoopEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PoopEntry(
      id: doc.id,
      babyId: data['babyId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      consistency: ConsistencyExtension.fromString(
        data['consistency'] as String? ?? 'soft',
      ),
      size: PoopSizeExtension.fromString(data['size'] as String?),
      color: PoopColorExtension.fromString(data['color'] as String?),
      notes: data['notes'] as String?,
      loggedBy: data['loggedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'babyId': babyId,
      'timestamp': Timestamp.fromDate(timestamp),
      'consistency': consistency.value,
      if (size != null) 'size': size!.value,
      if (color != null) 'color': color!.value,
      if (notes != null) 'notes': notes,
      if (loggedBy != null) 'loggedBy': loggedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PoopEntry copyWith({
    String? id,
    String? babyId,
    DateTime? timestamp,
    Consistency? consistency,
    PoopSize? size,
    PoopColor? color,
    String? notes,
    String? loggedBy,
    DateTime? createdAt,
  }) {
    return PoopEntry(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      timestamp: timestamp ?? this.timestamp,
      consistency: consistency ?? this.consistency,
      size: size ?? this.size,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      loggedBy: loggedBy ?? this.loggedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
