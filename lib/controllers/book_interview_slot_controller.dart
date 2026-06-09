import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/applications_controller.dart';
import 'package:hirematrix/controllers/my_interview_bookings_controller.dart';

class BookInterviewSlotController extends GetxController {
  final isLoading = false.obs;
  final isBooking = false.obs;
  final application = Rxn<Map<String, dynamic>>();
  final availableSlots = <dynamic>[].obs;
  final groupedSlots = <String, List<dynamic>>{}.obs;
  final bookingStatus = 'none'.obs; // 'none', 'success', 'info', 'error'
  final statusMessage = ''.obs;
  final selectedSlotId = RxnInt();

  Future<void> fetchSlots(dynamic applicationId) async {
    isLoading.value = true;
    bookingStatus.value = 'none';
    statusMessage.value = '';
    selectedSlotId.value = null;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/applications/$applicationId/slots'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['application'] != null) {
          application.value = Map<String, dynamic>.from(data['application']);
        }
        if (data['status'] == 'success') {
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
        } else if (data['status'] == 'info' || data['status'] == 'error') {
          bookingStatus.value = data['status'];
          statusMessage.value = data['message'] ?? 'Unable to book slot at this time.';
        } else {
          bookingStatus.value = 'error';
          statusMessage.value = data['message'] ?? 'Failed to load available slots.';
        }
      } else {
        bookingStatus.value = 'error';
        statusMessage.value = 'Server returned error loading slots.';
      }
    } catch (_) {
      bookingStatus.value = 'error';
      statusMessage.value = 'Connection error. Could not retrieve slots.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> confirmBooking({
    required dynamic applicationId,
    required int slotId,
  }) async {
    final authController = Get.find<AuthController>();
    final candidateId = authController.currentUser['id'];
    if (candidateId == null) return false;

    isBooking.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/applications/book-slot'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'application_id': applicationId,
          'slot_id': slotId,
          'candidate_id': candidateId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Success',
            data['message'] ?? 'Interview slot booked successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
          // Refresh my bookings list if the controller exists
          try {
            final bookingsCtrl = Get.find<MyInterviewBookingsController>();
            await bookingsCtrl.fetchBookings();
          } catch (_) {}
          // Refresh applications controller
          try {
            final appsController = Get.find<ApplicationsController>();
            await appsController.fetchApplications();
          } catch (_) {}
          return true;
        } else {
          Get.snackbar(
            'Booking Failed',
            data['message'] ?? 'Unable to confirm slot booking.',
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
      isBooking.value = false;
    }
    return false;
  }
}
