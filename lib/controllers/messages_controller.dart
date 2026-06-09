import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class MessagesController extends GetxController {
  final int recruiterId;
  final int applicationId;

  MessagesController({
    required this.recruiterId,
    required this.applicationId,
  });

  final isLoading = false.obs;
  final isSending = false.obs;
  final messages = <dynamic>[].obs;
  final recruiterName = ''.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  Timer? _livePollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchThread(showLoading: true);
    _startLivePolling();
  }

  @override
  void onClose() {
    _livePollingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _startLivePolling() {
    _livePollingTimer?.cancel();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchThread(showLoading: false);
    });
  }

  Future<void> fetchThread({bool showLoading = false}) async {
    if (showLoading) isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final candidateId = authController.currentUser['id'];
      if (candidateId == null) return;

      final url = '${ApiConstants.baseUrl}/messages/thread?'
          'candidate_id=$candidateId&'
          'recruiter_id=$recruiterId&'
          'application_id=$applicationId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          recruiterName.value = data['data']['recruiter']['name'] ?? 'Recruiter';
          
          final List newMessages = data['data']['messages'] ?? [];
          
          // Check if list actually changed before updating to prevent UI rebuilding scroll jumps
          if (newMessages.length != messages.length) {
            messages.assignAll(newMessages);
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching message thread: $e");
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSending.value = true;
    try {
      final authController = Get.find<AuthController>();
      final candidateId = authController.currentUser['id'];
      if (candidateId == null) return;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/messages/reply'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': candidateId,
          'recruiter_id': recruiterId,
          'application_id': applicationId,
          'message': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          messageController.clear();
          // Instantly refresh thread locally
          await fetchThread(showLoading: false);
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to send message',
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
      isSending.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
