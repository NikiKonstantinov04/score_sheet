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
  final _formKey = GlobalKey<FormState>();

  final _boardNumberController = TextEditingController();
  final _tricksController = TextEditingController();
  final _hcpController = TextEditingController();

  int? _level;
  Suit? _suit;
  Direction _declarer = Direction.north;
  bool _doubled = false;
  bool _redoubled = false;

  late Board _currentBoard;

  @override
  void initState() {
    super.initState();
    if (widget.existingGame != null) {
      final game = widget.existingGame!;
      _currentBoard = game.board;
      _boardNumberController.text = '${game.board.number}';
      _level = game.contract.level;
      _suit = game.contract.suit;
      _doubled = game.contract.doubled;
      _redoubled = game.contract.redoubled;
      _declarer = game.declarer;
      _tricksController.text = '${game.tricksWon}';
      if (widget.showHcpField && game.hcp != null) {
        _hcpController.text = '${game.hcp}';
      }
    } else {
      int nextBoardNumber = 1;
      while (widget.usedBoardNumbers.contains(nextBoardNumber)) {
        nextBoardNumber++;
      }
      _currentBoard = Board.auto(nextBoardNumber);
      _boardNumberController.text = '$nextBoardNumber';
    }
  }

  @override
  void dispose() {
    _boardNumberController.dispose();
    _tricksController.dispose();
    _hcpController.dispose();
    super.dispose();
  }

  /// Връща цвят за съответния suit.
  Color _suitColor(Suit suit) {
    switch (suit) {
      case Suit.club:
        return Colors.grey.shade700;
      case Suit.diamond:
        return Colors.orange.shade700;
      case Suit.heart:
        return Colors.red.shade700;
      case Suit.spade:
        return Colors.black;
      case Suit.noTrump:
        return Colors.indigo.shade700;
    }
  }

  /// Валидира формата и връща Game, ако всичко е наред.
  Game? _createGame() {
    if (_level == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля, изберете ниво')),
      );
      return null;
    }
    if (_suit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля, изберете цвят')),
      );
      return null;
    }
    if (!_formKey.currentState!.validate()) return null;

    final boardNumber = int.parse(_boardNumberController.text);
    final tricksWon = int.parse(_tricksController.text);

    int? hcp;
    if (widget.showHcpField) {
      hcp = int.tryParse(_hcpController.text);
    }

    final board = Board.auto(boardNumber);
    final contract = Contract(
      level: _level!,
      suit: _suit!,
      doubled: _doubled,
      redoubled: _redoubled,
    );

    return Game(
      board: board,
      contract: contract,
      declarer: _declarer,
      tricksWon: tricksWon,
      hcp: hcp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нова игра')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Информация за борда
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _boardNumberController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Номер на борд',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Дилър: ${_currentBoard.dealer.bgName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shield,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Зона: ${_currentBoard.zone.bgName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Секция Контракт
            Text('Контракт', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Избор на ниво
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final level = i + 1;
                return ChoiceChip(
                  label: Text('$level'),
                  selected: _level == level,
                  onSelected: (selected) {
                    setState(() {
                      _level = selected ? level : null;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            // Избор на цвят
            Wrap(
              spacing: 8,
              children: Suit.values.map((suit) {
                final isSelected = _suit == suit;
                return ChoiceChip(
                  label: Text(
                    suit.symbol,
                    style: TextStyle(
                      color: _suitColor(suit),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _suit = selected ? suit : null;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: _suitColor(suit).withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? _suitColor(suit) : Colors.grey.shade400,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Контра/Реконтра
            Text('Опции', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Декларант
            Text('Декларант', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Direction>(
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
            const SizedBox(height: 16),

            // Брой взети взятки
            TextFormField(
              controller: _tricksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Взети взятки (0-13)',
                hintText: 'Въведете брой',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Моля, въведете брой взятки';
                }
                final t = int.tryParse(value);
                if (t == null || t < 0 || t > 13) {
                  return 'Въведете число от 0 до 13';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // HCP поле само за каре
            if (widget.showHcpField) ...[
              TextFormField(
                controller: _hcpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'HCP в NS',
                  hintText: 'напр. 24',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Моля, въведете HCP';
                  }
                  final hcp = int.tryParse(value);
                  if (hcp == null || hcp < 0 || hcp > 40) {
                    return 'Въведете число от 0 до 40';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Бутон за запис
            FilledButton.icon(
              onPressed: () {
                final game = _createGame();
                if (game != null) {
                  Navigator.of(context).pop(game);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Запази'),
            ),
          ],
        ),
      ),
    );
  }
}