import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';

class PlansController extends GetxController {
  final isLoading = false.obs;
  final plansList = <dynamic>[].obs;
  final currentSubscription = <String, dynamic>{}.obs;

  late Razorpay _razorpay;
  String? _pendingPlanName;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchPlansData();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> fetchPlansData() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/plans/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final resData = data['data'];
          plansList.assignAll(resData['plans'] ?? []);
          currentSubscription.value = resData['currentSubscription'] ?? {};
        }
      }
    } catch (_) {
      Get.snackbar(
        'Connection Error',
        'Could not fetch premium plans',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startPaymentFlow(int planId, String planName) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/create-order'),
        headers: {'Accept': 'application/json'},
        body: {'candidate_id': userId.toString(), 'plan_id': planId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _pendingPlanName = planName;

          var options = {
            'key': data['key_id'],
            'amount': data['amount'],
            'name': 'HireMatrix',
            'description': planName,
            'order_id': data['order_id'],
            'currency': data['currency'],
            'prefill': {
              'contact': authController.currentUser['phone']?.toString() ?? '',
              'email': authController.currentUser['email']?.toString() ?? '',
            },
            'theme': {'color': '#3B82F6'},
          };

          _razorpay.open(options);
        } else {
          Get.snackbar(
            'Error',
            data['message'] ?? 'Failed to create payment order.',
          );
        }
      } else {
        Get.snackbar('Error', 'Server error. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection failed to start payment.');
    } finally {
      isLoading.value = false;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    isLoading.value = true;
    try {
      final verifyResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/verify'),
        headers: {'Accept': 'application/json'},
        body: {
          'candidate_id': userId.toString(),
          'razorpay_order_id': response.orderId ?? '',
          'razorpay_payment_id': response.paymentId ?? '',
          'razorpay_signature': response.signature ?? '',
        },
      );

      if (verifyResponse.statusCode == 200) {
        final data = jsonDecode(verifyResponse.body);
        if (data['status'] == 'success') {
          showSuccessDialog(_pendingPlanName ?? 'Premium Plan');
          await fetchPlansData();
          try {
            final dashCtrl = Get.find<DashboardController>();
            await dashCtrl.fetchDashboardData();
          } catch (_) {}
        } else {
          Get.snackbar(
            'Verification Failed',
            data['message'] ?? 'Payment verification failed.',
          );
        }
      } else {
        Get.snackbar('Error', 'Verification failed on server.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection failed during verification.');
    } finally {
      isLoading.value = false;
      _pendingPlanName = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      'Payment Cancelled/Failed',
      response.message ?? 'Payment failed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet Selected',
      response.walletName ?? '',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showSuccessDialog(String planName) {
    final context = Get.context;
    if (context == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Subscription Active!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.getText(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully upgraded to $planName. All premium AI services are now unlocked.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Great, Let\'s Go!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
