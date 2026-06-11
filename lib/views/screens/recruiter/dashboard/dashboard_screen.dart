import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/language_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';
import '../candidates/recruitment_pipeline_screen.dart';
import '../jobs/interview_slots_screen.dart';
import '../jobs/post_job_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showPendingActionsAlert = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.currentRecruiter != null) {
      try {
        await Provider.of<DashboardController>(
          context,
          listen: false,
        ).fetchDashboard(auth.currentRecruiter!.id, auth: auth);
      } catch (e) {
        if (e.toString().contains("SESSION_INVALID")) {
          if (mounted) {
            auth.logout();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final recruiter = Provider.of<AuthController>(context).currentRecruiter;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageController>(context);

    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        if (dashboard.isLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final stats =
            (dashboard.dashboardData['stats'] as Map?)
                ?.cast<String, dynamic>() ??
            <String, dynamic>{};

        // Calculate pending screen count & interviews today count
        final int pendingScreening = stats['need_review'] ?? 0;
        final now = DateTime.now();
        final int hrInterviewsToday = dashboard.upcomingInterviews.where((
          item,
        ) {
          final dateStr = item['interview_date'] ?? '';
          final date = DateTime.tryParse(dateStr);
          if (date == null) return false;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).length;

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.getPrimary(isDarkMode),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.paddingH,
              vertical: Responsive.spacing(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecruiterHero(recruiter, isDarkMode, stats),
                SizedBox(height: Responsive.spacing(20)),
                _buildAlerts(
                  stats,
                  pendingScreening,
                  hrInterviewsToday,
                  isDarkMode,
                ),
                _buildSectionHeader(
                  lang.translate('hiring_overview'),
                  isDarkMode,
                  null,
                ),
                SizedBox(height: Responsive.spacing(12)),
                _buildHiringOverviewGrid(dashboard.dashboardData, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildRecruitmentPipelineCard(
                  dashboard.dashboardData,
                  isDarkMode,
                ),
                SizedBox(height: Responsive.spacing(28)),
                _buildRecentApplicationsCard(
                  dashboard.applications,
                  isDarkMode,
                ),
                SizedBox(height: Responsive.spacing(28)),
                _buildActionCenterCard(
                  pendingScreening,
                  hrInterviewsToday,
                  isDarkMode,
                ),
                SizedBox(height: Responsive.spacing(28)),
                _buildConversionMetricsCard(
                  dashboard.conversionMetrics,
                  isDarkMode,
                ),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(
                  lang.translate('upcoming_interviews'),
                  isDarkMode,
                  null,
                ),
                SizedBox(height: Responsive.spacing(12)),
                _buildInterviewList(dashboard.upcomingInterviews, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(
                  lang.translate('recruiter_activity'),
                  isDarkMode,
                  null,
                ),
                SizedBox(height: Responsive.spacing(12)),
                _buildActivityTimeline(isDarkMode),
                SizedBox(height: Responsive.spacing(100)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hero Card
  Widget _buildRecruiterHero(
    Recruiter? recruiter,
    bool isDark,
    Map<String, dynamic> stats,
  ) {
    final int totalApplications =
        int.tryParse(stats['total_applications']?.toString() ?? '0') ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.getPrimary(isDark).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.speed_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Recruiter Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Find Your Next Great Hire',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A quick view of open roles, active applications, and what needs attention today.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroActionButton(
                        'Post Job',
                        Icons.add_rounded,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PostJobScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroActionButton(
                        'Manage Job',
                        Icons.business_center_rounded,
                        () {
                          widget.onSwitchTab?.call(1);
                        },
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroActionButton(
                        '$totalApplications Candidates',
                        Icons.trending_up_rounded,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RecruitmentPipelineScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Alerts
  Widget _buildAlerts(
    Map<String, dynamic> stats,
    int pendingScreening,
    int hrInterviewsToday,
    bool isDark,
  ) {
    final bool noJobs =
        (stats['open_jobs'] ?? 0) == 0 &&
        (stats['total_applications'] ?? 0) == 0;
    if (noJobs) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(isDark)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'No jobs posted yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.getText(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Post your first job to start receiving applications and build your hiring pipeline.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.getTextMuted(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostJobScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: Text(
                'Post Your First Job',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int totalPending = pendingScreening + hrInterviewsToday;
    if (totalPending > 0 && _showPendingActionsAlert) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2213) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF5D4017) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Actions:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (pendingScreening > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF5D4017)
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pendingScreening.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          ' applications to screen',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE0A040)
                                : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                      if (pendingScreening > 0 && hrInterviewsToday > 0)
                        Text(
                          ', ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFE0A040)
                                : const Color(0xFF78350F),
                          ),
                        ),
                      if (hrInterviewsToday > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getPrimary(isDark),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hrInterviewsToday.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          ' HR interviews today',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE0A040)
                                : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showPendingActionsAlert = false;
                });
              },
              icon: Icon(
                Icons.close_rounded,
                color: isDark
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFD97706),
                size: 16,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Quick Stats Grid
  Widget _buildHiringOverviewGrid(Map<String, dynamic> data, bool isDark) {
    final stats =
        (data['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final lang = Provider.of<LanguageController>(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.isTablet ? 4 : 2,
      crossAxisSpacing: Responsive.spacing(12),
      mainAxisSpacing: Responsive.spacing(12),
      childAspectRatio: 1.4,
      children: [
        _buildHiringOverviewCard(
          lang.translate('total_applications'),
          stats['total_applications']?.toString() ?? '0',
          'Across all active jobs',
          Icons.description_rounded,
          AppColors.getSecondary(isDark),
          isDark,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecruitmentPipelineScreen(),
              ),
            ).then((_) => _loadData());
          },
        ),
        _buildHiringOverviewCard(
          lang.translate('open_jobs'),
          stats['open_jobs']?.toString() ?? '0',
          'Currently hiring',
          Icons.business_center_rounded,
          AppColors.getPrimary(isDark),
          isDark,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecruitmentPipelineScreen(),
              ),
            ).then((_) => _loadData());
          },
        ),
        _buildHiringOverviewCard(
          lang.translate('conversion_rate'),
          stats['conversion_rate']?.toString() ?? '0%',
          'Pipeline efficiency',
          Icons.pie_chart_rounded,
          const Color(0xFFF5BC0B),
          isDark,
          null,
        ),
        _buildHiringOverviewCard(
          lang.translate('interview_bookings'),
          stats['interview_bookings']?.toString() ?? '0',
          'HR rounds scheduled',
          Icons.calendar_today_rounded,
          Colors.blue,
          isDark,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InterviewSlotsScreen(),
              ),
            ).then((_) => _loadData());
          },
        ),
      ],
    );
  }

  Widget _buildHiringOverviewCard(
    String label,
    String val,
    String sub,
    IconData icon,
    Color accentColor,
    bool isDark,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[200]!.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          val,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF16212B),
                          ),
                        ),
                        Icon(
                          icon,
                          size: 24,
                          color: accentColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    Text(
                      sub,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextMuted(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recruitment Pipeline
  Widget _buildRecruitmentPipelineCard(Map<String, dynamic> data, bool isDark) {
    final stats =
        (data['pipeline_stats'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final dashboardStats =
        (data['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final int totalApps =
        int.tryParse(dashboardStats['total_applications']?.toString() ?? '0') ??
        0;

    final int shortlisted =
        int.tryParse(stats['Shortlisted']?.toString() ?? '0') ?? 0;
    final int rejected =
        int.tryParse(stats['Rejected']?.toString() ?? '0') ?? 0;
    final int screeningCompleted = shortlisted + rejected;
    final int interviewSlotBooked =
        int.tryParse(stats['Interview']?.toString() ?? '0') ?? 0;

    double calcPct(int numerator, int denominator) {
      if (denominator <= 0) return 0.0;
      return double.parse(((numerator / denominator) * 100).toStringAsFixed(1));
    }

    final double screeningPct = calcPct(screeningCompleted, totalApps);
    final double shortlistPct = calcPct(shortlisted, screeningCompleted);
    final double interviewPct = calcPct(interviewSlotBooked, shortlisted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.getPrimary(isDark),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recruitment Pipeline',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  widget.onSwitchTab?.call(1);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.getPrimary(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Review jobs',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A quick read on volume, screening progress, and where the process slows down.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.getTextMuted(isDark),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildPipelineStageItem(
            'Applications',
            totalApps,
            Icons.inbox,
            AppColors.getPrimary(isDark),
            null,
            isDark,
          ),
          _buildPipelineDivider(isDark),
          _buildPipelineStageItem(
            'Screening Completed',
            screeningCompleted,
            Icons.settings_outlined,
            Colors.blue,
            '$screeningPct% from applications',
            isDark,
          ),
          _buildPipelineDivider(isDark),
          _buildPipelineStageItem(
            'Shortlisted',
            shortlisted,
            Icons.star_border_rounded,
            Colors.green,
            '$shortlistPct% from screened',
            isDark,
          ),
          _buildPipelineDivider(isDark),
          _buildPipelineStageItem(
            'HR Interviews',
            interviewSlotBooked,
            Icons.calendar_today_outlined,
            Colors.orange,
            '$interviewPct% from shortlisted',
            isDark,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.getBorder(isDark).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.getTextMuted(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Each stage shows conversion rate from the previous stage.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStageItem(
    String title,
    int count,
    IconData icon,
    Color color,
    String? conversionText,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getText(isDark),
                ),
              ),
              if (conversionText != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 10,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      conversionText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Text(
          NumberFormat('#,###').format(count),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getText(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
      width: 2,
      height: 15,
      color: AppColors.getBorder(isDark),
    );
  }

  // Recent Applications
  Widget _buildRecentApplicationsCard(List<dynamic> applications, bool isDark) {
    final recent = applications.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Applications',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.getText(isDark),
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent applications',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextMuted(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 24, color: AppColors.getBorder(isDark)),
              itemBuilder: (context, index) {
                final app = recent[index];
                final candidateName = app['candidate_name'] ?? 'Candidate';
                final jobTitle = app['job_title'] ?? 'Job Role';
                final status = app['status'] ?? 'Applied';
                final appliedAt = app['applied_at'] ?? '';
                final dateFormatted = appliedAt.isNotEmpty
                    ? DateFormat(
                        'MMM dd, yyyy',
                      ).format(DateTime.tryParse(appliedAt) ?? DateTime.now())
                    : '';

                Color statusColor = Colors.grey;
                if (status.toLowerCase().contains('pending') ||
                    status.toLowerCase().contains('applied')) {
                  statusColor = Colors.orange;
                } else if (status.toLowerCase().contains('shortlist')) {
                  statusColor = Colors.blue;
                } else if (status.toLowerCase().contains('offer') ||
                    status.toLowerCase().contains('select') ||
                    status.toLowerCase().contains('hired')) {
                  statusColor = Colors.green;
                } else if (status.toLowerCase().contains('reject')) {
                  statusColor = Colors.red;
                }

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecruitmentPipelineScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.getPrimary(
                          isDark,
                        ).withValues(alpha: 0.08),
                        child: Text(
                          candidateName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidateName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getText(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jobTitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.getTextMuted(isDark),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatted,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.getTextMuted(isDark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Action Center
  Widget _buildActionCenterCard(
    int pendingScreening,
    int hrInterviewsToday,
    bool isDark,
  ) {
    final bool hasActionCenterItems =
        pendingScreening > 0 || hrInterviewsToday > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Action Center',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getText(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasActionCenterItems) ...[
            if (pendingScreening > 0) ...[
              _buildActionCenterItem(
                'Screen New Applications',
                'Review and shortlist incoming candidates.',
                pendingScreening,
                Colors.orange,
                isDark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecruitmentPipelineScreen(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              if (hrInterviewsToday > 0)
                Divider(height: 20, color: AppColors.getBorder(isDark)),
            ],
            if (hrInterviewsToday > 0) ...[
              _buildActionCenterItem(
                'Interviews Today',
                'Track today\'s booked interviews and status.',
                hrInterviewsToday,
                AppColors.getPrimary(isDark),
                isDark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterviewSlotsScreen(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ] else ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Everything is up to date',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No pending screenings or interviews right now. You\'re all caught up.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.getTextMuted(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.onSwitchTab?.call(1);
                    },
                    icon: Icon(
                      Icons.work,
                      size: 14,
                      color: AppColors.getPrimary(isDark),
                    ),
                    label: Text(
                      'Review Jobs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.getPrimary(isDark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCenterItem(
    String title,
    String subtitle,
    int count,
    Color badgeColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getText(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.getTextMuted(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Conversion Metrics
  Widget _buildConversionMetricsCard(
    Map<String, dynamic> metrics,
    bool isDark,
  ) {
    final overall = metrics['overall_conversion'] ?? 0.0;
    final appToScreen = metrics['application_to_screening'];
    final screenToShort = metrics['screening_to_shortlist'];
    final shortToInterview = metrics['shortlist_to_hr_interview'];
    final interviewToSelect = metrics['hr_interview_to_selection'];

    String formatRate(dynamic val) {
      if (val == null) return 'N/A';
      return '$val%';
    }

    Color getRateColor(dynamic val, double threshold) {
      if (val == null) return Colors.grey;
      final double dVal = double.tryParse(val.toString()) ?? 0.0;
      return dVal >= threshold ? Colors.green : Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Metrics',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.getText(isDark),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall conversion',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$overall%',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pipeline efficiency',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.getTextMuted(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Stage transitions',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getText(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quick view of where candidates move forward or slow down.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.getTextMuted(isDark),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTransitionRow(
            'Application → Screening',
            appToScreen,
            50.0,
            isDark,
            formatRate,
            getRateColor,
          ),
          _buildTransitionDivider(isDark),
          _buildTransitionRow(
            'Screening → Shortlist',
            screenToShort,
            40.0,
            isDark,
            formatRate,
            getRateColor,
          ),
          _buildTransitionDivider(isDark),
          _buildTransitionRow(
            'Shortlist → HR Interview',
            shortToInterview,
            60.0,
            isDark,
            formatRate,
            getRateColor,
          ),
          _buildTransitionDivider(isDark),
          _buildTransitionRow(
            'HR Interview → Selection',
            interviewToSelect,
            30.0,
            isDark,
            formatRate,
            getRateColor,
          ),
          _buildTransitionDivider(isDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Conversion',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getText(isDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$overall%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionRow(
    String label,
    dynamic val,
    double threshold,
    bool isDark,
    String Function(dynamic) formatRate,
    Color Function(dynamic, double) getRateColor,
  ) {
    final color = getRateColor(val, threshold);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getText(isDark),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            formatRate(val),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.getBorder(isDark).withValues(alpha: 0.5),
      ),
    );
  }

  // Original helper lists & details (Interviews & Activity)
  Widget _buildInterviewList(List<dynamic> interviews, bool isDark) {
    final lang = Provider.of<LanguageController>(context);
    if (interviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.spacing(20)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 32,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('no_upcoming_interviews'),
              style: GoogleFonts.inter(
                fontSize: Responsive.fontSize(11),
                fontWeight: FontWeight.w500,
                color: AppColors.getTextMuted(isDark),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: interviews
          .take(2)
          .map((item) => _buildInterviewItem(item, isDark))
          .toList(),
    );
  }

  Widget _buildInterviewItem(Map<String, dynamic> item, bool isDark) {
    final date =
        DateTime.tryParse(item['interview_date'] ?? '') ?? DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(date);
    final type = item['interview_type'] ?? 'Round';
    final mode = item['interview_mode'] ?? 'Online';
    final meetingLink = item['meeting_link'];
    final bool isBooked =
        item['is_booked'] == true || item['is_booked'] == 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.getPrimary(
                  isDark,
                ).withValues(alpha: 0.1),
                child: Text(
                  item['candidate_name']?[0] ?? 'C',
                  style: TextStyle(
                    color: AppColors.getPrimary(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['candidate_name'] ?? 'Candidate',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${item['job_title'] ?? 'Role'} • $type',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.getPrimary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (mode.toLowerCase() == 'online'
                              ? Colors.blue
                              : Colors.orange)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  mode.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: mode.toLowerCase() == 'online'
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (isBooked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: mode.toLowerCase() == 'online'
                        ? () => _joinMeeting(meetingLink)
                        : null,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: mode.toLowerCase() == 'online'
                            ? AppColors.getPrimary(isDark)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Provider.of<LanguageController>(
                          context,
                          listen: false,
                        ).translate('join_meeting'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _showRescheduleSheet(item),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.getBorder(isDark)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Provider.of<LanguageController>(
                          context,
                          listen: false,
                        ).translate('reschedule'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Waiting for candidate booking...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _joinMeeting(String? link) async {
    if (link == null || link.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting link unavailable'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch meeting link'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRescheduleSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RescheduleSheet(interview: item),
    );
  }

  Widget _buildActivityTimeline(bool isDark) {
    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        final activities = dashboard.recruiterActivity;
        if (activities.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.spacing(20)),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 32,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent activity.',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.fontSize(11),
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextMuted(isDark),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 4 ? 4 : activities.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
            itemBuilder: (context, index) {
              final act = activities[index];
              return ListTile(
                dense: true,
                minLeadingWidth: 0,
                leading: Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(
                  act['action'] ?? 'Recruiter Activity',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  act['details'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.getTextMuted(isDark),
                  ),
                ),
                trailing: Text(
                  DateFormat('hh:mm a').format(
                    DateTime.tryParse(act['created_at'] ?? '') ??
                        DateTime.now(),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isDark,
    VoidCallback? onSeeAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: Responsive.fontSize(14),
              fontWeight: FontWeight.w800,
              color: AppColors.getText(isDark),
            ),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.fontSize(10),
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: AppColors.getPrimary(isDark),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  final Map<String, dynamic> interview;
  const _RescheduleSheet({required this.interview});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _mode;
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.interview['interview_mode'] ?? 'Online';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.bgSoftDark : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reschedule Interview',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Select New Date'),
              _buildPickerTile(
                icon: Icons.calendar_today_rounded,
                text: _selectedDate == null
                    ? 'Choose Date'
                    : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildLabel('Select New Time'),
              _buildPickerTile(
                icon: Icons.access_time_rounded,
                text: _selectedTime == null
                    ? 'Choose Time'
                    : _selectedTime!.format(context),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _selectedTime = time);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildLabel('Interview Mode'),
              Row(
                children: ['Online', 'Offline', 'Hybrid']
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(m),
                          selected: _mode == m,
                          onSelected: (val) => setState(() => _mode = m),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mode == m ? Colors.white : Colors.grey,
                          ),
                          selectedColor: AppColors.getPrimary(isDark),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _buildLabel('Update Meeting Link (if Online)'),
              TextField(
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://meet.google.com/...',
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Reschedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    ),
  );

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdate() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success =
        await Provider.of<DashboardController>(
          context,
          listen: false,
        ).rescheduleInterview({
          'interview_id': widget.interview['id'],
          'recruiter_id': recruiterId,
          'interview_date': DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(finalDateTime),
          'interview_mode': _mode,
        });

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview rescheduled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reschedule'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
