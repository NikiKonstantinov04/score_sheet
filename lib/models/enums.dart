/// Посоки на играчите.
enum Direction {
  north,
  east,
  south,
  west,
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
