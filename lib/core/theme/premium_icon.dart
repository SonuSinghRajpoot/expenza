import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_design.dart';

/// A custom widget to render Heroicons with standard premium styling in Light and Dark modes.
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
    // Dynamic color fallback: adapts to ambient theme or textPrimaryOf(context)
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? AppDesign.textPrimaryOf(context);

    return SvgPicture.string(
      svgPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
