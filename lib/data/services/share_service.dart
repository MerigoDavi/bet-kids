import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareWin({
    required String username,
    required String gameName,
    required int coins,
  }) async {
    final message = '🎉 $username ganhou $coins moedas no $gameName do BetKids! ⭐\n'
        'Venha jogar também e mostre quem é o melhor! 🏆';
    await SharePlus.instance.share(ShareParams(text: message, subject: 'Ganhei no BetKids! 🎮'));
  }

  static Future<void> shareScore({
    required String username,
    required int totalCoins,
    required int gamesPlayed,
  }) async {
    final message = '🌟 $username tem $totalCoins moedas no BetKids!\n'
        'Já joguei $gamesPlayed partidas! Você consegue me superar? 😎\n'
        '#BetKids #JogosDivertidos';
    await SharePlus.instance.share(ShareParams(text: message, subject: 'Meu score no BetKids!'));
  }

  static Future<void> shareLeaderboardPosition({
    required String username,
    required int position,
    required int coins,
  }) async {
    final medal = switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🏅',
    };
    final message = '$medal $username está em ${position}º lugar no BetKids com $coins moedas!\n'
        'Jogue agora e tente me superar! 🎮';
    await SharePlus.instance.share(ShareParams(text: message, subject: 'Estou no ranking do BetKids!'));
  }
}
