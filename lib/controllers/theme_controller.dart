import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyBrightness = 'smart_wallet_theme_brightness';
const String _keyVariant = 'smart_wallet_theme_variant';

enum AppThemeVariant { defaultTheme, custom, random }

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  ThemeMode _mode = ThemeMode.system;
  AppThemeVariant _variant = AppThemeVariant.defaultTheme;

  ThemeMode get mode => _mode;
  AppThemeVariant get variant => _variant;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? brightness = prefs.getString(_keyBrightness);
    final String? variantName = prefs.getString(_keyVariant);
    _mode = brightness == 'dark'
        ? ThemeMode.dark
        : brightness == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    _variant = variantName != null
        ? AppThemeVariant.values.firstWhere(
            (AppThemeVariant v) => v.name == variantName,
            orElse: () => AppThemeVariant.defaultTheme,
          )
        : AppThemeVariant.defaultTheme;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    _mode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyBrightness,
      value == ThemeMode.dark ? 'dark' : value == ThemeMode.light ? 'light' : 'system',
    );
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant value) async {
    _variant = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVariant, value.name);
    notifyListeners();
  }

  Future<void> toggleBrightness() async {
    if (_mode == ThemeMode.light) {
      await setMode(ThemeMode.dark);
    } else {
      await setMode(ThemeMode.light);
    }
  }
}
