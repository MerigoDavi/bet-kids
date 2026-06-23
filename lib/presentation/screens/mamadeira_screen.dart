import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';

// tabela de multiplicadores por inclinação
// tilt 0.0 = celular em pé | tilt 1.0 = celular deitado (copo todo bebido)
const _tiers = [
  (minTilt: 0.0,  multi: 1.0,  label: '— Sem risco extra'),
  (minTilt: 0.2,  multi: 1.5,  label: '⚡ 1.5x'),
  (minTilt: 0.4,  multi: 2.0,  label: '🔥 2x'),
  (minTilt: 0.65, multi: 3.0,  label: '💀 3x'),
  (minTilt: 0.85, multi: 5.0,  label: '☠️ 5x'),
];

double _tiltParaMultiplicador(double tilt) {
  double multi = 1.0;
  for (final t in _tiers) {
    if (tilt >= t.minTilt) multi = t.multi;
  }
  return multi;
}

String _tiltParaLabel(double tilt) {
  String label = _tiers.first.label;
  for (final t in _tiers) {
    if (tilt >= t.minTilt) label = t.label;
  }
  return label;
}

class MamadeiraScreen extends StatefulWidget {
  const MamadeiraScreen({super.key});

  @override
  State<MamadeiraScreen> createState() => _MamadeiraScreenState();
}

class _MamadeiraScreenState extends State<MamadeiraScreen> {
  double _tiltMax = 0.0;     // quanto já foi bebido (0 = nada, 1 = tudo) — só sobe, nunca volta sozinho
  bool _confirmado = false;
  double _multiplicadorFinal = 1.0;
  int _reenchimentosRestantes = 3;

  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((e) {
      // y ≈ 9.8 quando em pé, y ≈ 0 quando deitado para frente
      final t = ((9.8 - e.y) / 9.8).clamp(0.0, 1.0);
      // o copo só esvazia ao beber — voltar o celular não enche de novo
      if (!_confirmado && t > _tiltMax) setState(() => _tiltMax = t);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _confirmar() {
    final multi = _tiltParaMultiplicador(_tiltMax);
    context.read<UserProvider>().setMultiplicador(multi);
    setState(() {
      _confirmado = true;
      _multiplicadorFinal = multi;
    });
  }

  void _reencher() {
    if (_reenchimentosRestantes <= 0) return;
    setState(() {
      _tiltMax = 0.0;
      _reenchimentosRestantes--;
    });
  }

  bool _podeReencher(double nivelLiquido) =>
      _reenchimentosRestantes > 0 && nivelLiquido < 1.0;

  @override
  Widget build(BuildContext context) {
    final tilt = _tiltMax;
    final nivelLiquido = 1.0 - tilt;             // 1 = cheio, 0 = vazio
    final multi = _tiltParaMultiplicador(tilt);
    final label = _tiltParaLabel(tilt);

    final corMulti = multi >= 5
        ? AppColors.lose
        : multi >= 3
            ? const Color(0xFFFF7043)
            : multi >= 2
                ? AppColors.colorSlots
                : multi >= 1.5
                    ? AppColors.gold
                    : Colors.white54;

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
                    child: Text('🧃 Suco do Risco',
                        style: GoogleFonts.nunito(
                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                  const CoinDisplayWidget(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _confirmado ? _telaConfirmado() : _telaJogando(nivelLiquido, multi, label, corMulti),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telaJogando(double nivelLiquido, double multi, String label, Color corMulti) {
    final tilt = _tiltMax;

    return Column(
      children: [
        // instrução
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: AppColors.colorMamadeira, width: 4)),
          ),
          child: Text(
            'Vire o copo para beber o suco Tang hiper saturado e aumentar o risco do próximo jogo.\nQuanto mais beber, maior o multiplicador, e o perigo também (mas dá pra ignorar)! Pode beber até 3x de forma direta.',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
        ),

        const SizedBox(height: 28),

        // copo de suco tang visual
        Center(child: _CopoSuco(nivelLiquido: nivelLiquido)),

        const SizedBox(height: 20),

        // legenda de multiplicadores abaixo do copo
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: _tiers.reversed.map((t) {
            final ativa = _tiltParaMultiplicador(tilt) == t.multi;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ativa ? corMulti : Colors.white24,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: ativa ? FontWeight.w800 : FontWeight.w400,
                    color: ativa ? corMulti : Colors.white38,
                  ),
                ),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // reencher o copo
        TextButton.icon(
          onPressed: _podeReencher(nivelLiquido) ? _reencher : null,
          icon: Icon(Icons.refresh_rounded,
              color: _podeReencher(nivelLiquido) ? AppColors.colorMamadeira : Colors.white24),
          label: Text(
            _reenchimentosRestantes > 0
                ? 'Reencher copo ($_reenchimentosRestantes restantes)'
                : 'Sem reenchimentos',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _podeReencher(nivelLiquido) ? AppColors.colorMamadeira : Colors.white24,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // multiplicador atual em destaque
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: corMulti.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: corMulti),
          ),
          child: Column(
            children: [
              Text(
                multi == 1.0 ? 'Sem risco extra' : 'Multiplicador: ${multi}x',
                style: GoogleFonts.nunito(
                    fontSize: 22, fontWeight: FontWeight.w900, color: corMulti),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(fontSize: 15, color: corMulti.withOpacity(0.8)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // aviso de risco
        if (multi > 1)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lose.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lose.withOpacity(0.4)),
            ),
            child: Text(
              '⚠️ O próximo jogo terá ganhos E perdas multiplicados por ${multi}x',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.lose),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: multi == 1.0 ? '✅ Jogar sem risco extra' : '🧃 Confirmar ${multi}x!',
            onPressed: _confirmar,
            color: multi == 1.0 ? AppColors.neutral : corMulti,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _telaConfirmado() {
    final multi = _multiplicadorFinal;
    final corMulti = multi >= 5
        ? AppColors.lose
        : multi >= 3
            ? const Color(0xFFFF7043)
            : multi >= 2
                ? AppColors.colorSlots
                : multi >= 1.5
                    ? AppColors.gold
                    : Colors.white54;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        Text('🧃', style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 24),

        Text(
          multi == 1.0 ? 'Sem risco extra!' : '${multi}x ativado!',
          style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: corMulti),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          multi == 1.0
              ? 'Nenhum multiplicador ativo.\nJogue normalmente!'
              : 'O próximo jogo terá\nganhos e perdas em ${multi}x.',
          style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70, height: 1.6),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          child: KidButton(
            label: '🎮 Ir jogar!',
            onPressed: () => Navigator.pop(context),
            color: AppColors.colorMamadeira,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() => _confirmado = false),
          child: Text('← Beber mais',
              style: GoogleFonts.nunito(color: Colors.white54, fontSize: 14)),
        ),
      ],
    );
  }
}

// widget do copo de suco tang animado pelo líquido
class _CopoSuco extends StatelessWidget {
  final double nivelLiquido; // 1.0 = cheio, 0.0 = vazio

  const _CopoSuco({required this.nivelLiquido});

  static const double _largoTopo = 170;
  static const double _largoBase = 125;
  static const double _altura = 340;

  @override
  Widget build(BuildContext context) {
    // cor do suco tang muda conforme o nível cai (mais escuro/avermelhado = mais perigo)
    final corLiquido = nivelLiquido > 0.6
        ? const Color(0xFFFFC04D) // laranja claro — copo cheio
        : nivelLiquido > 0.3
            ? const Color(0xFFFF8F00) // laranja forte — meio copo
            : const Color(0xFFE64A19); // laranja-avermelhado — quase vazio

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // aro/borda do copo
        Container(
          width: _largoTopo + 8,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.colorMamadeira.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        // corpo do copo (trapézio) com o suco
        ClipPath(
          clipper: _CopoClipper(largoTopo: _largoTopo, largoBase: _largoBase),
          child: Container(
            width: _largoTopo,
            height: _altura,
            color: AppColors.surface.withOpacity(0.5),
            child: Stack(
              children: [
                // suco animado
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: _altura * nivelLiquido,
                    color: corLiquido.withOpacity(0.85),
                  ),
                ),

                // marcações de nível (linhas horizontais)
                ...[0.25, 0.5, 0.75].map((frac) {
                  return Positioned(
                    bottom: _altura * frac - 1,
                    left: 12,
                    right: 12,
                    child: Container(height: 1.5, color: Colors.white24),
                  );
                }),

                // percentual no centro
                Center(
                  child: Text(
                    '${(nivelLiquido * 100).round()}%',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // base do copo
        Container(
          width: _largoBase,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.colorMamadeira.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
        ),
      ],
    );
  }
}

// recorta o copo em formato de trapézio (mais largo no topo, mais estreito na base)
class _CopoClipper extends CustomClipper<Path> {
  final double largoTopo;
  final double largoBase;

  _CopoClipper({required this.largoTopo, required this.largoBase});

  @override
  Path getClip(Size size) {
    final margem = (largoTopo - largoBase) / 2;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(largoTopo, 0)
      ..lineTo(largoTopo - margem, size.height)
      ..lineTo(margem, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
