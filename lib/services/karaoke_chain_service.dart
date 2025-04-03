import '../models/karaoke_chain.dart';
import '../models/user_chain_setting.dart';
import 'database_helper.dart';

class KaraokeChainService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // カラオケチェーン店の操作
  Future<List<KaraokeChain>> getAllChains() async {
    return await _db.readAllChains();
  }

  Future<KaraokeChain?> getChainById(int id) async {
    return await _db.readChain(id);
  }

  Future<KaraokeChain> createChain(KaraokeChain chain) async {
    return await _db.createChain(chain);
  }

  Future<bool> updateChain(KaraokeChain chain) async {
    final result = await _db.updateChain(chain);
    return result > 0;
  }

  Future<bool> deleteChain(int id) async {
    final result = await _db.deleteChain(id);
    return result > 0;
  }

  // ユーザーのチェーン設定の操作
  Future<List<KaraokeChain>> getSelectedChains(int userId) async {
    return await _db.getSelectedChains(userId);
  }

  Future<List<UserChainSetting>> getUserSettings(int userId) async {
    return await _db.readUserSettings(userId);
  }

  Future<void> updateUserSettings(
    int userId,
    List<UserChainSetting> settings,
  ) async {
    await _db.updateUserSettings(userId, settings);
  }

  Future<void> updateSingleUserSetting(UserChainSetting setting) async {
    final existingSetting = await _db.readUserSetting(
      setting.userId,
      setting.chainId,
    );

    if (existingSetting != null) {
      await _db.updateUserSetting(setting);
    } else {
      await _db.createUserSetting(setting);
    }
  }

  // ユーザーの設定を初期化（デフォルト値に戻す）
  Future<void> resetUserSettings(int userId) async {
    final chains = await getAllChains();
    final settings = chains
        .map((chain) => UserChainSetting(
              userId: userId,
              chainId: chain.id!,
              isSelected: chain.isDefaultSelected,
              displayOrder: chain.defaultOrder,
            ))
        .toList();

    await updateUserSettings(userId, settings);
  }

  // 選択状態の更新
  Future<void> updateChainSelection(
    int userId,
    int chainId,
    bool isSelected,
  ) async {
    final existingSetting = await _db.readUserSetting(userId, chainId);
    final chain = await getChainById(chainId);

    if (chain == null) return;

    if (existingSetting != null) {
      final updatedSetting = existingSetting.copyWith(isSelected: isSelected);
      await _db.updateUserSetting(updatedSetting);
    } else {
      final newSetting = UserChainSetting(
        userId: userId,
        chainId: chainId,
        isSelected: isSelected,
        displayOrder: chain.defaultOrder,
      );
      await _db.createUserSetting(newSetting);
    }
  }

  // 表示順序の更新
  Future<void> updateChainOrder(
    int userId,
    List<int> chainIds,
  ) async {
    final settings = await Future.wait(
      chainIds.asMap().entries.map((entry) async {
        final chainId = entry.value;
        final displayOrder = entry.key;
        final existingSetting = await _db.readUserSetting(userId, chainId);

        if (existingSetting != null) {
          return existingSetting.copyWith(displayOrder: displayOrder);
        } else {
          final chain = await getChainById(chainId);
          if (chain == null) throw Exception('Chain not found');

          return UserChainSetting(
            userId: userId,
            chainId: chainId,
            isSelected: chain.isDefaultSelected,
            displayOrder: displayOrder,
          );
        }
      }),
    );

    await updateUserSettings(userId, settings);
  }
}
