import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/ai_casino_host_service.dart';
import 'kid_button.dart';

/// Popup do "Tio Sorte" — mascote de IA local que tenta (de forma propositalmente
/// caricata) convencer o jogador a apostar mais. Sátira de dark patterns reais de
/// apps de aposta que usam IA pra maximizar engajamento.
class AiHostPopup {
  static bool _visivel = false;

  /// Mostra o popup, se nenhum outro já estiver na tela.
  /// [onAction] é chamado se o jogador tocar no botão de ação (ex: apostar mais).
  /// [onDismiss] é chamado se o jogador dispensar o popup (ex: seguir com a aposta original).
  static Future<void> show(
    BuildContext context, {
    required AiHostSituacao situacao,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    String dismissLabel = 'Agora não',
  }) async {
    if (_visivel || !context.mounted) return;
    _visivel = true;
    await showDialog(
      context: context,
      // se houver uma ação de dispensa pendente, exige um toque explícito
      // num dos botões (não deixa fechar tocando fora sem disparar o callback)
      barrierDismissible: onDismiss == null,
      builder: (_) => _AiHostDialog(
        situacao: situacao,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: onDismiss,
        dismissLabel: dismissLabel,
      ),
    );
    _visivel = false;
  }
}

class _AiHostDialog extends StatefulWidget {
  final AiHostSituacao situacao;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final String dismissLabel;

  const _AiHostDialog({
    required this.situacao,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
    required this.dismissLabel,
  });

  @override
  State<_AiHostDialog> createState() => _AiHostDialogState();
}

class _AiHostDialogState extends State<_AiHostDialog> {
  String? _fala;

  @override
  void initState() {
    super.initState();
    AiCasinoHostService.instance.falar(widget.situacao).then((fala) {
      if (mounted) setState(() => _fala = fala);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.colorAiHost, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.colorAiHost.withOpacity(0.2),
                    border: Border.all(color: AppColors.colorAiHost, width: 2),
                  ),
                  child: const Center(child: Text('🎩', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tio Sorte 🤖',
                          style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.colorAiHost)),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _fala == null
                            ? Row(
                                key: const ValueKey('carregando'),
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('pensando...',
                                      style: GoogleFonts.nunito(fontSize: 14, color: Colors.white54)),
                                ],
                              )
                            : Text(
                                _fala!,
                                key: const ValueKey('fala'),
                                style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.actionLabel != null && widget.onAction != null)
              SizedBox(
                width: double.infinity,
                child: KidButton(
                  label: widget.actionLabel!,
                  color: AppColors.colorAiHost,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onAction!();
                  },
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismiss?.call();
              },
              child: Text(widget.dismissLabel,
                  style: GoogleFonts.nunito(color: Colors.white54, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
