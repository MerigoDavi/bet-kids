import 'dart:async';
import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'presentation/screens/cigarro_screen.dart';
import 'presentation/screens/coin_flip_screen.dart';
import 'presentation/screens/mamadeira_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/roulette_screen.dart';
import 'presentation/screens/splash_screen.dart';

/// Tempo antes do inferno das notificações começar
const _comeBackDelay = Duration(seconds: 5);

/// Intervalo do gambling addiction
const _comeBackRepeatInterval = Duration(seconds: 2);

class BetKidsApp extends StatefulWidget {
  const BetKidsApp({super.key});

  @override
  State<BetKidsApp> createState() => _BetKidsAppState();
}

class _BetKidsAppState extends State<BetKidsApp> with WidgetsBindingObserver {
  Timer? _comeBackDelayTimer;
  Timer? _comeBackRepeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _comeBackDelayTimer?.cancel();
    _comeBackRepeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _cancelComeBackTimers() {
    _comeBackDelayTimer?.cancel();
    _comeBackRepeatTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cancelComeBackTimers();
        _comeBackDelayTimer = Timer(_comeBackDelay, () {
          NotificationService.showComeBackToRouletteNotification();
          _comeBackRepeatTimer = Timer.periodic(_comeBackRepeatInterval, (_) {
            NotificationService.showComeBackToRouletteNotification();
          });
        });
        break;
      case AppLifecycleState.resumed:
        _cancelComeBackTimers();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'BetKids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.roulette: (_) => const RouletteScreen(),
        AppRoutes.coinFlip: (_) => const CoinFlipScreen(),
        AppRoutes.mamadeira: (_) => const MamadeiraScreen(),
        AppRoutes.cigarro: (_) => const CigarroScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.leaderboard: (_) => const LeaderboardScreen(),
      },
    );
  }
}
