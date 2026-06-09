import 'package:flutter/material.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/widgets/animated_gradient_background.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final String email = Get.arguments as String? ?? '';

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return Scaffold(
        body: AnimatedGradientBackground(
          isDark: isDark,
          child: SafeArea(
            child: Stack(
              children: [
                // Back Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        _buildHeader(email, isDark),
                        const SizedBox(height: 32),
                        _buildResetCard(authController, email, isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(String email, bool isDark) {
    return Column(
      children: [
        // Security Key Icon Design
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security_outlined,
            size: 64,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose New Password',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Enter the 6-digit code sent to\n$email",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetCard(
    AuthController authController,
    String email,
    bool isDark,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1A1A2E).withOpacity(0.6),
                              const Color(0xFF16213E).withOpacity(0.6),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Inner light effect
                        Positioned(
                          top: -50,
                          left: -50,
                          width: 200,
                          height: 200,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Reset Code Field
                              Text(
                                'Verification Code',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        Icons.pin_outlined,
                                        size: 20,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[500],
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            authController.resetCodeController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '123456',
                                          counterText: '',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey[400],
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 2. New Password Field
                              Text(
                                'New Password',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey[500],
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: authController
                                              .newPasswordController,
                                          obscureText: !authController
                                              .isNewPasswordVisible
                                              .value,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '••••••',
                                            hintStyle: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey[400],
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => authController
                                            .isNewPasswordVisible
                                            .toggle(),
                                        icon: Icon(
                                          authController
                                                  .isNewPasswordVisible
                                                  .value
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 3. Confirm Password Field
                              Text(
                                'Confirm New Password',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey[500],
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: authController
                                              .confirmNewPasswordController,
                                          obscureText: !authController
                                              .isConfirmNewPasswordVisible
                                              .value,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '••••••',
                                            hintStyle: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey[400],
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => authController
                                            .isConfirmNewPasswordVisible
                                            .toggle(),
                                        icon: Icon(
                                          authController
                                                  .isConfirmNewPasswordVisible
                                                  .value
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Reset Password Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authController.isLoading.value
                                      ? null
                                      : () =>
                                            authController.resetPassword(email),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: AppColors.getPrimary(
                                      isDark,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authController.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Reset Password',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
