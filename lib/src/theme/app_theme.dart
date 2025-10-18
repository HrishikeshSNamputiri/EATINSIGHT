import 'package:flutter/material.dart';

class AppTheme {
  static const Color seed = Color(0xFF006684);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.light,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: _input(),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
        indicatorShape: StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: _input(),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
        indicatorShape: StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static InputDecorationTheme _input() => const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      );
}
