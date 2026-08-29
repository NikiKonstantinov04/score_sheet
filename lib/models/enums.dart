/// Посоки на играчите.
enum Direction {
  north,
  east,
  south,
  west,
}
extension DirectionName on Direction {
  String get bgName {
    switch (this) {
      case Direction.north:
        return 'Север';
      case Direction.south:
        return 'Юг';
      case Direction.east:
        return 'Изток';
      case Direction.west:
        return 'Запад';
    }
  }
}

/// Цветове, включително без коз.
enum Suit {
  club('♣'),
  diamond('♦'),
  heart('♥'),
  spade('♠'),
  noTrump('NT');

  const Suit(this.symbol);
  final String symbol;
}

/// Зони
enum Zones {
  none,
  ns,
  ew,
  all,
}

extension ZonesName on Zones {
  String get bgName {
    switch (this) {
      case Zones.none:
        return 'Никой';
      case Zones.ns:
        return 'Север-Юг';
      case Zones.ew:
        return 'Изток-Запад';
      case Zones.all:
        return 'Всички';
    }
  }
}