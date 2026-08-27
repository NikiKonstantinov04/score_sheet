import 'package:flutter/material.dart';
import '../models/models.dart';
import '../scoring/scoring.dart';
import '../services/storage_service.dart';
import 'game_input_screen.dart';
import 'results_screen.dart';

/// Екран за провеждане на мач – показва игрите и позволява добавяне.
class MatchScreen extends StatefulWidget {
  final MatchMode mode;
  final Match? existingSingleMatch;
  final Match? existingTable1;
  final Match? existingTable2;

  const MatchScreen({
    super.key,
    required this.mode,
    this.existingSingleMatch,
    this.existingTable1,
    this.existingTable2,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  Match? _singleMatch;
  Match? _table1Match;
  Match? _table2Match;
  int _selectedTable = 1;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MatchMode.singleTable) {
      _singleMatch = widget.existingSingleMatch ?? Match();
    } else {
      _table1Match = widget.existingTable1 ?? Match();
      _table2Match = widget.existingTable2 ?? Match();
    }
  }

  Match? _getCurrentMatch() {
    if (widget.mode == MatchMode.singleTable) return _singleMatch;
    return _selectedTable == 1 ? _table1Match : _table2Match;
  }

  Future<void> _addGame() async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null) return;

    final usedBoardNumbers =
    currentMatch.games.map((g) => g.board.number).toList();

    final newGame = await Navigator.of(context).push<Game>(
      MaterialPageRoute(
        builder: (context) => GameInputScreen(
          usedBoardNumbers: usedBoardNumbers,
          showHcpField: widget.mode == MatchMode.singleTable,
        ),
      ),
    );

    if (newGame == null) return;

    try {
      currentMatch.addGame(newGame);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _removeGame(int boardNumber) {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null) return;
    currentMatch.removeGameByBoardNumber(boardNumber);
    setState(() {});
  }

  Future<void> _clearAllGames() async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null || currentMatch.games.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на всички игри'),
        content: const Text('Сигурни ли сте, че искате да изтриете всички игри?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      currentMatch.clear();
      setState(() {});
    }
  }

  void _showResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          mode: widget.mode,
          singleMatch: _singleMatch,
          table1: _table1Match,
          table2: _table2Match,
        ),
      ),
    );
  }

  Future<void> _saveCurrentMatch() async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null || currentMatch.games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Няма игри за запис')),
      );
      return;
    }

    // Показваме диалог за име на мача
    final nameController = TextEditingController(
      text: 'Мач ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запази мач'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Име на мача'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    // Записваме според режима
    if (widget.mode == MatchMode.singleTable) {
      await StorageService.saveMatchWithName(
        mode: MatchMode.singleTable,
        singleMatch: currentMatch,
        table1: null,
        table2: null,
        name: name,
      );
    } else {
      if (_table1Match != null && _table2Match != null) {
        await StorageService.saveMatchWithName(
          mode: MatchMode.teamMatch,
          singleMatch: null,
          table1: _table1Match,
          table2: _table2Match,
          name: name,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Мачът "$name" е запазен')),
      );
    }
  }

  String _getSummary() {
    if (widget.mode == MatchMode.singleTable) {
      if (_singleMatch == null || _singleMatch!.games.isEmpty) {
        return 'Все още няма игри';
      }
      final scoring = MatchScoring.single(_singleMatch!);
      final nsImps = scoring.getTotalImps(perspectiveNS: true);
      final ewImps = -nsImps;
      return 'NS: $nsImps IMP  |  EW: $ewImps IMP';
    } else {
      if (_table1Match == null || _table2Match == null) {
        return 'Все още няма игри';
      }
      if (_table1Match!.games.isEmpty || _table2Match!.games.isEmpty) {
        return 'Въведете игри и на двете маси';
      }
      final teamMatch = TeamMatch(table1: _table1Match!, table2: _table2Match!);
      final teamA = teamMatch.getTotalImpsForTeamA();
      return 'Отбор A: $teamA IMP  |  Отбор B: ${-teamA} IMP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMatch = _getCurrentMatch();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == MatchMode.singleTable ? 'Каре' : 'Отборен мач'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAllGames,
            tooltip: 'Изтрий всички игри',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveCurrentMatch,
            tooltip: 'Запази мач',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: _showResults,
            tooltip: 'Резултати',
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.mode == MatchMode.teamMatch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 1,
                    label: Text('Маса 1'),
                    icon: Icon(Icons.table_restaurant),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Маса 2'),
                    icon: Icon(Icons.table_restaurant),
                  ),
                ],
                selected: {_selectedTable},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedTable = newSelection.first;
                  });
                },
              ),
            ),
          if (currentMatch == null)
            const Expanded(
              child: Center(child: Text('Няма създаден мач')),
            )
          else if (currentMatch.games.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Няма добавени игри.\nНатиснете + за да добавите.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: currentMatch.games.length,
                itemBuilder: (context, index) {
                  final game = currentMatch.games[index];
                  final isPositive = game.score >= 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha:  0.15),
                        child: Text(
                          '${game.board.number}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        '${game.contract.level}${game.contract.suit.symbol}'
                            '${game.contract.doubled ? " X" : ""}'
                            '${game.contract.redoubled ? " XX" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Декларант: ${game.declarer.name}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${game.score}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeGame(game.board.number),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getSummary(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGame,
        tooltip: 'Добави игра',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}