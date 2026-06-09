import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';

class LandingController extends GetxController {
  final isLoading = true.obs;
  final featuredJobs = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeaturedJobs();
  }

  Future<void> fetchFeaturedJobs() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/jobs/featured'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          featuredJobs.assignAll(data['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Error fetching featured jobs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
