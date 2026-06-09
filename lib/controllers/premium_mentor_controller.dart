import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class PremiumMentorController extends GetxController {
  final isLoading = false.obs;
  final isChatSending = false.obs;
  final isPlanCreating = false.obs;

  final hasSubscription = false.obs;
  final subscription = <String, dynamic>{}.obs;
  final usageToday = 0.obs;
  final activeSessions = <dynamic>[].obs;
  final chatHistory = <dynamic>[].obs;
  final allowedFeatures = <dynamic>[].obs;
  final suggestedRoles = <String>[].obs;
  final userProfile = <String, dynamic>{}.obs;
  final followUpChips = <String>[].obs;
  
  final currentSessionId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMentorData();
  }

  Future<void> fetchMentorData({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/premium-mentor/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          hasSubscription.value = true;
          subscription.value = data['subscription'] ?? {};
          usageToday.value = int.tryParse(data['usage_today']?.toString() ?? '0') ?? 0;
          activeSessions.assignAll(data['active_sessions'] ?? []);
          chatHistory.assignAll(data['history'] ?? []);
          allowedFeatures.assignAll(data['features'] ?? []);
          suggestedRoles.assignAll((data['suggested_roles'] as List?)?.map((e) => e.toString()).toList() ?? []);
          userProfile.value = data['user_profile'] ?? {};

          // If there's an active session and currentSessionId is empty, set it
          if (currentSessionId.isEmpty && activeSessions.isNotEmpty) {
            // Pick the first active session's plan ID as context
            final firstSession = activeSessions.first;
            if (firstSession['id'] != null) {
              currentSessionId.value = 'plan-${firstSession['id']}';
            }
          }
        } else if (data['status'] == 'no_subscription') {
          hasSubscription.value = false;
          subscription.value = {};
        }
      }
    } catch (e) {
      debugPrint('Error fetching mentor data: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    // Append user message immediately
    chatHistory.add({
      'role': 'user',
      'content': message,
      'created_at': DateTime.now().toIso8601String(),
    });
    followUpChips.clear();

    isChatSending.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/premium-mentor/chat'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'message': message,
          'session_id': currentSessionId.value,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          currentSessionId.value = data['session_id'] ?? currentSessionId.value;
          
          chatHistory.add({
            'role': 'assistant',
            'content': data['message'] ?? '',
            'premium_features': data['premium_features'] ?? [],
            'created_at': DateTime.now().toIso8601String(),
          });

          // Update follow up chips
          final chipsList = (data['follow_up_chips'] as List?)?.map((e) => e.toString()).toList() ?? [];
          followUpChips.assignAll(chipsList);

          // Update usage
          await fetchMentorData(silent: true);
        } else if (data['status'] == 'limit_reached') {
          chatHistory.add({
            'role': 'assistant',
            'content': data['error'] ?? 'Daily chat limit reached.',
            'is_system_error': true,
          });
        } else {
          chatHistory.add({
            'role': 'assistant',
            'content': data['error'] ?? 'Error communicating with mentor.',
            'is_system_error': true,
          });
        }
      } else {
        chatHistory.add({
          'role': 'assistant',
          'content': 'Failed to communicate with mentor (Status Code: ${response.statusCode}).',
          'is_system_error': true,
        });
      }
    } catch (e) {
      chatHistory.add({
        'role': 'assistant',
        'content': 'Connection error occurred. Please check your internet.',
        'is_system_error': true,
      });
    } finally {
      isChatSending.value = false;
    }
  }

  Future<bool> createCareerPlan(String targetRole, String timeline, String currentRole) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return false;

    isPlanCreating.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/premium-mentor/create-plan'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'target_role': targetRole,
          'timeline': timeline,
          'current_role': currentRole,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['session_id'] != null) {
            currentSessionId.value = 'plan-${data['session_id']}';
          }
          await fetchMentorData();
          Get.snackbar(
            'Success',
            data['message'] ?? 'Career plan created successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return true;
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Failed to create career plan.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to create career plan. Server returned error code ${response.statusCode}.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Connection Error',
        'Could not connect to server.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPlanCreating.value = false;
    }
    return false;
  }

  void switchContext(String sessionId, String planTitle) {
    if (sessionId.isNotEmpty && currentSessionId.value != sessionId) {
      currentSessionId.value = sessionId;
      // Filter or inject context switched card in chat log
      chatHistory.add({
        'role': 'system_event',
        'content': 'Context switched: $planTitle',
      });
      followUpChips.clear();
    }
  }
}
