import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';

class NotificationController extends GetxController {
  final isLoading = false.obs;
  final notifications = <dynamic>[].obs;
  final unreadCount = 0.obs;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications(showInAppBanner: false);
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchNotifications(showInAppBanner: true);
    });
  }

  Future<void> fetchNotifications({bool showInAppBanner = false}) async {
    if (!showInAppBanner) isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        if (!showInAppBanner) isLoading.value = false;
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List newNotifications = data['data']['notifications'] ?? [];
          final int newUnreadCount = int.tryParse(data['data']['unread_count']?.toString() ?? '0') ?? 0;

          if (showInAppBanner) {
            await _checkAndShowInAppNotifications(newNotifications);
          } else {
            await _saveCurrentMaxIdToPrefs(newNotifications);
          }

          notifications.assignAll(newNotifications);
          unreadCount.value = newUnreadCount;
          
          // Also sync dashboard notifications count if dashboard controller is loaded
          _syncDashboardUnreadCount(unreadCount.value);
        }
      } else {
        if (!showInAppBanner) {
          Get.snackbar(
            'Error',
            'Failed to load notifications',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      if (!showInAppBanner) isLoading.value = false;
    }
  }

  Future<void> _saveCurrentMaxIdToPrefs(List newNotifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int maxId = prefs.getInt('last_notified_notification_id') ?? 0;
      for (var notif in newNotifications) {
        final int notifId = int.tryParse(notif['id']?.toString() ?? '0') ?? 0;
        if (notifId > maxId) {
          maxId = notifId;
        }
      }
      await prefs.setInt('last_notified_notification_id', maxId);
    } catch (e) {
      debugPrint("Error saving max notification ID: $e");
    }
  }

  Future<void> _checkAndShowInAppNotifications(List newNotifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedId = prefs.getInt('last_notified_notification_id') ?? 0;
      int maxId = lastNotifiedId;

      for (var notif in newNotifications) {
        final int notifId = int.tryParse(notif['id']?.toString() ?? '0') ?? 0;
        final bool isRead = (notif['is_read'] == 1 || notif['is_read'] == true || notif['is_read'] == '1');

        if (!isRead && notifId > lastNotifiedId) {
          if (notifId > maxId) {
            maxId = notifId;
          }

          Get.snackbar(
            notif['title'] ?? 'New Notification',
            notif['message'] ?? '',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF1E293B).withOpacity(0.95),
            colorText: Colors.white,
            borderRadius: 12,
            margin: const EdgeInsets.all(12),
            icon: const Icon(
              Icons.notifications_active,
              color: Colors.blueAccent,
            ),
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.notifications);
              },
              child: const Text(
                'VIEW',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      }

      if (maxId > lastNotifiedId) {
        await prefs.setInt('last_notified_notification_id', maxId);
      }
    } catch (e) {
      debugPrint("Error checking in-app notifications: $e");
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/mark-read/$notificationId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'candidate_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update local list
          final index = notifications.indexWhere((n) => n['id'] == notificationId || n['id'].toString() == notificationId.toString());
          if (index != -1) {
            final updated = Map<String, dynamic>.from(notifications[index]);
            updated['is_read'] = 1; // Or true depending on type, database returns 1 or 0 usually
            notifications[index] = updated;
          }
          unreadCount.value = int.tryParse(data['data']['unread_count']?.toString() ?? '0') ?? 0;
          _syncDashboardUnreadCount(unreadCount.value);
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to mark notification as read',
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
    }
  }

  Future<void> markAllAsRead() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/mark-all-read/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update all locally
          for (var i = 0; i < notifications.length; i++) {
            final updated = Map<String, dynamic>.from(notifications[i]);
            updated['is_read'] = 1;
            notifications[i] = updated;
          }
          unreadCount.value = 0;
          _syncDashboardUnreadCount(0);
          Get.snackbar(
            'Success',
            'All notifications marked as read',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to mark all as read',
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
      isLoading.value = false;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser['id'];
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/delete/$notificationId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'candidate_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Remove from local list
          notifications.removeWhere((n) => n['id'] == notificationId || n['id'].toString() == notificationId.toString());
          unreadCount.value = int.tryParse(data['data']['unread_count']?.toString() ?? '0') ?? 0;
          _syncDashboardUnreadCount(unreadCount.value);
          Get.snackbar(
            'Success',
            'Notification deleted',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete notification',
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
    }
  }

  void _syncDashboardUnreadCount(int count) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        final statsCopy = Map<String, dynamic>.from(dashboardController.stats);
        statsCopy['unread_notifications'] = count;
        dashboardController.stats.value = statsCopy;
      }
    } catch (_) {}
  }

  void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    _syncDashboardUnreadCount(0);
  }
}
