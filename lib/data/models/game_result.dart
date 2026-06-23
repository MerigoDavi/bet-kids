enum GameType { roulette, blackjack, slots, trivia, coinFlip }

class GameResult {
  final String userId;
  final GameType gameType;
  final int bet;
  final int payout;
  final bool won;
  final DateTime playedAt;

  const GameResult({
    required this.userId,
    required this.gameType,
    required this.bet,
    required this.payout,
    required this.won,
    required this.playedAt,
  });

  int get profit => payout - bet;

  String get gameLabel => switch (gameType) {
        GameType.roulette  => '🎡 Roleta',
        GameType.blackjack => '🃏 Blackjack',
        GameType.slots     => '🎰 Caça-Níqueis',
        GameType.trivia    => '🧠 Trivia',
        GameType.coinFlip  => '🪙 Cara ou Coroa',
      };

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'gameType': gameType.name,
        'bet': bet,
        'payout': payout,
        'won': won ? 1 : 0,
        'playedAt': playedAt.millisecondsSinceEpoch,
      };

  factory GameResult.fromMap(Map<String, dynamic> map) => GameResult(
        userId: map['userId'] as String,
        gameType: GameType.values.firstWhere((e) => e.name == map['gameType']),
        bet: map['bet'] as int,
        payout: map['payout'] as int,
        won: (map['won'] as int) == 1,
        playedAt: DateTime.fromMillisecondsSinceEpoch(map['playedAt'] as int),
      );
}
