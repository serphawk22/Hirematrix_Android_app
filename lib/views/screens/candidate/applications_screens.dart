import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/applications_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/views/screens/candidate/book_interview_slot.dart';
import 'package:hirematrix/views/screens/candidate/my_interview_bookings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final ApplicationsController controller = Get.put(ApplicationsController());

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtitleColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF475569);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;

      final total = controller.applicationsList.length;
      final active = controller.applicationsList.where((app) {
        final status = app['status'] ?? '';
        return ![
          'filtered_out',
          'rejected',
          'selected',
          'withdrawn',
          'hired',
        ].contains(status);
      }).length;
      final completed = controller.applicationsList.where((app) {
        final status = app['status'] ?? '';
        return ['selected', 'hired'].contains(status);
      }).length;

      return Scaffold(
        backgroundColor: mainBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          Icons.list_alt,
                          color: AppColors.getPrimary(isDark),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'APPLICATION TRACKING',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'My Applications',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track application status, recruiter activity, and next steps in a simple view.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricChip(
                            total.toString(),
                            'Total',
                            AppColors.getPrimary(isDark),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricChip(
                            active.toString(),
                            'Active',
                            const Color(0xFFF59E0B),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricChip(
                            completed.toString(),
                            'Completed',
                            const Color(0xFF10B981),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Applications list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchApplications,
                  color: AppColors.getPrimary(isDark),
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.applicationsList.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getPrimary(isDark),
                          ),
                        ),
                      );
                    }

                    if (controller.applicationsList.isEmpty) {
                      return _buildEmptyState(textColor, subtitleColor);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.applicationsList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final application = controller.applicationsList[index];
                        return _buildApplicationCard(
                          application,
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

  Widget _buildMetricChip(
    String value,
    String label,
    Color badgeColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtitleColor) {
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
                color: AppColors.getPrimary(Get.isDarkMode).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox,
                color: AppColors.getPrimary(Get.isDarkMode),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Applications Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not applied to any jobs yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    dynamic application,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final title = application['job_title'] ?? 'Untitled Role';
    final company = application['company'] ?? 'Company';
    final location = application['location'] ?? 'N/A';
    final salary = application['salary_range']?.toString() ?? '';
    final appliedAtDate = application['applied_at'] != null
        ? application['applied_at'].toString()
        : '';
    final status = application['status'] ?? 'applied';
    final statusLabel = application['status_label'] ?? 'Applied';

    String appliedOn = 'Recently';
    if (appliedAtDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(appliedAtDate);
        appliedOn = '${parsed.day}/${parsed.month}/${parsed.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status, statusLabel, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                location,
                style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
              ),
              if (salary.isNotEmpty) ...[
                const SizedBox(width: 14),
                Icon(
                  Icons.monetization_on_outlined,
                  size: 14,
                  color: subtitleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  salary,
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
              ],
              const Spacer(),
              Text(
                'Applied: $appliedOn',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Step: ${status == 'applied' ? 'Reviewing' : statusLabel}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showDetailsBottomSheet(
                  application,
                  isDark,
                  cardColor,
                  textColor,
                  subtitleColor,
                ),
                icon: const Text('Manage'),
                label: const Icon(Icons.arrow_forward_ios, size: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label, bool isDark) {
    Color badgeColor = Colors.grey;
    switch (status) {
      case 'applied':
      case 'interview_slot_booked':
        badgeColor = const Color(0xFFF59E0B); // Orange
        break;
      case 'shortlisted':
      case 'selected':
      case 'hired':
        badgeColor = const Color(0xFF10B981); // Green
        break;
      case 'rejected':
        badgeColor = Colors.redAccent;
        break;
      case 'hold':
      case 'withdrawn':
      case 'filtered_out':
      default:
        badgeColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(
    dynamic application,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final title = application['job_title'] ?? 'Untitled Role';
    final company = application['company'] ?? 'Company';
    final status = application['status'] ?? 'applied';
    final statusMessage = application['status_message'] ?? '';
    final timeline = application['timeline'] ?? [];
    final recruiterActivity = application['recruiter_activity'] ?? {};
    final resumeTitle =
        application['resume_version_title'] ?? 'Default Profile Resume';
    final aiPolicy = application['ai_interview_policy'] ?? 'REQUIRED_HARD';

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Next step copy
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusMessage,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recruiter activity
                    _buildRecruiterActivityWidget(recruiterActivity, isDark),
                    const SizedBox(height: 20),

                    // Details
                    Text(
                      'Application Info',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Resume used', resumeTitle, isDark),
                    _buildDetailRow(
                      'Interview policy',
                      aiPolicy.toString().replaceAll('_', ' '),
                      isDark,
                    ),
                    const SizedBox(height: 20),

                    // Timeline
                    Text(
                      'Timeline Progress',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimelineWidget(timeline, isDark),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(application, status, isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[500]),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruiterActivityWidget(dynamic activity, bool isDark) {
    final profileViewed =
        activity['profile_unique_recruiters'] ??
        activity['profile_viewed_count'] ??
        0;
    final contactViewed =
        activity['contact_unique_recruiters'] ??
        activity['contact_viewed_count'] ??
        0;
    final resumeDownloaded =
        activity['resume_unique_recruiters'] ??
        activity['resume_downloaded_count'] ??
        0;
    final lastActivityAt = activity['last_recruiter_activity_at'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recruiter Activity Highlights',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActivityItem(
                'Profile views',
                profileViewed.toString(),
                Icons.visibility_outlined,
                isDark,
              ),
              _buildActivityItem(
                'Contact details',
                contactViewed.toString(),
                Icons.contacts_outlined,
                isDark,
              ),
              _buildActivityItem(
                'Resumes',
                resumeDownloaded.toString(),
                Icons.description_outlined,
                isDark,
              ),
            ],
          ),
          if (lastActivityAt != null &&
              lastActivityAt.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Last activity recorded: $lastActivityAt',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.getPrimary(isDark)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildTimelineWidget(List<dynamic> timeline, bool isDark) {
    final hasRejected = timeline.any((step) => step['key'] == 'rejected');
    final filteredTimeline = hasRejected
        ? timeline.where((step) => step['key'] != 'selected').toList()
        : timeline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(filteredTimeline.length, (index) {
        final step = filteredTimeline[index];
        final label = step['label'] ?? '';
        final note = step['note'] ?? '';
        final isDone = step['is_done'] == true;
        final isCurrent = step['is_current'] == true;
        final isLast = index == filteredTimeline.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.getPrimary(isDark)
                          : (isDone
                                ? const Color(0xFF10B981)
                                : Colors.grey[400]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : (isDone
                                ? const Color(0xFF10B981)
                                : Colors.grey[300]),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isCurrent || isDone
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.getPrimary(isDark)
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF111827)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(dynamic application, String status, bool isDark) {
    final aiPolicy = application['ai_interview_policy'] ?? 'REQUIRED_HARD';
    final isWithdrawAllowed = ![
      'withdrawn',
      'filtered_out',
      'rejected',
      'selected',
      'hired',
      'interview_slot_booked',
    ].contains(status);

    final prep = application['interview_prep'];
    final hasPrep =
        prep != null &&
        ((prep is Map && prep.isNotEmpty) || (prep is List && prep.isNotEmpty));
    final canShowCoaching =
        hasPrep &&
        ![
          'filtered_out',
          'rejected',
          'withdrawn',
          'selected',
          'hired',
        ].contains(status);

    final applicationId = application['id']?.toString() ?? '0';

    return Column(
      children: [
        if (status == 'applied' && aiPolicy != 'OFF') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchWebUrl('candidate/applications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                aiPolicy == 'OPTIONAL'
                    ? 'Start AI Interview (Optional)'
                    : 'Start AI Interview',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (status == 'shortlisted') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(
                () => BookInterviewSlotScreen(applicationId: applicationId),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Book Interview Slot',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (status == 'interview_slot_booked') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const MyInterviewBookingsScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'View Interview Schedule',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canShowCoaching) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchWebUrl(
                'candidate/applications/$applicationId/mock-interview',
              ),
              icon: Icon(
                Icons.forum_outlined,
                size: 18,
                color: AppColors.getPrimary(isDark),
              ),
              label: Text(
                'Continue Preparation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.getPrimary(isDark)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (isWithdrawAllowed) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  _confirmWithdrawal(int.tryParse(applicationId) ?? 0),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Withdraw Application',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _launchWebUrl(String path) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/$path',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar('Error', 'Could not open portal page.');
      }
    } catch (_) {
      Get.snackbar('Error', 'Invalid portal URL.');
    }
  }

  void _confirmWithdrawal(int id) {
    Get.defaultDialog(
      title: 'Withdraw Application?',
      middleText:
          'Are you sure you want to withdraw this application? This action cannot be undone.',
      textCancel: 'Cancel',
      textConfirm: 'Withdraw',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back(); // close dialog
        Get.back(); // close bottom sheet
        await controller.withdrawApplication(id);
      },
    );
  }
}
