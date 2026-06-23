import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/kid_button.dart';

const _avatarOptions = ['⭐', '🦁', '🐸', '🐧', '🦊', '🐨', '🐯', '🦄', '🐼', '🦋', '🐬', '🦅'];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  String _selectedAvatar = '⭐';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _startPlaying() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showError('Digite seu nome de jogador!');
      return;
    }
    if (username.length < 2) {
      _showError('Seu nome precisa ter pelo menos 2 letras!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = await authProvider.signIn();
      await context.read<UserProvider>().createUser(userId, username, _selectedAvatar);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      _showError('Ops! Algo deu errado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: AppColors.lose,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(_selectedAvatar, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text(
                      'Quem vai jogar? 🎮',
                      style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              Text('Escolha seu avatar:',
                  style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _avatarOptions.map((avatar) {
                  final sel = avatar == _selectedAvatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatar),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withOpacity(0.3) : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.white24,
                          width: sel ? 3 : 1,
                        ),
                      ),
                      child: Center(child: Text(avatar, style: const TextStyle(fontSize: 28))),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _usernameController,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Seu nome de jogador ✏️',
                  hintStyle: GoogleFonts.nunito(color: Colors.white38),
                  counterStyle: GoogleFonts.nunito(color: Colors.white38),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('🎯', style: TextStyle(fontSize: 24)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                ),
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SizedBox(
                      width: double.infinity,
                      child: KidButton(
                        label: '🚀 Começar a Jogar!',
                        onPressed: _startPlaying,
                        color: const Color(0xFF11998E),
                        fontSize: 20,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
