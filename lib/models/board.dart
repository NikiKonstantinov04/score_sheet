import 'enums.dart';

/// Клас за борд
class Board {
  final int number;
  final Zones zone;
  final Direction dealer;

  Board._(this.number, this.zone, this.dealer);

  factory Board.auto(int number) {
    return Board._(number, _zoneForNumber(number),_dealerForNumber(number));
  }
  static Direction _dealerForNumber(int number) {
    if (number < 1) {
      throw ArgumentError('Номерът на борда трябва да е поне 1.');
    }
    final index = (number - 1) % 4;
    const dealerTable = <Direction> [
      Direction.north, //1
      Direction.east, //2
      Direction.south, //3
      Direction.west, //4
    ];
    return dealerTable[index];
  }

  static Zones _zoneForNumber(int number) {
    if (number < 1) {
      throw ArgumentError('Номерът на борда трябва да е поне 1.');
    }
    final index = (number - 1) % 16;

    const zoneTable = <Zones>[
      Zones.none, // 1
      Zones.ns,   // 2
      Zones.ew,   // 3
      Zones.all,  // 4
      Zones.ns,   // 5
      Zones.ew,   // 6
      Zones.all,  // 7
      Zones.none, // 8
      Zones.ew,   // 9
      Zones.all,  // 10
      Zones.none, // 11
      Zones.ns,   // 12
      Zones.all,  // 13
      Zones.none, // 14
      Zones.ns,   // 15
      Zones.ew,   // 16
    ];
    return zoneTable[index];
  }

  ///Метод за записване и четене в паметта на устройството
  Map<String, dynamic> toJson() => {'number': number};

  factory Board.fromJson(Map<String, dynamic> json) {
    final number = json['number'] as int;
    return Board.auto(number);
  }
}
