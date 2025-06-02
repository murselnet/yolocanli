import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  defaultDark,
  nightBlue,
  tealAccent,
  purpleDream,
}

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.defaultDark;
  static const String _themeKey = 'app_theme';

  AppTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getInt(_themeKey);
    if (savedTheme != null) {
      _currentTheme = AppTheme.values[savedTheme];
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);

    notifyListeners();
  }

  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.defaultDark:
        return _defaultDarkTheme;
      case AppTheme.nightBlue:
        return _nightBlueTheme;
      case AppTheme.tealAccent:
        return _tealAccentTheme;
      case AppTheme.purpleDream:
        return _purpleDreamTheme;
    }
  }

  // Default dark theme (original app theme)
  static final ThemeData _defaultDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey[900],
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.blueGrey[800],
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  );

  // Night blue theme
  static final ThemeData _nightBlueTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    primaryColor: Colors.indigo,
    hintColor: Colors.lightBlue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF0A1929),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF162A45),
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF162A45),
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
    ),
  );

  // Teal accent theme
  static final ThemeData _tealAccentTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    primaryColor: Colors.teal,
    hintColor: Colors.tealAccent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.tealAccent,
    ),
    cardTheme: CardTheme(
      color: Colors.grey[800],
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.tealAccent,
      foregroundColor: Colors.black,
    ),
  );

  // Purple dream theme
  static final ThemeData _purpleDreamTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.purple,
    primaryColor: Colors.purple,
    hintColor: Colors.deepPurpleAccent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF1A1025),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D1B3D),
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF2D1B3D),
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
    ),
  );
}
