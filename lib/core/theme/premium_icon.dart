import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A custom widget to render Heroicons with standard premium styling.
class PremiumIcon extends StatelessWidget {
  final String svgPath;
  final double size;
  final Color? color;

  const PremiumIcon({
    super.key,
    required this.svgPath,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Default color is Slate 800 (0xFF1E293B) if not provided.
    final iconColor = color ?? const Color(0xFF1E293B);

    return SvgPicture.string(
      svgPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
