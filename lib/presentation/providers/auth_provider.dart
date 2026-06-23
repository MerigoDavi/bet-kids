import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  bool _isInitialized = false;

  String? get userId => _userId;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _userId != null;

  Future<void> initialize() async {
    AuthService.initialize();
    _userId = await AuthService.getCurrentUserId();
    _isInitialized = true;
    notifyListeners();
  }

  Future<String> signIn() async {
    _userId = await AuthService.signInAnonymously();
    notifyListeners();
    return _userId!;
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
