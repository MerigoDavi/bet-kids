import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/card_deck.dart';
import '../../data/models/game_result.dart';
import '../../data/services/share_service.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';
import '../widgets/playing_card_widget.dart';

enum _GameState { betting, playerTurn, dealerTurn, gameOver }

enum _GameOutcome { win, lose, push }

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen> {
  final _deck = CardDeck();
  late ConfettiController _confettiController;

  _GameState _state = _GameState.betting;
  _GameOutcome? _outcome;
  List<PlayingCard> _playerHand = [];
  List<PlayingCard> _dealerHand = [];
  int _bet = 50;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _deck.shuffle();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _deal() {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.canAfford(_bet)) {
      _showSnack('❌ Moedas insuficientes!', AppColors.lose);
      return;
    }

    _deck.reset();
    setState(() {
      _playerHand = [_deck.draw(), _deck.draw()];
      _dealerHand = [_deck.draw(), _deck.draw()..copyWith(isFaceDown: true)];
      _dealerHand = [_dealerHand[0], _dealerHand[1].copyWith(isFaceDown: true)];
      _state = _GameState.playerTurn;
      _outcome = null;
    });

    if (calculateHandValue(_playerHand) == 21) {
      _stand();
    }
  }

  void _hit() {
    if (_state != _GameState.playerTurn || _isProcessing) return;

    setState(() => _playerHand = [..._playerHand, _deck.draw()]);

    if (calculateHandValue(_playerHand) > 21) {
      _endGame(_GameOutcome.lose);
    }
  }

  Future<void> _stand() async {
    if (_state != _GameState.playerTurn || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _state = _GameState.dealerTurn;
      _dealerHand = [_dealerHand[0], _dealerHand[1].copyWith(isFaceDown: false)];
    });

    await Future.delayed(const Duration(milliseconds: 600));

    while (calculateHandValue(_dealerHand) < 17 && mounted) {
      setState(() => _dealerHand = [..._dealerHand, _deck.draw()]);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    if (!mounted) return;

    final playerScore = calculateHandValue(_playerHand);
    final dealerScore = calculateHandValue(_dealerHand);

    if (dealerScore > 21 || playerScore > dealerScore) {
      _endGame(_GameOutcome.win);
    } else if (playerScore == dealerScore) {
      _endGame(_GameOutcome.push);
    } else {
      _endGame(_GameOutcome.lose);
    }
  }

  Future<void> _doubleDown() async {
    if (_state != _GameState.playerTurn || _isProcessing) return;
    final userProvider = context.read<UserProvider>();
    if (!userProvider.canAfford(_bet * 2)) {
      _showSnack('❌ Moedas insuficientes para dobrar!', AppColors.lose);
      return;
    }

    setState(() {
      _bet *= 2;
      _playerHand = [..._playerHand, _deck.draw()];
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _stand();
  }

  void _endGame(_GameOutcome outcome) {
    if (!mounted) return;

    final payout = switch (outcome) {
      _GameOutcome.win => _bet * 2,
      _GameOutcome.push => _bet,
      _GameOutcome.lose => 0,
    };

    context.read<UserProvider>().recordGameResult(
          GameResult(
            userId: context.read<UserProvider>().user!.id,
            gameType: GameType.blackjack,
            bet: _bet,
            payout: payout,
            won: outcome == _GameOutcome.win,
            playedAt: DateTime.now(),
          ),
        );

    if (outcome == _GameOutcome.win) _confettiController.play();

    setState(() {
      _state = _GameState.gameOver;
      _outcome = outcome;
      _isProcessing = false;
    });
  }

  void _resetGame() {
    setState(() {
      _state = _GameState.betting;
      _playerHand = [];
      _dealerHand = [];
      _bet = 50;
      _outcome = null;
    });
  }

  Future<void> _shareWin() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    await ShareService.shareWin(
      username: user.username,
      gameName: 'Blackjack 🃏',
      coins: _bet,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
                // header padrão do app
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text('🃏 Blackjack',
                            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            textAlign: TextAlign.center),
                      ),
                      const CoinDisplayWidget(),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildDealerSection(),
                        _buildScoreDisplay(),
                        _buildPlayerSection(),
                        const SizedBox(height: 12),
                        _buildActionArea(),
                        const SizedBox(height: 8),
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
                colors: const [AppColors.gold, AppColors.win, AppColors.primary, Color(0xFF4ECDC4)],
                numberOfParticles: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealerSection() {
    final dealerScore = calculateHandValue(_dealerHand);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dealer',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            if (_dealerHand.isNotEmpty)
              Text(
                _state == _GameState.playerTurn ? '?' : '$dealerScore',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: _dealerHand.isEmpty
              ? _cartasVazias()
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: _dealerHand
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PlayingCardWidget(card: c),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    if (_state == _GameState.betting) {
      return _buildOutcomeCard();
    }

    final playerScore = calculateHandValue(_playerHand);
    final isBust = playerScore > 21;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: _state == _GameState.gameOver
          ? _buildOutcomeCard()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBust) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.lose.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text('BUST! 💥', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lose)),
                  ),
                ] else ...[
                  Text(
                    'Seu total: $playerScore',
                    style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildOutcomeCard() {
    if (_state == _GameState.betting) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Text(
          'Faça sua aposta e jogue!',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    final (icon, message, color) = switch (_outcome) {
      _GameOutcome.win => ('🎉', 'Você ganhou ${_bet}x2 moedas!', AppColors.win),
      _GameOutcome.push => ('🤝', 'Empate! Aposta devolvida.', Colors.orange),
      _GameOutcome.lose => ('😢', 'Perdeu $_bet moedas...', AppColors.lose),
      null => ('🎰', '', Colors.white),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildPlayerSection() {
    final playerScore = calculateHandValue(_playerHand);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Você',
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            if (_playerHand.isNotEmpty)
              Text(
                '$playerScore',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: _playerHand.isEmpty
              ? _cartasVazias()
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: _playerHand
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: PlayingCardWidget(card: c),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  // placeholder enquanto as cartas ainda não foram distribuídas
  Widget _cartasVazias() {
    return Row(
      children: List.generate(2, (_) => Container(
        width: 70, height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
      )),
    );
  }

  Widget _buildActionArea() {
    return switch (_state) {
      _GameState.betting => _buildBettingControls(),
      _GameState.playerTurn => _buildPlayerControls(),
      _GameState.dealerTurn => _buildDealerTurnUI(),
      _GameState.gameOver => _buildGameOverControls(),
    };
  }

  Widget _buildBettingControls() {
    return Column(
      children: [
        Text(
          'Aposta: $_bet 🪙',
          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [25, 50, 100, 250, 500].map((amount) {
            final selected = _bet == amount;
            return GestureDetector(
              onTap: () => setState(() => _bet = amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$amount',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.white60),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🃏 Distribuir Cartas!',
            onPressed: _deal,
            color: AppColors.colorBlackjack,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls() {
    final canDoubleDown = _playerHand.length == 2 && context.watch<UserProvider>().canAfford(_bet * 2);
    return Row(
      children: [
        Expanded(
          child: KidButton(
            label: '👆 Pedir',
            onPressed: _hit,
            color: const Color(0xFF11998E),
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KidButton(
            label: '✋ Parar',
            onPressed: _stand,
            color: AppColors.lose,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KidButton(
            label: '2x Dobrar',
            onPressed: canDoubleDown ? _doubleDown : null,
            color: AppColors.colorSlots,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDealerTurnUI() {
    return Center(
      child: Text(
        '⏳ Dealer jogando...',
        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5),
    );
  }

  Widget _buildGameOverControls() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🔄 Jogar Novamente!',
            onPressed: _resetGame,
            color: AppColors.colorBlackjack,
          ),
        ),
        if (_outcome == _GameOutcome.win) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: KidButton(
              label: '📤 Compartilhar Vitória!',
              onPressed: _shareWin,
              color: const Color(0xFF11998E),
            ),
          ),
        ],
      ],
    );
  }
}
