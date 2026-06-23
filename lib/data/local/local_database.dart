import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/game_result.dart';

class LocalDatabase {
  static Database? _db;

  static Future<void> initialize() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'bet_kids.db'),
      onCreate: _onCreate,
      version: 1,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar TEXT NOT NULL,
        coins INTEGER NOT NULL DEFAULT 1000,
        gamesPlayed INTEGER NOT NULL DEFAULT 0,
        totalWon INTEGER NOT NULL DEFAULT 0,
        bestWin INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE game_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        gameType TEXT NOT NULL,
        bet INTEGER NOT NULL,
        payout INTEGER NOT NULL,
        won INTEGER NOT NULL,
        playedAt INTEGER NOT NULL
      )
    ''');
  }

  static Database get _database {
    if (_db == null) throw StateError('Database not initialized');
    return _db!;
  }

  static Future<void> saveUser(UserProfile user) async {
    await _database.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<UserProfile?> getUser(String id) async {
    final maps = await _database.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  static Future<void> updateUser(UserProfile user) async {
    await _database.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<List<UserProfile>> getLeaderboard() async {
    final maps = await _database.query(
      'users',
      orderBy: 'coins DESC',
      limit: 20,
    );
    return maps.map(UserProfile.fromMap).toList();
  }

  static Future<void> saveGameResult(GameResult result) async {
    await _database.insert('game_results', result.toMap());
  }

  static Future<List<GameResult>> getUserResults(String userId, {int limit = 20}) async {
    final maps = await _database.query(
      'game_results',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'playedAt DESC',
      limit: limit,
    );
    return maps.map(GameResult.fromMap).toList();
  }
}
