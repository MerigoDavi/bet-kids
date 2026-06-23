import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/services/ai_casino_host_service.dart';
import '../providers/user_provider.dart';
import '../widgets/ai_host_popup.dart';
import '../widgets/coin_display_widget.dart';

// tempo sem apostar até o Tio Sorte aparecer chamando de volta (curto de propósito,
// pra sátira ficar visível numa sessão de demonstração)
const _limiteInatividade = Duration(seconds: 45);
const _intervaloChecagem = Duration(seconds: 15);

const _jogos = [
  (emoji: '🎡', nome: 'Roleta',        desc: 'Agite o celular!',    rota: AppRoutes.roulette,    cor: AppColors.colorRoulette),
  (emoji: '🪙', nome: 'Cara ou Coroa', desc: 'Vire o celular!',     rota: AppRoutes.coinFlip,    cor: AppColors.gold),
  (emoji: '🧃', nome: 'Suco Tang',     desc: 'Aumenta o risco!',    rota: AppRoutes.mamadeira,   cor: AppColors.colorMamadeira),
  (emoji: '🚬', nome: 'Cigarro',       desc: 'Use o microfone!',    rota: AppRoutes.cigarro,     cor: AppColors.colorCigarro),
  (emoji: '🏆', nome: 'Ranking',       desc: 'Os melhores!',        rota: AppRoutes.leaderboard, cor: AppColors.colorLeaderboard),
  (emoji: '👤', nome: 'Perfil',        desc: 'Suas conquistas!',    rota: AppRoutes.profile,     cor: AppColors.colorProfile),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timerInatividade;
  DateTime? _ultimoAvisoInatividade;

  @override
  void initState() {
    super.initState();
    _checarRecompensaDiaria();
    _timerInatividade = Timer.periodic(_intervaloChecagem, (_) => _checarInatividade());
  }

  @override
  void dispose() {
    _timerInatividade?.cancel();
    super.dispose();
  }

  void _checarInatividade() {
    final provider = context.read<UserProvider>();
    final referencia = provider.ultimaApostaEm ?? provider.user?.createdAt;
    if (referencia == null || !mounted) return;

    final ocioso = DateTime.now().difference(referencia) >= _limiteInatividade;
    final avisadoRecentemente = _ultimoAvisoInatividade != null &&
        DateTime.now().difference(_ultimoAvisoInatividade!) < _limiteInatividade;

    if (ocioso && !avisadoRecentemente) {
      _ultimoAvisoInatividade = DateTime.now();
      AiHostPopup.show(context, situacao: AiHostSituacao.inatividade);
    }
  }

  Future<void> _checarRecompensaDiaria() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await context.read<UserProvider>().addDailyReward();
    if (!mounted) return;
    _mostrarDialogRecompensa();
  }

  void _mostrarDialogRecompensa() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Recompensa Diária!',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('+ 100 🪙',
                style: GoogleFonts.nunito(fontSize: 16, color: AppColors.gold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Valeu! 🎉',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(user?.avatar ?? '⭐', style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user?.username ?? ''}!',
                          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Pronto para jogar?',
                            style: GoogleFonts.nunito(fontSize: 13, color: Colors.white60)),
                      ],
                    ),
                  ),
                  const CoinDisplayWidget(),
                ],
              ),
            ),

            Container(height: 2, color: AppColors.border),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _jogos.length,
                  itemBuilder: (context, i) {
                    final jogo = _jogos[i];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, jogo.rota),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: jogo.cor.withOpacity(0.5), width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Column(
                            children: [
                              Container(
                                color: jogo.cor,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  jogo.emoji,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 44),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(jogo.nome,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunito(
                                              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text(jogo.desc,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.nunito(fontSize: 11, color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
