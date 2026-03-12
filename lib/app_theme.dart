import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';

abstract class AppTheme {
  static Color _seedForVariant(AppThemeVariant variant, Brightness brightness) {
    switch (variant) {
      case AppThemeVariant.defaultTheme:
        return const Color(0xFF2563EB); // blue
      case AppThemeVariant.custom:
        return const Color(0xFF059669); // emerald/teal
      case AppThemeVariant.random:
        return const Color(0xFF7C3AED); // violet
    }
  }

  static ThemeData light(AppThemeVariant variant) {
    final Color seed = _seedForVariant(variant, Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    );
  }

  static ThemeData dark(AppThemeVariant variant) {
    final Color seed = _seedForVariant(variant, Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
    );
  }
}
