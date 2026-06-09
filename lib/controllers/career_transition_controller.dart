import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/core/constants/app_colors.dart';

class CareerTransitionController extends GetxController {
  final isLoading = false.obs;
  final isActionLoading = false.obs;

  // Active transition info
  final transition = <String, dynamic>{}.obs;
  final tasks = <dynamic>[].obs;
  final currentRole = ''.obs;
  final pdfUrl = ''.obs;

  // History and modules/lessons
  final historyList = <dynamic>[].obs;
  final modulesList = <dynamic>[].obs;
  final lessonsList = <dynamic>[].obs;

  Future<void> fetchTransition() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          transition.value = resData['transition'] ?? {};
          tasks.assignAll(resData['tasks'] ?? []);
          currentRole.value = resData['currentRole'] ?? '';
          pdfUrl.value = resData['pdfUrl'] ?? '';
        }
      } else {
        Get.snackbar('Error', 'Failed to load transition plan',
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

  Future<bool> createTransition(String current, String target) async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/create'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'current_role': current,
          'target_role': target,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar('Success', data['message'] ?? 'Roadmap created successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
          await fetchTransition();
          return true;
        }
      }
      Get.snackbar('Error', 'Failed to generate roadmap',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
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

  Future<void> completeTask(dynamic taskId) async {
    try {
      final parsedId = int.tryParse(taskId?.toString() ?? '') ?? 0;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/complete-task/$parsedId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Instantly update local list
          for (var i = 0; i < tasks.length; i++) {
            if (tasks[i]['id'].toString() == parsedId.toString()) {
              final updated = Map<String, dynamic>.from(tasks[i]);
              updated['is_completed'] = 1;
              tasks[i] = updated;
              break;
            }
          }
          Get.snackbar('Success', 'Task marked completed!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
        }
      }
    } catch (e) {
      // quiet fail
    }
  }

  Future<bool> resetTransition() async {
    isActionLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/reset'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          transition.clear();
          tasks.clear();
          Get.snackbar('Reset Success', 'Saved to history! You can start a new path.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
          await fetchTransition();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> fetchHistory() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/history/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          historyList.assignAll(data['data']['transitions'] ?? []);
        }
      }
    } catch (e) {
      // quiet fail
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> reactivateTransition(dynamic transitionId) async {
    isActionLoading.value = true;
    try {
      final parsedId = int.tryParse(transitionId?.toString() ?? '') ?? 0;
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/reactivate'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'transition_id': parsedId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar('Success', 'Path reactivated successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white);
          await fetchTransition();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> fetchModules() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/modules/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          modulesList.assignAll(data['data']['modules'] ?? []);
        }
      }
    } catch (e) {
      // quiet fail
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLessons(dynamic moduleId) async {
    isLoading.value = true;
    try {
      final parsedId = int.tryParse(moduleId?.toString() ?? '') ?? 0;
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/career-transition/module-lessons/$parsedId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          lessonsList.assignAll(data['data']['lessons'] ?? []);
        }
      }
    } catch (e) {
      // quiet fail
    } finally {
      isLoading.value = false;
    }
  }
}
