import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPermissionService {
  static const String _hasSeenPermissionScreenKey =
      'has_seen_permission_screen';

  // 位置情報の権限状態を確認する
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  // 位置情報の権限をリクエストする
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // 位置情報の権限がある場合はtrue、ない場合はfalseを返す
  Future<bool> hasLocationPermission() async {
    final permission = await checkPermissionStatus();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ユーザーが既に位置情報許可画面を見たかどうかを保存する
  Future<void> setPermissionScreenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenPermissionScreenKey, true);
  }

  // ユーザーが既に位置情報許可画面を見たかどうかを確認する
  Future<bool> hasSeenPermissionScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenPermissionScreenKey) ?? false;
  }

  // 位置情報が必要かどうかを判断する
  // 「位置情報許可画面を見ていない」または「位置情報の権限がない」場合はtrueを返す
  Future<bool> shouldShowPermissionScreen() async {
    final hasPermission = await hasLocationPermission();

    // 既に権限がある場合は表示しない
    if (hasPermission) {
      return false;
    }

    // 権限がない場合は表示する
    return true;
  }
}
