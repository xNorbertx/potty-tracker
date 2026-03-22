enum PoopSize {
  small,
  medium,
  large,
}

extension PoopSizeExtension on PoopSize {
  String get label {
    switch (this) {
      case PoopSize.small:
        return 'Small';
      case PoopSize.medium:
        return 'Medium';
      case PoopSize.large:
        return 'Large';
    }
  }

  String get emoji {
    switch (this) {
      case PoopSize.small:
        return '🔸';
      case PoopSize.medium:
        return '🟠';
      case PoopSize.large:
        return '🔶';
    }
  }

  String get value => name;

  static PoopSize? fromString(String? value) {
    if (value == null) return null;
    return PoopSize.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PoopSize.medium,
    );
  }
}
