import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/game_result.dart';
import '../../data/models/trivia_question.dart';
import '../../data/services/trivia_service.dart';
import '../../data/services/share_service.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/kid_button.dart';

const _betPerQuestion = 50;
const _payoutCorrect = 150;
const _questionTimeSeconds = 15;

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late ConfettiController _confettiController;

  List<TriviaQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _totalEarned = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  Timer? _timer;
  int _timeLeft = _questionTimeSeconds;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await TriviaService.fetchQuestions(amount: 5);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _questionTimeSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    if (_hasAnswered) return;
    _selectAnswer('__timeout__');
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered || !mounted) return;
    _timer?.cancel();

    final current = _questions[_currentIndex];
    final isCorrect = answer == current.correctAnswer;

    if (isCorrect) {
      _score++;
      _totalEarned += _payoutCorrect;
      _confettiController.play();
    }

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = answer;
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex >= _questions.length - 1) {
      await _finishGame();
      return;
    }

    setState(() {
      _currentIndex++;
      _hasAnswered = false;
      _selectedAnswer = null;
    });
    _startTimer();
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    final totalBet = _questions.length * _betPerQuestion;

    await context.read<UserProvider>().recordGameResult(
          GameResult(
            userId: context.read<UserProvider>().user!.id,
            gameType: GameType.trivia,
            bet: totalBet,
            payout: _totalEarned,
            won: _totalEarned > totalBet,
            playedAt: DateTime.now(),
          ),
        );

    setState(() => _gameOver = true);
  }

  Future<void> _shareResult() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    await ShareService.shareWin(
      username: user.username,
      gameName: 'Trivia Quiz 🧠',
      coins: _totalEarned,
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
                  child: _isLoading
                      ? _buildLoading()
                      : _gameOver
                          ? _buildGameOver()
                          : _buildQuestion(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [AppColors.gold, AppColors.win, AppColors.primary, Color(0xFF4ECDC4)],
                numberOfParticles: 20,
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
              '🧠 Trivia Quiz',
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const CoinDisplayWidget(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Carregando perguntas...',
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgress(),
          const SizedBox(height: 16),
          _buildTimer(),
          const SizedBox(height: 20),
          _buildQuestionCard(question),
          const SizedBox(height: 20),
          ..._buildAnswerButtons(question),
          const SizedBox(height: 16),
          if (_hasAnswered) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        Text(
          'Pergunta ${_currentIndex + 1}/${_questions.length}',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70),
        ),
        const Spacer(),
        Text(
          '⭐ $_score corretas',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gold),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final progress = _timeLeft / _questionTimeSeconds;
    final color = _timeLeft > 8 ? AppColors.win : _timeLeft > 4 ? Colors.orange : AppColors.lose;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⏱ ', style: const TextStyle(fontSize: 20)),
            Text(
              '$_timeLeft s',
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(TriviaQuestion question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.category,
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  List<Widget> _buildAnswerButtons(TriviaQuestion question) {
    return question.allAnswers.asMap().entries.map((entry) {
      final answer = entry.value;
      final isCorrect = answer == question.correctAnswer;
      final isSelected = _selectedAnswer == answer;

      Color buttonColor;
      if (!_hasAnswered) {
        buttonColor = AppColors.surface;
      } else if (isCorrect) {
        buttonColor = AppColors.win.withOpacity(0.3);
      } else if (isSelected && !isCorrect) {
        buttonColor = AppColors.lose.withOpacity(0.3);
      } else {
        buttonColor = AppColors.surface.withOpacity(0.5);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _hasAnswered ? null : () => _selectAnswer(answer),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasAnswered && isCorrect
                    ? AppColors.win
                    : _hasAnswered && isSelected && !isCorrect
                        ? AppColors.lose
                        : Colors.white12,
                width: _hasAnswered && (isCorrect || isSelected) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (_hasAnswered)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(isCorrect ? '✅' : (isSelected ? '❌' : ''), style: const TextStyle(fontSize: 18)),
                  ),
                Expanded(
                  child: Text(
                    answer,
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: entry.key * 80)).fadeIn().slideX(begin: 0.1);
    }).toList();
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex >= _questions.length - 1;
    return SizedBox(
      width: double.infinity,
      child: KidButton(
        label: isLast ? '🏆 Ver Resultado!' : '➡️ Próxima!',
        onPressed: isLast ? _finishGame : _nextQuestion,
        color: const Color(0xFF11998E),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildGameOver() {
    final totalBet = _questions.length * _betPerQuestion;
    final profit = _totalEarned - totalBet;
    final won = profit > 0;
    final percentage = (_score / _questions.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _getPerformanceEmoji(percentage),
            style: const TextStyle(fontSize: 80),
          ).animate().scale(begin: const Offset(0.0, 0.0), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            _getPerformanceTitle(percentage),
            style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildResultGrid(percentage, profit),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: KidButton(
              label: '🔄 Jogar Novamente!',
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _score = 0;
                  _totalEarned = 0;
                  _hasAnswered = false;
                  _selectedAnswer = null;
                  _gameOver = false;
                });
                _loadQuestions();
              },
              color: const Color(0xFF11998E),
            ),
          ),
          const SizedBox(height: 12),
          if (won)
            SizedBox(
              width: double.infinity,
              child: KidButton(
                label: '📤 Compartilhar Resultado!',
                onPressed: _shareResult,
                color: const Color(0xFF8E44AD),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultGrid(int percentage, int profit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildResultRow('✅ Acertos', '$_score/${_questions.length} ($percentage%)'),
          const Divider(color: Colors.white12),
          _buildResultRow('🪙 Ganhou', '+$_totalEarned moedas'),
          const Divider(color: Colors.white12),
          _buildResultRow(
            profit >= 0 ? '📈 Lucro' : '📉 Prejuízo',
            '${profit >= 0 ? '+' : ''}$profit moedas',
            valueColor: profit >= 0 ? AppColors.win : AppColors.lose,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70)),
          Text(
            value,
            style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor ?? Colors.white),
          ),
        ],
      ),
    );
  }

  String _getPerformanceEmoji(int percentage) {
    if (percentage >= 80) return '🏆';
    if (percentage >= 60) return '⭐';
    if (percentage >= 40) return '📚';
    return '💪';
  }

  String _getPerformanceTitle(int percentage) {
    if (percentage >= 80) return 'Gênio! Você acertou tudo!';
    if (percentage >= 60) return 'Muito bem! Continue assim!';
    if (percentage >= 40) return 'Bom esforço! Pratique mais!';
    return 'Não desista! Você consegue!';
  }
}
