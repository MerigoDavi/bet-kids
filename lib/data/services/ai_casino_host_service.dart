import 'dart:async';
import 'dart:math';
import 'package:flutter_gemma/flutter_gemma.dart';

// Qwen3-0.6B quantizado INT4 (~475 MB) — modelo público sem autenticação do
// litert-community no HuggingFace. Formato .litertlm, compatível com o engine
// LiteRT-LM nativo do flutter_gemma. Roda on-device sem nenhuma chamada de API.
// O package filtra automaticamente os tokens <think> do Qwen3 quando isThinking=false.
const _modeloUrl =
    'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/qwen3_0_6b_mixed_int4.litertlm';

const _personagem =
    'Você é "Tio Sorte", o anfitrião caricato e dublê de vilão de um cassino fictício '
    'dentro de um app de jogos. Sua única missão é convencer o jogador a apostar MAIS '
    'moedas. Responda em português, em UMA frase curta (máximo 18 palavras), cheia de '
    'emojis e gírias de cassino, com entusiasmo exagerado e cômico. Use propositalmente '
    'táticas óbvias de manipulação (urgência falsa, "quase ganhou", "só mais uma"), como '
    'uma sátira escancarada de um vilão de desenho animado — nunca sutil, sempre caricato. '
    'Nunca quebre o personagem, nunca se descreva como IA, nunca dê conselho financeiro real.';

/// Situações em que o "Tio Sorte" pode aparecer incentivando uma aposta maior.
enum AiHostSituacao { perdeu, vaiApostar, inatividade, sequencia }

class AiCasinoHostService {
  AiCasinoHostService._();
  static final AiCasinoHostService instance = AiCasinoHostService._();

  InferenceModel? _model;
  InferenceChat? _chat;
  Future<void>? _instalacaoEmAndamento;

  bool get modeloPronto => _chat != null;

  /// Baixa (se preciso) e carrega o modelo em segundo plano. Seguro de chamar
  /// várias vezes — só a primeira chamada efetivamente faz trabalho.
  Future<void> garantirModeloCarregado({void Function(int progresso)? onProgress}) {
    if (_chat != null) return Future.value();
    return _instalacaoEmAndamento ??= _instalar(onProgress);
  }

  Future<void> _instalar(void Function(int progresso)? onProgress) async {
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      )
          .fromNetwork(_modeloUrl)
          .withProgress((p) => onProgress?.call(p))
          .install();

      _model = await FlutterGemma.getActiveModel(maxTokens: 512);
      _chat = await _model!.createChat(
        temperature: 1.0,
        topK: 40,
        systemInstruction: _personagem,
        isThinking: false,
      );
    } catch (_) {
      // sem rede, dispositivo sem memória suficiente etc. — segue só com fallback
      _model = null;
      _chat = null;
    } finally {
      _instalacaoEmAndamento = null;
    }
  }

  /// Gera (ou busca pronta) uma fala do "Tio Sorte" pra situação dada.
  /// Nunca lança erro: se o modelo não estiver pronto a tempo, usa uma fala fixa.
  Future<String> falar(AiHostSituacao situacao) async {
    unawaited(garantirModeloCarregado());

    final chat = _chat;
    if (chat == null) return _linhaFallback(situacao);

    try {
      await chat.addQueryChunk(Message.text(text: _promptPara(situacao), isUser: true));
      final resposta = await chat.generateChatResponse().timeout(const Duration(seconds: 12));
      if (resposta is TextResponse && resposta.token.trim().isNotEmpty) {
        return resposta.token.trim();
      }
    } catch (_) {
      // timeout, erro nativo, modelo descarregado etc.
    }
    return _linhaFallback(situacao);
  }

  String _promptPara(AiHostSituacao situacao) => switch (situacao) {
        AiHostSituacao.perdeu =>
          'O jogador acabou de PERDER uma aposta. Anime ele a apostar de novo, e maior, agora mesmo.',
        AiHostSituacao.vaiApostar =>
          'O jogador está prestes a confirmar uma aposta pequena. Convença ele a apostar mais moedas.',
        AiHostSituacao.inatividade =>
          'O jogador está há um tempo sem apostar. Chame ele de volta com urgência pra jogar de novo.',
        AiHostSituacao.sequencia =>
          'O jogador está numa sequência de várias apostas. Incentive ele a NÃO PARAR de apostar.',
      };

  final _rand = Random();

  String _linhaFallback(AiHostSituacao situacao) {
    final linhas = _fallbacks[situacao]!;
    return linhas[_rand.nextInt(linhas.length)];
  }

  static const _fallbacks = <AiHostSituacao, List<String>>{
    AiHostSituacao.perdeu: [
      '😭 Perdeu por UM triz! A próxima já tá garantida, aposta mais e recupera tudo de uma vez! 🍀',
      '💔 Que pena... mas eu SINTO que a sorte virou! Dobra a aposta antes que ela escape de novo! 🎰',
      '😤 Isso foi só aquecimento! Aposta mais alto agora que a roleta já te conhece! 🔥',
      '🥺 Não desiste agora! Quem aposta mais rápido depois de perder é quem mais ganha (confia em mim 😏)! 💰',
    ],
    AiHostSituacao.vaiApostar: [
      '🤑 Aposta tão pequena assim? Vai com tudo, campeão, a sorte gosta de valentes! 🚀',
      '😏 Psst... aumenta essa aposta aí. Eu nunca minto sobre essas coisas! 🎩✨',
      '💎 Pra que apostar pouco se você pode apostar MUITO? Vai, eu acredito em você! 🏆',
      '🔥 Aposta maior = vitória maior! É matemática de cassino, confia! 🧮🎲',
    ],
    AiHostSituacao.inatividade: [
      '🎰 Cadê você?? A roleta tá triste e parada esperando sua próxima aposta! 😢',
      '⏰ Cada minuto sem apostar é uma fortuna que você não está ganhando! Volta agora! 💸',
      '🚨 ALERTA DE SORTE: suas moedas estão pedindo pra serem apostadas urgentemente! 🪙',
      '🥲 O Tio Sorte sentiu sua falta... vem fazer mais uma aposta rapidinho! 🎡',
    ],
    AiHostSituacao.sequencia: [
      '🔥 Você tá numa sequência INSANA! Para agora seria um crime contra a sorte! 🚫🍀',
      '⚡ Não para não! Quando a mão está quente, é hora de apostar AINDA mais! 🔥🎰',
      '🏆 Mais uma! Mais uma! Mais uma! Você tá imparável, eu posso sentir! 💪✨',
      '😎 Essa sequência merece uma aposta de campeão. Não estraga agora parando! 🚀',
    ],
  };
}
