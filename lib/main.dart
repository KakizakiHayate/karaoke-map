import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'app_state.dart';
import 'services/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: ThemeData(
        primaryColor: const Color(0xFF00AEEF),
        primarySwatch: _createMaterialColor(const Color(0xFF00AEEF)),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF00AEEF),
          secondary: const Color(0xFFE0E0E0),
          error: const Color(0xFFE4002B),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          titleMedium: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          titleSmall: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
          bodySmall: TextStyle(color: Color(0xFF1A1A1A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'NotoSansJP',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w700,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFE0E0E0),
        dividerColor: const Color(0xFFE0E0E0),
      ),
      home: const AppStartupHandler(),
    );
  }
}

// プライマリーカラーからマテリアルカラーを生成する関数
MaterialColor _createMaterialColor(Color color) {
  List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
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
