import 'package:flutter/material.dart';

/// Represents the baby poo colour guide from Pregnancy Birth & Baby
/// (https://www.pregnancybirthbaby.org.au/article/baby-poo-guide).
///
enum PoopColor {
  greenBlack(
    'green_black',
    'Green / black (sticky tar-like)',
    Color(0xFF2F3D3C),
  ),
  mustardYellow(
    'mustard_yellow',
    'Mustard yellow',
    Color(0xFFF8C641),
  ),
  darkerYellow(
    'darker_yellow',
    'Darker yellow',
    Color(0xFFE6A329),
  ),
  frothyGreen(
    'frothy_green',
    'Frothy green',
    Color(0xFF4CAF50),
  ),
  darkGreen(
    'dark_green',
    'Dark green',
    Color(0xFF1B5E20),
  ),
  greenBrown(
    'green_brown',
    'Green / brown',
    Color(0xFF5D6B3C),
  ),
  orange(
    'orange',
    'Orange',
    Color(0xFFF57C00),
  ),
  brown(
    'brown',
    'Brown',
    Color(0xFF6D4C41),
  ),
  red(
    'red',
    'Red',
    Color(0xFFD32F2F),
  ),
  chalkWhite(
    'chalk_white',
    'Chalk white',
    Color(0xFFE0E0E0),
  ),
  black(
    'black',
    'Black',
    Color(0xFF000000),
  );

  const PoopColor(this.value, this.label, this.swatch);

  final String value;
  final String label;
  final Color swatch;
}

extension PoopColorExtension on PoopColor {
  static PoopColor? fromString(String? value) {
    if (value == null) return null;
    try {
      return PoopColor.values.firstWhere((c) => c.value == value);
    } catch (_) {
      return null;
    }
  }
}
