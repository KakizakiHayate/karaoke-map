import 'database_helper.dart';

class UserService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // 新規ユーザーを作成
  Future<int> createUser() async {
    final db = await _db.database;
    final id = await db.insert('users', {
      'created_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  // ユーザーIDを取得（存在しない場合は新規作成）
  Future<int> getOrCreateUserId() async {
    final db = await _db.database;
    final users = await db.query('users', limit: 1);

    if (users.isEmpty) {
      // ユーザーが存在しない場合は新規作成
      return await createUser();
    }

    // 既存のユーザーIDを返す
    return users.first['id'] as int;
  }
}
