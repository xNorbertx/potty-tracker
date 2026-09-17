import 'package:flutter/material.dart';
import '../l10n/app_locale.dart';

/// Broad color groups keep logging quick while retaining the colors parents
/// commonly notice. Older, more detailed stored values remain readable below.
enum PoopColor {
  yellow('yellow', 'Yellow / mustard', Color(0xFFF8C641)),
  brown('brown', 'Brown', Color(0xFF6D4C41)),
  green('green', 'Green', Color(0xFF388E3C)),
  orange('orange', 'Orange', Color(0xFFF57C00)),
  red('red', 'Red', Color(0xFFD32F2F)),
  paleWhite('pale_white', 'Pale / white', Color(0xFFE0E0E0)),
  black('black', 'Black', Color(0xFF000000));

  const PoopColor(this.value, this.label, this.swatch);

  final String value;
  final String label;
  final Color swatch;
}

extension PoopColorExtension on PoopColor {
  String labelFor(AppLanguage language) =>
      AppLocale.localized(language, value == 'pale_white' ? 'paleWhite' : value);
  static PoopColor? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'mustard_yellow':
      case 'darker_yellow':
        return PoopColor.yellow;
      case 'green_black':
        return PoopColor.black;
      case 'frothy_green':
      case 'dark_green':
        return PoopColor.green;
      case 'green_brown':
        return PoopColor.brown;
      case 'chalk_white':
        return PoopColor.paleWhite;
    }
    try {
      return PoopColor.values.firstWhere((color) => color.value == value);
    } catch (_) {
      return null;
    }
  }
}
