import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final LinearGradient gradient;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.borderWidth = 1.5,
    this.borderRadius = 20,
    this.gradient = AppColors.gradientH,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius + borderWidth),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
