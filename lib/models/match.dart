import 'enums.dart';
import 'game.dart';

/// Контейнер за множество игри (бордове) в един мач.
class Match {
  // Частен списък, за да контролираме достъпа и модификациите.
  final List<Game> _games = [];

  /// Създава празен мач или с начален списък от игри.
  Match({List<Game>? initialGames}) {
    if (initialGames != null) {
      _games.addAll(initialGames);
    }
  }

  /// Добавя игра към мача.
  /// Ако вече съществува игра за същия номер на борда, хвърля грешка
  /// (опция – може да разрешите замяна, но това е по-безопасно за бридж).
  void addGame(Game game) {
    // Проверка дали вече имаме този борд
    final existing = _games.where((g) => g.board.number == game.board.number);
    if (existing.isNotEmpty) {
      throw StateError('Вече съществува игра за борд ${game.board.number}.');
    }
    _games.add(game);
  }

  /// Премахва игра по подаден обект.
  /// Връща true, ако е премахната успешно, иначе false.
  bool removeGame(Game game) {
    return _games.remove(game);
  }

  /// Премахва игра по номер на борда.
  /// Връща премахнатата игра или null, ако не е намерена.
  Game? removeGameByBoardNumber(int boardNumber) {
    final index = _games.indexWhere((g) => g.board.number == boardNumber);
    if (index != -1) {
      return _games.removeAt(index);
    }
    return null;
  }

  /// Връща непроменим изглед към списъка с игри.
  List<Game> get games => List.unmodifiable(_games);

  /// Брой игри в мача.
  int get gameCount => _games.length;

  /// Проверява дали има игра за даден номер на борда.
  bool containsBoard(int boardNumber) {
    return _games.any((g) => g.board.number == boardNumber);
  }

  /// Намира игра по номер на борда.
  Game? getGameByBoardNumber(int boardNumber) {
    for (final game in _games) {
      if (game.board.number == boardNumber) {
        return game;
      }
    }
    return null;
  }

  /// Изчиства всички игри.
  void clear() {
    _games.clear();
  }

  /// Сумарен резултат от гледна точка на Север-Юг.
  /// (Положителен, ако NS печелят, отрицателен, ако EW печелят)
  int get totalNSScore {
    int total = 0;
    for (final game in _games) {
      // Ако декларантът е NS, резултатът е положителен за NS,
      // ако е EW – отрицателен.
      final isNS = game.declarer == Direction.north || game.declarer == Direction.south;
      total += isNS ? game.score : -game.score;
    }
    return total;
  }

  ///Метод за записване и четене в паметта на устройството
  Map<String, dynamic> toJson() => {
    'games': _games.map((g) => g.toJson()).toList(),
  };

  factory Match.fromJson(Map<String, dynamic> json) {
    final match = Match();
    final gamesJson = json['games'] as List<dynamic>? ?? [];
    for (final gJson in gamesJson) {
      match.addGame(Game.fromJson(gJson as Map<String, dynamic>));
    }
    return match;
  }

  /// Заменя съществуваща игра по номер на борда.
  /// Връща true, ако е заменена; false, ако няма такава игра.
  bool replaceGame(int boardNumber, Game newGame) {
    final index = _games.indexWhere((g) => g.board.number == boardNumber);
    if (index == -1) return false;
    _games[index] = newGame;
    return true;
  }}