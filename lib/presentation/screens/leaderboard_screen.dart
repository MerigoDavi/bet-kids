import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/share_service.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().loadLeaderboard();
  }

  Future<void> _sharePosition() async {
    final userProvider = context.read<UserProvider>();
    final leaderboard = userProvider.leaderboard;
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    final index = leaderboard.indexWhere((u) => u.id == currentUser.id);
    await ShareService.shareLeaderboardPosition(
      username: currentUser.username,
      position: index == -1 ? leaderboard.length + 1 : index + 1,
      coins: currentUser.coins,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final leaderboard = userProvider.leaderboard;
    final currentUserId = userProvider.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('🏆 Ranking',
                        style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                  const CoinDisplayWidget(),
                ],
              ),
            ),

            Expanded(
              child: leaderboard.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text('Nenhum jogador ainda!\nSeja o primeiro!',
                              style: GoogleFonts.nunito(fontSize: 16, color: Colors.white60),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (leaderboard.length >= 3) _buildPodium(leaderboard.take(3).toList()),
                        const SizedBox(height: 16),
                        ...leaderboard.asMap().entries.map((entry) => _LeaderboardItem(
                              user: entry.value,
                              rank: entry.key + 1,
                              isCurrentUser: entry.value.id == currentUserId,
                            )),
                        const SizedBox(height: 16),
                        KidButton(
                          label: '📤 Compartilhar Posição!',
                          onPressed: _sharePosition,
                          color: const Color(0xFF8E44AD),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<UserProfile> top3) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 0, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text('🏆 Top 3',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PodiumPlace(user: top3[1], rank: 2, height: 80, medal: '🥈'),
              _PodiumPlace(user: top3[0], rank: 1, height: 110, medal: '🥇'),
              _PodiumPlace(user: top3[2], rank: 3, height: 60, medal: '🥉'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final UserProfile user;
  final int rank;
  final double height;
  final String medal;

  const _PodiumPlace({required this.user, required this.rank, required this.height, required this.medal});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(user.avatar, style: const TextStyle(fontSize: 30)),
        const SizedBox(height: 4),
        Text(
          user.username.length > 8 ? '${user.username.substring(0, 8)}...' : user.username,
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        Text('${user.coins} 🪙', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.gold)),
        const SizedBox(height: 8),
        Text(medal, style: const TextStyle(fontSize: 26)),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.gold.withOpacity(0.3)
                : rank == 2
                    ? Colors.grey.withOpacity(0.3)
                    : const Color(0xFFCD7F32).withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text('$rank',
                style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final UserProfile user;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardItem({required this.user, required this.rank, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrentUser ? AppColors.primary : Colors.white12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(_rankLabel(rank),
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Text(user.avatar, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.username,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCurrentUser ? AppColors.primary : Colors.white)),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                        child: Text('Você',
                            style: GoogleFonts.nunito(
                                fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text('${user.gamesPlayed} partidas',
                    style: GoogleFonts.nunito(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          Text('${user.coins} 🪙',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.gold)),
        ],
      ),
    );
  }

  String _rankLabel(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#$rank',
      };
}
