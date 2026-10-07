import 'package:flutter/material.dart';
import '../models/models.dart';
import '../scoring/scoring.dart';
import '../services/storage_service.dart';
import 'game_input_screen.dart';
import 'results_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/qr_service.dart';
import 'qr_scan_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Екран за провеждане на мач – показва игрите и позволява добавяне.
class MatchScreen extends StatefulWidget {
  final MatchMode mode;
  final Match? existingSingleMatch;
  final Match? existingTable1;
  final Match? existingTable2;
  final String? savedMatchId;
  final String? savedMatchName;

  const MatchScreen({
    super.key,
    required this.mode,
    this.existingSingleMatch,
    this.existingTable1,
    this.existingTable2,
    this.savedMatchId,
    this.savedMatchName,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  Match? _singleMatch;
  Match? _table1Match;
  Match? _table2Match;
  int _selectedTable = 1;
  String? _savedMatchId;
  String? _savedMatchName;

  bool get _isMobile =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _savedMatchId = widget.savedMatchId;
    _savedMatchName = widget.savedMatchName;
    if (widget.mode == MatchMode.singleTable) {
      _singleMatch = widget.existingSingleMatch ?? Match();
      _singleMatch!.sortGames();
    } else {
      _table1Match = widget.existingTable1 ?? Match();
      _table1Match!.sortGames();
      _table2Match = widget.existingTable2 ?? Match();
      _table2Match!.sortGames();
    }
  }

  Match? _getCurrentMatch() {
    if (widget.mode == MatchMode.singleTable) return _singleMatch;
    return _selectedTable == 1 ? _table1Match : _table2Match;
  }

  Color _getSuitColor(BuildContext context, Suit suit) {
    final brightness = Theme.of(context).brightness;
    switch (suit) {
      case Suit.club:
        return brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700;
      case Suit.diamond:
        return Colors.orange.shade700;
      case Suit.heart:
        return Colors.red.shade700;
      case Suit.spade:
        return brightness == Brightness.dark ? Colors.white : Colors.black;
      case Suit.noTrump:
        return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
  }

  String _getDeclarerLetter(Direction declarer) {
    switch (declarer) {
      case Direction.north:
        return 'N';
      case Direction.east:
        return 'E';
      case Direction.south:
        return 'S';
      case Direction.west:
        return 'W';
    }
  }

  Future<void> _autoSave() async {
    if (_savedMatchId == null || _savedMatchName == null) return;

    final currentMatch = _getCurrentMatch();
    if (currentMatch == null) return;

    await StorageService.saveMatch(
      id: _savedMatchId,
      mode: widget.mode,
      singleMatch: widget.mode == MatchMode.singleTable ? currentMatch : null,
      table1: widget.mode == MatchMode.teamMatch ? _table1Match : null,
      table2: widget.mode == MatchMode.teamMatch ? _table2Match : null,
      name: _savedMatchName!,
    );
  }

  Future<void> _ensureSaved() async {
    if (_savedMatchId != null) return;

    final now = DateTime.now();
    final defaultName =
        'Мач ${now.day}.${now.month}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Име на мача'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Име',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (name == null || name.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _savedMatchId = id;
    _savedMatchName = name;

    await _autoSave();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Мачът "$name" е запазен')),
    );
  }

  Future<void> _addGame() async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null) return;

    await _ensureSaved();
    if (!mounted) return;
    if (_savedMatchId == null) return;

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

    if (!mounted) return;
    if (newGame == null) return;

    try {
      currentMatch.addGame(newGame);
      currentMatch.sortGames();
      setState(() {});
      await _autoSave();
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
    _autoSave();
  }

  Future<void> _clearAllGames() async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null || currentMatch.games.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на всички игри'),
        content: const Text(
            'Сигурни ли сте, че искате да изтриете всички въведени игри за тази маса?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      currentMatch.clear();
      setState(() {});
      await _autoSave();
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

  Future<void> _editGame(Game game) async {
    final currentMatch = _getCurrentMatch();
    if (currentMatch == null) return;

    final usedBoardNumbers =
    currentMatch.games.map((g) => g.board.number).toList();
    usedBoardNumbers.remove(game.board.number);

    final editedGame = await Navigator.of(context).push<Game>(
      MaterialPageRoute(
        builder: (context) => GameInputScreen(
          usedBoardNumbers: usedBoardNumbers,
          showHcpField: widget.mode == MatchMode.singleTable,
          existingGame: game,
        ),
      ),
    );

    if (!mounted) return;
    if (editedGame == null) return;

    try {
      currentMatch.replaceGame(game.board.number, editedGame);
      currentMatch.sortGames();
      setState(() {});
      await _autoSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showQrOptions() async {
    if (widget.mode != MatchMode.teamMatch) return;

    final bool canScan = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('QR обмен'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'send'),
            child: const Row(
              children: [
                Icon(Icons.qr_code_2),
                SizedBox(width: 12),
                Text('Изпрати данни'),
              ],
            ),
          ),
          if (canScan)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'scan'),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner),
                  SizedBox(width: 12),
                  Text('Сканирай данни'),
                ],
              ),
            ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'send') {
      await _sendQrData();
    } else if (action == 'scan') {
      await _scanQrData();
    }
  }

  Future<void> _sendQrData() async {
    final table = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изберете маса за изпращане'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Маса 1'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              title: const Text('Маса 2'),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );

    if (table == null) return;

    final match = table == 1 ? _table1Match : _table2Match;
    if (match == null || match.games.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Няма данни за маса $table')),
        );
      }
      return;
    }

    final payload = QrPayload(tableNumber: table, match: match);
    final qrData = payload.toJsonString();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR код за маса $table'),
        content: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 250,
            height: 250,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Затвори'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQrData() async {
    final scannedData = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const QrScanScreen(),
      ),
    );

    if (scannedData == null || !mounted) return;

    final payload = QrPayload.fromJsonString(scannedData);
    if (payload == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Невалиден QR код')),
        );
      }
      return;
    }

    final targetTable = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('В коя маса да се импортират данните?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Маса 1'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              title: const Text('Маса 2'),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );

    if (targetTable == null || !mounted) return;

    final targetMatch = targetTable == 1 ? _table1Match : _table2Match;
    if (targetMatch != null && targetMatch.games.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Масата вече съдържа игри'),
          content: const Text('Искате ли да презапишете съществуващите данни?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отказ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Презапиши'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      if (targetTable == 1) {
        _table1Match = payload.match;
      } else {
        _table2Match = payload.match;
      }
      if (targetTable == 1) {
        _table1Match?.sortGames();
      } else {
        _table2Match?.sortGames();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Данните от маса ${payload.tableNumber} са импортирани в маса $targetTable')),
      );
    }
  }

  Future<bool> _confirmDeleteGame(int boardNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на борд'),
        content: Text('Сигурни ли сте, че искате да изтриете борд $boardNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _removeGameWithConfirmation(int boardNumber) async {
    final confirmed = await _confirmDeleteGame(boardNumber);
    if (confirmed && mounted) {
      _removeGame(boardNumber);
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
      return 'NS: ${nsImps >= 0 ? "+$nsImps" : nsImps} IMP  •  EW: ${ewImps >= 0 ? "+$ewImps" : ewImps} IMP';
    } else {
      if (_table1Match == null || _table2Match == null) {
        return 'Все още няма игри';
      }
      if (_table1Match!.games.isEmpty || _table2Match!.games.isEmpty) {
        return 'Въведете игри и на двете маси';
      }
      final teamMatch = TeamMatch(table1: _table1Match!, table2: _table2Match!);
      final teamA = teamMatch.getTotalImpsForTeamA();
      return 'Отбор A: ${teamA >= 0 ? "+$teamA" : teamA} IMP  •  Отбор B: ${-teamA >= 0 ? "+${-teamA}" : -teamA} IMP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.mode == MatchMode.singleTable ? 'Каре' : 'Отборен мач'),
        centerTitle: true,
        toolbarHeight: isLandscape ? 44 : kToolbarHeight,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearAllGames();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Изтрий всички игри', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.mode == MatchMode.teamMatch)
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              onPressed: _showQrOptions,
              tooltip: 'Обмен чрез QR код',
            ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(theme)
            : _buildPortraitLayout(theme),
      ),
      bottomNavigationBar: isLandscape
          ? null
          : _buildPortraitBottomBar(theme),
    );
  }

  /// Portrait layout – вертикален списък + долен панел.
  Widget _buildPortraitLayout(ThemeData theme) {
    return Column(
      children: [
        if (widget.mode == MatchMode.teamMatch) _buildTableSelector(),
        Expanded(child: _buildGamesListOrEmpty(theme)),
      ],
    );
  }

  /// Landscape layout – списък отляво, странична лента отдясно.
  Widget _buildLandscapeLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Лява част: селектор + списък с игри
        Expanded(
          child: Column(
            children: [
              if (widget.mode == MatchMode.teamMatch) _buildTableSelector(),
              Expanded(child: _buildGamesListOrEmpty(theme)),
            ],
          ),
        ),
        // Дясна част: странична лента
        _buildLandscapeSidebar(theme),
      ],
    );
  }

  /// Селектор на маса (за отборен режим).
  Widget _buildTableSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 1,
              label: Text('Маса 1 (${_table1Match?.games.length ?? 0})'),
              icon: const Icon(Icons.table_restaurant),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Маса 2 (${_table2Match?.games.length ?? 0})'),
              icon: const Icon(Icons.table_restaurant),
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
    );
  }

  /// Списък с игрите или празно състояние.
  Widget _buildGamesListOrEmpty(ThemeData theme) {
    final currentMatch = _getCurrentMatch();

    if (currentMatch == null) {
      return const Center(child: Text('Няма създаден мач'));
    }

    if (currentMatch.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.style_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Няма въведени игри',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Натиснете бутона по-долу, за да добавите борд',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: currentMatch.games.length,
      itemBuilder: (context, index) {
        final game = currentMatch.games[index];
        final declarerIsNS = game.declarer == Direction.north ||
            game.declarer == Direction.south;
        final displayScore = declarerIsNS ? game.score : -game.score;
        final isPositive = displayScore >= 0;
        final suitColor = _getSuitColor(context, game.contract.suit);

        return Dismissible(
          key: Key('game_${game.board.number}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _confirmDeleteGame(game.board.number);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          onDismissed: (_) => _removeGame(game.board.number),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLowest,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => _editGame(game),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${game.board.number}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    '${game.contract.level}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    game.contract.suit.symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: suitColor,
                    ),
                  ),
                  if (game.contract.doubled)
                    const Text(' X',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                  if (game.contract.redoubled)
                    const Text(' XX',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(width: 8),
                  Text(
                    'от ${_getDeclarerLetter(game.declarer)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Взети: ${game.tricksWon} взятки',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isPositive ? "+$displayScore" : displayScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPositive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  if (!_isMobile)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _removeGameWithConfirmation(game.board.number),
                      tooltip: 'Изтрий борд',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Долен панел за portrait.
  Widget _buildPortraitBottomBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ТЕКУЩ РЕЗУЛТАТ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSummary(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _showResults,
                  icon: const Icon(Icons.bar_chart_rounded, size: 20),
                  label: const Text('Карта'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addGame,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'ДОБАВИ БОРД',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Странична лента за landscape.
  Widget _buildLandscapeSidebar(ThemeData theme) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ТЕКУЩ РЕЗУЛТАТ',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getSummary(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showResults,
              icon: const Icon(Icons.bar_chart_rounded, size: 20),
              label: const Text('КАРТА'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addGame,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'ДОБАВИ БОРД',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}