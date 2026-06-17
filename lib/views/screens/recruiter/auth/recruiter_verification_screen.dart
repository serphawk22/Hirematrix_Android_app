import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/core/constants/app_colors.dart';

class RecruiterVerificationScreen extends StatefulWidget {
  const RecruiterVerificationScreen({super.key});

  @override
  State<RecruiterVerificationScreen> createState() =>
      _RecruiterVerificationScreenState();
}

class _RecruiterVerificationScreenState
    extends State<RecruiterVerificationScreen> {
  late final AuthController _authController;
  late final ThemeController _themeController;

  // 6 OTP input controllers and focus nodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _userId;
  late String _email;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _themeController = Get.find<ThemeController>();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _userId = args['user_id']?.toString() ?? '';
    _email = args['email']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp =>
      _otpControllers.map((c) => c.text.trim()).join();

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onOtpPasted(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _otpControllers[i].text = digits[i];
    }
    if (digits.length >= 6) {
      _focusNodes[5].requestFocus();
    } else if (digits.isNotEmpty) {
      _focusNodes[digits.length.clamp(0, 5)].requestFocus();
    }
    setState(() {});
  }

  void _submit() {
    _authController.verifyRecruiterEmailOtp(_userId, _otp);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _themeController.isDarkMode;

      return Scaffold(
        backgroundColor: isDark ? AppColors.getBackground(isDark) : Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo / Brand
                      Text(
                        'HireMatrix',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(isDark).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 38,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'Verify Your Email',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We sent a 6-digit verification code to',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email.isNotEmpty ? _email : 'your email address',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // OTP card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111111) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF23343A)
                                : const Color(0xFFD9ECE5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              'Enter Verification Code',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the 6-digit code sent to your email address.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // OTP boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (i) {
                                return _OtpBox(
                                  controller: _otpControllers[i],
                                  focusNode: _focusNodes[i],
                                  isDark: isDark,
                                  onChanged: (v) => _onOtpChanged(i, v),
                                  onPaste: _onOtpPasted,
                                );
                              }),
                            ),
                            const SizedBox(height: 28),

                            // Verify button
                            Obx(() => SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_authController.isVerifying.value || _otp.length != 6)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppColors.getPrimary(isDark),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _authController.isVerifying.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Verify Account',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            )),

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey[200])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    "Didn't receive the code?",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey[200])),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Resend button
                            Obx(() => TextButton.icon(
                              onPressed: _authController.isResending.value
                                  ? null
                                  : () => _authController.resendRecruiterVerificationEmail(_userId),
                              icon: _authController.isResending.value
                                  ? SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(isDark)),
                                      ),
                                    )
                                  : Icon(Icons.refresh_rounded, size: 16, color: AppColors.getPrimary(isDark)),
                              label: Text(
                                'Resend Verification Email',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already verified?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.offAllNamed('/login'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Individual OTP box widget
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPaste;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onChanged,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: controller.text.isNotEmpty
                  ? AppColors.getPrimary(isDark)
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
              width: controller.text.isNotEmpty ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.getPrimary(isDark),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
        onChanged: onChanged,
        onTap: () {
          // Select all on tap so typing replaces current digit
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
      ),
    );
  }
}
