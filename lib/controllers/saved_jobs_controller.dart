import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';

class SavedJobsController extends GetxController {
  final isLoading = false.obs;
  final savedJobsList = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavedJobs();
  }

  Future<void> fetchSavedJobs() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/jobs/saved/$userId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          savedJobsList.assignAll(data['data'] ?? []);
        }
      }
    } catch (_) {
      Get.snackbar(
        'Connection Error',
        'Could not fetch saved jobs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleUnsaveJob(int jobId, bool isExternal) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/jobs/unsave'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': userId,
          'job_id': jobId,
          'is_external': isExternal,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Removed',
            'Job removed from shortlist',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
          await fetchSavedJobs();
          // Update dashboard count or lists
          try {
            final dashCtrl = Get.find<DashboardController>();
            await dashCtrl.fetchDashboardData();
          } catch (_) {}
        } else {
          Get.snackbar('Error', data['message'] ?? 'Failed to unsave job');
        }
      } else {
        Get.snackbar('Error', 'Server error. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection failed.');
    } finally {
      isLoading.value = false;
    }
  }
}
