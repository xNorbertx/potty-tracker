import 'package:flutter/material.dart';

enum Consistency {
  soft,
  watery,
  hard,
  unusual,
}

extension ConsistencyExtension on Consistency {
  String get emoji {
    switch (this) {
      case Consistency.soft:
        return '💛';
      case Consistency.watery:
        return '💧';
      case Consistency.hard:
        return '🪨';
      case Consistency.unusual:
        return '🌈';
    }
  }

  String get label {
    switch (this) {
      case Consistency.soft:
        return 'Soft/Mushy';
      case Consistency.watery:
        return 'Watery/Runny';
      case Consistency.hard:
        return 'Hard/Pellets';
      case Consistency.unusual:
        return 'Unusual Color';
    }
  }

  Color get color {
    switch (this) {
      case Consistency.soft:
        return const Color(0xFFFDD835);
      case Consistency.watery:
        return const Color(0xFF29B6F6);
      case Consistency.hard:
        return const Color(0xFF757575);
      case Consistency.unusual:
        return const Color(0xFFAB47BC);
    }
  }

  String get value => name;

  static Consistency fromString(String value) {
    return Consistency.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Consistency.soft,
    );
  }
}
