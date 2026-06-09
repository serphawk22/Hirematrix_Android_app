import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/widgets/animated_gradient_background.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return Scaffold(
        body: AnimatedGradientBackground(
          isDark: isDark,
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(isDark),
                    const SizedBox(height: 32),
                    _buildRegisterCard(authController, isDark),
                    const SizedBox(height: 24),
                    _buildFooter(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Logo and Brand
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HireMatrix',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Create Candidate Account',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Join HireMatrix and build your profile to start applying for jobs.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(AuthController authController, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
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
                            children: [
                              // Google Sign Up Button
                              _buildGoogleButton(authController, isDark),
                              const SizedBox(height: 24),

                              // Divider
                              _buildDivider(isDark),
                              const SizedBox(height: 24),

                              // Full Name Field
                              _buildFullNameField(authController, isDark),
                              const SizedBox(height: 20),

                              // Email Field
                              _buildEmailField(authController, isDark),
                              const SizedBox(height: 20),

                              // Phone Field
                              _buildPhoneField(authController, isDark),
                              const SizedBox(height: 20),

                              // Password Field
                              _buildPasswordField(authController, isDark),
                              const SizedBox(height: 20),

                              // Confirm Password Field
                              _buildConfirmPasswordField(
                                authController,
                                isDark,
                              ),
                              const SizedBox(height: 24),

                              // Sign Up Button
                              _buildSignUpButton(authController, isDark),
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

  Widget _buildGoogleButton(AuthController authController, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => authController.registerWithGoogle(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey[300]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleIcon(),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.g_mobiledata, size: 20);
        },
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildFullNameField(AuthController authController, bool isDark) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Name',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authController.nameError.value.isNotEmpty
                    ? Colors.red
                    : (isDark ? Colors.white24 : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: authController.nameController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your full name',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (authController.nameError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                authController.nameError.value,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailField(AuthController authController, bool isDark) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Address',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authController.emailError.value.isNotEmpty
                    ? Colors.red
                    : (isDark ? Colors.white24 : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: authController.regEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (authController.emailError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                authController.emailError.value,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(AuthController authController, bool isDark) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authController.phoneError.value.isNotEmpty
                    ? Colors.red
                    : (isDark ? Colors.white24 : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: authController.phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your phone number',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (authController.phoneError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                authController.phoneError.value,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(AuthController authController, bool isDark) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authController.passwordError.value.isNotEmpty
                    ? Colors.red
                    : (isDark ? Colors.white24 : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: authController.regPasswordController,
                    obscureText: !authController.isRegPasswordVisible.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => authController.toggleRegPasswordVisibility(),
                  icon: Icon(
                    authController.isRegPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (authController.passwordError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                authController.passwordError.value,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(
    AuthController authController,
    bool isDark,
  ) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Re-Type Password',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authController.confirmPasswordError.value.isNotEmpty
                    ? Colors.red
                    : (isDark ? Colors.white24 : Colors.grey[200]!),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: authController.confirmPasswordController,
                    obscureText: !authController.isConfirmPasswordVisible.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Re-type password',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      authController.toggleConfirmPasswordVisibility(),
                  icon: Icon(
                    authController.isConfirmPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (authController.confirmPasswordError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                authController.confirmPasswordError.value,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(AuthController authController, bool isDark) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: authController.isLoading.value
              ? null
              : () => authController.registerWithEmail(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.getPrimary(isDark),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        TextButton(
          onPressed: () => Get.toNamed('/login'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Login',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.getPrimary(isDark),
            ),
          ),
        ),
      ],
    );
  }
}
