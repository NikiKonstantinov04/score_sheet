import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score_sheet/models/models.dart';
import 'package:score_sheet/scoring/scoring.dart';
import 'package:score_sheet/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Match createSingleMatch() {
      final match = Match();
      match.addGame(
        Game(
          board: Board.auto(1),
          contract: Contract(level: 4, suit: Suit.spade),
          declarer: Direction.south,
          tricksWon: 10,
          hcp: 24,
        ),
      );
      return match;
    }

    Match createTeamTable1() {
      final match = Match();
      match.addGame(
        Game(
          board: Board.auto(1),
          contract: Contract(level: 4, suit: Suit.spade),
          declarer: Direction.south,
          tricksWon: 10,
        ),
      );
      return match;
    }

    Match createTeamTable2() {
      final match = Match();
      match.addGame(
        Game(
          board: Board.auto(1),
          contract: Contract(level: 3, suit: Suit.noTrump),
          declarer: Direction.east,
          tricksWon: 9,
        ),
      );
      return match;
    }

    test('запазва и зарежда нов мач (каре)', () async {
      final match = createSingleMatch();

      final id = await StorageService.saveMatchWithName(
        mode: MatchMode.singleTable,
        singleMatch: match,
        table1: null,
        table2: null,
        name: 'Тестов мач',
      );

      expect(id, isNotEmpty);

      final savedMatches = await StorageService.getAllSavedMatches();
      expect(savedMatches, hasLength(1));
      expect(savedMatches.first.name, 'Тестов мач');
      expect(savedMatches.first.mode, MatchMode.singleTable);

      final data = await StorageService.loadMatchData(id);
      expect(data, isNotNull);
      expect(data!['mode'], MatchMode.singleTable.name);

      final loadedMatch = Match.fromJson(data['singleMatch'] as Map<String, dynamic>);
      expect(loadedMatch.games, hasLength(1));
      expect(loadedMatch.games.first.board.number, 1);
    });

    test('запазва и зарежда отборен мач', () async {
      final table1 = createTeamTable1();
      final table2 = createTeamTable2();

      final id = await StorageService.saveMatchWithName(
        mode: MatchMode.teamMatch,
        singleMatch: null,
        table1: table1,
        table2: table2,
        name: 'Отборен тест',
      );

      final savedMatches = await StorageService.getAllSavedMatches();
      expect(savedMatches, hasLength(1));
      expect(savedMatches.first.mode, MatchMode.teamMatch);

      final data = await StorageService.loadMatchData(id);
      expect(data!['mode'], MatchMode.teamMatch.name);

      final loadedTable1 = Match.fromJson(data['table1'] as Map<String, dynamic>);
      final loadedTable2 = Match.fromJson(data['table2'] as Map<String, dynamic>);
      expect(loadedTable1.games, hasLength(1));
      expect(loadedTable2.games, hasLength(1));
    });

    test('обновява съществуващ мач (авто-запис)', () async {
      final match = createSingleMatch();

      final id = await StorageService.saveMatchWithName(
        mode: MatchMode.singleTable,
        singleMatch: match,
        table1: null,
        table2: null,
        name: 'Първоначално име',
      );

      // Добавяме още една игра в мача
      match.addGame(
        Game(
          board: Board.auto(2),
          contract: Contract(level: 2, suit: Suit.heart),
          declarer: Direction.north,
          tricksWon: 8,
        ),
      );

      final updated = await StorageService.updateMatch(
        id: id,
        mode: MatchMode.singleTable,
        singleMatch: match,
        table1: null,
        table2: null,
      );

      expect(updated, isTrue);

      final savedMatches = await StorageService.getAllSavedMatches();
      expect(savedMatches, hasLength(1)); // не трябва да се създава нов запис

      final data = await StorageService.loadMatchData(id);
      final loadedMatch = Match.fromJson(data!['singleMatch'] as Map<String, dynamic>);
      expect(loadedMatch.games, hasLength(2));

      // Името трябва да е запазено
      expect(savedMatches.first.name, 'Първоначално име');
    });

    test('изтрива мач по id', () async {
      final match = createSingleMatch();

      final id = await StorageService.saveMatchWithName(
        mode: MatchMode.singleTable,
        singleMatch: match,
        table1: null,
        table2: null,
        name: 'За изтриване',
      );

      await StorageService.deleteMatch(id);

      final savedMatches = await StorageService.getAllSavedMatches();
      expect(savedMatches, isEmpty);

      final data = await StorageService.loadMatchData(id);
      expect(data, isNull);
    });

    test('loadMatchData връща null за несъществуващ id', () async {
      final data = await StorageService.loadMatchData('несъществуващ-id');
      expect(data, isNull);
    });

    test('updateMatch връща false за несъществуващ id', () async {
      final match = createSingleMatch();
      final result = await StorageService.updateMatch(
        id: 'няма-такъв-id',
        mode: MatchMode.singleTable,
        singleMatch: match,
        table1: null,
        table2: null,
      );
      expect(result, isFalse);
    });
  });
}