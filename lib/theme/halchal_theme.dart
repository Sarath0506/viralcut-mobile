import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/layout/app_spacing.dart';
import 'token_colors.dart';
import 'halchal_colors.dart';

abstract final class HalchalTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final vc = HalchalColors.forBrightness(brightness);
    final isDark = brightness == Brightness.dark;

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: textTheme,
      extensions: [vc],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: vc.primary,
        onPrimary: vc.onPrimary,
        primaryContainer: vc.surfaceVariant,
        onPrimaryContainer: vc.onSurface,
        secondary: vc.primaryVariant,
        onSecondary: vc.onPrimary,
        tertiary: vc.money,
        onTertiary: vc.onPrimary,
        error: vc.error,
        onError: vc.onPrimary,
        surface: vc.surface,
        onSurface: vc.onSurface,
        outline: vc.border,
      ),
      scaffoldBackgroundColor: vc.background,
      appBarTheme: AppBarTheme(
        backgroundColor: vc.background,
        foregroundColor: vc.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: vc.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: vc.primary,
          foregroundColor: vc.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorColor: vc.primary.withValues(alpha: 0.12),
        backgroundColor: vc.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? vc.primary : vc.muted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            height: 1.2,
            letterSpacing: 0.1,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? vc.primary : vc.muted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: vc.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
          borderSide: BorderSide(color: vc.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
          borderSide: BorderSide(color: vc.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
          borderSide: BorderSide(color: vc.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: vc.border),
    );
  }
}
