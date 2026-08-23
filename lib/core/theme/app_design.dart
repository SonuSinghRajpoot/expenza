import 'package:flutter/material.dart';

/// AppDesign contains standard spacing, padding, border radius,
/// and color tokens for both Light and Dark themes to ensure UI consistency.
///
/// Following the industry standard 8-point grid system and Material 3 design principles.
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

  // --- COLOR TOKENS (LIGHT THEME) ---
  // Brand/Primary Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryDark = Color(0xFF818CF8);

  // Text Colors (Light)
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Surface/Background Colors (Light)
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Colors.white;

  // Border/Divider Colors (Light)
  static const Color borderDefault = Color(0xFFE2E8F0);

  // --- COLOR TOKENS (DARK THEME - NEUTRAL CHARCOAL) ---
  // Text Colors (Dark)
  static const Color darkTextPrimary = Color(0xFFF3F3F3);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextTertiary = Color(0xFF707070);

  // Surface/Background Colors (Dark - Standard M3 Neutral Charcoal)
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceElevated = Color(0xFF1E1E1E);
  static const Color darkSurfaceContainerHigh = Color(0xFF282828);

  // Border/Divider Colors (Dark - Neutral Charcoal)
  static const Color darkBorderDefault = Color(0xFF2E2E2E);

  // --- SEMANTIC COLORS ---
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

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

  // --- CONTEXT-AWARE COLOR GETTERS ---

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : surfaceElevated;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color textTertiaryOf(BuildContext context) =>
      isDark(context) ? darkTextTertiary : textTertiary;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorderDefault : borderDefault;

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

  /// Helper method for consistent card decorations across Light and Dark modes.
  static BoxDecoration cardDecoration({
    BuildContext? context,
    Color? color,
    Color? borderColor,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    final dark = context != null && isDark(context);
    final defaultBg = dark ? darkSurfaceElevated : surfaceElevated;
    final defaultBorder = dark ? darkBorderDefault : borderDefault;

    return BoxDecoration(
      color: color ?? defaultBg,
      borderRadius: BorderRadius.circular(borderRadius ?? cardBorderRadius),
      border: Border.all(color: borderColor ?? defaultBorder),
      boxShadow: boxShadow,
    );
  }

  /// Helper method for consistent input decorations across Light and Dark modes.
  static InputDecoration inputDecoration(
    String hint, {
    BuildContext? context,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final dark = context != null && isDark(context);
    final bg = dark ? darkSurface : surface;
    final border = dark ? darkBorderDefault : borderDefault;
    final hintColor = dark ? darkTextTertiary : textTertiary;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: bg,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        borderSide: BorderSide(color: dark ? primaryDark : primary, width: 2),
      ),
      hintStyle: TextStyle(
        fontSize: 15,
        color: hintColor,
      ),
    );
  }
}

/// Helpful BuildContext extension for concise theme and color lookups.
extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get surfaceColor => AppDesign.surfaceOf(this);
  Color get surfaceElevatedColor => AppDesign.surfaceElevatedOf(this);
  Color get textPrimaryColor => AppDesign.textPrimaryOf(this);
  Color get textSecondaryColor => AppDesign.textSecondaryOf(this);
  Color get textTertiaryColor => AppDesign.textTertiaryOf(this);
  Color get borderColor => AppDesign.borderOf(this);
}
