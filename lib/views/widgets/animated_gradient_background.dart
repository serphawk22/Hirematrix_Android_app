import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> {
  @override
  Widget build(BuildContext context) {
    // Dynamically calculate light and subtle colors/opacities for the background circles
    final Color purpleCircleColor = widget.isDark
        ? const Color(0xFFAC75FF).withOpacity(0.12)
        : const Color(0xFFE9D5FF).withOpacity(0.35);

    final Color purpleShadowColor = widget.isDark
        ? const Color(0xFFAC75FF).withOpacity(0.08)
        : const Color(0xFFE9D5FF).withOpacity(0.20);

    final Color blueCircleColor = widget.isDark
        ? const Color(0xFF6B95FF).withOpacity(0.12)
        : const Color(0xFFDBE6FF).withOpacity(0.35);

    final Color blueShadowColor = widget.isDark
        ? const Color(0xFF6B95FF).withOpacity(0.08)
        : const Color(0xFFDBE6FF).withOpacity(0.20);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [
                  AppColors.getBackground(widget.isDark),
                  const Color(0xFF1E1B4B),
                  AppColors.getBackground(widget.isDark),
                  const Color(0xFF111827),
                  AppColors.getBackground(widget.isDark),
                ]
              : [
                  const Color(0xFFDBE6FF),
                  const Color(0xFFEEF2FF),
                  const Color(0xFFFCEFE6),
                  const Color(0xFFFBC5AF),
                  const Color(0xFFDBE6FF),
                ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          transform: const GradientRotation(1.2),
        ),
      ),
      child: Stack(
        children: [
          // Static background blobs
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purpleCircleColor,
                boxShadow: [
                  BoxShadow(
                    color: purpleShadowColor,
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blueCircleColor,
                boxShadow: [
                  BoxShadow(
                    color: blueShadowColor,
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
