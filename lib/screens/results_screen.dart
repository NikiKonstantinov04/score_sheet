import 'package:flutter/material.dart';
import '../models/models.dart';
import '../scoring/scoring.dart';
import '../scoring/kare.dart';

class ResultsScreen extends StatelessWidget {
  final MatchMode mode;
  final Match? singleMatch;
  final Match? table1;
  final Match? table2;

  const ResultsScreen({
    super.key,
    required this.mode,
    this.singleMatch,
    this.table1,
    this.table2,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Резултати')),
      body: mode == MatchMode.singleTable
          ? _buildSingleTableResults(context)
          : _buildTeamResults(context),
    );
  }

  Widget _buildSingleTableResults(BuildContext context) {
    final match = singleMatch;
    if (match == null || match.games.isEmpty) {
      return const Center(child: Text('Няма игри'));
    }

    final scoring = MatchScoring.single(match);
    final impsNS = scoring.getTotalImps(perspectiveNS: true);
    final impsEW = -impsNS;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(context, title: 'Общо IMP', leftLabel: 'NS', leftValue: impsNS, rightLabel: 'EW', rightValue: impsEW),
        const SizedBox(height: 20),
        Text('Детайли по бордове', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    // Можем да добавим алтернативно оцветяване, но тук не е нужно
                    return null;
                  }),
                  columns: const [
                    DataColumn(label: Text('Борд')),
                    DataColumn(label: Text('Договор')),
                    DataColumn(label: Text('HCP'), numeric: true),
                    DataColumn(label: Text('Задължение'), numeric: true),
                    DataColumn(label: Text('Резултат'), numeric: true),
                    DataColumn(label: Text('Нетен'), numeric: true),
                    DataColumn(label: Text('IMP (NS)'), numeric: true),
                  ],
                  rows: match.games.asMap().entries.map((entry) {
                    final index = entry.key;
                    final game = entry.value;
                    final commitment = game.hcp != null ? getCommitment(game.hcp!, game.board.zone) : 0;
                    final nsScore = game.declarer == Direction.north || game.declarer == Direction.south
                        ? game.score
                        : -game.score;
                    final netScore = nsScore - commitment;
                    final imp = scoring.getBoardImps(game.board.number, perspectiveNS: true);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        return index.isOdd ? Colors.grey.shade100 : null;
                      }),
                      cells: [
                        DataCell(Text('${game.board.number}')),
                        DataCell(Text(
                          '${game.contract.level}${game.contract.suit.symbol}'
                              '${game.contract.doubled ? " X" : ""}'
                              '${game.contract.redoubled ? " XX" : ""}',
                        )),
                        DataCell(Text(game.hcp?.toString() ?? '--')),
                        DataCell(Text('$commitment')),
                        DataCell(Text('$nsScore', style: TextStyle(color: nsScore >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold))),
                        DataCell(Text('$netScore', style: TextStyle(color: netScore >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold))),
                        DataCell(Text('$imp', style: TextStyle(color: imp >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamResults(BuildContext context) {
    if (table1 == null || table2 == null) {
      return const Center(child: Text('Липсват данни за двете маси'));
    }

    final teamMatch = TeamMatch(table1: table1!, table2: table2!);
    final teamA = teamMatch.getTotalImpsForTeamA();
    final teamB = -teamA;

    final boardNumbers = <int>{};
    boardNumbers.addAll(table1!.games.map((g) => g.board.number));
    boardNumbers.addAll(table2!.games.map((g) => g.board.number));
    final sortedBoardNumbers = boardNumbers.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(context, title: 'Общо IMP', leftLabel: 'Отбор A', leftValue: teamA, rightLabel: 'Отбор B', rightValue: teamB),
        const SizedBox(height: 20),
        Text('Детайли по бордове', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                  columns: const [
                    DataColumn(label: Text('Борд')),
                    DataColumn(label: Text('IMP A'), numeric: true),
                    DataColumn(label: Text('IMP B'), numeric: true),
                  ],
                  rows: sortedBoardNumbers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final boardNumber = entry.value;
                    int impA = 0;
                    int impB = 0;
                    bool isComplete = false;
                    try {
                      impA = teamMatch.getBoardImpsForTeamA(boardNumber);
                      impB = -impA;
                      isComplete = true;
                    } catch (_) {}

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        return index.isOdd ? Colors.grey.shade100 : null;
                      }),
                      cells: [
                        DataCell(Text('$boardNumber')),
                        DataCell(isComplete ? Text('$impA', style: TextStyle(color: impA >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold)) : const Text('--')),
                        DataCell(isComplete ? Text('$impB', style: TextStyle(color: impB >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold)) : const Text('--')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context, {required String title, required String leftLabel, required int leftValue, required String rightLabel, required int rightValue}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem(context, label: leftLabel, value: leftValue),
                Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                _buildTotalItem(context, label: rightLabel, value: rightValue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(BuildContext context, {required String label, required int value}) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: value >= 0 ? Colors.green.shade700 : Colors.red.shade700)),
      ],
    );
  }
}