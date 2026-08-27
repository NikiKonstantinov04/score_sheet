import 'enums.dart';

/// Договор (контракт).
class Contract {
  final int level;      // 1..7
  final Suit suit;      // цвят или без коз
  final bool doubled;   // контра
  final bool redoubled; // реконтра

  Contract({
    required this.level,
    required this.suit,
    this.doubled = false,
    this.redoubled = false,
  }) {
    if (level < 1 || level > 7) {
      throw ArgumentError('Нивото трябва да е между 1 и 7.');
    }
    if (doubled && redoubled) {
      throw ArgumentError('Контрактът не може да бъде едновременно контра и реконтра.');
    }
  }

  ///Метод за записване и четене в паметта на устройството
  Map<String, dynamic> toJson() => {
    'level': level,
    'suit': suit.name,
    'doubled': doubled,
    'redoubled': redoubled,
  };

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      level: json['level'] as int,
      suit: Suit.values.byName(json['suit'] as String),
      doubled: json['doubled'] as bool? ?? false,
      redoubled: json['redoubled'] as bool? ?? false,
    );
  }
}
