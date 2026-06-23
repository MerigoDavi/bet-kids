import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;
    if (authProvider.isLoggedIn) {
      await context.read<UserProvider>().loadUser(authProvider.userId!);
      if (!mounted) return;
      if (context.read<UserProvider>().user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎰', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              'BetKids',
              style: GoogleFonts.nunito(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jogos Divertidos para Crianças!',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
