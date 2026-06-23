import 'package:flutter/material.dart' show Color, GlobalKey, NavigatorState;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_routes.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Permite navegar a partir do toque na notificação, mesmo sem um
  /// BuildContext disponível (ex: app reaberto pelo tap).
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const _channelId = 'bet_kids_channel';
  static const _channelName = 'BetKids Notificações';

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route);
    }
  }

  static Future<void> showWinNotification(int coins) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFD700),
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(1, '🎉 Você ganhou!', 'Você ganhou $coins moedas! Continue jogando!', details);
  }

  static Future<void> showDailyRewardNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      2,
      '⭐ Recompensa Diária!',
      'Sua recompensa de 100 moedas está esperando! Venha jogar!',
      details,
    );
  }

  static Future<void> showAchievementNotification(String achievement) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(3, '🏆 Conquista Desbloqueada!', achievement, details);
  }

  /// Notificação de reengajamento disparada após o app ficar em segundo
  /// plano por alguns segundos. O toque leva direto para [AppRoutes.roulette].
  static Future<void> showComeBackToRouletteNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFFF1744),
      ticker: 'Você está perdendo lucros!',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
    );
    await _plugin.show(
      4,
      '⚠️ Você está perdendo lucros!',
      'A roleta está esperando! Volte agora e gire antes que sua sorte mude!',
      details,
      payload: AppRoutes.roulette,
    );
  }
}

