import 'package:flutter/material.dart';
import '../models/models.dart';

/// Формуляр за въвеждане на нова игра.
class GameInputScreen extends StatefulWidget {
  final List<int> usedBoardNumbers;
  final bool showHcpField;
  final Game? existingGame;

  const GameInputScreen({
    super.key,
    this.usedBoardNumbers = const [],
    this.showHcpField = false,
    this.existingGame,
  });

  @override
  State<GameInputScreen> createState() => _GameInputScreenState();
}

class _GameInputScreenState extends State<GameInputScreen> {
  late Board _currentBoard;

  int _level = 1;
  Suit? _suit;
  Direction _declarer = Direction.north;
  bool _doubled = false;
  bool _redoubled = false;

  int _tricks = 7;
  int _hcp = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingGame != null) {
      final game = widget.existingGame!;
      _currentBoard = game.board;
      _level = game.contract.level;
      _suit = game.contract.suit;
      _doubled = game.contract.doubled;
      _redoubled = game.contract.redoubled;
      _declarer = game.declarer;
      _tricks = game.tricksWon;
      _hcp = widget.showHcpField ? (game.hcp ?? 20) : 0;
    } else {
      // Автоматично намиране на НАЙ-МАЛКИЯ свободен номер (започвайки от 1)
      int nextBoardNumber = 1;
      while (widget.usedBoardNumbers.contains(nextBoardNumber)) {
        nextBoardNumber++;
      }

      _currentBoard = Board.auto(nextBoardNumber);
      _tricks = 6 + _level;
      _hcp = widget.showHcpField ? 20 : 0;
    }
  }

  Color _suitColor(BuildContext context, Suit suit) {
    final brightness = Theme.of(context).brightness;
    switch (suit) {
      case Suit.club:
        return brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700;
      case Suit.diamond:
        return Colors.orange.shade700;
      case Suit.heart:
        return Colors.red.shade700;
      case Suit.spade:
      case Suit.noTrump:
        return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
  }

  bool _isSideVulnerable(String side) {
    final zone = _currentBoard.zone;
    final isNS = (side == 'N' || side == 'S');
    switch (zone) {
      case Zones.none:
        return false;
      case Zones.ns:
        return isNS;
      case Zones.ew:
        return !isNS;
      case Zones.all:
        return true;
    }
  }

  Color _sideColor(String side) {
    return _isSideVulnerable(side)
        ? Colors.red.withValues(alpha: 0.25)
        : Colors.green.withValues(alpha: 0.25);
  }

  String get _previewText {
    if (_suit == null) return 'Изберете цвят';
    final sb = StringBuffer();
    sb.write('$_level${_suit!.symbol}');
    if (_doubled) sb.write(' X');
    if (_redoubled) sb.write(' XX');
    sb.write(' от ${_declarer.bgName}');
    sb.write(', $_tricks взятки');
    if (widget.showHcpField) {
      sb.write(' • HCP: $_hcp');
    }
    return sb.toString();
  }

  String _differenceText() {
    if (_suit == null) return '$_tricks';
    final required = 6 + _level;
    final diff = _tricks - required;
    if (diff == 0) return '=';
    if (diff > 0) return '+$diff';
    return '$diff';
  }

  Color? _differenceColor() {
    if (_suit == null) return null;
    final required = 6 + _level;
    final diff = _tricks - required;
    if (diff < 0) return Colors.red.shade700;
    if (diff > 0) return Colors.green.shade700;
    return null;
  }

  Game? _createGame() {
    if (_suit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля, изберете цвят')),
      );
      return null;
    }

    final board = Board.auto(_currentBoard.number);
    final contract = Contract(
      level: _level,
      suit: _suit!,
      doubled: _doubled,
      redoubled: _redoubled,
    );

    return Game(
      board: board,
      contract: contract,
      declarer: _declarer,
      tricksWon: _tricks,
      hcp: widget.showHcpField ? _hcp : null,
    );
  }

  /// Модален прозорец за бърз и неограничен избор на борд
  void _showBoardPickerModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Изберете борд',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final boardNum = index + 1;
                        final isUsed = widget.usedBoardNumbers.contains(boardNum) &&
                            boardNum != widget.existingGame?.board.number;
                        final isSelected = boardNum == _currentBoard.number;

                        return InkWell(
                          onTap: isUsed
                              ? null
                              : () {
                            setState(() {
                              _currentBoard = Board.auto(boardNum);
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : isUsed
                                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                                  : theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$boardNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : isUsed
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (isUsed)
                                  Text(
                                    'игран',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGame != null ? 'Редакция на игра' : 'Нова игра'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildBoardHeader(theme),
            const SizedBox(height: 12),
            _buildContractCard(theme),
            const SizedBox(height: 12),
            _buildDeclarerCard(theme),
            const SizedBox(height: 12),
            _buildResultCard(theme),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                _previewText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              final game = _createGame();
              if (game != null) Navigator.of(context).pop(game);
            },
            child: const Text('ЗАПАЗИ РЕЗУЛТАТА'),
          ),
        ),
      ),
    );
  }

  // ==================== СЕКЦИИ ====================

  Widget _buildBoardHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSideBox('NORTH', isHorizontal: true),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSideBox('WEST', isHorizontal: false),
              Expanded(
                child: InkWell(
                  onTap: () => _showBoardPickerModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentBoard.number}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSideBox('EAST', isHorizontal: false),
            ],
          ),
          const SizedBox(height: 4),
          _buildSideBox('SOUTH', isHorizontal: true),
        ],
      ),
    );
  }

  bool _isDealerSide(String side) {
    final dealer = _currentBoard.dealer;
    if (side.startsWith('N')) return dealer == Direction.north;
    if (side.startsWith('E')) return dealer == Direction.east;
    if (side.startsWith('S')) return dealer == Direction.south;
    if (side.startsWith('W')) return dealer == Direction.west;
    return false;
  }

  Widget _buildSideBox(String side, {required bool isHorizontal}) {
    final isDealer = _isDealerSide(side);
    final sideLetter = side.substring(0, 1);
    final isVulnerable = _isSideVulnerable(sideLetter);
    final theme = Theme.of(context);
    final displayText = isDealer ? 'DEALER' : side;

    // Конфигурация на цветовете и рамката
    final Color bgColor;
    final Border border;
    final Color textColor;

    if (isDealer) {
      bgColor = Colors.white;
      final vulColor = isVulnerable ? Colors.red : Colors.green;
      border = Border.all(color: vulColor, width: 2.5);
      textColor = Colors.black; // Черно за висока четливост върху бял фон
    } else {
      bgColor = _sideColor(sideLetter);
      border = Border.all(color: theme.dividerColor);
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      width: isHorizontal ? 100 : 36,
      height: isHorizontal ? 36 : 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: RotatedBox(
        quarterTurns: isHorizontal ? 0 : 1,
        child: Text(
          displayText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Контракт', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final level = i + 1;
                return ChoiceChip(
                  label: Text('$level'),
                  selected: _level == level,
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      _level = level;
                      if (_tricks < 6 + _level) _tricks = 6 + _level;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Suit.values.map((suit) {
                final isSelected = _suit == suit;
                final suitColor = _suitColor(context, suit);
                return ChoiceChip(
                  label: Text(
                    suit.symbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: 22,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (selected) {
                    setState(() {
                      _suit = selected ? suit : null;
                    });
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  selectedColor: suitColor.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: isSelected ? suitColor : Colors.transparent,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilterChip(
                  label: const Text('Контра'),
                  selected: _doubled,
                  onSelected: (value) {
                    setState(() {
                      _doubled = value;
                      if (_doubled) _redoubled = false;
                    });
                  },
                  selectedColor: Colors.red.withValues(alpha: 0.15),
                  checkmarkColor: Colors.red,
                  side: _doubled ? const BorderSide(color: Colors.red) : null,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Реконтра'),
                  selected: _redoubled,
                  onSelected: (value) {
                    setState(() {
                      _redoubled = value;
                      if (_redoubled) _doubled = false;
                    });
                  },
                  selectedColor: Colors.blue.withValues(alpha: 0.15),
                  checkmarkColor: Colors.blue,
                  side: _redoubled ? const BorderSide(color: Colors.blue) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclarerCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Декларант', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Direction>(
                segments: const [
                  ButtonSegment(value: Direction.north, label: Text('N')),
                  ButtonSegment(value: Direction.east, label: Text('E')),
                  ButtonSegment(value: Direction.south, label: Text('S')),
                  ButtonSegment(value: Direction.west, label: Text('W')),
                ],
                selected: {_declarer},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _declarer = newSelection.first;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Резултат', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Взети взятки', style: theme.textTheme.bodyLarge),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_suit != null && _tricks != 6 + _level)
                      IconButton(
                        onPressed: () => setState(() => _tricks = 6 + _level),
                        icon: Icon(Icons.refresh, color: theme.colorScheme.primary, size: 20),
                        tooltip: 'Върни на =',
                      ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: _tricks > 0 ? () => setState(() => _tricks--) : null,
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        _differenceText(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _differenceColor() ?? theme.textTheme.headlineSmall?.color,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: _tricks < 13 ? () => setState(() => _tricks++) : null,
                    ),
                  ],
                ),
              ],
            ),
            if (widget.showHcpField) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HCP в NS', style: theme.textTheme.bodyLarge),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _hcp > 0 ? () => setState(() => _hcp--) : null,
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '$_hcp',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: _hcp < 40 ? () => setState(() => _hcp++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}