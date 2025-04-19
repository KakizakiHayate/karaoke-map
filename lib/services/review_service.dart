import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// アプリ内レビュー機能を管理するサービスクラス
class ReviewService {
  static const String _searchCountKey = 'search_count';
  static const String _lastReviewRequestDateKey = 'last_review_request_date';
  static const List<int> _reviewTriggerCounts = [5, 25]; // レビュー表示のトリガーとなる検索回数

  final InAppReview _inAppReview = InAppReview.instance;
  final Logger _logger = Logger();

  /// 検索回数をインクリメントし、必要に応じてレビューダイアログを表示
  Future<void> incrementSearchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_searchCountKey) ?? 0;
      final newCount = currentCount + 1;

      await prefs.setInt(_searchCountKey, newCount);
      _logger.d('検索回数を更新: $newCount回');

      // 指定の検索回数に達した場合、かつ前回のレビュー表示から30日以上経過している場合
      if (_reviewTriggerCounts.contains(newCount) &&
          await _hasEnoughTimePassed()) {
        await _requestReview();
      }
    } catch (e) {
      _logger.e('検索回数の更新に失敗しました: $e');
    }
  }

  /// 現在の検索回数を取得
  Future<int> getSearchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_searchCountKey) ?? 0;
    } catch (e) {
      _logger.e('検索回数の取得に失敗しました: $e');
      return 0;
    }
  }

  /// 前回のレビュー表示から十分な時間が経過しているかを確認（30日以上）
  Future<bool> _hasEnoughTimePassed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestDateString = prefs.getString(_lastReviewRequestDateKey);

      if (lastRequestDateString == null) {
        return true; // 前回の表示がない場合は表示可能
      }

      final lastRequestDate = DateTime.parse(lastRequestDateString);
      final now = DateTime.now();
      final difference = now.difference(lastRequestDate);

      // 30日以上経過していれば再表示可能
      return difference.inDays >= 30;
    } catch (e) {
      _logger.e('レビュー表示の確認に失敗しました: $e');
      return false;
    }
  }

  /// アプリのレビューダイアログを表示
  Future<void> _requestReview() async {
    try {
      final bool isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        _logger.i('レビューダイアログを表示します');
        await _inAppReview.requestReview();

        // レビューリクエスト日を保存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _lastReviewRequestDateKey, DateTime.now().toIso8601String());
      } else {
        _logger.w('レビューダイアログを表示できません');
      }
    } catch (e) {
      _logger.e('レビューダイアログの表示に失敗しました: $e');
    }
  }

  /// レビューを強制的に表示（テスト用）
  Future<void> forceRequestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        // 開発中やテスト環境ではストアページを開く
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      _logger.e('強制レビュー表示に失敗しました: $e');
    }
  }

  /// 保存されている検索回数をリセット（テスト用）
  Future<void> resetSearchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_searchCountKey, 0);
      _logger.d('検索回数をリセットしました');
    } catch (e) {
      _logger.e('検索回数のリセットに失敗しました: $e');
    }
  }
}
