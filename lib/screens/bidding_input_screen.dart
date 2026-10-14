import 'package:flutter/material.dart';
import '../models/models.dart';

class BiddingInputScreen extends StatefulWidget {
  final Board board;
  final List<Bid> initialBidding;

  const BiddingInputScreen({
    super.key,
    required this.board,
    this.initialBidding = const [],
  });

  @override
  State<BiddingInputScreen> createState() => _BiddingInputScreenState();
}

class _BiddingInputScreenState extends State<BiddingInputScreen> {
  late List<Bid> _bids;
  int? _selectedLevel;

  // Позиции в ред на часовниковата стрелка.
  static const _positions = [
    Direction.west,
    Direction.north,
    Direction.east,
    Direction.south,
  ];

  @override
  void initState() {
    super.initState();
    _bids = List.from(widget.initialBidding);
  }

  // ==================== ИНДЕКСИ ====================

  int get _dealerCol {
    switch (widget.board.dealer) {
      case Direction.west:
        return 0;
      case Direction.north:
        return 1;
      case Direction.east:
        return 2;
      case Direction.south:
        return 3;
    }
  }

  /// Индекс на последния валиден bid в _bids (-1 ако няма).
  int get _lastBidIndex {
    for (int i = _bids.length - 1; i >= 0; i--) {
      if (_bids[i].isBid) return i;
    }
    return -1;
  }

  /// Най-високият анонс досега (без Pass/X/XX).
  Bid? get _currentHighestBid {
    final idx = _lastBidIndex;
    return idx >= 0 ? _bids[idx] : null;
  }

  /// Кой играч прави следващия анонс.
  Direction get _nextBidder {
    final nextIdx = _bids.length;
    final playerIdx = (_positions.indexOf(widget.board.dealer) + nextIdx) % 4;
    return _positions[playerIdx];
  }

  /// Кой е направил последния bid.
  Direction? get _lastBidder {
    final idx = _lastBidIndex;
    if (idx < 0) return null;
    final playerIdx = (_positions.indexOf(widget.board.dealer) + idx) % 4;
    return _positions[playerIdx];
  }

  bool _isNS(Direction d) => d == Direction.north || d == Direction.south;

  // ==================== СЪСТОЯНИЕ ====================

  /// Дали bid-ът е doubled (има X след последния bid, без XX).
  bool get _isDoubled {
    for (int i = _bids.length - 1; i >= 0; i--) {
      if (_bids[i].isBid) return false;
      if (_bids[i].isRedouble) return false;
      if (_bids[i].isDouble) return true;
    }
    return false;
  }

  /// Дали bid-ът е redoubled.
  bool get _isRedoubled {
    for (int i = _bids.length - 1; i >= 0; i--) {
      if (_bids[i].isBid) return false;
      if (_bids[i].isRedouble) return true;
    }
    return false;
  }

  /// Приключен ли е търгът.
  bool get _isAuctionFinished {
    if (_bids.isEmpty) return false;
    // 4 паса в началото.
    if (_bids.length == 4 && _bids.every((b) => b.isPass)) return true;
    // 3 паса след последен non-pass.
    if (_bids.length >= 4) {
      final last3 = _bids.sublist(_bids.length - 3);
      if (last3.every((b) => b.isPass)) return true;
    }
    return false;
  }

  // ==================== ВАЛИДАЦИЯ ====================

  /// Ранг на цвят: ♣=0, ♦=1, ♥=2, ♠=3, NT=4.
  int _suitRank(Suit suit) {
    switch (suit) {
      case Suit.club:
        return 0;
      case Suit.diamond:
        return 1;
      case Suit.heart:
        return 2;
      case Suit.spade:
        return 3;
      case Suit.noTrump:
        return 4;
    }
  }

  /// Валиден ли е този bid (по-висок от текущия най-висок).
  bool _isBidValid(int level, Suit suit) {
    if (_isAuctionFinished) return false;
    final highest = _currentHighestBid;
    if (highest == null) return true;
    if (level > highest.level) return true;
    if (level < highest.level) return false;
    return _suitRank(suit) > _suitRank(highest.suit!);
  }

  /// Дали поне един цвят е валиден за това ниво.
  bool _isLevelEnabled(int level) {
    if (_isAuctionFinished) return false;
    for (final suit in Suit.values) {
      if (_isBidValid(level, suit)) return true;
    }
    return false;
  }

  /// Валиден ли е X.
  bool get _canDouble {
    if (_isAuctionFinished) return false;
    final last = _lastBidder;
    if (last == null) return false;
    if (_isDoubled || _isRedoubled) return false;
    // Само опоненти могат да контрират.
    return _isNS(last) != _isNS(_nextBidder);
  }

  /// Валиден ли е XX.
  bool get _canRedouble {
    if (_isAuctionFinished) return false;
    final last = _lastBidder;
    if (last == null) return false;
    if (!_isDoubled) return false;
    // Само опоненти на този, който е контрирал, могат да реконтрират.
    return _isNS(last) != _isNS(_nextBidder);
  }

  // ==================== ЛОГИКА ====================

  List<List<Bid?>> _buildGrid() {
    if (_bids.isEmpty) return [];
    final rows = <List<Bid?>>[];
    int col = _dealerCol;
    int row = 0;
    for (final bid in _bids) {
      while (rows.length <= row) {
        rows.add(List.filled(4, null));
      }
      rows[row][col] = bid;
      col++;
      if (col > 3) {
        col = 0;
        row++;
      }
    }
    return rows;
  }

  void _addBid(Bid bid) {
    setState(() {
      _bids.add(bid);
      _selectedLevel = null;
    });
  }

  void _undo() {
    if (_bids.isEmpty) return;
    setState(() {
      _bids.removeLast();
      _selectedLevel = null;
    });
  }

  void _clear() {
    setState(() {
      _bids.clear();
      _selectedLevel = null;
    });
  }

  Color _suitColor(BuildContext context, Suit suit) {
    final brightness = Theme.of(context).brightness;
    switch (suit) {
      case Suit.club:
        return brightness == Brightness.dark
            ? Colors.grey.shade400
            : Colors.grey.shade700;
      case Suit.diamond:
        return Colors.orange.shade700;
      case Suit.heart:
        return Colors.red.shade700;
      case Suit.spade:
      case Suit.noTrump:
        return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
  }

  Color _bidColor(Bid bid) {
    final theme = Theme.of(context);
    if (bid.isBid && bid.suit != null) {
      return _suitColor(context, bid.suit!);
    }
    if (bid.isDouble) return Colors.red.shade600;
    if (bid.isRedouble) return Colors.blue.shade600;
    return theme.colorScheme.onSurfaceVariant;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анонси'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _buildAuctionCard(theme),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(_bids),
            icon: const Icon(Icons.check),
            label: const Text('ЗАПАЗИ АНОНСИТЕ'),
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionCard(ThemeData theme) {
    final headerBg = theme.colorScheme.primary;
    final headerFg = theme.colorScheme.onPrimary;
    final rows = _buildGrid();
    final enabled = _selectedLevel != null && !_isAuctionFinished;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header W N E S
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                for (final col in ['W', 'N', 'E', 'S'])
                  Expanded(
                    child: Text(
                      col,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5,
                        color: headerFg,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bidding table
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Няма въведени анонси',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            for (var r = 0; r < rows.length; r++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: r.isEven
                      ? Colors.transparent
                      : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: rows[r][i] == null
                            ? const SizedBox.shrink()
                            : Text(
                          rows[r][i]!.display,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _bidColor(rows[r][i]!),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // Всички бутони
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ниво
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (i) {
                    final level = i + 1;
                    final levelEnabled = _isLevelEnabled(level);
                    return ChoiceChip(
                      label: Text('$level'),
                      selected: _selectedLevel == level,
                      showCheckmark: false,
                      onSelected: levelEnabled
                          ? (selected) {
                        setState(() {
                          _selectedLevel = selected ? level : null;
                        });
                      }
                          : null,
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Цвят
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Suit.values.map((suit) {
                    final suitColor = _suitColor(context, suit);
                    final suitEnabled = enabled &&
                        _selectedLevel != null &&
                        _isBidValid(_selectedLevel!, suit);
                    return Opacity(
                      opacity: suitEnabled ? 1.0 : 0.4,
                      child: ChoiceChip(
                        label: Text(
                          suit.symbol,
                          style: TextStyle(
                            color: suitColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: false,
                        showCheckmark: false,
                        onSelected: suitEnabled
                            ? (selected) =>
                            _addBid(Bid.bid(_selectedLevel!, suit))
                            : null,
                        backgroundColor:
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        selectedColor: suitColor.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: suitEnabled ? suitColor : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Pass / X / XX + Отмени / Изчисти
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Pass'),
                      selected: false,
                      onSelected: _isAuctionFinished
                          ? null
                          : (_) => _addBid(const Bid.pass()),
                      showCheckmark: false,
                      selectedColor: Colors.green.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: _isAuctionFinished
                            ? theme.dividerColor
                            : Colors.green.shade600,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isAuctionFinished
                            ? theme.disabledColor
                            : Colors.green.shade700,
                      ),
                    ),
                    FilterChip(
                      label: const Text('X'),
                      selected: false,
                      onSelected: _canDouble
                          ? (_) => _addBid(const Bid.double())
                          : null,
                      showCheckmark: false,
                      selectedColor: Colors.red.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: _canDouble
                            ? Colors.red.shade600
                            : theme.dividerColor,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _canDouble
                            ? Colors.red.shade700
                            : theme.disabledColor,
                      ),
                    ),
                    FilterChip(
                      label: const Text('XX'),
                      selected: false,
                      onSelected: _canRedouble
                          ? (_) => _addBid(const Bid.redouble())
                          : null,
                      showCheckmark: false,
                      selectedColor: Colors.blue.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: _canRedouble
                            ? Colors.blue.shade600
                            : theme.dividerColor,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _canRedouble
                            ? Colors.blue.shade700
                            : theme.disabledColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      icon: const Icon(Icons.undo, size: 18),
                      tooltip: 'Отмени',
                      onPressed: _bids.isEmpty ? null : _undo,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Изчисти',
                      onPressed: _bids.isEmpty ? null : _clear,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}