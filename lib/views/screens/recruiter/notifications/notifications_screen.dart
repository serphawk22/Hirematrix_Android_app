import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/views/screens/recruiter/candidates/candidate_management_screen.dart';
import 'package:hirematrix/views/screens/recruiter/candidates/candidate_profile_view_screen.dart';
import 'package:hirematrix/views/screens/recruiter/jobs/interview_bookings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<DashboardController>(
        context,
        listen: false,
      ).refresh(recruiterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainBg = isDark ? AppColors.bgDark : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
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
          Consumer<DashboardController>(
            builder: (context, dashboard, child) {
              final unreadCount = dashboard.notifications.where((n) {
                final isRead =
                    n['is_read'] == 1 ||
                    n['is_read'] == '1' ||
                    n['is_read'] == true;
                return !isRead;
              }).length;

              if (unreadCount > 0 && recruiterId != null) {
                return TextButton.icon(
                  onPressed: () => dashboard.markAllAsRead(recruiterId),
                  icon: const Icon(
                    Icons.done_all,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
                  label: Text(
                    'Mark All Read',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.blueAccent,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    'All Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track candidate activity, applications, and recruiter actions in one place.',
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
              child: Consumer<DashboardController>(
                builder: (context, dashboard, child) {
                  if (dashboard.isLoading && dashboard.notifications.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getPrimary(isDark),
                        ),
                      ),
                    );
                  }

                  if (dashboard.notifications.isEmpty) {
                    return _buildEmptyState(textColor, subtitleColor, isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    color: AppColors.getPrimary(isDark),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: dashboard.notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = dashboard.notifications[index];
                        return _buildNotificationCard(
                          notification,
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          recruiterId,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                color: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
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
              "You're all caught up!",
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
    String? recruiterId,
  ) {
    final String idStr = notification['id']?.toString() ?? '0';
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? '';
    final bool isRead =
        (notification['is_read'] == 1 ||
        notification['is_read'] == true ||
        notification['is_read'] == '1');
    final String dateStr = notification['created_at'] ?? '';
    String iconName = notification['icon'] ?? 'fas fa-bell';
    final String colorName = notification['color'] ?? 'info';
    final String? actionLink = notification['action_link'];
    final String actionText = notification['action_text'] ?? 'Open';
    final String? notifType = notification['type']?.toString();
    if (notifType == 'candidate_email_reply') iconName = 'fas fa-envelope';
    if (notifType == 'candidate_message_reply') iconName = 'fas fa-reply';
    if (notifType == 'interview_scheduled' || notifType == 'interview_booked') iconName = 'fas fa-calendar-check';
    if (notifType == 'interview_rescheduled') iconName = 'fas fa-calendar-alt';
    if (notifType == 'application_status_changed') iconName = 'fas fa-tasks';
    if (notifType == 'offer_sent') iconName = 'fas fa-file-alt';

    final Color badgeColor = _getIconColor(colorName, isDark);
    final dynamic icon = _getIconData(iconName);

    return Container(
      decoration: BoxDecoration(
        color: isRead
            ? cardColor
            : badgeColor.withValues(alpha: isDark ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[850]! : Colors.grey[200]!)
              : badgeColor.withValues(alpha: 0.3),
          width: isRead ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
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
                              color: badgeColor.withValues(alpha: 0.12),
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
                                          if (!isRead) ...[
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.getPrimary(isDark),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
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
                                        : textColor.withValues(alpha: 0.85),
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
                          // Action buttons
                          Row(
                            children: [
                              if (actionLink != null && actionLink.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (!isRead && recruiterId != null) {
                                      Provider.of<DashboardController>(
                                        context,
                                        listen: false,
                                      ).markAsRead(idStr, recruiterId);
                                    }
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
                                  onPressed: () {
                                    if (recruiterId != null) {
                                      Provider.of<DashboardController>(
                                        context,
                                        listen: false,
                                      ).markAsRead(idStr, recruiterId);
                                    }
                                  },
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
                            onPressed: () =>
                                _confirmDelete(idStr, context, recruiterId),
                            icon: Icon(
                              Icons.delete_outline,
                              color: isDark
                                  ? Colors.redAccent.withValues(alpha: 0.8)
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

  void _confirmDelete(
    String notificationId,
    BuildContext context,
    String? recruiterId,
  ) {
    if (recruiterId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<DashboardController>(
                context,
                listen: false,
              ).deleteNotification(notificationId, recruiterId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(
    String? actionLink,
    BuildContext context, {
    String? notifType,
    dynamic notifData,
  }) {
    if (actionLink == null || actionLink.isEmpty) return;

    final uri = Uri.tryParse(actionLink);
    if (uri == null) return;
    final path = uri.path;

    final String message = notifData != null ? (notifData['message']?.toString() ?? '') : '';

    if (notifType == 'candidate_message_reply' || path.contains('/recruiter/candidate/')) {
      final segments = uri.pathSegments;
      final candidateIndex = segments.indexOf('candidate');
      if (candidateIndex != -1 && candidateIndex + 1 < segments.length) {
        final candidateId = segments[candidateIndex + 1];
        final appId = uri.queryParameters['application_id'];
        final jobId = uri.queryParameters['job_id'];

        String candidateName = 'Candidate';
        if (message.contains(' replied to your message.')) {
          candidateName = message.split(' replied to your message.').first;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidateProfileViewScreen(
              candidateId: candidateId,
              applicationId: appId,
              jobId: jobId,
              candidateName: candidateName,
              initialTabIndex: 2,
            ),
          ),
        );
        return;
      }
    }

    if (path.contains('/recruiter/candidates') ||
        path.contains('/recruiter/applications')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const CandidateManagementScreen(isStandalone: true),
        ),
      );
    } else if (path.contains('interviews') ||
        path.contains('bookings') ||
        path.contains('slots') ||
        (notifType != null && notifType.contains('interview'))) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InterviewBookingsScreen(),
        ),
      );
    } else if (path.contains('/recruiter/messages')) {
      // route to messages if it exists in recruiter
      // For now fallback to candidate management
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const CandidateManagementScreen(isStandalone: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete this action on our web portal.'),
          backgroundColor: Colors.blueAccent,
        ),
      );
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
        return FontAwesomeIcons.fileArrowUp;
      case 'fas fa-paper-plane':
        return FontAwesomeIcons.paperPlane;
      case 'fas fa-info-circle':
        return FontAwesomeIcons.circleInfo;
      case 'fas fa-calendar-plus':
        return FontAwesomeIcons.calendarPlus;
      case 'fas fa-calendar-times':
        return FontAwesomeIcons.calendarXmark;
      case 'fas fa-calendar-check':
        return FontAwesomeIcons.calendarCheck;
      case 'fas fa-calendar-alt':
        return FontAwesomeIcons.calendarDays;
      case 'fas fa-clipboard-check':
        return FontAwesomeIcons.clipboardCheck;
      case 'fas fa-layer-group':
        return FontAwesomeIcons.layerGroup;
      case 'fas fa-file-signature':
        return FontAwesomeIcons.fileSignature;
      case 'fas fa-check-circle':
        return FontAwesomeIcons.circleCheck;
      case 'fas fa-user-check':
        return FontAwesomeIcons.userCheck;
      case 'fas fa-address-card':
        return FontAwesomeIcons.addressCard;
      case 'fas fa-file-download':
        return FontAwesomeIcons.fileArrowDown;
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
      case 'fas fa-envelope':
        return FontAwesomeIcons.envelope;
      case 'fas fa-tasks':
        return FontAwesomeIcons.listCheck;
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
