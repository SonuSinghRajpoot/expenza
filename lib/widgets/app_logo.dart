import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_design.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool? isDarkMode;

  const AppLogo({
    super.key,
    this.size = 48,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode ?? AppDesign.isDark(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF6366F1).withValues(alpha: 0.2),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: SvgPicture.asset(
          dark ? 'assets/icons/app_logo_dark.svg' : 'assets/icons/app_logo_light.svg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
