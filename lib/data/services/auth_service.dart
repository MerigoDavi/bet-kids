import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const _userIdKey = 'local_user_id';
  static FirebaseAuth? _firebaseAuth;

  static bool get _firebaseAvailable => _firebaseAuth != null;

  static void initialize() {
    try {
      _firebaseAuth = FirebaseAuth.instance;
    } catch (_) {
      _firebaseAuth = null;
    }
  }

  static Future<String> signInAnonymously() async {
    if (_firebaseAvailable) {
      try {
        final result = await _firebaseAuth!.signInAnonymously();
        return result.user!.uid;
      } catch (_) {}
    }
    return _getOrCreateLocalId();
  }

  static Future<String> _getOrCreateLocalId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userIdKey);
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await prefs.setString(_userIdKey, newId);
    return newId;
  }

  static Future<String?> getCurrentUserId() async {
    if (_firebaseAvailable && _firebaseAuth!.currentUser != null) {
      return _firebaseAuth!.currentUser!.uid;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> signOut() async {
    if (_firebaseAvailable) {
      try {
        await _firebaseAuth!.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
