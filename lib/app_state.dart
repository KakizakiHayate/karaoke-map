import 'package:flutter/foundation.dart';
import 'services/user_service.dart';

class AppState extends ChangeNotifier {
  int? _userId;
  final UserService _userService = UserService();

  int? get userId => _userId;

  Future<void> initializeUser() async {
    _userId = await _userService.getOrCreateUserId();
    notifyListeners();
  }
}
