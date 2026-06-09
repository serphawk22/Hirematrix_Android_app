import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class ResumeStudioController extends GetxController {
  final isLoading = false.obs;
  final isActionLoading = false.obs;

  final profileReadiness = <String, dynamic>{}.obs;
  final activeTransition = <String, dynamic>{}.obs;
  final resumeVersions = <dynamic>[].obs;
  final resumeTargets = <dynamic>[].obs;
  final resumeTemplates = <dynamic>[].obs;

  Future<void> fetchStudioData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/resume-studio/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          profileReadiness.value = resData['profileReadiness'] ?? {};
          activeTransition.value = resData['activeTransition'] ?? {};
          resumeVersions.assignAll(resData['resumeVersions'] ?? []);
          resumeTargets.assignAll(resData['resumeTargets'] ?? []);
          resumeTemplates.assignAll(resData['resumeTemplates'] ?? []);
        }
      } else {
        Get.snackbar('Error', 'Failed to load Resume Studio data',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> generateAiResume({
    required String mode,
    required String targetRole,
    required int jobId,
    required String templateKey,
    required bool makePrimary,
  }) async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/resume-studio/generate'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'generation_mode': mode,
          'target_role': targetRole,
          'job_id': jobId.toString(),
          'template_key': templateKey,
          'make_primary': makePrimary ? '1' : '0',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar('Success', data['message'] ?? 'Resume generated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        await fetchStudioData();
        return true;
      } else {
        Get.snackbar('Error', data['messages']?['error'] ?? data['error'] ?? 'Failed to generate resume',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> syncTransition() async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/resume-studio/sync-transition'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar('Success', data['message'] ?? 'Synced transition resume successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        await fetchStudioData();
        return true;
      } else {
        Get.snackbar('Error', data['messages']?['error'] ?? data['error'] ?? 'Failed to sync transition resume',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> setPrimary(int versionId) async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/resume-studio/set-primary'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'version_id': versionId.toString(),
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar('Success', data['message'] ?? 'Primary resume version updated.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        await fetchStudioData();
        return true;
      } else {
        Get.snackbar('Error', data['messages']?['error'] ?? data['error'] ?? 'Failed to set primary version',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> deleteVersion(int versionId) async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/resume-studio/delete'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'version_id': versionId.toString(),
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        Get.snackbar('Success', data['message'] ?? 'Resume version deleted.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        await fetchStudioData();
        return true;
      } else {
        Get.snackbar('Error', data['messages']?['error'] ?? data['error'] ?? 'Failed to delete version',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }
}
