import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _languageCodeKey = 'languageCode';

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageCodeKey);
    if (savedLanguageCode != null) {
      _currentLocale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale.languageCode == locale.languageCode) return;

    _currentLocale = locale;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);

    notifyListeners();
  }

  bool isCurrentLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
}
