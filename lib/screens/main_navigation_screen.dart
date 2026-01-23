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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppDesign.surfaceElevated,
          selectedItemColor: AppDesign.primary,
          unselectedItemColor: AppDesign.textTertiary,
          selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: PremiumIcon(
                svgPath: AppIcons.expenses,
                color: AppDesign.textTertiary,
              ),
              activeIcon: PremiumIcon(
                svgPath: AppIcons.expenses,
                color: AppDesign.primary,
              ),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: PremiumIcon(
                svgPath: AppIcons.account,
                color: AppDesign.textTertiary,
              ),
              activeIcon: PremiumIcon(
                svgPath: AppIcons.account,
                color: AppDesign.primary,
              ),
              label: 'Accounts',
            ),
          ],
        ),
      ),
    );
  }
}
