import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';

class MyInterviewBookingsController extends GetxController {
  final isLoading = false.obs;
  final bookingsList = <dynamic>[].obs;
  final upcomingBookings = <dynamic>[].obs;
  final pastBookings = <dynamic>[].obs;
  final nextBooking = Rxn<dynamic>();
  final upcomingCount = 0.obs;
  final completedCount = 0.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final authController = Get.find<AuthController>();
      final candidateId = authController.currentUser['id'];
      if (candidateId == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/applications/bookings/$candidateId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> rawBookings = data['bookings'] ?? [];

          // Sort bookings chronologically
          rawBookings.sort((a, b) {
            final aDt = DateTime.tryParse(a['slot_datetime']?.toString() ?? '') ?? DateTime(1970);
            final bDt = DateTime.tryParse(b['slot_datetime']?.toString() ?? '') ?? DateTime(1970);
            return aDt.compareTo(bDt);
          });

          bookingsList.assignAll(rawBookings);

          // Categorize into upcoming vs past
          final now = DateTime.now();
          final tempUpcoming = <dynamic>[];
          final tempPast = <dynamic>[];
          int tempCompleted = 0;

          for (var booking in rawBookings) {
            final slotDtStr = booking['slot_datetime']?.toString() ?? '';
            final slotDt = DateTime.tryParse(slotDtStr);
            if (slotDt != null) {
              if (slotDt.isAfter(now)) {
                tempUpcoming.add(booking);
              } else {
                tempPast.add(booking);
              }
            } else {
              tempPast.add(booking);
            }

            if (booking['booking_status'] == 'completed') {
              tempCompleted++;
            }
          }

          upcomingBookings.assignAll(tempUpcoming);
          pastBookings.assignAll(tempPast);
          completedCount.value = tempCompleted;
          upcomingCount.value = tempUpcoming.length;
          nextBooking.value = tempUpcoming.isNotEmpty ? tempUpcoming.first : null;
        } else {
          errorMessage.value = data['message'] ?? 'Failed to load interview bookings.';
        }
      } else {
        errorMessage.value = 'Server returned error loading bookings.';
      }
    } catch (e) {
      errorMessage.value = 'Connection error. Could not retrieve bookings.';
    } finally {
      isLoading.value = false;
    }
  }
}
