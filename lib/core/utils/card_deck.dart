import 'dart:math';

enum CardSuit { spades, hearts, diamonds, clubs }

enum CardRank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }

class PlayingCard {
  final CardSuit suit;
  final CardRank rank;
  final bool isFaceDown;

  const PlayingCard({
    required this.suit,
    required this.rank,
    this.isFaceDown = false,
  });

  PlayingCard copyWith({bool? isFaceDown}) =>
      PlayingCard(suit: suit, rank: rank, isFaceDown: isFaceDown ?? this.isFaceDown);

  String get suitSymbol => switch (suit) {
        CardSuit.spades => '♠',
        CardSuit.hearts => '♥',
        CardSuit.diamonds => '♦',
        CardSuit.clubs => '♣',
      };

  String get rankLabel => switch (rank) {
        CardRank.ace => 'A',
        CardRank.two => '2',
        CardRank.three => '3',
        CardRank.four => '4',
        CardRank.five => '5',
        CardRank.six => '6',
        CardRank.seven => '7',
        CardRank.eight => '8',
        CardRank.nine => '9',
        CardRank.ten => '10',
        CardRank.jack => 'J',
        CardRank.queen => 'Q',
        CardRank.king => 'K',
      };

  int get baseValue => switch (rank) {
        CardRank.ace => 11,
        CardRank.two => 2,
        CardRank.three => 3,
        CardRank.four => 4,
        CardRank.five => 5,
        CardRank.six => 6,
        CardRank.seven => 7,
        CardRank.eight => 8,
        CardRank.nine => 9,
        CardRank.ten || CardRank.jack || CardRank.queen || CardRank.king => 10,
      };

  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;
}

class CardDeck {
  final List<PlayingCard> _cards = [];
  final Random _random = Random();

  CardDeck() {
    _buildDeck();
  }

  void _buildDeck() {
    _cards.clear();
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        _cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
  }

  void shuffle() => _cards.shuffle(_random);

  PlayingCard draw() {
    if (_cards.isEmpty) {
      _buildDeck();
      shuffle();
    }
    return _cards.removeLast();
  }

  void reset() {
    _buildDeck();
    shuffle();
  }
}

int calculateHandValue(List<PlayingCard> hand) {
  int total = 0;
  int aces = 0;

  for (final card in hand) {
    if (card.isFaceDown) continue;
    if (card.rank == CardRank.ace) {
      aces++;
      total += 11;
    } else {
      total += card.baseValue;
    }
  }

  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }

  return total;
}
