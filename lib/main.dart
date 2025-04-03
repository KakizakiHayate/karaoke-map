import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'app_state.dart';
import 'services/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // データベースの初期化を確実に行う
  final db = await DatabaseHelper.instance.database;

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppStartupHandler(),
    );
  }
}

class AppStartupHandler extends StatelessWidget {
  const AppStartupHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppState>().userId;

    // ユーザーIDが初期化されるまでローディング画面を表示
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 初期化完了後にホーム画面を表示
    return const HomeScreen();
  }
}
