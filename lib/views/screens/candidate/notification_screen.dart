import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/notification_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/screens/candidate/my_interview_bookings_screen.dart';
import 'package:hirematrix/views/screens/candidate/applications_screens.dart';
import 'package:hirematrix/views/screens/candidate/messages_screen.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    controller.fetchNotifications(showInAppBanner: false);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtitleColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF475569);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: textColor,
            ),
          ),
          actions: [
            if (controller.unreadCount.value > 0)
              TextButton.icon(
                onPressed: () => controller.markAllAsRead(),
                icon: const Icon(
                  Icons.done_all,
                  size: 18,
                  color: Colors.blueAccent,
                ),
                label: Text(
                  'Mark Read',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner matching style of applied/saved jobs
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.getCard(isDark) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: AppColors.getPrimary(isDark),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ACTIVITY FEED',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Portal Notifications',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track application updates, recruiter actions, and portal events in one place.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchNotifications,
                  color: AppColors.getPrimary(isDark),
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getPrimary(isDark),
                          ),
                        ),
                      );
                    }

                    if (controller.notifications.isEmpty) {
                      return _buildEmptyState(textColor, subtitleColor, isDark);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = controller.notifications[index];
                        return _buildNotificationCard(
                          notification,
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(Color textColor, Color subtitleColor, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: AppColors.getPrimary(isDark),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! We will notify you here when recruiter updates or events occur.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    dynamic notification,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final int id = int.tryParse(notification['id']?.toString() ?? '0') ?? 0;
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? '';
    final bool isRead =
        (notification['is_read'] == 1 ||
        notification['is_read'] == true ||
        notification['is_read'] == '1');
    final String dateStr = notification['created_at'] ?? '';
    final String iconName = notification['icon'] ?? 'fas fa-bell';
    final String colorName = notification['color'] ?? 'info';
    final String? actionLink = notification['action_link'];
    final String actionText = notification['action_text'] ?? 'Take Action';
    final String? notifType = notification['type']?.toString();

    final Color badgeColor = _getIconColor(colorName, isDark);
    final dynamic icon = _getIconData(iconName);

    return Container(
      decoration: BoxDecoration(
        color: isRead
            ? cardColor
            : badgeColor.withOpacity(isDark ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[850]! : Colors.grey[200]!)
              : badgeColor.withOpacity(0.3),
          width: isRead ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isRead) Container(width: 4.5, color: badgeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: _buildIcon(icon, badgeColor)),
                          ),
                          const SizedBox(width: 12),
                          // Content area
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.getPrimary(
                                                  isDark,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'New',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _timeAgo(dateStr),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: subtitleColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: isRead
                                        ? subtitleColor
                                        : textColor.withOpacity(0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Action buttons on the left
                          Row(
                            children: [
                              if (actionLink != null && actionLink.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (!isRead) controller.markAsRead(id);
                                    _handleNotificationAction(
                                      actionLink,
                                      context,
                                      notifType: notifType,
                                      notifData: notification,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: badgeColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Text(
                                    actionText,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  label: const Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                  ),
                                ),
                              if (actionLink != null &&
                                  actionLink.isNotEmpty &&
                                  !isRead)
                                const SizedBox(width: 8),
                              if (!isRead)
                                TextButton.icon(
                                  onPressed: () => controller.markAsRead(id),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? Colors.grey[300]
                                        : const Color(0xFF374151),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.check, size: 13),
                                  label: Text(
                                    'Mark Read',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Delete button on the far right
                          IconButton(
                            onPressed: () => _confirmDelete(id),
                            icon: Icon(
                              Icons.delete_outline,
                              color: isDark
                                  ? Colors.redAccent.withOpacity(0.8)
                                  : Colors.redAccent,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete notification',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int notificationId) {
    Get.defaultDialog(
      title: 'Delete Notification',
      middleText: 'Are you sure you want to delete this notification?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back();
        controller.deleteNotification(notificationId);
      },
    );
  }

  /// Routes the "Take Action" button to the correct native screen based on
  /// the notification [type] returned by the backend, with URL-path fallback.
  void _handleNotificationAction(
    String? actionLink,
    BuildContext context, {
    String? notifType,
    dynamic notifData,
  }) {
    // ── 1. Primary routing by backend notification type ──────────────────────
    switch (notifType ?? '') {
      // ── Interview-related → My Bookings screen ──────────────────────────
      case 'interview_booked':
      case 'interview_scheduled':
      case 'interview_rescheduled':
      case 'interview_reviewed':
      case 'slot_not_booked':
      case 'reschedule_required':
        Get.to(() => const MyInterviewBookingsScreen());
        return;

      // ── Application status changed → Applications screen ────────────────
      case 'application_status_changed':
      case 'ai_not_started':
      case 'ai_incomplete':
      case 'offer_sent':
      case 'result_published':
        _goToApplications();
        return;

      // ── Recruiter engagement signals → Applications screen ──────────────
      case 'recruiter_resume_downloaded':
      case 'recruiter_contact_viewed':
      case 'recruiter_profile_viewed':
        _goToApplications();
        return;

      // ── Message from recruiter → Messages screen ────────────────────────
      case 'recruiter_message':
      case 'candidate_message_reply':
        _goToMessages(actionLink);
        return;

      // ── Invitation to apply → Job details screen ────────────────────────
      case 'job_invitation':
      case 'job_alert_match':
        _goToJobDetails(actionLink, notifData);
        return;

      // ── AI / daily tip actions ───────────────────────────────────────────
      case 'daily_resume_tip':
        Get.toNamed(AppRoutes.resumeStudio);
        return;
      case 'daily_interview_practice':
        _goToApplications();
        return;
      case 'daily_job_search_task':
      case 'daily_skill_prompt':
        Get.toNamed(AppRoutes.jobSearchStrategy);
        return;
      case 'resume_not_uploaded':
        Get.toNamed(AppRoutes.resumeStudio);
        return;
    }

    // ── 2. Fallback: route by action_link URL path ───────────────────────────
    if (actionLink == null || actionLink.isEmpty) return;
    final uri = Uri.tryParse(actionLink);
    if (uri == null) return;
    final path = uri.path;

    if (path.contains('/candidate/my-bookings') ||
        path.contains('/candidate/book-slot') ||
        path.contains('/candidate/reschedule-slot') ||
        path.contains('/candidate/interview')) {
      Get.to(() => const MyInterviewBookingsScreen());
    } else if (path.contains('/candidate/applications')) {
      _goToApplications();
    } else if (path.contains('/candidate/messages/')) {
      _goToMessages(actionLink);
    } else if (path.contains('/premium/plans')) {
      Get.toNamed(AppRoutes.plans);
    } else if (path.contains('/candidate/resume-studio')) {
      Get.toNamed(AppRoutes.resumeStudio);
    } else if (path.contains('/candidate/job-search-strategy')) {
      Get.toNamed(AppRoutes.jobSearchStrategy);
    } else if (path.contains('/localcompany')) {
      Get.toNamed(AppRoutes.localCompanies);
    } else if (path.contains('/career-transition')) {
      Get.toNamed(AppRoutes.careerTransition);
    } else if (path.contains('/job/') || path.contains('/jobs/')) {
      _goToJobDetails(actionLink, notifData);
    } else {
      Get.snackbar(
        'Action Required',
        'Please complete this action on our web portal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    }
  }

  // ── Helper navigation methods ────────────────────────────────────────────

  void _goToApplications() {
    try {
      final dc = Get.find<DashboardController>();
      dc.currentIndex.value = 2;
      Get.until((route) => Get.currentRoute == AppRoutes.dashboard);
    } catch (_) {
      Get.offAllNamed(AppRoutes.dashboard);
      Future.delayed(const Duration(milliseconds: 150), () {
        try {
          Get.find<DashboardController>().currentIndex.value = 2;
        } catch (_) {}
      });
    }
  }

  void _goToMessages(String? actionLink) {
    if (actionLink == null || actionLink.isEmpty) {
      Get.toNamed(AppRoutes.messages);
      return;
    }
    final uri = Uri.tryParse(actionLink);
    if (uri == null) {
      Get.toNamed(AppRoutes.messages);
      return;
    }
    final segments = uri.pathSegments;
    final idx = segments.indexOf('messages');
    if (idx != -1 && idx + 1 < segments.length) {
      final recruiterId = int.tryParse(segments[idx + 1]) ?? 0;
      final applicationId =
          int.tryParse(uri.queryParameters['application_id'] ?? '0') ?? 0;
      if (recruiterId > 0) {
        Get.toNamed(
          AppRoutes.messages,
          arguments: {
            'recruiter_id': recruiterId,
            'application_id': applicationId,
          },
        );
        return;
      }
    }
    Get.toNamed(AppRoutes.messages);
  }

  void _goToJobDetails(String? actionLink, dynamic notifData) {
    // Try to extract job_id from action_link (e.g. /jobs/123 or /jobs?id=123)
    int jobId = 0;
    if (actionLink != null && actionLink.isNotEmpty) {
      final uri = Uri.tryParse(actionLink);
      if (uri != null) {
        // Pattern: /job/123 or /jobs/123
        final segments = uri.pathSegments;
        int jobIdx = segments.indexOf('job');
        if (jobIdx == -1) jobIdx = segments.indexOf('jobs');
        if (jobIdx != -1 && jobIdx + 1 < segments.length) {
          jobId = int.tryParse(segments[jobIdx + 1]) ?? 0;
        }
        // Pattern: ?id=123 or ?job_id=123
        if (jobId == 0) {
          jobId =
              int.tryParse(
                uri.queryParameters['id'] ??
                    uri.queryParameters['job_id'] ??
                    '0',
              ) ??
              0;
        }
      }
    }
    // Try notifData fields as a last resort
    if (jobId == 0 && notifData != null) {
      jobId = int.tryParse(notifData['job_id']?.toString() ?? '0') ?? 0;
    }

    if (jobId > 0) {
      // Build a minimal job map; JobDetailsScreen will fetch remaining data
      final Map<String, dynamic> jobMap = {'id': jobId};
      Get.to(() => JobDetailsScreen(job: jobMap));
    } else {
      // Fallback: open the Jobs tab in the dashboard
      try {
        Get.find<DashboardController>().currentIndex.value = 1;
        Get.until((route) => Get.currentRoute == AppRoutes.dashboard);
      } catch (_) {
        Get.offAllNamed(AppRoutes.dashboard);
        Future.delayed(const Duration(milliseconds: 150), () {
          try {
            Get.find<DashboardController>().currentIndex.value = 1;
          } catch (_) {}
        });
      }
    }
  }

  Widget _buildIcon(dynamic icon, Color badgeColor) {
    if (icon is IconData) {
      return Icon(icon, color: badgeColor, size: 16);
    } else {
      return FaIcon(icon, color: badgeColor, size: 16);
    }
  }

  dynamic _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fas fa-file-upload':
        return FontAwesomeIcons.fileUpload;
      case 'fas fa-paper-plane':
        return FontAwesomeIcons.paperPlane;
      case 'fas fa-info-circle':
        return FontAwesomeIcons.infoCircle;
      case 'fas fa-calendar-plus':
        return FontAwesomeIcons.calendarPlus;
      case 'fas fa-calendar-times':
        return FontAwesomeIcons.calendarTimes;
      case 'fas fa-calendar-check':
        return FontAwesomeIcons.calendarCheck;
      case 'fas fa-calendar-alt':
        return FontAwesomeIcons.calendarAlt;
      case 'fas fa-clipboard-check':
        return FontAwesomeIcons.clipboardCheck;
      case 'fas fa-layer-group':
        return FontAwesomeIcons.layerGroup;
      case 'fas fa-file-signature':
        return FontAwesomeIcons.fileSignature;
      case 'fas fa-check-circle':
        return FontAwesomeIcons.checkCircle;
      case 'fas fa-user-check':
        return FontAwesomeIcons.userCheck;
      case 'fas fa-address-card':
        return FontAwesomeIcons.addressCard;
      case 'fas fa-file-download':
        return FontAwesomeIcons.fileDownload;
      case 'icon-mail_outline':
        return Icons.mail_outline;
      case 'icon-reply':
      case 'fas fa-reply':
        return FontAwesomeIcons.reply;
      case 'fas fa-bell':
        return FontAwesomeIcons.bell;
      case 'fas fa-file-lines':
        return FontAwesomeIcons.fileLines;
      case 'fas fa-video':
        return FontAwesomeIcons.video;
      case 'fas fa-briefcase':
        return FontAwesomeIcons.briefcase;
      case 'fas fa-lightbulb':
        return FontAwesomeIcons.lightbulb;
      case 'fas fa-sun':
        return FontAwesomeIcons.sun;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  Color _getIconColor(String colorName, bool isDark) {
    switch (colorName.toLowerCase()) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'danger':
        return const Color(0xFFEF4444);
      case 'success':
        return const Color(0xFF10B981);
      case 'primary':
        return AppColors.getPrimary(isDark);
      case 'info':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inDays >= 30) {
        return '${(difference.inDays / 30).floor()}m ago';
      } else if (difference.inDays >= 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays >= 1) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return '';
    }
  }
}
