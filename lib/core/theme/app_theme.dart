import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_design.dart';

/// AppTheme defines modern Material 3 theme configurations for both
/// Light and Dark modes conforming to Android edge-to-edge guidelines.
class AppTheme {
  /// Light Theme Configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppDesign.primary,
      onPrimary: Colors.white,
      secondary: AppDesign.secondary,
      onSecondary: Colors.white,
      error: AppDesign.error,
      onError: Colors.white,
      surface: AppDesign.surfaceElevated,
      onSurface: AppDesign.textPrimary,
      surfaceContainerLowest: AppDesign.surfaceElevated,
      surfaceContainerLow: AppDesign.surface,
      surfaceContainer: AppDesign.surface,
      surfaceContainerHigh: Color(0xFFF1F5F9),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      outline: AppDesign.borderDefault,
      outlineVariant: Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDesign.surface,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppDesign.textPrimary,
        displayColor: AppDesign.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesign.surfaceElevated,
        foregroundColor: AppDesign.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppDesign.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppDesign.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
          side: const BorderSide(color: AppDesign.borderDefault),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDesign.surfaceElevated,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesign.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesign.cardBorderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppDesign.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDesign.borderDefault,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
            ),
          ),
        ),
      ),
    );
  }

  /// Dark Theme Configuration (Standard Material 3 Neutral Charcoal)
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppDesign.primaryDark,
      onPrimary: Colors.white,
      secondary: AppDesign.secondaryDark,
      onSecondary: Colors.white,
      error: AppDesign.errorDark,
      onError: Colors.white,
      surface: AppDesign.darkSurfaceElevated,
      onSurface: AppDesign.darkTextPrimary,
      surfaceContainerLowest: Color(0xFF0D0D0D),
      surfaceContainerLow: AppDesign.darkSurface,
      surfaceContainer: AppDesign.darkSurfaceElevated,
      surfaceContainerHigh: AppDesign.darkSurfaceContainerHigh,
      surfaceContainerHighest: Color(0xFF333333),
      outline: AppDesign.darkBorderDefault,
      outlineVariant: Color(0xFF383838),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDesign.darkSurface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppDesign.darkTextPrimary,
        displayColor: AppDesign.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesign.darkSurfaceElevated,
        foregroundColor: AppDesign.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppDesign.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppDesign.darkSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
          side: const BorderSide(color: AppDesign.darkBorderDefault),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDesign.darkSurfaceElevated,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDesign.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDesign.cardBorderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppDesign.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDesign.darkBorderDefault,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDesign.darkSurfaceElevated,
        contentTextStyle: GoogleFonts.outfit(
          color: AppDesign.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
          side: const BorderSide(color: AppDesign.darkBorderDefault),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the corresponding edge-to-edge SystemUiOverlayStyle for a given Brightness
  static SystemUiOverlayStyle getSystemUiOverlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
}
