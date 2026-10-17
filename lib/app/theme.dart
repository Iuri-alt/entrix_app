import 'package:flutter/material.dart';

import '../domain/models/enums.dart';

/// Tokens de cor do Entrix (azul-marinho + verde da identidade original).
abstract final class AppColors {
  static const page = Color(0xFF0B1530);
  static const surface = Color(0xFF14213D);
  static const surfaceRaised = Color(0xFF1B2A49);
  static const border = Color(0x1FFFFFFF);
  static const textPrimary = Color(0xFFF0EFEC);
  static const textSecondary = Color(0xFFB9C2D6);
  static const textMuted = Color(0xFF8A94AB);
  static const brand = Color(0xFF1DB954);
  static const onBrand = Color(0xFF07140C);

  static const good = Color(0xFF0CA30C);
  static const warning = Color(0xFFFAB219);
  static const serious = Color(0xFFEC835A);
  static const critical = Color(0xFFD03B3B);
  static const info = Color(0xFF3987E5);
  static const neutral = Color(0xFF898781);

  static Color signal(Signal s) => switch (s) {
        Signal.good => good,
        Signal.warning => warning,
        Signal.critical => critical,
        Signal.info => info,
        Signal.neutral => neutral,
      };

  static IconData signalIcon(Signal s) => switch (s) {
        Signal.good => Icons.check_circle_rounded,
        Signal.warning => Icons.error_rounded,
        Signal.critical => Icons.cancel_rounded,
        Signal.info => Icons.schedule_rounded,
        Signal.neutral => Icons.radio_button_unchecked_rounded,
      };
}

/// Paleta categórica validada (CVD e contraste ≥ 3:1) sobre [AppColors.surface].
abstract final class ChartColors {
  static const series = [
    Color(0xFF3987E5), // azul
    Color(0xFFD95926), // laranja
    Color(0xFF199E70), // água
    Color(0xFFC98500), // amarelo
    Color(0xFFD55181), // magenta
    Color(0xFF008300), // verde
    Color(0xFF9085E9), // violeta
    Color(0xFFE66767), // vermelho
  ];
  static const income = Color(0xFF3987E5);
  static const expense = Color(0xFFD95926);
  static const grid = Color(0xFF24345A);
  static const axis = Color(0xFF34466E);
  static const dimmed = Color(0xFF34466E);
}

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      secondary: AppColors.info,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.page,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      surfaceContainerHighest: AppColors.surfaceRaised,
      outline: AppColors.textMuted,
      outlineVariant: AppColors.border,
      error: const Color(0xFFFF8A80),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.page,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.page,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        side: BorderSide(color: AppColors.border),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x331DB954),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x331DB954),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.brand,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        tabAlignment: TabAlignment.start,
        dividerColor: AppColors.border,
      ),
    );
  }
}
