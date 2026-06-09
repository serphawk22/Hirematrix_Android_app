import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/applications_controller.dart';
import 'package:hirematrix/controllers/my_interview_bookings_controller.dart';

class RescheduleInterviewController extends GetxController {
  final isLoading = false.obs;
  final isRescheduling = false.obs;
  final application = Rxn<Map<String, dynamic>>();
  final booking = Rxn<Map<String, dynamic>>();
  final availableSlots = <dynamic>[].obs;
  final groupedSlots = <String, List<dynamic>>{}.obs;
  final canRescheduleInfo = Rxn<Map<String, dynamic>>();
  final history = <dynamic>[].obs;
  final selectedSlotId = RxnInt();
  final reasonController = TextEditingController();

  Future<void> fetchRescheduleInfo(dynamic applicationId) async {
    isLoading.value = true;
    selectedSlotId.value = null;
    reasonController.clear();
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/applications/$applicationId/reschedule-info'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (data['application'] != null) {
            application.value = Map<String, dynamic>.from(data['application']);
          }
          if (data['booking'] != null) {
            booking.value = Map<String, dynamic>.from(data['booking']);
          }
          if (data['can_reschedule_info'] != null) {
            canRescheduleInfo.value = Map<String, dynamic>.from(data['can_reschedule_info']);
          }
          
          final List<dynamic> rawSlots = data['available_slots'] ?? [];
          availableSlots.assignAll(rawSlots);

          // Group slots by date
          final Map<String, List<dynamic>> tempGrouped = {};
          for (var slot in rawSlots) {
            final dateStr = slot['slot_date'] ?? '';
            if (dateStr.isNotEmpty) {
              if (!tempGrouped.containsKey(dateStr)) {
                tempGrouped[dateStr] = [];
              }
              tempGrouped[dateStr]!.add(slot);
            }
          }
          groupedSlots.assignAll(tempGrouped);

          if (data['history'] != null) {
            history.assignAll(List<dynamic>.from(data['history']));
          }
        }
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to fetch reschedule info.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> rescheduleBooking({
    required dynamic applicationId,
    required int slotId,
    required String reason,
  }) async {
    final authController = Get.find<AuthController>();
    final candidateId = authController.currentUser['id'];
    if (candidateId == null) return false;

    isRescheduling.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/applications/reschedule'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'application_id': applicationId,
          'slot_id': slotId,
          'candidate_id': candidateId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            data['message'] ?? 'Interview rescheduled successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
          // Refresh controllers
          try {
            final bookingsCtrl = Get.find<MyInterviewBookingsController>();
            await bookingsCtrl.fetchBookings();
          } catch (_) {}
          try {
            final appsController = Get.find<ApplicationsController>();
            await appsController.fetchApplications();
          } catch (_) {}
          return true;
        } else {
          Get.snackbar(
            'Reschedule Failed',
            data['message'] ?? 'Unable to reschedule slot.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Server error. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Connection failure.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isRescheduling.value = false;
    }
    return false;
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
