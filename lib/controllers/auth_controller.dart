import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hirematrix/controllers/notification_controller.dart';

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

  @override
  void onClose() {
    super.onClose();
  }

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
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            'Login successful!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          final user = data['data']['user'];
          currentUser.value = user;
          await saveUserSession(user);
          
          if (user['role'] == 'candidate' && user['onboarding_completed'] == 0) {
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
          
          if (user['onboarding_completed'] == 0) {
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
  final recruiterNameController = TextEditingController();
  final designationController = TextEditingController();
  final recruiterEmailController = TextEditingController();
  final recruiterPhoneController = TextEditingController();
  final recruiterPasswordController = TextEditingController();
  final recruiterConfirmPasswordController = TextEditingController();

  // Recruiter Error Observables
  final companyNameError = ''.obs;
  final recruiterNameError = ''.obs;
  final designationError = ''.obs;
  final recruiterEmailError = ''.obs;
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

  bool isValidCompanyEmail(String email) {
    // Block free email providers
    final freeProviders = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'aol.com',
      'icloud.com',
      'mail.com',
      'protonmail.com',
      'zoho.com',
      'yandex.com',
      'gmx.com',
      'tutanota.com',
    ];

    final emailDomain = email.split('@').last.toLowerCase();
    return !freeProviders.contains(emailDomain);
  }

  void validateRecruiterRegistration() {
    // Reset errors
    companyNameError.value = '';
    recruiterNameError.value = '';
    designationError.value = '';
    recruiterEmailError.value = '';
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

    // Validate Email
    if (recruiterEmailController.text.trim().isEmpty) {
      recruiterEmailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(recruiterEmailController.text.trim())) {
      recruiterEmailError.value = 'Please enter a valid email address';
      isValid = false;
    } else if (!isValidCompanyEmail(recruiterEmailController.text.trim())) {
      recruiterEmailError.value =
          'Please use a company domain email (free providers are blocked)';
      isValid = false;
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;

    // Show success message
    Get.snackbar(
      'Success',
      'Recruiter registration successful! Please login.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Clear form
    companyNameController.clear();
    recruiterNameController.clear();
    designationController.clear();
    recruiterEmailController.clear();
    recruiterPhoneController.clear();
    recruiterPasswordController.clear();
    recruiterConfirmPasswordController.clear();

    // Navigate to login
    Get.offAllNamed('/login');
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
