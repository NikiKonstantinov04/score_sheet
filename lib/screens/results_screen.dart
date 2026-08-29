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
      appBar: AppBar(
        title: Text(mode == MatchMode.singleTable ? 'Резултати (Каре)' : 'Резултати (Отборно)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: mode == MatchMode.singleTable
            ? _buildSingleTableResults(context)
            : _buildTeamResults(context),
      ),
    );
  }

  Widget _buildSingleTableResults(BuildContext context) {
    final match = singleMatch;
    if (match == null || match.games.isEmpty) {
      return _buildEmptyState(context);
    }

    final scoring = MatchScoring.single(match);
    final impsNS = scoring.getTotalImps(perspectiveNS: true);
    final impsEW = -impsNS;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(
          context,
          title: 'ОБЩО IMP РЕЗУЛТАТ',
          leftLabel: 'Север / Юг',
          leftValue: impsNS,
          rightLabel: 'Изток / Запад',
          rightValue: impsEW,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.table_chart_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Детайли по бордове',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMaxHeight: 52,
                      horizontalMargin: 16,
                      columnSpacing: 16,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      ),
                      columns: const [
                        DataColumn(label: Text('Борд', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Договор', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('HCP', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Задълж.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Резултат', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Нетен', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('IMP (NS)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: match.games.map((game) {
                        final commitment = game.hcp != null
                            ? getCommitment(game.hcp!, game.board.zone)
                            : 0;
                        final nsScore = game.declarer == Direction.north ||
                            game.declarer == Direction.south
                            ? game.score
                            : -game.score;
                        final netScore = nsScore - commitment;
                        final imp = scoring.getBoardImps(
                          game.board.number,
                          perspectiveNS: true,
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  '${game.board.number}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(_buildFormattedContract(context, game.contract)),
                            DataCell(Text(game.hcp?.toString() ?? '--')),
                            DataCell(Text('$commitment')),
                            DataCell(_buildScoreText(context, nsScore)),
                            DataCell(_buildScoreText(context, netScore)),
                            DataCell(_buildImpBadge(context, imp)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamResults(BuildContext context) {
    if (table1 == null || table2 == null) {
      return _buildEmptyState(context);
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
        _buildTotalCard(
          context,
          title: 'ОБЩО IMP РЕЗУЛТАТ',
          leftLabel: 'Отбор A',
          leftValue: teamA,
          rightLabel: 'Отбор B',
          rightValue: teamB,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.table_chart_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Сравнение по бордове',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMaxHeight: 52,
                      horizontalMargin: 24,
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      ),
                      columns: const [
                        DataColumn(label: Text('Борд', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('IMP (Отбор A)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('IMP (Отбор B)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: sortedBoardNumbers.map((boardNumber) {
                        int impA = 0;
                        int impB = 0;
                        bool isComplete = false;
                        try {
                          impA = teamMatch.getBoardImpsForTeamA(boardNumber);
                          impB = -impA;
                          isComplete = true;
                        } catch (_) {}

                        return DataRow(
                          cells: [
                            DataCell(
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  '$boardNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              isComplete ? _buildImpBadge(context, impA) : const Text('--'),
                            ),
                            DataCell(
                              isComplete ? _buildImpBadge(context, impB) : const Text('--'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(
      BuildContext context, {
        required String title,
        required String leftLabel,
        required int leftValue,
        required String rightLabel,
        required int rightValue,
      }) {
    final theme = Theme.of(context);
    final isLeftWinner = leftValue > rightValue;
    final isRightWinner = rightValue > leftValue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildScoreboardSide(
                  context,
                  label: leftLabel,
                  value: leftValue,
                  isWinner: isLeftWinner,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: _buildScoreboardSide(
                  context,
                  label: rightLabel,
                  value: rightValue,
                  isWinner: isRightWinner,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardSide(
      BuildContext context, {
        required String label,
        required int value,
        required bool isWinner,
      }) {
    final theme = Theme.of(context);
    final formattedValue = value > 0 ? '+$value' : '$value';

    // Адаптивен цвят за положителни/отрицателни стойности
    final bool isDark = theme.brightness == Brightness.dark;
    final Color positiveColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color negativeColor = isDark ? Colors.red.shade400 : Colors.red.shade700;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedValue,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: value > 0
                ? positiveColor
                : value < 0
                ? negativeColor
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedContract(BuildContext context, Contract contract) {
    final brightness = Theme.of(context).brightness;
    Color suitColor;

    switch (contract.suit) {
      case Suit.club:
        suitColor = brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade800;
        break;
      case Suit.diamond:
        suitColor = brightness == Brightness.dark ? Colors.orange.shade400 : Colors.orange.shade800;
        break;
      case Suit.heart:
        suitColor = brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade700;
        break;
      case Suit.spade:
      case Suit.noTrump:
        suitColor = brightness == Brightness.dark ? Colors.white : Colors.black;
        break;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '${contract.level}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: contract.suit.symbol,
            style: TextStyle(fontWeight: FontWeight.bold, color: suitColor, fontSize: 16),
          ),
          if (contract.doubled)
            TextSpan(
              text: ' X',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade700,
              ),
            ),
          if (contract.redoubled)
            TextSpan(
              text: ' XX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: brightness == Brightness.dark ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreText(BuildContext context, int score) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color positiveColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color negativeColor = isDark ? Colors.red.shade400 : Colors.red.shade700;

    return Text(
      score > 0 ? '+$score' : '$score',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: score > 0
            ? positiveColor
            : score < 0
            ? negativeColor
            : theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildImpBadge(BuildContext context, int imp) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color positiveColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color negativeColor = isDark ? Colors.red.shade400 : Colors.red.shade700;

    final Color bgColor = imp > 0
        ? positiveColor.withValues(alpha: 0.15)
        : imp < 0
        ? negativeColor.withValues(alpha: 0.15)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        imp > 0 ? '+$imp' : '$imp',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: imp > 0
              ? positiveColor
              : imp < 0
              ? negativeColor
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Няма налични резултати',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}