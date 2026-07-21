import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hirematrix/controllers/notification_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthController extends GetxController {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final forgotPasswordEmailController = TextEditingController();
  final resetCodeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  // Observables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmNewPasswordVisible = false.obs;
  final rememberMe = false.obs;
  final currentUser = {}.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> saveUserSession(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user));
    } catch (e) {
      // ignore
    }
  }

  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      currentUser.value = {};
      
      // Clear login controllers so they don't auto-fill with previous credentials
      emailController.clear();
      passwordController.clear();

      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().clearNotifications();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> signInWithEmail() async {
    if (emailController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isSuccess = data['status'] == 'success' || data['success'] == true;

        if (isSuccess) {
          Get.snackbar(
            'Success',
            'Login successful!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          Map<String, dynamic> user;
          String token;
          
          if (data['recruiter'] != null) {
            // Recruiter login response format
            final recruiter = data['recruiter'];
            user = {
              'id': recruiter['id'],
              'full_name': recruiter['full_name'] ?? '',
              'name': recruiter['full_name'] ?? '', // for candidate profile usage in shared screens
              'email': recruiter['email'] ?? '',
              'phone': recruiter['phone'] ?? '',
              'designation': recruiter['designation'] ?? '',
              'company_id': recruiter['company_id'] ?? '',
              'company_name': recruiter['company_name'] ?? '',
              'company_logo': recruiter['company_logo'] ?? '',
              'account_type': recruiter['account_type'] ?? 'basic',
              'role': 'recruiter',
            };
            token = data['token']?.toString() ?? 'mock_token';
          } else {
            // Candidate login response format
            user = data['data']['user'];
            token = data['data']?['token']?.toString() ?? user['token']?.toString() ?? 'mock_token';
          }
          
          currentUser.value = user;
          await saveUserSession(user);
          
          if (user['role'] == 'recruiter') {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('recruiterId', user['id'].toString());
              await prefs.setString('recruiterData', jsonEncode(user));

              const storage = FlutterSecureStorage();
              await storage.write(key: 'session_token', value: token);
              await storage.write(key: 'session_token_${user['id']}', value: token);
            } catch (e) {
              debugPrint("Error saving recruiter provider session: $e");
            }
            Get.offAllNamed(AppRoutes.recruiterDashboard);
          } else if (user['role'] == 'candidate' && user['onboarding_completed'] == 0) {
             Get.offAllNamed(AppRoutes.onboarding, arguments: {
               'user_id': int.tryParse(user['id'].toString()) ?? 0,
               'name': user['name'] ?? '',
               'phone': user['phone'] ?? '',
               'onboarding_step': user['onboarding_step'] ?? 'personal',
             });
          } else {
             Get.offAllNamed(AppRoutes.dashboard);
          }
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Login failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['messages']?.values?.first ?? data['message'] ?? 'Login failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _processGoogleAuth() async {
    isLoading.value = true;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '627294850313-m0va1nooqoiei9jv5uom0d809rtgbq6i.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        isLoading.value = false;
        return; // User cancelled the sign-in
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/google-login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'google_id': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName ?? '',
          'picture': googleUser.photoUrl ?? '',
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            'Google Sign-In successful!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          final user = data['data']['user'];
          currentUser.value = user;
          await saveUserSession(user);
          
          if (user['role'] == 'recruiter') {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('recruiterId', user['id'].toString());
              await prefs.setString('recruiterData', jsonEncode(user));

              final token = data['data']?['token']?.toString() ?? user['token']?.toString() ?? 'mock_token';
              const storage = FlutterSecureStorage();
              await storage.write(key: 'session_token', value: token);
              await storage.write(key: 'session_token_${user['id']}', value: token);
            } catch (e) {
              debugPrint("Error saving recruiter provider session: $e");
            }
            Get.offAllNamed(AppRoutes.recruiterDashboard);
          } else if (user['role'] == 'candidate' && user['onboarding_completed'] == 0) {
             Get.offAllNamed(AppRoutes.onboarding, arguments: {
               'user_id': int.tryParse(user['id'].toString()) ?? 0,
               'name': user['name'] ?? '',
               'phone': user['phone'] ?? '',
               'onboarding_step': user['onboarding_step'] ?? 'personal',
             });
          } else {
             Get.offAllNamed(AppRoutes.dashboard);
          }
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Google Sign-In failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        String errMsg = 'Google Sign-In failed';
        try {
          final data = jsonDecode(response.body);
          errMsg = data['messages']?.values?.first ?? data['message'] ?? errMsg;
        } catch (_) {}
        Get.snackbar(
          'Error',
          errMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Google Sign-In failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    await _processGoogleAuth();
  }

  // Add these controllers for registration
  final nameController = TextEditingController();
  final regEmailController = TextEditingController();
  final phoneController = TextEditingController();
  final regPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Add these observables
  final nameError = ''.obs;
  final emailError = ''.obs;
  final phoneError = ''.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;
  final isRegPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Add these methods
  void toggleRegPasswordVisibility() {
    isRegPasswordVisible.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.toggle();
  }

  void validateRegistration() {
    nameError.value = '';
    emailError.value = '';
    phoneError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';

    bool isValid = true;

    if (nameController.text.trim().isEmpty) {
      nameError.value = 'Full name is required';
      isValid = false;
    }

    if (regEmailController.text.trim().isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(regEmailController.text.trim())) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    if (phoneController.text.trim().isEmpty) {
      phoneError.value = 'Phone number is required';
      isValid = false;
    }

    if (regPasswordController.text.isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    } else if (regPasswordController.text.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    }

    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    } else if (regPasswordController.text != confirmPasswordController.text) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    if (isValid) {
      registerWithEmail();
    }
  }

  Future<void> registerWithEmail() async {
    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': regEmailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': regPasswordController.text,
          'confirm_password': confirmPasswordController.text,
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Welcome to HireMatrix!',
            'Account created. Let\'s set up your profile.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          // Clear registration controllers
          regEmailController.clear();
          regPasswordController.clear();
          confirmPasswordController.clear();
          nameController.clear();
          phoneController.clear();
          
          // Clear login controllers to avoid auto-filling previous credentials
          emailController.clear();
          passwordController.clear();

          // Navigate to login after registration
          Get.offAllNamed(AppRoutes.login);
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Registration failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['messages']?.values?.first ?? data['message'] ?? 'Registration failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> registerWithGoogle() async {
    await _processGoogleAuth();
  }

  // Recruiter Registration Controllers
  final companyNameController = TextEditingController();
  final recruiterType = 'direct_employer'.obs;
  final recruiterNameController = TextEditingController();
  final designationController = TextEditingController();
  final recruiterEmailController = TextEditingController();
  final officialEmailController = TextEditingController();
  final websiteController = TextEditingController();
  final agencyRegistrationNumberController = TextEditingController();
  final gstNumberController = TextEditingController();
  final recruiterPhoneController = TextEditingController();
  final recruiterPasswordController = TextEditingController();
  final recruiterConfirmPasswordController = TextEditingController();

  // Recruiter Error Observables
  final companyNameError = ''.obs;
  final recruiterNameError = ''.obs;
  final designationError = ''.obs;
  final recruiterEmailError = ''.obs;
  final officialEmailError = ''.obs;
  final recruiterPhoneError = ''.obs;
  final recruiterPasswordError = ''.obs;
  final recruiterConfirmPasswordError = ''.obs;

  // Recruiter Password Visibility
  final isRecruiterPasswordVisible = false.obs;
  final isRecruiterConfirmPasswordVisible = false.obs;

  // Recruiter Methods
  void toggleRecruiterPasswordVisibility() {
    isRecruiterPasswordVisible.toggle();
  }

  void toggleRecruiterConfirmPasswordVisibility() {
    isRecruiterConfirmPasswordVisible.toggle();
  }

  void validateRecruiterRegistration() {
    // Reset errors
    companyNameError.value = '';
    recruiterNameError.value = '';
    designationError.value = '';
    recruiterEmailError.value = '';
    officialEmailError.value = '';
    recruiterPhoneError.value = '';
    recruiterPasswordError.value = '';
    recruiterConfirmPasswordError.value = '';

    bool isValid = true;

    // Validate Company Name
    if (companyNameController.text.trim().isEmpty) {
      companyNameError.value = 'Company name is required';
      isValid = false;
    }

    // Validate Recruiter Name
    if (recruiterNameController.text.trim().isEmpty) {
      recruiterNameError.value = 'Recruiter name is required';
      isValid = false;
    }

    // Validate Designation
    if (designationController.text.trim().isEmpty) {
      designationError.value = 'Designation is required';
      isValid = false;
    }

    // Validate Email (free emails allowed in mobile app)
    if (recruiterEmailController.text.trim().isEmpty) {
      recruiterEmailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(recruiterEmailController.text.trim())) {
      recruiterEmailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    if (officialEmailController.text.trim().isNotEmpty) {
      if (!GetUtils.isEmail(officialEmailController.text.trim())) {
        officialEmailError.value = 'Please enter a valid official email address';
        isValid = false;
      }
    }

    // Validate Phone
    if (recruiterPhoneController.text.trim().isEmpty) {
      recruiterPhoneError.value = 'Phone number is required';
      isValid = false;
    }

    // Validate Password
    if (recruiterPasswordController.text.isEmpty) {
      recruiterPasswordError.value = 'Password is required';
      isValid = false;
    } else if (recruiterPasswordController.text.length < 6) {
      recruiterPasswordError.value = 'Password must be at least 6 characters';
      isValid = false;
    }

    // Validate Confirm Password
    if (recruiterConfirmPasswordController.text.isEmpty) {
      recruiterConfirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    } else if (recruiterPasswordController.text !=
        recruiterConfirmPasswordController.text) {
      recruiterConfirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    if (isValid) {
      registerRecruiter();
    }
  }

  Future<void> registerRecruiter() async {
    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/recruiter/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'company_name': companyNameController.text.trim(),
          'recruiter_type': recruiterType.value,
          'name': recruiterNameController.text.trim(),
          'designation': designationController.text.trim(),
          'email': recruiterEmailController.text.trim(),
          'official_email': officialEmailController.text.trim(),
          'website': websiteController.text.trim(),
          'agency_registration_number': agencyRegistrationNumberController.text.trim(),
          'gst_number': gstNumberController.text.trim(),
          'phone': recruiterPhoneController.text.trim(),
          'password': recruiterPasswordController.text,
          'confirm_password': recruiterConfirmPasswordController.text,
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final userId = data['data']?['user_id']?.toString() ?? '';
          final email = recruiterEmailController.text.trim();

          // Clear form
          companyNameController.clear();
          recruiterType.value = 'direct_employer';
          recruiterNameController.clear();
          designationController.clear();
          recruiterEmailController.clear();
          officialEmailController.clear();
          websiteController.clear();
          agencyRegistrationNumberController.clear();
          gstNumberController.clear();
          recruiterPhoneController.clear();
          recruiterPasswordController.clear();
          recruiterConfirmPasswordController.clear();
          
          // Clear login controllers to avoid auto-filling previous credentials
          emailController.clear();
          passwordController.clear();

          // Navigate to verification screen
          Get.offAllNamed(
            '/recruiter/verify',
            arguments: {'user_id': userId, 'email': email},
          );
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Registration failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['messages']?.values?.first ?? data['message'] ?? 'Registration failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Email OTP verification state for recruiter
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final isVerifying = false.obs;
  final isResending = false.obs;

  Future<void> verifyRecruiterEmailOtp(String userId, String otp) async {
    if (otp.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter the complete 6-digit code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isVerifying.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/recruiter/verify-email'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'user_id': userId, 'token': otp}),
      );

      isVerifying.value = false;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar(
          'Email Verified!',
          'Your recruiter account is now active. Please login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.offAllNamed('/login');
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'Invalid or expired verification code',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resendRecruiterVerificationEmail(String userId) async {
    isResending.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/recruiter/resend-verification'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      isResending.value = false;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar(
          'Email Sent',
          'A new verification code has been sent to your email.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'Failed to resend verification email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isResending.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> sendForgotPasswordEmail() async {
    final email = forgotPasswordEmailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/forgot-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            'Verification code sent to your email successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          // Navigate to Reset Password Screen, passing email as argument
          Get.toNamed(AppRoutes.resetPassword, arguments: email);
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Failed to send reset link',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['messages']?.values?.first ?? data['message'] ?? 'Failed to send reset link',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    final code = resetCodeController.text.trim();
    final password = newPasswordController.text;
    final confirmPassword = confirmNewPasswordController.text;

    if (code.isEmpty || code.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter the 6-digit verification code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a new password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': code,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            'Password reset successfully! Please log in.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          // Clear all controllers
          resetCodeController.clear();
          newPasswordController.clear();
          confirmNewPasswordController.clear();
          forgotPasswordEmailController.clear();
          
          // Navigate to Login Screen
          Get.offAllNamed(AppRoutes.login);
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Failed to reset password',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['messages']?.values?.first ?? data['message'] ?? 'Failed to reset password',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
