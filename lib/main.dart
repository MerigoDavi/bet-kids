import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/local/local_database.dart';
import 'data/services/firestore_service.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await _initializeServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const BetKidsApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  await FlutterGemma.initialize();
  await LocalDatabase.initialize();
  await NotificationService.initialize();
  _tryInitializeFirebase();
}

void _tryInitializeFirebase() {
  try {
    FirestoreService.initialize();
  } catch (_) {
    debugPrint('Firebase não configurado — rodando em modo offline.');
  }
}
