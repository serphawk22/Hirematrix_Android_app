import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class JobSearchStrategyController extends GetxController {
  final isLoading = false.obs;
  
  final strategy = <String, dynamic>{}.obs;
  final selectedTab = 0.obs;
  final topSuggestedJobs = <dynamic>[].obs;
  final recommendedJobs = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStrategyData();
  }

  Future<void> fetchStrategyData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/job-search-strategy/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          strategy.value = resData['jobSearchStrategy'] ?? {};
          topSuggestedJobs.assignAll(resData['topSuggestedJobs'] ?? []);
          
          _deriveRecommendedJobs();
        }
      } else {
        Get.snackbar(
          'Error', 
          'Failed to load job search strategy',
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _deriveRecommendedJobs() {
    final recommendedIdsRaw = strategy['recommended_job_ids'];
    List<int> recommendedIds = [];
    if (recommendedIdsRaw is List) {
      recommendedIds = recommendedIdsRaw.map((id) => int.tryParse(id.toString()) ?? 0).where((id) => id > 0).toList();
    }

    final matched = topSuggestedJobs.where((job) {
      final jobId = int.tryParse(job['id']?.toString() ?? '0') ?? 0;
      return recommendedIds.contains(jobId);
    }).toList();

    if (matched.isEmpty) {
      recommendedJobs.assignAll(topSuggestedJobs.take(3).toList());
    } else {
      recommendedJobs.assignAll(matched);
    }
  }
}
