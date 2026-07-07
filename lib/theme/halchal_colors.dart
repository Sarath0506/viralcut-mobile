import 'package:flutter/material.dart';

import 'token_colors.dart';

/// Brand semantic colors for the active brightness.
/// Use [HalchalColors.of] in feature code — not [ViralCutTokenColors] *Light/*Dark.
@immutable
class HalchalColors extends ThemeExtension<HalchalColors> {
  const HalchalColors({
    required this.primary,
    required this.primaryVariant,
    required this.money,
    required this.moneyBright,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onSurface,
    required this.deepSurface,
    required this.border,
    required this.muted,
    required this.error,
    required this.warning,
    required this.onPrimary,
    required this.authGradientStart,
    required this.authGradientMid,
    required this.authGradientEnd,
    required this.infoSurface,
  });

  final Color primary;
  final Color primaryVariant;
  final Color money;
  final Color moneyBright;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onBackground;
  final Color onSurface;
  final Color deepSurface;
  final Color border;
  final Color muted;
  final Color error;
  final Color warning;
  final Color onPrimary;
  final Color authGradientStart;
  final Color authGradientMid;
  final Color authGradientEnd;
  final Color infoSurface;

  static HalchalColors of(BuildContext context) {
    final ext = Theme.of(context).extension<HalchalColors>();
    assert(ext != null, 'HalchalColors not registered on ThemeData');
    return ext!;
  }

  static HalchalColors forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return HalchalColors(
      primary: isDark
          ? ViralCutTokenColors.primaryDark
          : ViralCutTokenColors.primaryLight,
      primaryVariant: isDark
          ? ViralCutTokenColors.primaryVariantDark
          : ViralCutTokenColors.primaryVariantLight,
      money: isDark
          ? ViralCutTokenColors.moneyDark
          : ViralCutTokenColors.moneyLight,
      moneyBright: isDark
          ? ViralCutTokenColors.moneyBrightDark
          : ViralCutTokenColors.moneyBrightLight,
      background: isDark
          ? ViralCutTokenColors.backgroundDark
          : ViralCutTokenColors.backgroundLight,
      surface: isDark
          ? ViralCutTokenColors.surfaceDark
          : ViralCutTokenColors.surfaceLight,
      surfaceVariant: isDark
          ? ViralCutTokenColors.surfaceVariantDark
          : ViralCutTokenColors.surfaceVariantLight,
      onBackground: isDark
          ? ViralCutTokenColors.onBackgroundDark
          : ViralCutTokenColors.onBackgroundLight,
      onSurface: isDark
          ? ViralCutTokenColors.onSurfaceDark
          : ViralCutTokenColors.onSurfaceLight,
      deepSurface: isDark
          ? ViralCutTokenColors.deepSurfaceDark
          : ViralCutTokenColors.deepSurfaceLight,
      border: isDark
          ? ViralCutTokenColors.borderDark
          : ViralCutTokenColors.borderLight,
      muted: isDark
          ? ViralCutTokenColors.mutedDark
          : ViralCutTokenColors.mutedLight,
      error: isDark
          ? ViralCutTokenColors.errorDark
          : ViralCutTokenColors.errorLight,
      warning: isDark
          ? ViralCutTokenColors.warningDark
          : ViralCutTokenColors.warningLight,
      onPrimary: isDark
          ? ViralCutTokenColors.onPrimaryDark
          : ViralCutTokenColors.onPrimaryLight,
      authGradientStart: isDark
          ? ViralCutTokenColors.authGradientStartDark
          : ViralCutTokenColors.authGradientStartLight,
      authGradientMid: isDark
          ? ViralCutTokenColors.authGradientMidDark
          : ViralCutTokenColors.authGradientMidLight,
      authGradientEnd: isDark
          ? ViralCutTokenColors.authGradientEndDark
          : ViralCutTokenColors.authGradientEndLight,
      infoSurface: isDark
          ? ViralCutTokenColors.infoSurfaceDark
          : ViralCutTokenColors.infoSurfaceLight,
    );
  }

  @override
  HalchalColors copyWith({
    Color? primary,
    Color? primaryVariant,
    Color? money,
    Color? moneyBright,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? onBackground,
    Color? onSurface,
    Color? deepSurface,
    Color? border,
    Color? muted,
    Color? error,
    Color? warning,
    Color? onPrimary,
    Color? authGradientStart,
    Color? authGradientMid,
    Color? authGradientEnd,
    Color? infoSurface,
  }) {
    return HalchalColors(
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      money: money ?? this.money,
      moneyBright: moneyBright ?? this.moneyBright,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      deepSurface: deepSurface ?? this.deepSurface,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      onPrimary: onPrimary ?? this.onPrimary,
      authGradientStart: authGradientStart ?? this.authGradientStart,
      authGradientMid: authGradientMid ?? this.authGradientMid,
      authGradientEnd: authGradientEnd ?? this.authGradientEnd,
      infoSurface: infoSurface ?? this.infoSurface,
    );
  }

  @override
  HalchalColors lerp(ThemeExtension<HalchalColors>? other, double t) {
    if (other is! HalchalColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return HalchalColors(
      primary: lerpColor(primary, other.primary),
      primaryVariant: lerpColor(primaryVariant, other.primaryVariant),
      money: lerpColor(money, other.money),
      moneyBright: lerpColor(moneyBright, other.moneyBright),
      background: lerpColor(background, other.background),
      surface: lerpColor(surface, other.surface),
      surfaceVariant: lerpColor(surfaceVariant, other.surfaceVariant),
      onBackground: lerpColor(onBackground, other.onBackground),
      onSurface: lerpColor(onSurface, other.onSurface),
      deepSurface: lerpColor(deepSurface, other.deepSurface),
      border: lerpColor(border, other.border),
      muted: lerpColor(muted, other.muted),
      error: lerpColor(error, other.error),
      warning: lerpColor(warning, other.warning),
      onPrimary: lerpColor(onPrimary, other.onPrimary),
      authGradientStart: lerpColor(authGradientStart, other.authGradientStart),
      authGradientMid: lerpColor(authGradientMid, other.authGradientMid),
      authGradientEnd: lerpColor(authGradientEnd, other.authGradientEnd),
      infoSurface: lerpColor(infoSurface, other.infoSurface),
    );
  }
}

/// OAuth provider brand colors (not theme-dependent).
abstract final class ViralCutOAuthColors {
  static const google = Color(0xFF4285F4);
  static const facebook = Color(0xFF1877F2);
}
