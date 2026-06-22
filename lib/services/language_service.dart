import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  bangla('bn', 'বাংলা'),
  urdu('ur', 'اردو');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class LanguageService extends ChangeNotifier {
  LanguageService(this._preferences)
    : _language = AppLanguage.fromCode(_preferences.getString(_languageKey));

  static const String _languageKey = 'selected_language';

  final SharedPreferences _preferences;
  AppLanguage _language;

  AppLanguage get language => _language;

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    await _preferences.setString(_languageKey, language.code);
    notifyListeners();
  }
}
