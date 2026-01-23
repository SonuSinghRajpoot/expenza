import 'package:flutter/material.dart';

/// AppDesign contains standard spacing, padding, and border radius tokens
/// to ensure UI consistency across the entire application.
///
/// Following the industry standard 8-point grid system.
class AppDesign {
  // --- SPACING TOKENS ---

  /// Global horizontal padding for screens to align content with the edges.
  static const double screenHorizontalPadding = 12.0;

  /// Standard vertical padding for screen content.
  static const double screenVerticalPadding = 16.0;

  /// Standard spacing between major sections (e.g., between cards).
  static const double sectionSpacing = 24.0;

  /// Standard spacing between related elements (e.g., inside a card).
  static const double elementSpacing = 16.0;

  /// Small spacing for tight layouts or small gaps.
  static const double smallSpacing = 8.0;

  /// Extra small spacing.
  static const double tinySpacing = 4.0;

  // --- BREAKPOINTS ---

  /// Maximum width for mobile layout.
  static const double mobileBreakpoint = 600.0;

  // --- BORDER RADIUS TOKENS ---

  /// Standard radius for cards and major containers (Premium/Modern look).
  static const double cardBorderRadius = 24.0;

  /// Slightly smaller radius for items inside cards or lists.
  static const double itemBorderRadius = 16.0;

  /// Radius for buttons and interactive components.
  static const double buttonBorderRadius = 12.0;

  /// Small radius for small containers/icons.
  static const double smallBorderRadius = 8.0;

  // --- COLOR TOKENS ---
  // Brand/Primary Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF6366F1);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Surface/Background Colors
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Colors.white;

  // Border/Divider Colors
  static const Color borderDefault = Color(0xFFE2E8F0);

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Category Colors
  static const Color categoryTravel = Color(0xFF2563EB);
  static const Color categoryAccommodation = Color(0xFF10B981);
  static const Color categoryFood = Color(0xFFF59E0B);
  static const Color categoryEvent = Color(0xFF8B5CF6);
  static const Color categoryMisc = Color(0xFF6B7280);

  // --- COMPONENT SPECIFIC ---

  /// Padding for the inside of a Card.
  static const double cardInternalPadding = 16.0;

  /// Extra padding needed at the end of AppBar actions to align with screen padding.
  /// Calculation: ScreenPadding (12) - IconButton default padding (8) = 4.
  static const double appBarActionEndPadding = 4.0;

  // --- UTILITY METHODS ---

  /// Helper to get consistent screen edge insets.
  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
    vertical: screenVerticalPadding,
  );

  /// Helper for uniform card insets.
  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(cardInternalPadding);

  // --- DECORATION HELPERS ---

  /// Helper method for consistent card decorations.
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? surfaceElevated,
      borderRadius: BorderRadius.circular(borderRadius ?? cardBorderRadius),
      border: Border.all(color: borderColor ?? borderDefault),
    );
  }

  /// Helper method for consistent input decorations.
  /// Note: Requires app_text_styles.dart to be imported.
  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: const BorderSide(color: borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: const BorderSide(color: borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      hintStyle: const TextStyle(
        fontSize: 15,
        color: textTertiary,
      ),
    );
  }
}
