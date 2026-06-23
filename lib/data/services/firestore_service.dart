import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/game_result.dart';

class FirestoreService {
  static FirebaseFirestore? _db;

  static void initialize() {
    try {
      _db = FirebaseFirestore.instance;
    } catch (_) {
      _db = null;
    }
  }

  static bool get _available => _db != null;

  static Future<void> saveUser(UserProfile user) async {
    if (!_available) return;
    try {
      await _db!.collection('users').doc(user.id).set(user.toMap());
    } catch (_) {}
  }

  static Future<UserProfile?> getUser(String id) async {
    if (!_available) return null;
    try {
      final doc = await _db!.collection('users').doc(id).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateCoins(String userId, int coins) async {
    if (!_available) return;
    try {
      await _db!.collection('users').doc(userId).update({'coins': coins});
    } catch (_) {}
  }

  static Future<void> saveGameResult(GameResult result) async {
    if (!_available) return;
    try {
      await _db!.collection('game_results').add(result.toMap());
    } catch (_) {}
  }

  static Future<List<UserProfile>> getLeaderboard() async {
    if (!_available) return [];
    try {
      final snap = await _db!
          .collection('users')
          .orderBy('coins', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) => UserProfile.fromMap(d.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
