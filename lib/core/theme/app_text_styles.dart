import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_design.dart';

/// AppTextStyles contains semantic typography tokens
/// to ensure text styling consistency across the entire application in Light and Dark modes.
class AppTextStyles {
  // --- STATIC BASE STYLES (Light default / Theme-inheritable) ---

  // Headlines
  static TextStyle get headline1 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppDesign.textPrimary,
      );

  static TextStyle get headline2 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppDesign.textPrimary,
      );

  static TextStyle get headline3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppDesign.textPrimary,
      );

  // Body Text
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppDesign.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppDesign.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppDesign.textSecondary,
      );

  // Labels/Captions
  static TextStyle get labelMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppDesign.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppDesign.textTertiary,
      );

  // --- CONTEXT-AWARE DYNAMIC STYLES ---

  static TextStyle headline1Of(BuildContext context) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppDesign.textPrimaryOf(context),
      );

  static TextStyle headline2Of(BuildContext context) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppDesign.textPrimaryOf(context),
      );

  static TextStyle headline3Of(BuildContext context) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppDesign.textPrimaryOf(context),
      );

  static TextStyle bodyLargeOf(BuildContext context) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppDesign.textPrimaryOf(context),
      );

  static TextStyle bodyMediumOf(BuildContext context) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppDesign.textPrimaryOf(context),
      );

  static TextStyle bodySmallOf(BuildContext context) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppDesign.textSecondaryOf(context),
      );

  static TextStyle labelMediumOf(BuildContext context) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppDesign.textSecondaryOf(context),
      );

  static TextStyle captionOf(BuildContext context) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppDesign.textTertiaryOf(context),
      );
}
