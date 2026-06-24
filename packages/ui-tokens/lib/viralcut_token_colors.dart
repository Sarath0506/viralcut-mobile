// Generated from packages/ui-tokens/tokens.json — do not edit by hand
import 'package:flutter/material.dart';

abstract final class ViralCutTokenColors {
  static const primaryLight = Color(0xFF630ED4);
  static const primaryDark = Color(0xFF9B6DFF);
  static const primaryVariantLight = Color(0xFF7C3AED);
  static const primaryVariantDark = Color(0xFFA78BFA);
  static const moneyLight = Color(0xFF006C49);
  static const moneyDark = Color(0xFF34D399);
  static const moneyBrightLight = Color(0xFF16A34A);
  static const moneyBrightDark = Color(0xFF4ADE80);
  static const backgroundLight = Color(0xFFF8F9FF);
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF111827);
  static const surfaceVariantLight = Color(0xFFEEF0FF);
  static const surfaceVariantDark = Color(0xFF1F2937);
  static const onBackgroundLight = Color(0xFF0B1C30);
  static const onBackgroundDark = Color(0xFFF1F5F9);
  static const onSurfaceLight = Color(0xFF0B1C30);
  static const onSurfaceDark = Color(0xFFE2E8F0);
  static const deepSurfaceLight = Color(0xFF0F172A);
  static const deepSurfaceDark = Color(0xFF020617);
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF334155);
  static const mutedLight = Color(0xFF64748B);
  static const mutedDark = Color(0xFF94A3B8);
  static const errorLight = Color(0xFFBA1A1A);
  static const errorDark = Color(0xFFF87171);
  static const warningLight = Color(0xFFAA4900);
  static const warningDark = Color(0xFFFB923C);
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const onPrimaryDark = Color(0xFFFFFFFF);
  static const authGradientStartLight = Color(0xFFF3EEFF);
  static const authGradientStartDark = Color(0xFF0B1220);
  static const authGradientMidLight = Color(0xFFF8F9FF);
  static const authGradientMidDark = Color(0xFF111827);
  static const authGradientEndLight = Color(0xFFEDE9FE);
  static const authGradientEndDark = Color(0xFF1F2937);
  static const infoSurfaceLight = Color(0xFFEEF4FF);
  static const infoSurfaceDark = Color(0xFF1E293B);

  /// Resolves a token [name] for the given [brightness].
  static Color resolve(Brightness brightness, String name) {
    return switch (name) {
      'primary' => brightness == Brightness.dark ? primaryDark : primaryLight,
      'primaryVariant' => brightness == Brightness.dark ? primaryVariantDark : primaryVariantLight,
      'money' => brightness == Brightness.dark ? moneyDark : moneyLight,
      'moneyBright' => brightness == Brightness.dark ? moneyBrightDark : moneyBrightLight,
      'background' => brightness == Brightness.dark ? backgroundDark : backgroundLight,
      'surface' => brightness == Brightness.dark ? surfaceDark : surfaceLight,
      'surfaceVariant' => brightness == Brightness.dark ? surfaceVariantDark : surfaceVariantLight,
      'onBackground' => brightness == Brightness.dark ? onBackgroundDark : onBackgroundLight,
      'onSurface' => brightness == Brightness.dark ? onSurfaceDark : onSurfaceLight,
      'deepSurface' => brightness == Brightness.dark ? deepSurfaceDark : deepSurfaceLight,
      'border' => brightness == Brightness.dark ? borderDark : borderLight,
      'muted' => brightness == Brightness.dark ? mutedDark : mutedLight,
      'error' => brightness == Brightness.dark ? errorDark : errorLight,
      'warning' => brightness == Brightness.dark ? warningDark : warningLight,
      'onPrimary' => brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight,
      'authGradientStart' => brightness == Brightness.dark ? authGradientStartDark : authGradientStartLight,
      'authGradientMid' => brightness == Brightness.dark ? authGradientMidDark : authGradientMidLight,
      'authGradientEnd' => brightness == Brightness.dark ? authGradientEndDark : authGradientEndLight,
      'infoSurface' => brightness == Brightness.dark ? infoSurfaceDark : infoSurfaceLight,
      _ => throw ArgumentError('Unknown color token: $name'),
    };
  }

  static Color forBrightness(Brightness brightness, Color light, Color dark) =>
      brightness == Brightness.dark ? dark : light;
}

abstract final class ViralCutTokenRadius {
  static const sm = 6.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

abstract final class ViralCutTokenFonts {
  static const sans = 'Inter';
  static const display = 'Plus Jakarta Sans';
}
