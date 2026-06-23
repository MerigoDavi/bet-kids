import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/game_result.dart';
import '../../data/local/local_database.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _user;
  List<GameResult> _history = [];
  List<UserProfile> _leaderboard = [];
  bool _isLoading = false;
  double _multiplicadorGlobal = 1.0;
  DateTime? _ultimaApostaEm;

  UserProfile? get user => _user;
  List<GameResult> get history => _history;
  List<UserProfile> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  int get coins => _user?.coins ?? 0;
  double get multiplicadorGlobal => _multiplicadorGlobal;
  DateTime? get ultimaApostaEm => _ultimaApostaEm;

  void setMultiplicador(double m) {
    _multiplicadorGlobal = m;
    notifyListeners();
  }

  void resetMultiplicador() {
    _multiplicadorGlobal = 1.0;
    notifyListeners();
  }

  Future<void> loadUser(String id) async {
    _isLoading = true;
    notifyListeners();

    _user = await LocalDatabase.getUser(id);

    if (_user == null) {
      final remoteUser = await FirestoreService.getUser(id);
      if (remoteUser != null) {
        _user = remoteUser;
        await LocalDatabase.saveUser(_user!);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createUser(String id, String username, String avatar) async {
    _user = UserProfile(
      id: id,
      username: username,
      avatar: avatar,
      createdAt: DateTime.now(),
    );
    await LocalDatabase.saveUser(_user!);
    await FirestoreService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> recordGameResult(GameResult result) async {
    if (_user == null) return;

    final newCoins = _user!.coins - result.bet + result.payout;
    final newBestWin = result.payout > _user!.bestWin ? result.payout : _user!.bestWin;

    _user = _user!.copyWith(
      coins: newCoins,
      gamesPlayed: _user!.gamesPlayed + 1,
      totalWon: result.won ? _user!.totalWon + result.payout : _user!.totalWon,
      bestWin: newBestWin,
    );

    await LocalDatabase.updateUser(_user!);
    await LocalDatabase.saveGameResult(result);
    await FirestoreService.saveUser(_user!);
    await FirestoreService.saveGameResult(result);

    _history = [result, ..._history];
    _ultimaApostaEm = DateTime.now();

    if (result.won) {
      await NotificationService.showWinNotification(result.payout);
    }

    notifyListeners();
  }

  Future<void> addDailyReward() async {
    if (_user == null) return;
    _user = _user!.copyWith(coins: _user!.coins + 100);
    await LocalDatabase.updateUser(_user!);
    await FirestoreService.updateCoins(_user!.id, _user!.coins);
    await NotificationService.showDailyRewardNotification();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    if (_user == null) return;
    _history = await LocalDatabase.getUserResults(_user!.id);
    notifyListeners();
  }

  Future<void> loadLeaderboard() async {
    _leaderboard = await FirestoreService.getLeaderboard();
    if (_leaderboard.isEmpty) {
      _leaderboard = await LocalDatabase.getLeaderboard();
    }
    notifyListeners();
  }

  bool canAfford(int amount) => (_user?.coins ?? 0) >= amount;
}
