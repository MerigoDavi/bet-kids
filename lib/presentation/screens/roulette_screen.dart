import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/shake_detector.dart';
import '../../data/models/game_result.dart';
import '../../data/services/ai_casino_host_service.dart';
import '../../data/services/share_service.dart';
import '../providers/user_provider.dart';
import '../widgets/ai_host_popup.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';
import '../widgets/roulette_wheel_widget.dart';

const _apostasDisponiveis = [10, 25, 50, 100, 250];

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late ConfettiController _confetti;
  late ShakeDetector _shake;

  double _rotacaoAtual = 0;
  Duration _duracaoGiro = const Duration(seconds: 4);
  int _aposta = 50;
  int? _segmentoGanhador;
  bool _girando = false;
  String _mensagem = '🤳 Agite o celular para girar!';
  bool _temResultado = false;
  double _intensidadeGiro = 0;

  @override
  void initState() {
    super.initState();
    _wheelController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addStatusListener(_aoTerminarAnimacao);

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _shake = ShakeDetector(onShake: (intensidade) {
      if (_girando || !mounted) return;
      _girar(intensidade: intensidade);
    });
    _shake.start();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _confetti.dispose();
    _shake.stop();
    super.dispose();
  }

  void _girar({required double intensidade}) {
    // trava extra: o giro só pode ser disparado pelo agitar do celular, e
    // nunca enquanto o giro anterior ainda está rodando
    if (_girando) return;

    final provider = context.read<UserProvider>();
    if (!provider.canAfford(_aposta)) {
      setState(() => _mensagem = '❌ Moedas insuficientes!');
      return;
    }

    // curva quadrática: diferença bem perceptível entre giro fraco e forte
    // fraco (0.0): 2 voltas, 1.2s  |  forte (1.0): 16 voltas, 9s
    final voltas = (2 + (intensidade * intensidade * 14)).round();
    final duracao = (1200 + (intensidade * intensidade * 7800)).round();

    final idx = Random().nextInt(rouletteSegments.length);
    final novaRotacao = _rotacaoAtual +
        getTargetRotation(idx, _rotacaoAtual, extraSpins: voltas);

    final forcaLabel = intensidade > 0.7
        ? '💥 Força máxima!'
        : intensidade > 0.4
            ? '💪 Bom balanço!'
            : '👋 Giro leve...';

    setState(() {
      _girando = true;
      _temResultado = false;
      _intensidadeGiro = intensidade;
      _segmentoGanhador = idx;
      _rotacaoAtual = novaRotacao;
      _duracaoGiro = Duration(milliseconds: duracao);
      _mensagem = forcaLabel;
    });
  }

  void _aoTerminarAnimacao(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    try {
      final seg = rouletteSegments[_segmentoGanhador!];
      final ganhou = seg.multiplier > 0;
      final provider = context.read<UserProvider>();
      final multi = provider.multiplicadorGlobal;

      // aplica o multiplicador da mamadeira — tanto ganho quanto perda são ampliados
      final apostaMult = (_aposta * multi).round();
      final premio = apostaMult * seg.multiplier;

      provider.recordGameResult(GameResult(
        userId: provider.user!.id,
        gameType: GameType.roulette,
        bet: apostaMult,
        payout: premio,
        won: ganhou,
        playedAt: DateTime.now(),
      ));
      provider.resetMultiplicador();

      if (ganhou) {
        // confetti desabilitado temporariamente para debug
        // _confetti.play();
      }

      final sufixoMulti = multi > 1 ? ' (${multi}x aplicado!)' : '';
      setState(() {
        _girando = false;
        _temResultado = true;
        _mensagem = ganhou
            ? '🎉 ${seg.label}! Você ganhou $premio moedas!$sufixoMulti'
            : '😢 Que pena! Tente novamente!$sufixoMulti';
      });

      _mostrarIncentivoIA(
          ganhou: ganhou, gamesPlayed: provider.user!.gamesPlayed);
    } catch (_) {
      if (mounted) {
        setState(() {
          _girando = false;
          _temResultado = true;
          _mensagem = '😢 Algo deu errado. Tente novamente!';
        });
      }
    }
  }

  void _mostrarIncentivoIA({required bool ganhou, required int gamesPlayed}) {
    if (!ganhou) {
      // popup desabilitado temporariamente para debug
    } else if (gamesPlayed % 5 == 0) {
      AiHostPopup.show(context, situacao: AiHostSituacao.sequencia);
    }
  }

  void _aumentarAposta() {
    final atual = _apostasDisponiveis.indexOf(_aposta);
    final proxima = _apostasDisponiveis[
        (atual + 1).clamp(0, _apostasDisponiveis.length - 1)];
    setState(() => _aposta = proxima);
  }

  Future<void> _compartilharResultado() async {
    final user = context.read<UserProvider>().user;
    if (user == null || _segmentoGanhador == null) return;
    final seg = rouletteSegments[_segmentoGanhador!];
    if (seg.multiplier > 0) {
      await ShareService.shareWin(
        username: user.username,
        gameName: 'Roleta 🎡',
        coins: _aposta * seg.multiplier,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWin = _temResultado &&
        (_segmentoGanhador != null) &&
        rouletteSegments[_segmentoGanhador!].multiplier > 0;
    final isLoss = _temResultado && !isWin;
    final corStatus = isWin
        ? AppColors.win
        : isLoss
            ? AppColors.lose
            : null;
    final multi = context.watch<UserProvider>().multiplicadorGlobal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // banner de risco ativo (mamadeira)
                if (multi > 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.colorMamadeira.withOpacity(0.85),
                    child: Text(
                      '🍼 Risco ativo: ${multi}x — ganhos e perdas multiplicados!',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          '🎡 Roleta',
                          style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const CoinDisplayWidget(),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // card de status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: corStatus != null
                                ? corStatus.withOpacity(0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: corStatus ?? Colors.white12),
                          ),
                          child: Text(
                            _mensagem,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: corStatus ?? Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // barra de força do agite (só aparece enquanto gira)
                        if (_girando) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Força do giro',
                                  style: GoogleFonts.nunito(
                                      fontSize: 12, color: Colors.white54)),
                              Text(
                                '${(_intensidadeGiro * 100).round()}%',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _intensidadeGiro > 0.7
                                      ? AppColors.lose
                                      : _intensidadeGiro > 0.4
                                          ? AppColors.colorSlots
                                          : AppColors.win,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _intensidadeGiro,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _intensidadeGiro > 0.7
                                    ? AppColors.lose
                                    : _intensidadeGiro > 0.4
                                        ? AppColors.colorSlots
                                        : AppColors.win,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        RouletteWheelWidget(
                          animationController: _wheelController,
                          targetRotation: _rotacaoAtual,
                          spinDuration: _duracaoGiro,
                        ),
                        const SizedBox(height: 24),

                        // dica de como jogar
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border(
                                left: BorderSide(
                                    color: AppColors.colorRoulette, width: 4)),
                          ),
                          child: Row(
                            children: [
                              const Text('📱', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dica',
                                        style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.colorRoulette)),
                                    Text('Agite o celular pra girar a roleta!',
                                        style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // seletor de aposta
                        Text('Aposta: $_aposta 🪙',
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _apostasDisponiveis.map((valor) {
                            final selecionado = _aposta == valor;
                            return GestureDetector(
                              onTap: _girando
                                  ? null
                                  : () => setState(() => _aposta = valor),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selecionado
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: selecionado
                                          ? AppColors.primary
                                          : Colors.white12),
                                ),
                                child: Text(
                                  '$valor',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selecionado
                                        ? Colors.white
                                        : Colors.white60,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        if (_temResultado &&
                            _segmentoGanhador != null &&
                            rouletteSegments[_segmentoGanhador!].multiplier >
                                0) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: KidButton(
                              label: '📤 Compartilhar Vitória!',
                              onPressed: _compartilharResultado,
                              color: const Color(0xFF11998E),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFF6B9D),
                  Color(0xFF4ECDC4),
                  Color(0xFF00FF7F)
                ],
                numberOfParticles: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
