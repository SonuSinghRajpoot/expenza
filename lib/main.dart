import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_design.dart';
import 'core/theme/app_text_styles.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/sharing_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FieldExpenseApp()));
}

class FieldExpenseApp extends StatelessWidget {
  const FieldExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDesign.primary,
          primary: AppDesign.primary,
          secondary: AppDesign.secondary,
          surface: AppDesign.surfaceElevated,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: AppDesign.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: AppDesign.surfaceElevated,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTextStyles.headline2,
          iconTheme: const IconThemeData(color: AppDesign.textPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
            side: const BorderSide(color: AppDesign.borderDefault),
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
      ),
      home: const SharingListener(child: MainNavigationScreen()),
    );
  }
}
