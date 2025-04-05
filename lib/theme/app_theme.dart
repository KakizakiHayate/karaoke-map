import 'package:flutter/material.dart';

/// アプリケーション全体で使用するテーマ定義
class AppTheme {
  AppTheme._(); // プライベートコンストラクタ - インスタンス化防止

  // JOYSOUNDブランドカラー
  static const Color primaryBlue = Color(0xFF00AEEF); // メインの水色
  static const Color primaryRed = Color(0xFFE4002B); // アクセントの赤色

  // 一般的なカラー
  static const Color textPrimary = Color(0xFF1A1A1A); // 主要テキスト色
  static const Color background = Colors.white; // 背景色
  static const Color cardBackground = Color(0xFFE0E0E0); // カード背景色
  static const Color divider = Color(0xFFE0E0E0); // 区切り線
  static const Color iconBackground = Color(0xFFEEEEEE); // アイコン背景色

  // ColorSchemeの拡張
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: primaryBlue,
    secondary: Color(0xFFE0E0E0),
    error: primaryRed,
    onPrimary: Colors.white,
    onSecondary: textPrimary,
    onError: Colors.white,
    surface: background,
    onSurface: textPrimary,
  );

  // テキストスタイル
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    bodyLarge: TextStyle(color: textPrimary),
    bodyMedium: TextStyle(color: textPrimary),
    bodySmall: TextStyle(color: textPrimary),
  );

  // ボタンテーマ
  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  // アウトラインボタンテーマ
  static final OutlinedButtonThemeData outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryBlue,
      side: const BorderSide(color: primaryBlue),
      textStyle: const TextStyle(
        fontFamily: 'NotoSansJP',
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // ナビゲーションバーテーマ
  static const BottomNavigationBarThemeData bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryBlue,
    unselectedItemColor: Colors.grey,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: FontWeight.w700,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: 'NotoSansJP',
      fontWeight: FontWeight.w700,
    ),
  );

  // プライマリーカラーからマテリアルカラーを生成する関数
  static MaterialColor createMaterialColor(Color color) {
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

  // アプリ全体のテーマデータ
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryBlue,
      primarySwatch: createMaterialColor(primaryBlue),
      colorScheme: colorScheme,
      textTheme: textTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      bottomNavigationBarTheme: bottomNavigationBarTheme,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      dividerColor: divider,
    );
  }
}
