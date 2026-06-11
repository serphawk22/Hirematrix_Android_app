import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/routes/app_routes.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserStr = prefs.getString('currentUser');
      if (savedUserStr == null) return true;

      final user = jsonDecode(savedUserStr);
      final candidateId = user['id'];
      if (candidateId == null) return true;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$candidateId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List notifications = data['notifications'] ?? [];
        final int unreadCount = int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;

        if (unreadCount > 0) {
          final lastNotifiedId = prefs.getInt('last_notified_notification_id') ?? 0;
          int maxId = lastNotifiedId;

          for (var notif in notifications) {
            final int notifId = int.tryParse(notif['id']?.toString() ?? '0') ?? 0;
            final bool isRead = (notif['is_read'] == 1 || notif['is_read'] == true || notif['is_read'] == '1');
            
            if (!isRead && notifId > lastNotifiedId) {
              if (notifId > maxId) {
                maxId = notifId;
              }
              
              // Trigger local notification
              await LocalNotificationService.showNotification(
                id: notifId,
                title: notif['title'] ?? 'New Notification',
                body: notif['message'] ?? '',
                payload: 'notifications_screen',
              );
            }
          }
          
          if (maxId > lastNotifiedId) {
            await prefs.setInt('last_notified_notification_id', maxId);
          }
        }
      }
    } catch (e) {
      debugPrint("Background notification sync error: $e");
    }
    return true;
  });
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationTap(payload);
        }
      },
    );

    // Request permissions for Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Check if app was launched via notification click
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails != null &&
        notificationAppLaunchDetails.didNotificationLaunchApp) {
      final payload = notificationAppLaunchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleNotificationTap(payload);
        });
      }
    }

    // Initialize workmanager for background sync
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic background check task (runs every 15 minutes)
    await Workmanager().registerPeriodicTask(
      "hirematrix_background_notifications_sync",
      "checkNotificationsTask",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hirematrix_notifications',
      'HireMatrix Notifications',
      channelDescription: 'Main notification channel for HireMatrix',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  static void _handleNotificationTap(String payload) {
    if (payload == 'notifications_screen') {
      try {
        Get.toNamed(AppRoutes.notifications);
      } catch (e) {
        debugPrint("Routing to notifications error: $e");
      }
    }
  }
}
