import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class CompanyProfileController extends GetxController {
  final authController = Get.find<AuthController>();

  final isLoading = true.obs;
  final errorMessage = RxnString();

  final companyData = Rxn<Map<String, dynamic>>();
  final openJobs = <dynamic>[].obs;
  final discoveredJobs = <dynamic>[].obs;
  final reviewSummary = <String, dynamic>{
    'total_reviews': 0,
    'average_rating': 0.0,
  }.obs;
  final reviews = <dynamic>[].obs;
  final eligibility = <String, dynamic>{
    'can_interview_review': false,
    'can_employee_review': false,
  }.obs;
  final currentUserReview = Rxn<Map<String, dynamic>>();
  final isSubmittingReview = false.obs;

  Future<void> fetchCompanyProfile(dynamic companyId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = authController.currentUser['id'] ?? 0;
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/company/$companyId?candidate_id=$userId',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          companyData.value = data['company'];
          openJobs.assignAll(data['open_jobs'] ?? []);
          discoveredJobs.assignAll(data['discovered_jobs'] ?? []);
          reviewSummary.value = data['review_summary'] ?? {
            'total_reviews': 0,
            'average_rating': 0.0,
          };
          reviews.assignAll(data['reviews'] ?? []);
          eligibility.value = data['eligibility'] ?? {
            'can_interview_review': false,
            'can_employee_review': false,
          };
          currentUserReview.value = data['current_user_review'];
        } else {
          errorMessage.value = data['message'] ?? 'Failed to load company profile.';
        }
      } else {
        errorMessage.value = 'Failed to load company profile. Server returned status: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Error fetching company profile: $e');
      errorMessage.value = 'Connection error. Check your internet connection.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitReview({
    required dynamic companyId,
    required String reviewType,
    required double rating,
    required String headline,
    required String reviewText,
    required String pros,
    required String cons,
  }) async {
    final userId = authController.currentUser['id'];
    if (userId == null) return false;

    isSubmittingReview.value = true;
    try {
      final url = '${ApiConstants.baseUrl}/company/$companyId/review';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': userId,
          'review_type': reviewType,
          'rating': rating,
          'headline': headline,
          'review_text': reviewText,
          'pros': pros,
          'cons': cons,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        Get.back(); // close modal
        Get.snackbar(
          'Success',
          body['message'] ?? 'Review saved successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Reload company profile to update review list/average rating
        await fetchCompanyProfile(companyId);
        return true;
      } else {
        Get.snackbar(
          'Error',
          body['message'] ?? 'Failed to save review.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Connection Error',
        'Could not submit review. Please try again.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmittingReview.value = false;
    }
    return false;
  }
}
