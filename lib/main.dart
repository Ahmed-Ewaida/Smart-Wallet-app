import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'controllers/theme_controller.dart';
import 'screens/smart_wallet_home_page.dart';

void main() {
  runApp(const SmartWalletApp());
}

class SmartWalletApp extends StatefulWidget {
  const SmartWalletApp({super.key});

  @override
  State<SmartWalletApp> createState() => _SmartWalletAppState();
}

class _SmartWalletAppState extends State<SmartWalletApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(_themeController.variant),
      darkTheme: AppTheme.dark(_themeController.variant),
      themeMode: _themeController.mode,
      home: SmartWalletHomePage(themeController: _themeController),
    );
  }
}
