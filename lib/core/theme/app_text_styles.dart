import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_design.dart';

/// AppTextStyles contains semantic typography tokens
/// to ensure text styling consistency across the entire application.
class AppTextStyles {
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
}
