import 'package:flutter_test/flutter_test.dart';
import 'package:score_sheet/models/match.dart';
import 'package:score_sheet/models/board.dart';
import 'package:score_sheet/models/contract.dart';
import 'package:score_sheet/models/enums.dart';
import 'package:score_sheet/models/game.dart';
import 'package:score_sheet/scoring/scoring.dart';
void main() {
  group('Board', () {
    test('автоматично определя зона и дилър', () {
      final board1 = Board.auto(1);
      expect(board1.zone, Zones.none);
      expect(board1.dealer, Direction.north);

      final board5 = Board.auto(5);
      expect(board5.zone, Zones.ns);
      expect(board5.dealer, Direction.north);
    });

    test('цикличност на зоната', () {
      expect(Board.auto(1).zone, Board.auto(17).zone);
      expect(Board.auto(2).zone, Board.auto(18).zone);
      expect(Board.auto(16).zone, Board.auto(32).zone);
    });

    test('хвърля грешка при номер < 1', () {
      expect(() => Board.auto(0), throwsArgumentError);
    });
  });

  group('Contract', () {
    test('валиден договор', () {
      final c = Contract(level: 4, suit: Suit.spade);
      expect(c.level, 4);
      expect(c.suit, Suit.spade);
      expect(c.doubled, false);
      expect(c.redoubled, false);
    });

    test('невалидно ниво', () {
      expect(() => Contract(level: 0, suit: Suit.club), throwsArgumentError);
      expect(() => Contract(level: 8, suit: Suit.noTrump), throwsArgumentError);
    });

    test('не може едновременно контра и реконтра', () {
      expect(
            () => Contract(level: 2, suit: Suit.heart, doubled: true, redoubled: true),
        throwsArgumentError,
      );
    });
  });

  group('Game scoring', () {
    test('частичен договор', () {
      final board = Board.auto(1); // неуязвим
      final game = Game(
        board: board,
        contract: Contract(level: 2, suit: Suit.diamond),
        declarer: Direction.south,
        tricksWon: 8, // точно
      );
      // 2*20 = 40 + 50 частичен бонус = 90
      expect(game.score, 90);
    });

    test('гейм при уязвими', () {
      final board = Board.auto(2); // NS уязвими
      final game = Game(
        board: board,
        contract: Contract(level: 4, suit: Suit.spade),
        declarer: Direction.north,
        tricksWon: 10,
      );
      // 4*30=120 + 500 гейм бонус (уязвим) = 620
      expect(game.score, 620);
    });

    test('малък шлем', () {
      final board = Board.auto(1); // неуязвим
      final game = Game(
        board: board,
        contract: Contract(level: 6, suit: Suit.noTrump),
        declarer: Direction.south,
        tricksWon: 12,
      );
      // 40 + 5*30 = 190, гейм (>=100) => 300, малък шлем неуязвим => 500, общо 990
      expect(game.score, 990);
    });

    test('паднал без контра, неуязвим', () {
      final board = Board.auto(1); // неуязвим
      final game = Game(
        board: board,
        contract: Contract(level: 3, suit: Suit.heart),
        declarer: Direction.west,
        tricksWon: 7, // 9 необходими, 2 паднали
      );
      // 2 * 50 = 100 отрицателно
      expect(game.score, -100);
    });

    test('паднал без контра, уязвим', () {
      final board = Board.auto(3); // EW уязвими, декларант east
      final game = Game(
        board: board,
        contract: Contract(level: 2, suit: Suit.spade),
        declarer: Direction.east,
        tricksWon: 6, // 8 необходими, 2 паднали
      );
      // 2 * 100 = 200 отрицателно
      expect(game.score, -200);
    });

    test('паднал с контра, неуязвим', () {
      final board = Board.auto(1); // неуязвим
      final game = Game(
        board: board,
        contract: Contract(level: 4, suit: Suit.heart, doubled: true),
        declarer: Direction.south,
        tricksWon: 7, // 10 необходими, 3 паднали
      );
      // 100 + 200 + 200 = 500 отрицателно
      expect(game.score, -500);
    });

    test('паднал с реконтра, уязвим', () {
      final board = Board.auto(2); // NS уязвими, декларант north
      final game = Game(
        board: board,
        contract: Contract(level: 2, suit: Suit.diamond, redoubled: true),
        declarer: Direction.north,
        tricksWon: 6, // 8 необходими, 2 паднали
      );
      // 400 + 600 = 1000 отрицателно
      expect(game.score, -1000);
    });

    test('надвишени взятки при контра', () {
      final board = Board.auto(1); // неуязвим
      final game = Game(
        board: board,
        contract: Contract(level: 2, suit: Suit.club, doubled: true),
        declarer: Direction.south,
        tricksWon: 9, // 8 необходими, 1 надвишена
      );
      // Базови: 2*20 = 40, контра -> 80, частичен бонус 50, insult 50, надвишена 100
      // Общо 80+50+50+100 = 280
      expect(game.score, 280);
    });
  });

  group('scoreToImps', () {
    test('граници', () {
      expect(scoreToImps(0), 0);
      expect(scoreToImps(19), 0);
      expect(scoreToImps(20), 1);
      expect(scoreToImps(49), 1);
      expect(scoreToImps(50), 2);
      expect(scoreToImps(89), 2);
      expect(scoreToImps(90), 3);
      // ... може да добавите още
    });

    test('отрицателни резултати', () {
      expect(scoreToImps(-100), -3); // abs(100) в [90,130)
      expect(scoreToImps(-420), -9);
    });
  });

  group('Match', () {
    test('добавяне и премахване', () {
      final match = Match();
      final board = Board.auto(1);
      final game = Game(
        board: board,
        contract: Contract(level: 1, suit: Suit.noTrump),
        declarer: Direction.south,
        tricksWon: 7,
      );
      match.addGame(game);
      expect(match.gameCount, 1);
      expect(match.containsBoard(1), true);

      final removed = match.removeGameByBoardNumber(1);
      expect(removed, isNotNull);
      expect(match.gameCount, 0);
      expect(match.containsBoard(1), false);
    });

    test('не позволява дублиран борд', () {
      final match = Match();
      final board1 = Board.auto(1);
      final game1 = Game(
        board: board1,
        contract: Contract(level: 1, suit: Suit.noTrump),
        declarer: Direction.south,
        tricksWon: 7,
      );
      match.addGame(game1);

      final board1Copy = Board.auto(1);
      final game2 = Game(
        board: board1Copy,
        contract: Contract(level: 2, suit: Suit.noTrump),
        declarer: Direction.north,
        tricksWon: 8,
      );
      expect(() => match.addGame(game2), throwsStateError);
    });

    test('totalNSScore', () {
      final match = Match();
      // NS играе 4♠ точно: +420 за NS
      match.addGame(Game(
        board: Board.auto(1),
        contract: Contract(level: 4, suit: Suit.spade),
        declarer: Direction.south,
        tricksWon: 10,
      ));
      // EW играе 3NT точно: резултат +400 за EW => -400 за NS
      match.addGame(Game(
        board: Board.auto(2),
        contract: Contract(level: 3, suit: Suit.noTrump),
        declarer: Direction.east,
        tricksWon: 9,
      ));
      expect(match.totalNSScore, 420 - 400);
    });
  });

  group('MatchScoring', () {
    test('каре IMP', () {
      final match = Match();
      match.addGame(Game(
        board: Board.auto(1),
        contract: Contract(level: 4, suit: Suit.spade),
        declarer: Direction.south,
        tricksWon: 10,
      ));
      final scoring = MatchScoring.single(match);
      expect(scoring.getTotalImps(perspectiveNS: true), 9);
      expect(scoring.getTotalImps(perspectiveNS: false), -9);
    });

    test('отборен мач IMP', () {
      final match1 = Match();
      match1.addGame(Game(
        board: Board.auto(1),
        contract: Contract(level: 4, suit: Suit.spade),
        declarer: Direction.south,
        tricksWon: 10,
      ));

      final match2 = Match();
      match2.addGame(Game(
        board: Board.auto(1),
        contract: Contract(level: 3, suit: Suit.noTrump),
        declarer: Direction.east,
        tricksWon: 9,
      ));

      final teamMatch = TeamMatch(table1: match1, table2: match2);
      final scoring = MatchScoring.team(teamMatch);
      expect(scoring.getTotalImps(perspectiveNS: true), 13);
      expect(scoring.getTotalImps(perspectiveNS: false), -13);
    });

    test('хвърля грешка при липсваща игра в отборен мач', () {
      final match1 = Match();
      match1.addGame(Game(
        board: Board.auto(1),
        contract: Contract(level: 4, suit: Suit.spade),
        declarer: Direction.south,
        tricksWon: 10,
      ));
      final match2 = Match(); // празен

      final teamMatch = TeamMatch(table1: match1, table2: match2);
      final scoring = MatchScoring.team(teamMatch);
      expect(() => scoring.getBoardImps(1, perspectiveNS: true), throwsStateError);
    });
  });
}