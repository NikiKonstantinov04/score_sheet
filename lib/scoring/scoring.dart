import '../models/models.dart';
import 'kare.dart';

/// Преобразува точков резултат в IMP по стандартната таблица.
int scoreToImps(int score) {
  final absScore = score.abs();
  final sign = score.isNegative ? -1 : 1;

  if (absScore < 10) return 0;
  if (absScore < 40) return sign * 1;
  if (absScore < 80) return sign * 2;
  if (absScore < 120) return sign * 3;
  if (absScore < 160) return sign * 4;
  if (absScore < 210) return sign * 5;
  if (absScore < 260) return sign * 6;
  if (absScore < 310) return sign * 7;
  if (absScore < 360) return sign * 8;
  if (absScore < 420) return sign * 9;
  if (absScore < 490) return sign * 10;
  if (absScore < 590) return sign * 11;
  if (absScore < 740) return sign * 12;
  if (absScore < 890) return sign * 13;
  if (absScore < 1090) return sign * 14;
  if (absScore < 1290) return sign * 15;
  if (absScore < 1490) return sign * 16;
  if (absScore < 1740) return sign * 17;
  if (absScore < 1990) return sign * 18;
  if (absScore < 2240) return sign * 19;
  if (absScore < 2490) return sign * 20;
  if (absScore < 2990) return sign * 21;
  if (absScore < 3490) return sign * 22;
  if (absScore < 3990) return sign * 23;
  return sign * 24;
}

/// Изчислява IMP за всяка игра в мач от гледна точка на зададена страна.
/// Връща карта (номер на борд -> IMP).
Map<int, int> calculateImpsForMatch(Match match, {required bool perspectiveNS}) {
  final imps = <int, int>{};
  for (final game in match.games) {
    // Резултат за NS
    final nsScore = game.declarer == Direction.north || game.declarer == Direction.south
        ? game.score
        : -game.score;
    // Ако искаме гледна точка на EW, обръщаме знака
    final perspectiveScore = perspectiveNS ? nsScore : -nsScore;
    imps[game.board.number] = scoreToImps(perspectiveScore);
  }
  return imps;
}

/// Изчислява общия брой IMP за мач от гледна точка на зададена страна.
int totalImpsForMatch(Match match, {required bool perspectiveNS}) {
  final imps = calculateImpsForMatch(match, perspectiveNS: perspectiveNS);
  return imps.values.fold(0, (sum, imp) => sum + imp);
}

/// Клас за отборен мач – съдържа два мача (по един на маса).
/// Отбор A играе NS на маса 1 и EW на маса 2.
/// Отбор B играе EW на маса 1 и NS на маса 2.
class TeamMatch {
  final Match table1; // маса 1
  final Match table2; // маса 2

  TeamMatch({required this.table1, required this.table2});

  /// Изчислява IMP за даден борд за отбор A.
  int getBoardImpsForTeamA(int boardNumber) {
    final game1 = table1.getGameByBoardNumber(boardNumber);
    final game2 = table2.getGameByBoardNumber(boardNumber);
    if (game1 == null || game2 == null) {
      throw StateError('Липсва игра за борд $boardNumber на една от масите.');
    }

    // Резултат за NS на маса 1
    final ns1 = game1.declarer == Direction.north || game1.declarer == Direction.south
        ? game1.score
        : -game1.score;
    // Резултат за NS на маса 2
    final ns2 = game2.declarer == Direction.north || game2.declarer == Direction.south
        ? game2.score
        : -game2.score;

    // Отбор A: NS на маса 1 + EW на маса 2 = ns1 + (-ns2)
    final teamAScore = ns1 - ns2;
    return scoreToImps(teamAScore);
  }

  /// Общ IMP за отбор A за всички бордове, които са налични и на двете маси.
  int getTotalImpsForTeamA() {
    // Взимаме всички номера на бордове от първата маса, за които има игра и на втората
    final boardNumbers = table1.games
        .map((g) => g.board.number)
        .where((n) => table2.containsBoard(n))
        .toList();

    int total = 0;
    for (final n in boardNumbers) {
      total += getBoardImpsForTeamA(n);
    }
    return total;
  }

  /// Общ IMP за отбор B (просто отрицателна стойност на отбор A).
  int getTotalImpsForTeamB() => -getTotalImpsForTeamA();
}

/// Режими на мача.
enum MatchMode {
  singleTable, // каре – една маса
  teamMatch,   // отборно – две маси
}

/// Клас, който обвива изчисленията за IMP в зависимост от режима.
class MatchScoring {
  final MatchMode mode;
  final Match? singleMatch; // използва се при singleTable
  final TeamMatch? teamMatchObj; // използва се при teamMatch

  // Частен конструктор – използвайте фабричните методи.
  MatchScoring._({
    required this.mode,
    this.singleMatch,
    this.teamMatchObj,
  });

  /// Фабричен конструктор за каре (една маса).
  factory MatchScoring.single(Match match) {
    return MatchScoring._(
      mode: MatchMode.singleTable,
      singleMatch: match,
    );
  }

  /// Фабричен конструктор за отборен мач (две маси).
  factory MatchScoring.team(TeamMatch teamMatch) {
    return MatchScoring._(
      mode: MatchMode.teamMatch,
      teamMatchObj: teamMatch,
    );
  }

  /// Връща IMP за даден борд.
  /// [perspectiveNS] – ако е true, връща IMP от гледна точка на Север-Юг
  /// (в каре) или от отбор A (в отборно). Ако е false – от гледна точка
  /// на Изток-Запад (в каре) или отбор B (в отборно).
  int getBoardImps(int boardNumber, {required bool perspectiveNS}) {
    switch (mode) {
      case MatchMode.singleTable:
        return _getSingleTableBoardImps(
            boardNumber, perspectiveNS: perspectiveNS);
      case MatchMode.teamMatch:
        final imps = teamMatchObj!.getBoardImpsForTeamA(boardNumber);
        return perspectiveNS ? imps : -imps;
    }
  }

  /// Общо IMP за целия мач.
  /// [perspectiveNS] – аналогично на getBoardImps.
  int getTotalImps({required bool perspectiveNS}) {
    switch (mode) {
      case MatchMode.singleTable:
        return _getSingleTableTotalImps(perspectiveNS: perspectiveNS);
      case MatchMode.teamMatch:
        final total = teamMatchObj!.getTotalImpsForTeamA();
        return perspectiveNS ? total : -total;
    }
  }

  // Помощен метод за каре – IMP за един борд.
  int _getSingleTableBoardImps(int boardNumber, {required bool perspectiveNS}) {
    final game = singleMatch!.getGameByBoardNumber(boardNumber);
    if (game == null) {
      throw StateError('Липсва игра за борд $boardNumber.');
    }

    // Резултат за NS
    int nsScore = game.declarer == Direction.north ||
        game.declarer == Direction.south
        ? game.score
        : -game.score;

    // Прилагаме задължение само ако има HCP
    if (game.hcp != null) {
      final commitment = getCommitment(game.hcp!, game.board.zone);
      nsScore -= commitment;
    }

    return scoreToImps(perspectiveNS ? nsScore : -nsScore);
  }

  // Помощен метод за каре – общо IMP.
  int _getSingleTableTotalImps({required bool perspectiveNS}) {
    int totalImps = 0;
    for (final game in singleMatch!.games) {
      int nsScore = game.declarer == Direction.north ||
          game.declarer == Direction.south
          ? game.score
          : -game.score;

      if (game.hcp != null) {
        final commitment = getCommitment(game.hcp!, game.board.zone);
        nsScore -= commitment;
      }

      totalImps += scoreToImps(perspectiveNS ? nsScore : -nsScore);
    }
    return totalImps;
  }
}