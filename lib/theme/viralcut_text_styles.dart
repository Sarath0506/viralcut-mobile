import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class ViralCutTextStyles {
  static TextStyle display(BuildContext context) => GoogleFonts.plusJakartaSans(
        textStyle: Theme.of(context).textTheme.bodyMedium,
      );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
        textStyle: Theme.of(context).textTheme.bodyMedium,
      );

  static TextStyle screenTitle(BuildContext context) => display(context).copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: 0,
      );

  static TextStyle sectionTitle(BuildContext context) => display(context).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
      );

  static TextStyle bodyText(BuildContext context) => body(context).copyWith(
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0,
      );

  static TextStyle label(BuildContext context) => body(context).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.4,
      );

  static TextStyle meta(BuildContext context) => body(context).copyWith(
        fontSize: 13,
        height: 1.35,
        letterSpacing: 0,
      );
}
