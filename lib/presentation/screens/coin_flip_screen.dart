import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/game_result.dart';
import '../../data/services/ai_casino_host_service.dart';
import '../providers/user_provider.dart';
import '../widgets/ai_host_popup.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';

// magnitude do acelerômetro — gravidade em repouso ≈ 9.8
const _limiarJogada = 20.0;             // acima disso = jogou o celular pra cima
const _faixaRepousoMin = 7.5;           // banda de magnitude considerada "parado na mão"
const _faixaRepousoMax = 12.0;
const _duracaoParadoNecessaria = Duration(milliseconds: 180);
const _duracaoMinimaGiro = Duration(milliseconds: 600);
const _duracaoMaximaGiro = Duration(seconds: 5); // trava de segurança

const _apostasDisponiveis = [10, 25, 50, 100, 250];

enum _Estado { apostando, lancando, girando, resultado }

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen>
    with SingleTickerProviderStateMixin {
  _Estado _estado = _Estado.apostando;
  int _aposta = 50;
  String _escolha = 'cara';
  String? _resultado;
  bool _ganhou = false;

  late final AnimationController _giroController;

  StreamSubscription<AccelerometerEvent>? _subAcel;
  DateTime? _paradoDesde;
  DateTime _inicioGiro = DateTime.now();
  Timer? _timeoutGiro;

  @override
  void initState() {
    super.initState();
    _giroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..repeat();
  }

  @override
  void dispose() {
    _subAcel?.cancel();
    _timeoutGiro?.cancel();
    _giroController.dispose();
    super.dispose();
  }

  void _lancar() {
    if (!context.read<UserProvider>().canAfford(_aposta)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Moedas insuficientes!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.lose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // o Tio Sorte às vezes tenta empurrar uma aposta maior antes de lançar
    final apostaBaixa = _aposta <= _apostasDisponiveis[1];
    if (apostaBaixa && Random().nextBool()) {
      AiHostPopup.show(
        context,
        situacao: AiHostSituacao.vaiApostar,
        actionLabel: '💰 Apostar mais!',
        onAction: () {
          _aumentarAposta();
          _iniciarLancamento();
        },
        onDismiss: _iniciarLancamento,
        dismissLabel: 'Lançar assim mesmo',
      );
      return;
    }

    _iniciarLancamento();
  }

  void _aumentarAposta() {
    final atual = _apostasDisponiveis.indexOf(_aposta);
    final proxima = _apostasDisponiveis[(atual + 1).clamp(0, _apostasDisponiveis.length - 1)];
    setState(() => _aposta = proxima);
  }

  void _iniciarLancamento() {
    setState(() {
      _estado = _Estado.lancando;
      _resultado = null;
    });

    _subAcel = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_aoReceberAcelerometro);
  }

  void _cancelarLancamento() {
    _subAcel?.cancel();
    setState(() => _estado = _Estado.apostando);
  }

  void _aoReceberAcelerometro(AccelerometerEvent e) {
    final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    if (_estado == _Estado.lancando) {
      if (mag > _limiarJogada) _iniciarGiro();
      return;
    }

    if (_estado == _Estado.girando) {
      final parado = mag >= _faixaRepousoMin && mag <= _faixaRepousoMax;
      final agora = DateTime.now();

      if (!parado) {
        _paradoDesde = null;
        return;
      }

      _paradoDesde ??= agora;
      final paradoTempoSuficiente = agora.difference(_paradoDesde!) >= _duracaoParadoNecessaria;
      final giroTempoSuficiente = agora.difference(_inicioGiro) >= _duracaoMinimaGiro;
      if (paradoTempoSuficiente && giroTempoSuficiente) _pararGiro();
    }
  }

  void _iniciarGiro() {
    setState(() {
      _estado = _Estado.girando;
      _inicioGiro = DateTime.now();
      _paradoDesde = null;
    });
    HapticFeedback.mediumImpact();
    _timeoutGiro = Timer(_duracaoMaximaGiro, () {
      if (_estado == _Estado.girando) _pararGiro();
    });
  }

  Future<void> _pararGiro() async {
    _subAcel?.cancel();
    _timeoutGiro?.cancel();

    final resultado = Random().nextBool() ? 'cara' : 'coroa';
    final ganhou = _escolha == resultado;
    final provider = context.read<UserProvider>();
    final multi = provider.multiplicadorGlobal;
    final apostaMult = (_aposta * multi).round();
    final payout = ganhou ? apostaMult * 2 : 0;

    provider.recordGameResult(GameResult(
      userId: provider.user!.id,
      gameType: GameType.coinFlip,
      bet: apostaMult,
      payout: payout,
      won: ganhou,
      playedAt: DateTime.now(),
    ));
    provider.resetMultiplicador();

    setState(() {
      _estado = _Estado.resultado;
      _resultado = resultado;
      _ganhou = ganhou;
    });

    if (ganhou) {
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 130));
      }
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    }

    if (!mounted) return;
    if (!ganhou) {
      AiHostPopup.show(
        context,
        situacao: AiHostSituacao.perdeu,
        actionLabel: '💰 Aumentar aposta!',
        onAction: _aumentarAposta,
      );
    } else if (provider.user!.gamesPlayed % 5 == 0) {
      AiHostPopup.show(context, situacao: AiHostSituacao.sequencia);
    }
  }

  (String, String) _info(String lado) =>
      lado == 'cara' ? ('🌟', 'CARA') : ('👑', 'COROA');

  @override
  Widget build(BuildContext context) {
    final multi = context.watch<UserProvider>().multiplicadorGlobal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // banner de risco ativo (mamadeira)
            if (multi > 1)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.colorMamadeira.withOpacity(0.85),
                child: Text(
                  '🍼 Risco ativo: ${multi}x — ganhos e perdas multiplicados!',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('🪙 Cara ou Coroa',
                        style: GoogleFonts.nunito(
                            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                  const CoinDisplayWidget(),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: switch (_estado) {
                  _Estado.apostando => _telaApostando(),
                  _Estado.lancando  => _telaLancando(),
                  _Estado.girando   => _telaGirando(),
                  _Estado.resultado => _telaResultado(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoEscolha(String valor) {
    final (emoji, label) = _info(valor);
    final sel = _escolha == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _escolha = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? AppColors.gold : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppColors.gold : Colors.white12, width: 2),
            boxShadow: sel
                ? const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 3))]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, color: sel ? Colors.black87 : Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telaApostando() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldDark,
            border: Border.all(color: AppColors.gold, width: 5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 7))],
          ),
          child: const Center(child: Text('🪙', style: TextStyle(fontSize: 64))),
        ),

        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Como jogar',
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text(
                'Escolha cara ou coroa, toque em LANÇAR\ne jogue o celular pra cima!\nA moeda gira até você pegar de volta na mão.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Text('Sua escolha',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),
        Row(
          children: [
            _botaoEscolha('cara'),
            const SizedBox(width: 12),
            _botaoEscolha('coroa'),
          ],
        ),

        const SizedBox(height: 28),

        Text('Aposta: $_aposta 🪙',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.gold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _apostasDisponiveis.map((v) {
            final sel = _aposta == v;
            return GestureDetector(
              onTap: () => setState(() => _aposta = v),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.gold : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.gold : Colors.white12),
                  boxShadow: sel
                      ? const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 3))]
                      : [],
                ),
                child: Text('$v',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.black87 : Colors.white54)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🪙 Lançar!',
            onPressed: _lancar,
            color: AppColors.gold,
            fontSize: 20,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _telaLancando() {
    final (emoji, label) = _info(_escolha);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Pronto?',
            style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('🚀 Jogue o celular pra cima\ncomo se fosse a moeda!',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center),

        const SizedBox(height: 40),

        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldDark,
            border: Border.all(color: AppColors.gold, width: 5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 7))],
          ),
          child: const Center(child: Text('🪙', style: TextStyle(fontSize: 64))),
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold),
          ),
          child: Text('Sua escolha: $emoji $label',
              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gold)),
        ),

        const SizedBox(height: 24),

        TextButton(
          onPressed: _cancelarLancamento,
          child: Text('← Cancelar',
              style: GoogleFonts.nunito(color: Colors.white54, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _telaGirando() {
    final (emoji, label) = _info(_escolha);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🌀 Girando...',
            style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Pegue o celular de volta na mão\npra parar a moeda!',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center),

        const SizedBox(height: 40),

        AnimatedBuilder(
          animation: _giroController,
          builder: (context, child) {
            final angulo = _giroController.value * 2 * pi;
            final mostrandoFrente = cos(angulo) > 0;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0025)
                ..rotateY(angulo),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldDark,
                  border: Border.all(color: AppColors.gold, width: 5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 7))],
                ),
                child: Center(
                  child: Text(mostrandoFrente ? '🌟' : '👑', style: const TextStyle(fontSize: 64)),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        Text('Sua escolha: $emoji $label',
            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white54)),
      ],
    );
  }

  Widget _telaResultado() {
    final (emojiEscolha, labelEscolha) = _info(_escolha);
    final (emojiResultado, labelResultado) = _info(_resultado!);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _ganhou ? AppColors.win.withOpacity(0.2) : AppColors.lose.withOpacity(0.2),
            border: Border.all(color: _ganhou ? AppColors.win : AppColors.lose, width: 5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 6))],
          ),
          child: Center(child: Text(emojiResultado, style: const TextStyle(fontSize: 60))),
        ),

        const SizedBox(height: 16),

        Text('A moeda caiu: $labelResultado',
            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),

        const SizedBox(height: 6),

        Text(
          'Você escolheu (${_escolha == _resultado ? "✅" : "❌"}): $emojiEscolha $labelEscolha',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ganhou ? AppColors.win.withOpacity(0.15) : AppColors.lose.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ganhou ? AppColors.win : AppColors.lose),
          ),
          child: Column(
            children: [
              Text(
                _ganhou ? '🎉 Você ganhou!' : '😢 Perdeu...',
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _ganhou ? AppColors.win : AppColors.lose),
              ),
              if (_ganhou) ...[
                const SizedBox(height: 4),
                Text('+${_aposta * 2} 🪙',
                    style: GoogleFonts.nunito(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gold)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🔄 Jogar de Novo!',
            onPressed: () => setState(() {
              _estado = _Estado.apostando;
              _ganhou = false;
              _resultado = null;
            }),
            color: AppColors.gold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
