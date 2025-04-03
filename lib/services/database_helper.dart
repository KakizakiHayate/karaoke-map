import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/karaoke_chain.dart';
import '../models/user_chain_setting.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final Logger _logger = Logger();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      _database = await _initDB('karaoke.db');
      return _database!;
    } catch (e) {
      _logger.e('Database initialization error: $e');
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // ユーザーテーブル
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 検索履歴テーブル
    await db.execute('''
      CREATE TABLE search_histories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        search_query TEXT NOT NULL,
        search_type TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // カラオケチェーン店テーブル
    await db.execute('''
      CREATE TABLE karaoke_chains (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_default_selected BOOLEAN NOT NULL DEFAULT true,
        default_order INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ユーザーのカラオケチェーン設定テーブル
    await db.execute('''
      CREATE TABLE user_chain_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        chain_id INTEGER NOT NULL,
        is_selected BOOLEAN NOT NULL,
        display_order INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (chain_id) REFERENCES karaoke_chains(id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        UNIQUE(user_id, chain_id)
      )
    ''');

    // 初期データの挿入
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // 初期ユーザーの作成
    await db.insert('users', {
      'created_at': DateTime.now().toIso8601String(),
    });

    final initialChains = [
      {'name': 'カラオケまねきねこ', 'default_order': 0},
      {'name': 'ビッグエコー', 'default_order': 1},
      {'name': 'カラオケBanBan', 'default_order': 2},
      {'name': 'カラオケ館', 'default_order': 3},
      {'name': 'ジャンカラ', 'default_order': 4},
      {'name': 'JOYSOUND直営店', 'default_order': 5},
      {'name': 'カラオケJOYJOY', 'default_order': 6},
      {'name': 'コート・ダジュール', 'default_order': 7},
      {'name': 'カラオケCLUB DAM', 'default_order': 8},
      {'name': 'カラオケルーム歌広場', 'default_order': 9},
    ];

    final batch = db.batch();
    for (final chain in initialChains) {
      batch.insert('karaoke_chains', {
        ...chain,
        'is_default_selected': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  // カラオケチェーン店のCRUD操作
  Future<KaraokeChain> createChain(KaraokeChain chain) async {
    final db = await database;
    final id = await db.insert('karaoke_chains', chain.toMap());
    return chain.copyWith(id: id);
  }

  Future<KaraokeChain?> readChain(int id) async {
    final db = await database;
    final maps = await db.query(
      'karaoke_chains',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return KaraokeChain.fromMap(maps.first);
    }
    return null;
  }

  Future<List<KaraokeChain>> readAllChains() async {
    final db = await database;
    const orderBy = 'default_order ASC';
    final result = await db.query('karaoke_chains', orderBy: orderBy);

    return result.map((json) => KaraokeChain.fromMap(json)).toList();
  }

  Future<int> updateChain(KaraokeChain chain) async {
    final db = await database;
    return db.update(
      'karaoke_chains',
      chain.toMap(),
      where: 'id = ?',
      whereArgs: [chain.id],
    );
  }

  Future<int> deleteChain(int id) async {
    final db = await database;
    return await db.delete(
      'karaoke_chains',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ユーザーのチェーン設定のCRUD操作
  Future<UserChainSetting> createUserSetting(UserChainSetting setting) async {
    final db = await database;
    final id = await db.insert('user_chain_settings', setting.toMap());
    return setting.copyWith(id: id);
  }

  Future<UserChainSetting?> readUserSetting(int userId, int chainId) async {
    final db = await database;
    final maps = await db.query(
      'user_chain_settings',
      where: 'user_id = ? AND chain_id = ?',
      whereArgs: [userId, chainId],
    );

    if (maps.isNotEmpty) {
      return UserChainSetting.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserChainSetting>> readUserSettings(int userId) async {
    final db = await database;
    const orderBy = 'display_order ASC';
    final result = await db.query(
      'user_chain_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: orderBy,
    );

    return result.map((json) => UserChainSetting.fromMap(json)).toList();
  }

  Future<int> updateUserSetting(UserChainSetting setting) async {
    final db = await database;
    return db.update(
      'user_chain_settings',
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }

  Future<int> deleteUserSetting(int id) async {
    final db = await database;
    return await db.delete(
      'user_chain_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ユーザーの全設定を一括更新
  Future<void> updateUserSettings(
    int userId,
    List<UserChainSetting> settings,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // 既存の設定を削除
      await txn.delete(
        'user_chain_settings',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // 新しい設定を挿入
      for (final setting in settings) {
        await txn.insert('user_chain_settings', setting.toMap());
      }
    });
  }

  // 特定のユーザーの選択済みチェーン店を取得
  Future<List<KaraokeChain>> getSelectedChains(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT kc.* 
      FROM karaoke_chains kc
      LEFT JOIN user_chain_settings ucs 
        ON kc.id = ucs.chain_id AND ucs.user_id = ?
      WHERE ucs.is_selected = 1 OR (ucs.id IS NULL AND kc.is_default_selected = 1)
      ORDER BY COALESCE(ucs.display_order, kc.default_order)
    ''', [userId]);

    return result.map((json) => KaraokeChain.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
