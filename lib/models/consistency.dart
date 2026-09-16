import 'package:flutter/material.dart';

enum Consistency {
  soft,
  formed,
  watery,
  hard,
}

extension ConsistencyExtension on Consistency {
  String get emoji {
    switch (this) {
      case Consistency.soft:
        return '💛';
      case Consistency.formed:
        return '💩';
      case Consistency.watery:
        return '💧';
      case Consistency.hard:
        return '🪨';
    }
  }

  String get label {
    switch (this) {
      case Consistency.soft:
        return 'Soft/Mushy';
      case Consistency.formed:
        return 'Formed';
      case Consistency.watery:
        return 'Watery/Runny';
      case Consistency.hard:
        return 'Hard/Pellets';
    }
  }

  Color get color {
    switch (this) {
      case Consistency.soft:
        return const Color(0xFFFDD835);
      case Consistency.formed:
        return const Color(0xFF6D4C41);
      case Consistency.watery:
        return const Color(0xFF29B6F6);
      case Consistency.hard:
        return const Color(0xFF757575);
    }
  }

  String get value => name;

  static Consistency fromString(String value) {
    // Older logs may contain the former colour-related "unusual" option.
    // Treat it as the neutral soft category so those records remain readable.
    if (value == 'unusual') return Consistency.soft;
    return Consistency.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Consistency.soft,
    );
  }
}
