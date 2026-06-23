import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/game_result.dart';
import '../../data/services/share_service.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().loadHistory();
  }

  Future<void> _shareProfile() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final history = context.read<UserProvider>().history;
    await ShareService.shareScore(
      username: user.username,
      totalCoins: user.coins,
      gamesPlayed: history.length,
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sair?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white)),
        content: Text(
          'Tem certeza que quer sair?',
          style: GoogleFonts.nunito(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.nunito(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sair', style: GoogleFonts.nunito(color: AppColors.lose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final history = context.watch<UserProvider>().history;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileHeader(user.avatar, user.username, user.coins),
                    const SizedBox(height: 24),
                    _buildStatsGrid(user.gamesPlayed, user.totalWon, user.bestWin),
                    const SizedBox(height: 24),
                    _buildAchievements(user.gamesPlayed, user.bestWin),
                    const SizedBox(height: 24),
                    _buildHistory(history),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '👤 Perfil',
              style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const CoinDisplayWidget(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String avatar, String username, int coins) {
    return Column(
      children: [
        Text(avatar, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(
          username,
          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          '$coins 🪙',
          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int gamesPlayed, int totalWon, int bestWin) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatCard(emoji: '🎮', label: 'Partidas', value: '$gamesPlayed'),
        _StatCard(emoji: '🪙', label: 'Total Ganho', value: '$totalWon'),
        _StatCard(emoji: '🏆', label: 'Melhor Vitória', value: '$bestWin'),
        _StatCard(
          emoji: '📊',
          label: 'Taxa de Acerto',
          value: gamesPlayed == 0 ? '-' : '${(context.watch<UserProvider>().history.where((r) => r.won).length / gamesPlayed * 100).round()}%',
        ),
      ],
    );
  }

  Widget _buildAchievements(int gamesPlayed, int bestWin) {
    final achievements = <(String, String, bool)>[
      ('🎮', 'Primeira Partida', gamesPlayed >= 1),
      ('🔥', 'Jogador Dedicado', gamesPlayed >= 10),
      ('⭐', 'Veterano', gamesPlayed >= 50),
      ('💰', 'Grande Ganho', bestWin >= 500),
      ('💎', 'Jackpot!', bestWin >= 2500),
      ('👑', 'Lenda', gamesPlayed >= 100),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏅 Conquistas',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: achievements.map((a) {
            return Opacity(
              opacity: a.$3 ? 1.0 : 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: a.$3 ? AppColors.gold.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.$3 ? AppColors.gold : Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(a.$2, style: GoogleFonts.nunito(fontSize: 13, color: a.$3 ? AppColors.gold : Colors.white60)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistory(List<GameResult> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Text('Nenhuma partida ainda!', style: GoogleFonts.nunito(color: Colors.white60)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Histórico Recente',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 12),
        ...history.take(10).map((result) => _HistoryItem(result: result)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '📤 Compartilhar Perfil!',
            onPressed: _shareProfile,
            color: const Color(0xFF8E44AD),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🚪 Sair',
            onPressed: _logout,
            color: AppColors.neutral,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatCard({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.colorProfile, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 0, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final GameResult result;

  const _HistoryItem({required this.result});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: result.won ? AppColors.win.withOpacity(0.3) : Colors.white12),
      ),
      child: Row(
        children: [
          Text(result.gameType == GameType.roulette ? '🎡' : result.gameType == GameType.blackjack ? '🃏' : result.gameType == GameType.slots ? '🎰' : '🧠',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.gameLabel, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(formatter.format(result.playedAt), style: GoogleFonts.nunito(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.won ? '+${result.payout} 🪙' : '-${result.bet} 🪙',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: result.won ? AppColors.win : AppColors.lose,
                ),
              ),
              Text(
                'Aposta: ${result.bet}',
                style: GoogleFonts.nunito(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
