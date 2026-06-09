import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';

class JobsController extends GetxController {
  final isLoading = false.obs;
  
  // Jobs lists
  final browseJobs = <dynamic>[].obs;
  final totalJobs = 0.obs;
  final candidateSkills = <String>[].obs;
  final candidateInterests = <String>[].obs;
  final savedJobIds = <int>[].obs;
  
  // Filter Options (fetched from API)
  final filterLocations = <String>[].obs;
  final filterCategories = <String>[].obs;
  final filterExperienceLevels = <String>[].obs;
  final filterEmploymentTypes = <String>[].obs;

  // Recommendations mapping
  final recSkillsJobs = <dynamic>[].obs;
  final recAppliesJobs = <dynamic>[].obs;
  final recPreferencesJobs = <dynamic>[].obs;
  final recAiJobs = <dynamic>[].obs;

  // Active filters in UI
  final activeMainTab = 0.obs;
  final searchQuery = ''.obs;
  final selectedCategory = ''.obs;
  final selectedCompany = ''.obs;
  final selectedLocation = ''.obs;
  final selectedWorkMode = ''.obs;
  final selectedSalaryRange = ''.obs;
  final selectedEmploymentTypes = <String>[].obs;
  final selectedExperienceLevels = <String>[].obs;
  final selectedPostedWithin = ''.obs; // e.g. '1', '3', '7', '14'
  
  final hasBaseResume = false.obs;
  final primaryResumeId = 0.obs;

  // Pagination
  final currentPage = 1.obs;

  // Direct Tab Navigation Callbacks
  void Function(int)? animateToTab;
  void Function(int)? setSubTab;
  
  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': currentPage.value.toString(),
      };

      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }
      if (selectedCategory.value.isNotEmpty) {
        queryParams['category'] = selectedCategory.value;
      }
      if (selectedCompany.value.isNotEmpty) {
        queryParams['company'] = selectedCompany.value;
      }
      if (selectedLocation.value.isNotEmpty) {
        queryParams['location'] = selectedLocation.value;
      }
      if (selectedWorkMode.value.isNotEmpty) {
        queryParams['work_mode'] = selectedWorkMode.value;
      }
      if (selectedSalaryRange.value.isNotEmpty) {
        queryParams['salary_range'] = selectedSalaryRange.value;
      }
      if (selectedPostedWithin.value.isNotEmpty) {
        queryParams['posted_within'] = selectedPostedWithin.value;
      }
      if (selectedEmploymentTypes.isNotEmpty) {
        queryParams['employment_type'] = selectedEmploymentTypes.join(',');
      }
      if (selectedExperienceLevels.isNotEmpty) {
        queryParams['experience_level'] = selectedExperienceLevels.join(',');
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/jobs/$userId').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          
          browseJobs.assignAll(resData['jobs'] ?? []);
          totalJobs.value = resData['totalJobs'] ?? 0;
          
          candidateSkills.assignAll(List<String>.from(resData['candidateSkills'] ?? []));
          candidateInterests.assignAll(List<String>.from(resData['candidateInterests'] ?? []));
          savedJobIds.assignAll(List<int>.from(resData['savedJobIds'] ?? []));
          
          // Recommendations
          final recs = resData['recommendations'] ?? {};
          recSkillsJobs.assignAll(recs['skills'] ?? []);
          recAppliesJobs.assignAll(recs['applies'] ?? []);
          recPreferencesJobs.assignAll(recs['preferences'] ?? []);
          recAiJobs.assignAll(recs['ai'] ?? []);
          
          // Filter options mapping
          final opts = resData['filterOptions'] ?? {};
          filterLocations.assignAll(List<String>.from(opts['locations'] ?? []));
          filterCategories.assignAll(List<String>.from(opts['categories'] ?? []));
          filterExperienceLevels.assignAll(List<String>.from(opts['experienceLevels'] ?? []));
          filterEmploymentTypes.assignAll(List<String>.from(opts['employmentTypes'] ?? []));
          
          hasBaseResume.value = resData['hasBaseResume'] ?? false;
          primaryResumeId.value = resData['primaryResumeId'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSaveJob(int jobId) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    final isSaved = savedJobIds.contains(jobId);
    
    // Optimistic UI update
    if (isSaved) {
      savedJobIds.remove(jobId);
    } else {
      savedJobIds.add(jobId);
    }

    try {
      final endpoint = isSaved ? 'unsave' : 'save';
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/jobs/$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': userId,
          'job_id': jobId,
        }),
      );

      if (response.statusCode != 200) {
        // Revert on failure
        if (isSaved) {
          savedJobIds.add(jobId);
        } else {
          savedJobIds.remove(jobId);
        }
        Get.snackbar('Error', 'Failed to update saved job',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      } else {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboardData();
        }
        Get.snackbar('Success', isSaved ? 'Job unsaved' : 'Job saved',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF4F46E5),
            colorText: Colors.white);
      }
    } catch (e) {
      if (isSaved) {
        savedJobIds.add(jobId);
      } else {
        savedJobIds.remove(jobId);
      }
      Get.snackbar('Error', 'Connection error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<Map<String, dynamic>?> generateCoverLetter(int jobId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return null;

      final uri = Uri.parse('${ApiConstants.baseUrl}/jobs/generate-ai-cover-letter').replace(queryParameters: {
        'candidate_id': userId.toString(),
        'job_id': jobId.toString(),
      });

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error generating cover letter: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeAtsMatch(int jobId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return null;

      final uri = Uri.parse('${ApiConstants.baseUrl}/jobs/analyze-ats-match').replace(queryParameters: {
        'candidate_id': userId.toString(),
        'job_id': jobId.toString(),
        'resume_id': primaryResumeId.value.toString(),
      });

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error analyzing ATS match: $e');
    }
    return null;
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedCategory.value = '';
    selectedCompany.value = '';
    selectedLocation.value = '';
    selectedWorkMode.value = '';
    selectedSalaryRange.value = '';
    selectedEmploymentTypes.clear();
    selectedExperienceLevels.clear();
    selectedPostedWithin.value = '';
    currentPage.value = 1;
    fetchJobs();
  }
}
