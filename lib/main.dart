import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'app_state.dart';
import 'services/database_helper.dart';
import 'services/location_permission_service.dart';
import 'screens/location_permission_screen.dart';
import 'theme/app_theme.dart';
import 'config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await EnvConfig.init();

  // データベースの初期化
  await DatabaseHelper.instance.database;

  // AppStateの初期化
  final appState = AppState();
  await appState.initializeUser();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppStartupHandler(),
    );
  }
}

class AppStartupHandler extends StatefulWidget {
  const AppStartupHandler({super.key});

  @override
  State<AppStartupHandler> createState() => _AppStartupHandlerState();
}

class _AppStartupHandlerState extends State<AppStartupHandler> {
  final LocationPermissionService _locationService =
      LocationPermissionService();
  bool _isChecking = true;
  bool _needsPermissionScreen = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    // 位置情報の権限が必要かどうかを確認
    final needsPermission = await _locationService.shouldShowPermissionScreen();

    setState(() {
      _needsPermissionScreen = needsPermission;
      _isChecking = false;
    });
  }

  void _onPermissionGranted() {
    setState(() {
      _needsPermissionScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppState>().userId;

    // ユーザーIDが初期化されるまでローディング画面を表示
    if (userId == null || _isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 位置情報許可画面が必要な場合はそれを表示
    if (_needsPermissionScreen) {
      return LocationPermissionScreen(
        onPermissionGranted: _onPermissionGranted,
      );
    }

    // それ以外の場合はホーム画面を表示
    return const HomeScreen();
  }
}
