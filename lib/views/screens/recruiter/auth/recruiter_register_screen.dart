import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class RecruiterRegisterScreen extends StatelessWidget {
  const RecruiterRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return Scaffold(
        backgroundColor: isDark
            ? AppColors.getBackground(isDark)
            : Colors.white,
        body: SafeArea(
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
      );
    });
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
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
        Text(
          'Create Recruiter Account',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create your recruiter account to \npost jobs and manage applications.',
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
                    color: isDark ? const Color(0xFF111111) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF23343A)
                          : const Color(0xFFD9ECE5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          _buildCompanyNameField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildRecruiterTypeField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildRecruiterNameField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildDesignationField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildEmailField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildOfficialEmailField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildWebsiteField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildAgencyRegistrationNumberField(
                            authController,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildGstNumberField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildPhoneField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildPasswordField(authController, isDark),
                          const SizedBox(height: 20),
                          _buildConfirmPasswordField(authController, isDark),
                          const SizedBox(height: 24),
                          _buildRegisterButton(authController, isDark),
                        ],
                      ),
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

  Widget _buildFieldTemplate({
    required String label,
    required IconData icon,
    required Widget child,
    required bool isDark,
    String? hintText,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null && errorText.isNotEmpty
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
                  icon,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        if (hintText != null && hintText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              hintText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildCompanyNameField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Company Name',
        icon: Icons.business_outlined,
        isDark: isDark,
        errorText: authController.companyNameError.value,
        child: _buildTextField(
          authController.companyNameController,
          'Your company name',
          isDark,
        ),
      ),
    );
  }

  Widget _buildRecruiterTypeField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Recruiter Type',
        icon: Icons.work_outline,
        isDark: isDark,
        hintText:
            'Consultancy accounts can register here, but job posting starts after admin verification.',
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: authController.recruiterType.value,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                authController.recruiterType.value = newValue;
              }
            },
            items: [
              DropdownMenuItem(
                value: 'direct_employer',
                child: Text('Direct employer'),
              ),
              DropdownMenuItem(
                value: 'consultancy',
                child: Text('Consultancy / staffing agency'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecruiterNameField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Recruiter Name',
        icon: Icons.person_outline,
        isDark: isDark,
        errorText: authController.recruiterNameError.value,
        child: _buildTextField(
          authController.recruiterNameController,
          'Your full name',
          isDark,
        ),
      ),
    );
  }

  Widget _buildDesignationField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Designation',
        icon: Icons.badge_outlined,
        isDark: isDark,
        errorText: authController.designationError.value,
        child: _buildTextField(
          authController.designationController,
          'e.g., Talent Acquisition Specialist',
          isDark,
        ),
      ),
    );
  }

  Widget _buildEmailField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Email Address',
        icon: Icons.email_outlined,
        isDark: isDark,
        hintText: 'Enter your email address to receive a verification code.',
        errorText: authController.recruiterEmailError.value,
        child: _buildTextField(
          authController.recruiterEmailController,
          'you@example.com',
          isDark,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
  }

  Widget _buildOfficialEmailField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Official Verification Email',
        icon: Icons.alternate_email_outlined,
        isDark: isDark,
        hintText: 'Leave blank to use the login email above.',
        errorText: authController.officialEmailError.value,
        child: _buildTextField(
          authController.officialEmailController,
          'verification@company.com',
          isDark,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
  }

  Widget _buildWebsiteField(AuthController authController, bool isDark) {
    return _buildFieldTemplate(
      label: 'Website',
      icon: Icons.language_outlined,
      isDark: isDark,
      child: _buildTextField(
        authController.websiteController,
        'https://company.com',
        isDark,
        keyboardType: TextInputType.url,
      ),
    );
  }

  Widget _buildAgencyRegistrationNumberField(
    AuthController authController,
    bool isDark,
  ) {
    return _buildFieldTemplate(
      label: 'Agency Registration Number',
      icon: Icons.verified_user_outlined,
      isDark: isDark,
      child: _buildTextField(
        authController.agencyRegistrationNumberController,
        'Required for consultancies if available',
        isDark,
      ),
    );
  }

  Widget _buildGstNumberField(AuthController authController, bool isDark) {
    return _buildFieldTemplate(
      label: 'GST Number',
      icon: Icons.receipt_long_outlined,
      isDark: isDark,
      child: _buildTextField(
        authController.gstNumberController,
        'GSTIN',
        isDark,
      ),
    );
  }

  Widget _buildPhoneField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Phone Number',
        icon: Icons.phone_outlined,
        isDark: isDark,
        errorText: authController.recruiterPhoneError.value,
        child: _buildTextField(
          authController.recruiterPhoneController,
          'Phone number',
          isDark,
          keyboardType: TextInputType.phone,
        ),
      ),
    );
  }

  Widget _buildPasswordField(AuthController authController, bool isDark) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Password',
        icon: Icons.lock_outline,
        isDark: isDark,
        errorText: authController.recruiterPasswordError.value,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: authController.recruiterPasswordController,
                obscureText: !authController.isRecruiterPasswordVisible.value,
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
              onPressed: () =>
                  authController.toggleRecruiterPasswordVisibility(),
              icon: Icon(
                authController.isRecruiterPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 20,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(
    AuthController authController,
    bool isDark,
  ) {
    return Obx(
      () => _buildFieldTemplate(
        label: 'Re-Type Password',
        icon: Icons.lock_outline,
        isDark: isDark,
        errorText: authController.recruiterConfirmPasswordError.value,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: authController.recruiterConfirmPasswordController,
                obscureText:
                    !authController.isRecruiterConfirmPasswordVisible.value,
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
                  authController.toggleRecruiterConfirmPasswordVisibility(),
              icon: Icon(
                authController.isRecruiterConfirmPasswordVisible.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 20,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(AuthController authController, bool isDark) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: authController.isLoading.value
              ? null
              : () => authController.validateRecruiterRegistration(),
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
                  'Register as Recruiter',
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
