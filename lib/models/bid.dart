import 'enums.dart';
import 'contract.dart';

enum BidType { pass, double, redouble, bid }

/// Единичен анонс в търга.
class Bid {
  final BidType type;
  final int level; // 0 за pass/double/redouble, 1-7 за bid
  final Suit? suit;

  const Bid._({required this.type, this.level = 0, this.suit});

  const Bid.pass() : this._(type: BidType.pass);
  const Bid.double() : this._(type: BidType.double);
  const Bid.redouble() : this._(type: BidType.redouble);
  const Bid.bid(int level, Suit suit)
      : this._(type: BidType.bid, level: level, suit: suit);

  bool get isBid => type == BidType.bid;
  bool get isPass => type == BidType.pass;
  bool get isDouble => type == BidType.double;
  bool get isRedouble => type == BidType.redouble;

  /// Текстово представяне: P, X, XX, 1♠, 2NT, ...
  String get display {
    switch (type) {
      case BidType.pass:
        return 'P';
      case BidType.double:
        return 'X';
      case BidType.redouble:
        return 'XX';
      case BidType.bid:
        if (suit == Suit.noTrump) return '${level}NT';
        return '$level${suit!.symbol}';
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (isBid) 'level': level,
    if (isBid) 'suit': suit!.name,
  };

  factory Bid.fromJson(Map<String, dynamic> json) {
    final type = BidType.values.byName(json['type'] as String);
    if (type == BidType.bid) {
      return Bid.bid(
        json['level'] as int,
        Suit.values.byName(json['suit'] as String),
      );
    }
    return Bid._(type: type);
  }
}

/// Анализира анонсите и връща крайния договор и декларант.
/// Връща (contract: null, declarer: null) ако търгът не е завършен.
({Contract? contract, Direction? declarer}) analyzeBidding(
    List<Bid> bids,
    Direction dealer,
    ) {
  if (bids.length < 4) {
    return (contract: null, declarer: null);
  }

  // Намираме последния редовен анонс (не pass/double/redouble).
  int lastBidIndex = -1;
  for (int i = bids.length - 1; i >= 0; i--) {
    if (bids[i].isBid) {
      lastBidIndex = i;
      break;
    }
  }
  if (lastBidIndex == -1) return (contract: null, declarer: null);

  final lastBid = bids[lastBidIndex];

  // Проверяваме за X / XX след последния bid.
  bool doubled = false;
  bool redoubled = false;
  for (int i = lastBidIndex + 1; i < bids.length; i++) {
    if (bids[i].isRedouble) {
      redoubled = true;
      doubled = false;
    } else if (bids[i].isDouble && !redoubled) {
      doubled = true;
    }
  }

  // Позиции: W=0, N=1, E=2, S=3 (по посока на часовниковата стрелка).
  const positions = [
    Direction.west,
    Direction.north,
    Direction.east,
    Direction.south,
  ];
  final dealerIdx = positions.indexOf(dealer);

  // Кой е направил последния bid.
  final lastBidPlayerIdx = (dealerIdx + lastBidIndex) % 4;
  final lastBidPlayer = positions[lastBidPlayerIdx];
  final isNS =
      lastBidPlayer == Direction.north || lastBidPlayer == Direction.south;

  // Намираме първия играч от същата страна, който е казал същия цвят.
  Direction? declarer;
  for (int i = 0; i <= lastBidIndex; i++) {
    if (!bids[i].isBid) continue;
    if (bids[i].suit != lastBid.suit) continue;
    final playerIdx = (dealerIdx + i) % 4;
    final player = positions[playerIdx];
    final playerIsNS =
        player == Direction.north || player == Direction.south;
    if (playerIsNS == isNS) {
      declarer = player;
      break;
    }
  }

  if (declarer == null) return (contract: null, declarer: null);

  return (
  contract: Contract(
    level: lastBid.level,
    suit: lastBid.suit!,
    doubled: doubled,
    redoubled: redoubled,
  ),
  declarer: declarer,
  );
}