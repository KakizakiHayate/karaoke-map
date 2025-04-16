import 'package:flutter/foundation.dart';
import 'services/user_service.dart';

class AppState extends ChangeNotifier {
  int? _userId;
  final UserService _userService = UserService();

  // デバッグモードの状態
  bool _isDebugMode = false;

  int? get userId => _userId;
  bool get isDebugMode => _isDebugMode;

  Future<void> initializeUser() async {
    _userId = await _userService.getOrCreateUserId();
    notifyListeners();
  }

  // デバッグモードを切り替えるメソッド
  void toggleDebugMode(bool value) {
    _isDebugMode = value;
    notifyListeners();
  }
}
