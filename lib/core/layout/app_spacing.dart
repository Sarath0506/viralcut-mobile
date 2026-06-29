import 'package:flutter/material.dart';

/// 4pt grid spacing used across onboarding, auth, and shell screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenHorizontal = 20;
  static const double screenBottom = 16;

  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double shellTopBarHeight = 56;
  static const double bottomNavHeight = 56;

  static EdgeInsets screenPadding(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      screenHorizontal,
      sm,
      screenHorizontal,
      bottom > 0 ? bottom : screenBottom,
    );
  }

  static EdgeInsets bottomActionPadding(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      lg,
      md,
      lg,
      bottom > 0 ? bottom : screenBottom,
    );
  }
}
