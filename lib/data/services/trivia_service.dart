import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trivia_question.dart';

class TriviaService {
  static const _baseUrl = 'https://opentdb.com/api.php';

  static Future<List<TriviaQuestion>> fetchQuestions({
    int amount = 5,
    String difficulty = 'easy',
  }) async {
    final uri = Uri.parse('$_baseUrl?amount=$amount&difficulty=$difficulty&type=multiple');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['response_code'] != 0) throw Exception('Trivia API returned error code');

      final results = data['results'] as List<dynamic>;
      return results.map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _fallbackQuestions();
    }
  }

  static List<TriviaQuestion> _fallbackQuestions() => [
        TriviaQuestion(
          category: 'Animais',
          question: 'Qual é o animal mais rápido do mundo?',
          correctAnswer: 'Guepardo',
          incorrectAnswers: ['Leão', 'Falcão-Peregrino', 'Cavalo'],
        ),
        TriviaQuestion(
          category: 'Ciências',
          question: 'Qual planeta é o maior do sistema solar?',
          correctAnswer: 'Júpiter',
          incorrectAnswers: ['Saturno', 'Netuno', 'Terra'],
        ),
        TriviaQuestion(
          category: 'Cores',
          question: 'Quais cores formam o verde?',
          correctAnswer: 'Azul e Amarelo',
          incorrectAnswers: ['Vermelho e Azul', 'Amarelo e Vermelho', 'Branco e Azul'],
        ),
        TriviaQuestion(
          category: 'Matemática',
          question: 'Quanto é 7 × 8?',
          correctAnswer: '56',
          incorrectAnswers: ['48', '63', '54'],
        ),
        TriviaQuestion(
          category: 'Geografia',
          question: 'Qual é a capital do Brasil?',
          correctAnswer: 'Brasília',
          incorrectAnswers: ['São Paulo', 'Rio de Janeiro', 'Salvador'],
        ),
      ];
}
