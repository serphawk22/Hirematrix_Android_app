import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';

import '../candidates/candidate_management_screen.dart';

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
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<DashboardController>(context, listen: false).refresh(recruiterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: recruiterId != null 
              ? () => Provider.of<DashboardController>(context, listen: false).markAllAsRead(recruiterId)
              : null,
            child: Text('Mark all as read', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.getPrimary(isDark))),
          ),
        ],
      ),
      body: Consumer<DashboardController>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (dashboard.notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dashboard.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = dashboard.notifications[index];
                return _buildNotificationCard(notification, isDark, recruiterId);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, bool isDark, String? recruiterId) {
    final isRead = item['is_read'] == 1 || item['is_read'] == '1' || item['is_read'] == true;
    final type = item['type'] ?? 'general';
    final date = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
    final timeStr = DateFormat('dd MMM, hh:mm a').format(date);

    IconData icon = Icons.notifications_outlined;
    Color color = Colors.blue;

    if (type == 'security') {
      icon = Icons.shield_outlined;
      color = Colors.orange;
    } else if (type == 'verification') {
      icon = Icons.verified_user_outlined;
      color = Colors.indigo;
    } else if (type == 'application') {
      icon = Icons.person_add_outlined;
      color = Colors.green;
    }

    return InkWell(
      onTap: () {
        if (!isRead && recruiterId != null) {
          Provider.of<DashboardController>(context, listen: false).markAsRead(item['id'].toString(), recruiterId);
        }
        if (type == 'application') {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const CandidateManagementScreen(isStandalone: true)));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isRead 
              ? AppColors.getPrimary(isDark).withValues(alpha: 0.3) 
              : (isDark ? Colors.white10 : Colors.grey[100]!),
            width: !isRead ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'Notification',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.getText(isDark),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: AppColors.getPrimary(isDark), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['message'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.getTextMuted(isDark),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll notify you when something important happens.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
