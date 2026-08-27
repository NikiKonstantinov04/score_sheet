import 'enums.dart';
import 'board.dart';
import 'contract.dart';

/// Игра (раздаване) – съдържа борд, договор, декларант и брой взети взятки.
class Game {
  final Board board;
  final Contract contract;
  final Direction declarer;
  final int tricksWon;
  final int? hcp; // оньорни точки на линията (само за каре)

  Game({
    required this.board,
    required this.contract,
    required this.declarer,
    required this.tricksWon,
    this.hcp,
  }) {
    if (tricksWon < 0 || tricksWon > 13) {
      throw ArgumentError('Броят взети взятки трябва да е между 0 и 13.');
    }
  }

  /// Изчислява резултата в точки (положителен за страната на декларанта).
  /// Използва стандартния бридж скоринг.
  int get score => _calculateScore();

  int _calculateScore() {
    final level = contract.level;
    final suit = contract.suit;
    final doubled = contract.doubled;
    final redoubled = contract.redoubled;

    // Необходими взятки за изпълнение на договора = 6 + ниво
    final requiredTricks = 6 + level;
    final tricksDifference = tricksWon - requiredTricks;

    if (tricksDifference >= 0) {
      // Изпълнен договор
      return _scoreMadeContract(level, suit, doubled, redoubled, tricksDifference);
    } else {
      // Паднал договор (неизпълнен)
      return _scoreDefeatedContract(
        doubled: doubled,
        redoubled: redoubled,
        undertricks: -tricksDifference,
        vulnerable: _isDeclarerVulnerable(),
      );
    }
  }

  /// Изчислява резултата при изпълнен договор.
  int _scoreMadeContract(
      int level,
      Suit suit,
      bool doubled,
      bool redoubled,
      int overtricks,
      ) {
    // Базова точкова стойност за всяка взятка от нивото.
    int basePointsPerTrick;
    switch (suit) {
      case Suit.club:
      case Suit.diamond:
        basePointsPerTrick = 20;
        break;
      case Suit.heart:
      case Suit.spade:
        basePointsPerTrick = 30;
        break;
      case Suit.noTrump:
      // Първа взятка 40, следващите 30
        basePointsPerTrick = 30; // ще коригираме за първата
        break;
    }

    // Точки за договора (без бонуси)
    int contractPoints;
    if (suit == Suit.noTrump) {
      // Без коз: първа взятка 40, останалите 30
      contractPoints = 40 + (level - 1) * 30;
    } else {
      contractPoints = level * basePointsPerTrick;
    }

    // Прилагане на контра/реконтра върху базовите точки
    if (doubled) {
      contractPoints *= 2;
    } else if (redoubled) {
      contractPoints *= 4;
    }

    // Бонус за гейм (ако базовите точки >= 100)
    int gameBonus = 0;
    if (contractPoints >= 100) {
      gameBonus = _isDeclarerVulnerable() ? 500 : 300;
    } else {
      // Частичен резултат
      gameBonus = 50;
    }

    // Бонус за шлем (малък шлем: 12 взятки, голям шлем: 13)
    int slamBonus = 0;
    if (level == 6) {
      slamBonus = _isDeclarerVulnerable() ? 750 : 500;
    } else if (level == 7) {
      slamBonus = _isDeclarerVulnerable() ? 1500 : 1000;
    }

    // Бонус за обявен контра или реконтра
    int insultBonus = 0;
    if (doubled) {
      insultBonus = 50;
    } else if (redoubled) {
      insultBonus = 100;
    }

    // Точки за надвишени взятки
    int overtrickPoints;
    if (doubled) {
      overtrickPoints = overtricks * (_isDeclarerVulnerable() ? 200 : 100);
    } else if (redoubled) {
      overtrickPoints = overtricks * (_isDeclarerVulnerable() ? 400 : 200);
    } else {
      // Без контра/реконтра
      overtrickPoints = overtricks * basePointsPerTrick;
    }

    return contractPoints + gameBonus + slamBonus + insultBonus + overtrickPoints;
  }

  /// Изчислява резултата при паднал договор (отрицателен за декларанта).
  int _scoreDefeatedContract({
    required bool doubled,
    required bool redoubled,
    required int undertricks,
    required bool vulnerable,
  }) {
    // Стойности на наказанието за всяка паднала взятка според уязвимостта и контра/реконтра.
    // Използваме списък от степени: [1-ва, 2-ра, 3-та, 4-та+]
    List<int> penaltySteps;

    if (!doubled && !redoubled) {
      // Без контра/реконтра
      penaltySteps = vulnerable ? [100, 100, 100, 100] : [50, 50, 50, 50];
    } else if (doubled) {
      // Контра
      penaltySteps = vulnerable
          ? [200, 300, 300, 400]  // 1-ва=200, 2-ра=300, 3-та=300, 4-та+=400
          : [100, 200, 200, 300]; // 1-ва=100, 2-ра=200, 3-та=200, 4-та+=300
    } else {
      // Реконтра (удвоява контра)
      penaltySteps = vulnerable
          ? [400, 600, 600, 800]
          : [200, 400, 400, 600];
    }

    int totalPenalty = 0;
    for (int i = 0; i < undertricks; i++) {
      int stepIndex = i < 3 ? i : 3; // 0->1-ва, 1->2-ра, 2->3-та, 3->4-та и следващи
      totalPenalty += penaltySteps[stepIndex];
    }

    return -totalPenalty;
  }

  /// Проверява дали декларантът е уязвим според зоната на борда.
  bool _isDeclarerVulnerable() {
    final isNS = (declarer == Direction.north || declarer == Direction.south);
    final zone = board.zone;

    if (zone == Zones.all) return true;
    if (zone == Zones.none) return false;
    if (zone == Zones.ns && isNS) return true;
    if (zone == Zones.ew && !isNS) return true;
    return false;
  }

  ///Метод за записване и четене в паметта на устройството
  Map<String, dynamic> toJson() => {
    'boardNumber': board.number,
    'contract': contract.toJson(),
    'declarer': declarer.name,
    'tricksWon': tricksWon,
    'hcp': hcp,
  };

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      board: Board.auto(json['boardNumber'] as int),
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      declarer: Direction.values.byName(json['declarer'] as String),
      tricksWon: json['tricksWon'] as int,
      hcp: json['hcp'] as int?,
    );
  }
}
