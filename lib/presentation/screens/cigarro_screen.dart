import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/coin_display_widget.dart';

// som da tragada
const _limiarDb = -24.0;

class CigarroScreen extends StatefulWidget {
  const CigarroScreen({super.key});

  @override
  State<CigarroScreen> createState() => _CigarroScreenState();
}

class _CigarroScreenState extends State<CigarroScreen> {
  final _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  String? _caminhoGravacao;

  bool _ouvindo = false;
  bool _aceso = false;
  bool _emTragada = false;
  String? _erro;

  final List<_BolhaSpec> _bolhas = [];
  final _rand = Random();
  int _proximoId = 0;

  @override
  void initState() {
    super.initState();
    _iniciarMicrofone();
  }

  Future<void> _iniciarMicrofone() async {
    setState(() => _erro = null);
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _erro = '🎙️ Precisamos do microfone para detectar a tragada.');
        return;
      }
      final dir = await getTemporaryDirectory();
      _caminhoGravacao = '${dir.path}/cigarro_mic_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: _caminhoGravacao!);
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        if (!_emTragada && amp.current > _limiarDb) _tragar();
      });
      setState(() => _ouvindo = true);
    } catch (_) {
      setState(() => _erro = 'Não foi possível acessar o microfone.');
    }
  }

  Future<void> _tragar() async {
    setState(() {
      _emTragada = true;
      _aceso = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    _soprarBolhas();

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _aceso = false;
      _emTragada = false;
    });
  }

  void _soprarBolhas() {
    setState(() {
      for (var i = 0; i < 10; i++) {
        final id = _proximoId++;
        _bolhas.add(_BolhaSpec(
          id: id,
          offsetX: _rand.nextDouble() * 70 - 35,
          balanco: _rand.nextDouble() * 26 - 13,
          tamanho: 16 + _rand.nextDouble() * 22,
          duracao: Duration(milliseconds: 1600 + _rand.nextInt(1000)),
        ));
      }
    });
  }

  void _removerBolha(int id) {
    if (!mounted) return;
    setState(() => _bolhas.removeWhere((b) => b.id == id));
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _recorder.stop();
    _recorder.dispose();
    final caminho = _caminhoGravacao;
    if (caminho != null) {
      File(caminho).delete().ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text('🚬 CIGARRO DE BOLHAS',
                        style: GoogleFonts.ultra(
                            fontSize: 18, color: Colors.white, letterSpacing: 0.5),
                        textAlign: TextAlign.center),
                  ),
                  const CoinDisplayWidget(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    // instrução
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: AppColors.colorCigarro, width: 4)),
                      ),
                      child: Text(
                        _erro ??
                            (_ouvindo
                                ? 'Aspire bem perto do microfone, como se fosse tragar...\nQuer dizer, tragando mesmo e sinta o relaxamento!'
                                : 'Ligando o microfone...'),
                        style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70, height: 1.5),
                      ),
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _iniciarMicrofone,
                        icon: Icon(Icons.refresh_rounded, color: AppColors.colorCigarro),
                        label: Text('Tentar de novo',
                            style: GoogleFonts.nunito(
                                color: AppColors.colorCigarro, fontWeight: FontWeight.w700)),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // cigarreta e bolhas
                    SizedBox(
                      width: 280,
                      height: _Cigarro.altura,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(bottom: 0, child: _Cigarro(aceso: _aceso)),
                          ..._bolhas.map((b) => Positioned(
                                bottom: _Cigarro.alturaFiltro / 2,
                                left: 140 + b.offsetX - b.tamanho / 2,
                                child: _Bolha(
                                  balanco: b.balanco,
                                  tamanho: b.tamanho,
                                  duracao: b.duracao,
                                  onFim: () => _removerBolha(b.id),
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _emTragada
                          ? (_aceso && _bolhas.isEmpty ? '🔥 Tragando...' : '🫧 Soprando bolhas!')
                          : 'Aguardando dar aquela tragada...',
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cigarro extends StatelessWidget {
  final bool aceso;

  const _Cigarro({required this.aceso});

  static const double _largura = 56;
  static const double _alturaBrasa = 34;
  static const double _alturaCinza = 10;
  static const double _alturaCorpo = 300;
  static const double alturaFiltro = 70;
  static const double altura = _alturaBrasa + _alturaCinza + _alturaCorpo + alturaFiltro;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // brasa
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _alturaBrasa,
          height: _alturaBrasa,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aceso ? const Color(0xFFFF5722) : const Color(0xFF9E9E9E),
            boxShadow: aceso
                ? [
                    BoxShadow(
                        color: const Color(0xFFFF7043).withOpacity(0.85),
                        blurRadius: 28,
                        spreadRadius: 8),
                    BoxShadow(
                        color: const Color(0xFFFFCA28).withOpacity(0.55),
                        blurRadius: 14,
                        spreadRadius: 2),
                  ]
                : const [],
          ),
        ),

        // pontinha
        Container(
          width: _largura - 8,
          height: _alturaCinza,
          decoration: BoxDecoration(
            color: const Color(0xFF616161),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // cigarrin
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: _largura,
            height: _alturaCorpo,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDEDED), Colors.white, Color(0xFFD9D9D9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.5, 1.0],
              ),
              border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
            ),
            child: Align(
              alignment: const Alignment(0, 0.7),
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  'MARLBORO KIDS',
                  style: GoogleFonts.ultra(
                    fontSize: 13,
                    color: AppColors.colorCigarro,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        // filtro
        Container(
          width: _largura,
          height: alturaFiltro,
          decoration: BoxDecoration(
            color: const Color(0xFFD7A86E),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            border: Border.all(color: const Color(0xFFB8895A), width: 1),
          ),
        ),
      ],
    );
  }
}

class _BolhaSpec {
  final int id;
  final double offsetX;
  final double balanco;
  final double tamanho;
  final Duration duracao;

  _BolhaSpec({
    required this.id,
    required this.offsetX,
    required this.balanco,
    required this.tamanho,
    required this.duracao,
  });
}

// boias
class _Bolha extends StatelessWidget {
  final double balanco;
  final double tamanho;
  final Duration duracao;
  final VoidCallback onFim;

  const _Bolha({
    required this.balanco,
    required this.tamanho,
    required this.duracao,
    required this.onFim,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duracao,
      curve: Curves.easeOut,
      onEnd: onFim,
      builder: (context, t, child) {
        final subida = 260 * t;
        final deriva = sin(t * pi * 3) * balanco;
        final opacidade = t < 0.7 ? 1.0 : (1 - t) / 0.3;
        return Transform.translate(
          offset: Offset(deriva, -subida),
          child: Opacity(
            opacity: opacidade.clamp(0.0, 1.0),
            child: Container(
              width: tamanho,
              height: tamanho,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.lightBlueAccent.withOpacity(0.25),
                    Colors.white.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
              ),
            ),
          ),
        );
      },
    );
  }
}
