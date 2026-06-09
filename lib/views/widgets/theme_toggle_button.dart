import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDark;

  const ThemeToggleButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isDark ? Icons.wb_sunny : Icons.nights_stay,
          size: 20,
          color: isDark ? Colors.white : AppColors.getPrimary(isDark),
        ),
        onPressed: () => themeController.toggleTheme(),
        style: IconButton.styleFrom(shape: const CircleBorder()),
      ),
    );
  }
}
