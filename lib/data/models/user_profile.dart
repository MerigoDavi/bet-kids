class UserProfile {
  final String id;
  final String username;
  final String avatar;
  final int coins;
  final int gamesPlayed;
  final int totalWon;
  final int bestWin;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.avatar,
    this.coins = 1000,
    this.gamesPlayed = 0,
    this.totalWon = 0,
    this.bestWin = 0,
    required this.createdAt,
  });

  UserProfile copyWith({
    int? coins,
    int? gamesPlayed,
    int? totalWon,
    int? bestWin,
  }) =>
      UserProfile(
        id: id,
        username: username,
        avatar: avatar,
        coins: coins ?? this.coins,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        totalWon: totalWon ?? this.totalWon,
        bestWin: bestWin ?? this.bestWin,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar': avatar,
        'coins': coins,
        'gamesPlayed': gamesPlayed,
        'totalWon': totalWon,
        'bestWin': bestWin,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        username: map['username'] as String,
        avatar: map['avatar'] as String? ?? '⭐',
        coins: map['coins'] as int? ?? 1000,
        gamesPlayed: map['gamesPlayed'] as int? ?? 0,
        totalWon: map['totalWon'] as int? ?? 0,
        bestWin: map['bestWin'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
