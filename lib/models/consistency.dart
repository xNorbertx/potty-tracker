import 'package:flutter/material.dart';
import '../l10n/app_locale.dart';

enum Consistency {
  hard,
  formed,
  pasty,
  soft,
  watery,
}

extension ConsistencyExtension on Consistency {
  String get emoji {
    switch (this) {
      case Consistency.hard:
        return '🪨';
      case Consistency.formed:
        return '💩';
      case Consistency.pasty:
        return '🟤';
      case Consistency.soft:
        return '💛';
      case Consistency.watery:
        return '💧';
    }
  }

  String get label {
    switch (this) {
      case Consistency.hard:
        return 'Hard/Pellets';
      case Consistency.formed:
        return 'Formed';
      case Consistency.pasty:
        return 'Pasty';
      case Consistency.soft:
        return 'Soft/Mushy';
      case Consistency.watery:
        return 'Watery/Runny';
    }
  }

  String labelFor(AppLanguage language) =>
      AppLocale.localized(language, value);

  Color get color {
    switch (this) {
      case Consistency.hard:
        return const Color(0xFF757575);
      case Consistency.formed:
        return const Color(0xFF6D4C41);
      case Consistency.pasty:
        return const Color(0xFFA1887F);
      case Consistency.soft:
        return const Color(0xFFFDD835);
      case Consistency.watery:
        return const Color(0xFF29B6F6);
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
