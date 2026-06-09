import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final isLoading = false.obs;
  final currentIndex = 0.obs;
  
  // Data holders
  final stats = <String, dynamic>{}.obs;
  final profileStrength = 0.obs;
  final topSuggestedJobs = <dynamic>[].obs;
  final topHiringCompanies = <dynamic>[].obs;
  final jobCategories = <dynamic>[].obs;
  final recentApplications = <dynamic>[].obs;
  final userProfile = <String, dynamic>{}.obs;
  final strategy = <String, dynamic>{}.obs;
  final currentSubscription = <String, dynamic>{}.obs;
  final blogPosts = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/dashboard/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          userProfile.value = resData['user'] ?? {};
          stats.value = resData['stats'] ?? {};
          profileStrength.value = int.tryParse(resData['profileStrength']?.toString() ?? '0') ?? 0;
          topSuggestedJobs.assignAll(resData['topSuggestedJobs'] ?? []);
          topHiringCompanies.assignAll(resData['topHiringCompanies'] ?? []);
          jobCategories.assignAll(resData['jobCategories'] ?? []);
          recentApplications.assignAll(resData['applications'] ?? []);
          strategy.value = resData['jobSearchStrategy'] ?? {};
          currentSubscription.value = resData['currentSubscription'] ?? {};
          blogPosts.assignAll(resData['blogPosts'] ?? []);
        }
      } else {
        Get.snackbar('Error', 'Failed to load dashboard data',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not connect to server',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
