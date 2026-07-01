import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class CompanyDiscoveryController extends GetxController {
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  final companies = <dynamic>[].obs;
  final segments = <dynamic>[].obs;
  final industries = <String>[].obs;
  final allCompanyCount = 0.obs;

  final activeSegment = ''.obs;
  final searchQuery = ''.obs;
  final selectedIndustry = ''.obs;
  final locationQuery = ''.obs;
  final selectedHiringStatus = ''.obs;

  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanyDiscovery();
  }

  void setSegment(String segmentKey) {
    if (activeSegment.value == segmentKey) {
      activeSegment.value = ''; // Toggle off
    } else {
      activeSegment.value = segmentKey;
    }
    fetchCompanyDiscovery();
  }

  void updateFilters({
    String? query,
    String? industry,
    String? location,
    String? status,
  }) {
    if (query != null) searchQuery.value = query;
    if (industry != null) selectedIndustry.value = industry;
    if (location != null) locationQuery.value = location;
    if (status != null) selectedHiringStatus.value = status;
    fetchCompanyDiscovery();
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedIndustry.value = '';
    locationQuery.value = '';
    selectedHiringStatus.value = '';
    activeSegment.value = '';
    fetchCompanyDiscovery();
  }

  Future<void> fetchCompanyDiscovery({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isLoadingMore.value || !hasMore.value) return;
      isLoadingMore.value = true;
      currentPage.value++;
    } else {
      isLoading.value = true;
      currentPage.value = 1;
      companies.clear();
    }

    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        isLoadingMore.value = false;
        return;
      }

      final queryParams = {
        'candidate_id': userId.toString(),
        'q': searchQuery.value,
        'industry': selectedIndustry.value,
        'location': locationQuery.value,
        'segment': activeSegment.value,
        'jobs': selectedHiringStatus.value,
        'page': currentPage.value.toString(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/${ApiConstants.companyDiscovery}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (isLoadMore) {
            companies.addAll(data['companies']);
          } else {
            companies.assignAll(data['companies']);
            segments.assignAll(data['segments']);
            industries.assignAll(List<String>.from(data['industries']));
            allCompanyCount.value = data['allCompanyCount'] ?? 0;
            totalPages.value = data['totalPages'] ?? 1;
          }
          hasMore.value = currentPage.value < totalPages.value;
        }
      } else {
        debugPrint('Failed to load company discovery: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading company discovery: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
