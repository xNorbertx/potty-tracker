enum Consistency {
  hard,
  formed,
  pasty,
  soft,
  watery,
}

extension ConsistencyExtension on Consistency {
  String get assetPath => 'assets/consistency/$name.png';

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
