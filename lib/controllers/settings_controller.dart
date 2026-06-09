import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';

class SettingsController extends GetxController {
  final isLoading = false.obs;

  late final DashboardController _dashController;
  late final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    _dashController = Get.find<DashboardController>();
    _authController = Get.find<AuthController>();
  }

  Future<void> updateSettingField(String field, bool value) async {
    final userId = _authController.currentUser['id'];
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile/update_settings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'user_id': userId, field: value ? 1 : 0}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            'Settings updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar('Error', data['message'] ?? 'Failed to update setting');
        }
      } else {
        Get.snackbar('Error', 'Server error. Please try again.');
      }
    } catch (_) {
      Get.snackbar('Connection Error', 'Could not sync settings to server');
    } finally {
      // Re-fetch data to sync latest true state
      await _dashController.fetchDashboardData();
      isLoading.value = false;
    }
  }

  Future<bool> handlePasswordChange({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final userId = _authController.currentUser['id'];
    if (userId == null) return false;

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar(
          'Success',
          'Password updated successfully. Please log in with your new password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Log out the user and navigate to login screen
        await _authController.clearUserSession();
        Get.offAllNamed(AppRoutes.login);
        return true;
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'Failed to change password',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Connection Error',
        'Could not connect to update password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
    return false;
  }
}
