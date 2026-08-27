import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/contract.dart';
import '../models/enums.dart';
import '../models/game.dart';

/// Формуляр за въвеждане на нова игра.
class GameInputScreen extends StatefulWidget {
  /// Списък от вече заети номера на бордове в текущия мач.
  final List<int> usedBoardNumbers;

  /// Дали да показва поле за оньорни точки (HCP) – само за каре.
  final bool showHcpField;

  const GameInputScreen({
    super.key,
    this.usedBoardNumbers = const [],
    this.showHcpField = false,
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
  Direction _declarer = Direction.north; // non-null, начална стойност
  bool _doubled = false;
  bool _redoubled = false;

  late Board _currentBoard;

  @override
  void initState() {
    super.initState();
    int nextBoardNumber = 1;
    while (widget.usedBoardNumbers.contains(nextBoardNumber)) {
      nextBoardNumber++;
    }
    _currentBoard = Board.auto(nextBoardNumber);
    _boardNumberController.text = '$nextBoardNumber';
  }

  @override
  void dispose() {
    _boardNumberController.dispose();
    _tricksController.dispose();
    _hcpController.dispose();
    super.dispose();
  }

  Game? _createGame() {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Дилър: ${_currentBoard.dealer.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shield, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Зона: ${_currentBoard.zone.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ниво и цвят на един ред
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _level,
                    hint: const Text('Ниво'),
                    decoration: const InputDecoration(
                      labelText: 'Ниво',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(7, (i) => i + 1)
                        .map((l) => DropdownMenuItem(value: l, child: Text('$l')))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _level = value;
                      });
                    },
                    validator: (value) => value == null ? 'Изберете' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Suit>(
                    value: _suit,
                    hint: const Text('Цвят'),
                    decoration: const InputDecoration(
                      labelText: 'Цвят',
                      border: OutlineInputBorder(),
                    ),
                    items: Suit.values
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.symbol, style: const TextStyle(fontSize: 20)),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _suit = value;
                      });
                    },
                    validator: (value) => value == null ? 'Изберете' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Контра/Реконтра и декларант
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

            // Декларант – SegmentedButton
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
                  labelText: 'Оньорни точки (HCP)',
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