import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/game_result.dart';
import '../../data/services/share_service.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';
import '../widgets/slot_reel_widget.dart';

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> {
  final _rng = Random();
  final _reelKeys = [GlobalKey<SlotReelWidgetState>(), GlobalKey<SlotReelWidgetState>(), GlobalKey<SlotReelWidgetState>()];
  late ConfettiController _confettiController;

  bool _isSpinning = false;
  int _bet = 50;
  List<int> _targetIndices = [0, 0, 0];
  String _resultMessage = '';
  int _stoppedReels = 0;
  bool _hasResult = false;
  int _lastPayout = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _targetIndices = List.generate(3, (_) => _rng.nextInt(slotSymbols.length));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _spin() {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.canAfford(_bet)) {
      _showSnack('❌ Moedas insuficientes!');
      return;
    }

    setState(() {
      _isSpinning = true;
      _stoppedReels = 0;
      _hasResult = false;
      _resultMessage = '';
      _targetIndices = List.generate(3, (_) => _rng.nextInt(slotSymbols.length));
    });
  }

  void _onReelStopped() {
    _stoppedReels++;
    if (_stoppedReels < 3) return;

    final symbols = _targetIndices.map((i) => slotSymbols[i]).toList();
    final result = calculateSlotPayout(symbols, _bet);
    final payout = result['payout']!;
    final multiplier = result['multiplier']!;
    final won = payout > 0;

    context.read<UserProvider>().recordGameResult(
          GameResult(
            userId: context.read<UserProvider>().user!.id,
            gameType: GameType.slots,
            bet: _bet,
            payout: payout,
            won: won,
            playedAt: DateTime.now(),
          ),
        );

    if (won) _confettiController.play();

    setState(() {
      _isSpinning = false;
      _hasResult = true;
      _lastPayout = payout;
      _resultMessage = won
          ? '${_buildWinMessage(multiplier, symbols)} +$payout 🪙'
          : '😢 Quase lá! Tente novamente!';
    });
  }

  String _buildWinMessage(int multiplier, List<String> symbols) {
    if (multiplier >= 50) return '🎊 JACKPOT! ${symbols.first}${symbols.first}${symbols.first}!';
    if (multiplier >= 20) return '🔥 INCRÍVEL! ${symbols.first}${symbols.first}${symbols.first}!';
    if (multiplier >= 10) return '🎉 SENSACIONAL! ${multiplier}x';
    if (multiplier > 2) return '⭐ Muito bem! ${multiplier}x';
    return '✨ Ganhou! ${multiplier}x';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.lose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _shareWin() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    await ShareService.shareWin(
      username: user.username,
      gameName: 'Caça-Níqueis 🎰',
      coins: _lastPayout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSlotMachine(),
                        const SizedBox(height: 24),
                        if (_hasResult) _buildResultCard(),
                        const SizedBox(height: 20),
                        _buildBetControls(),
                        const SizedBox(height: 20),
                        _buildSpinButton(),
                        const SizedBox(height: 16),
                        if (_hasResult && _lastPayout > 0) _buildShareButton(),
                        const SizedBox(height: 20),
                        _buildPayTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [AppColors.gold, Color(0xFFFF6B9D), Color(0xFF4ECDC4), AppColors.win],
                numberOfParticles: 50,
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
              '🎰 Caça-Níqueis',
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const CoinDisplayWidget(),
        ],
      ),
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7A0000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(
            '🎰 BetKids Slots 🎰',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                return SlotReelWidget(
                  key: _reelKeys[i],
                  targetIndex: _targetIndices[i],
                  isSpinning: _isSpinning,
                  stopDelay: Duration(milliseconds: 800 + i * 600),
                  onStopped: _onReelStopped,
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isWin = _lastPayout > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWin ? AppColors.win.withOpacity(0.15) : AppColors.lose.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isWin ? AppColors.win : AppColors.lose),
      ),
      child: Text(
        _resultMessage,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isWin ? AppColors.win : AppColors.lose,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildBetControls() {
    return Column(
      children: [
        Text(
          'Aposta: $_bet 🪙',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [10, 25, 50, 100, 200].map((amount) {
            final selected = _bet == amount;
            return GestureDetector(
              onTap: _isSpinning ? null : () => setState(() => _bet = amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$amount',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.white60, fontSize: 14),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpinButton() {
    return SizedBox(
      width: double.infinity,
      child: KidButton(
        label: _isSpinning ? '🎰 Girando...' : '🎰 GIRAR!',
        onPressed: _isSpinning ? null : _spin,
        color: AppColors.colorSlots,
        fontSize: 22,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: KidButton(
        label: '📤 Compartilhar!',
        onPressed: _shareWin,
        color: const Color(0xFF11998E),
      ),
    );
  }

  Widget _buildPayTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Tabela de Prêmios',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          ...[
            ('💎💎💎', '50x a aposta! JACKPOT!'),
            ('⭐⭐⭐', '20x a aposta!'),
            ('🍒🍒🍒', '10x a aposta!'),
            ('🍇🍇🍇', '8x a aposta!'),
            ('🍋🍋🍋', '5x a aposta!'),
            ('🍎🍎🍎', '4x a aposta!'),
            ('XX✓', '2 iguais = 2x!'),
          ].map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(e.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(e.$2, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
