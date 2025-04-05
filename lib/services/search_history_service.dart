import '../models/search_history.dart';
import 'database_helper.dart';

class SearchHistoryService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // 検索履歴を保存
  Future<SearchHistory> saveSearchHistory(SearchHistory history) async {
    final db = await _db.database;
    final id = await db.insert('search_histories', history.toMap());
    return history.copyWith(id: id);
  }

  // ユーザーの検索履歴を取得（最新順）
  Future<List<SearchHistory>> getUserSearchHistory(int userId,
      {int limit = 20}) async {
    final db = await _db.database;
    final result = await db.query(
      'search_histories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return result.map((json) => SearchHistory.fromMap(json)).toList();
  }

  // 検索履歴を削除
  Future<bool> deleteSearchHistory(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'search_histories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // ユーザーの全検索履歴を削除
  Future<bool> deleteAllUserSearchHistory(int userId) async {
    final db = await _db.database;
    final result = await db.delete(
      'search_histories',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result > 0;
  }

  // 古い履歴を自動削除（オプション）
  Future<void> cleanupOldHistory(int userId, {int keepDays = 30}) async {
    final db = await _db.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    await db.delete(
      'search_histories',
      where: 'user_id = ? AND created_at < ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
    );
  }
}
