import 'package:flutter/material.dart';
import 'dashboard/expenses_list_screen.dart';
import 'profile/profile_screen.dart';
import '../core/theme/app_design.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/premium_icon.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = AppDesign.textTertiaryOf(context);
    final bgColor = AppDesign.surfaceElevatedOf(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          ExpensesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppDesign.borderOf(context),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: bgColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: unselectedColor,
          selectedLabelStyle: AppTextStyles.bodySmallOf(context).copyWith(
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          unselectedLabelStyle: AppTextStyles.bodySmallOf(context).copyWith(
            fontWeight: FontWeight.w500,
            color: unselectedColor,
          ),
          items: [
            BottomNavigationBarItem(
              icon: PremiumIcon(
                svgPath: AppIcons.expenses,
                color: unselectedColor,
              ),
              activeIcon: PremiumIcon(
                svgPath: AppIcons.expenses,
                color: primaryColor,
              ),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: PremiumIcon(
                svgPath: AppIcons.account,
                color: unselectedColor,
              ),
              activeIcon: PremiumIcon(
                svgPath: AppIcons.account,
                color: primaryColor,
              ),
              label: 'Accounts',
            ),
          ],
        ),
      ),
    );
  }
}
