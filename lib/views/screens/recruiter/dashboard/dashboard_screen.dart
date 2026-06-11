import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/language_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';
import '../candidates/recruitment_pipeline_screen.dart';
import '../jobs/interview_slots_screen.dart';
import '../jobs/post_job_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        await Provider.of<DashboardController>(context, listen: false)
          .fetchDashboard(auth.currentRecruiter!.id, auth: auth);
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

        final stats = (dashboard.dashboardData['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

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
                _buildOperationalQuickActions(context, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(lang.translate('hiring_overview'), isDarkMode, null),
                SizedBox(height: Responsive.spacing(12)),
                _buildHiringOverviewGrid(dashboard.dashboardData, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(lang.translate('talent'), isDarkMode, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RecruitmentPipelineScreen())).then((_) => _loadData());
                }),
                SizedBox(height: Responsive.spacing(12)),
                _buildPipelineHorizontalList(dashboard.dashboardData, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(lang.translate('upcoming_interviews'), isDarkMode, null),
                SizedBox(height: Responsive.spacing(12)),
                _buildInterviewList(dashboard.upcomingInterviews, isDarkMode),
                SizedBox(height: Responsive.spacing(28)),
                _buildSectionHeader(lang.translate('recruiter_activity'), isDarkMode, null),
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

  Widget _buildRecruiterHero(Recruiter? recruiter, bool isDark, Map<String, dynamic> stats) {
    String greetingText = "Good Morning";
    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) greetingText = "Good Afternoon";
    if (hour >= 17) greetingText = "Good Evening";

    final hasActiveJobs = (int.tryParse(stats['open_jobs']?.toString() ?? '0') ?? 0) > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: Responsive.fontSize(10),
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.8),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${recruiter?.fullName ?? 'Recruiter'} 👋',
                    style: GoogleFonts.inter(fontSize: Responsive.fontSize(22), fontWeight: FontWeight.w800, color: AppColors.getText(isDark)),
                  ),
                ],
              ),
              Text(
                recruiter?.companyName ?? 'Enterprise Recruitment Partner',
                style: GoogleFonts.inter(fontSize: Responsive.fontSize(13), color: AppColors.getTextMuted(isDark), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildHeroChip(
                    hasActiveJobs 
                      ? Provider.of<LanguageController>(context, listen: false).translate('active_hiring') 
                      : Provider.of<LanguageController>(context, listen: false).translate('no_active_hiring'), 
                    hasActiveJobs ? Colors.green : Colors.grey, 
                    isDark
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: Responsive.scale(44), height: Responsive.scale(44),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.getPrimary(isDark).withValues(alpha: 0.1), width: 1.5),
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
            child: Text(
              (recruiter != null && recruiter.fullName.isNotEmpty)
                  ? recruiter.fullName[0].toUpperCase()
                  : 'R',
              style: GoogleFonts.inter(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.w800, color: AppColors.getPrimary(isDark)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroChip(String label, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildOperationalQuickActions(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildQuickActionBtn('Post Job', Icons.add_box_rounded, Colors.blue, isDark, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PostJobScreen())).then((_) => _loadData());
          }),
          _buildQuickActionBtn('Schedule', Icons.calendar_today_rounded, Colors.orange, isDark, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InterviewSlotsScreen())).then((_) => _loadData());
          }),
          _buildQuickActionBtn('Talent', Icons.person_add_rounded, Colors.green, isDark, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RecruitmentPipelineScreen())).then((_) => _loadData());
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(String label, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Container(
      width: Responsive.scale(92),
      margin: EdgeInsets.only(right: Responsive.spacing(10)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: Responsive.scale(18)),
                SizedBox(height: Responsive.spacing(6)),
                Text(label, style: GoogleFonts.inter(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiringOverviewGrid(Map<String, dynamic> data, bool isDark) {
    final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
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
          AppColors.secondaryLight, 
          isDark
        ),
        _buildHiringOverviewCard(
          lang.translate('open_jobs'), 
          stats['open_jobs']?.toString() ?? '0', 
          'Currently hiring', 
          Icons.business_center_rounded, 
          AppColors.primaryLight, 
          isDark
        ),
        _buildHiringOverviewCard(
          lang.translate('conversion_rate'), 
          stats['conversion_rate']?.toString() ?? '0%', 
          'Pipeline efficiency', 
          Icons.pie_chart_rounded, 
          const Color(0xFFF5BC0B), 
          isDark
        ),
        _buildHiringOverviewCard(
          lang.translate('interview_bookings'), 
          stats['interview_bookings']?.toString() ?? '0', 
          'HR rounds scheduled', 
          Icons.calendar_today_rounded, 
          Colors.blue, 
          isDark
        ),
      ],
    );
  }

  Widget _buildHiringOverviewCard(String label, String val, String sub, IconData icon, Color accentColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!.withValues(alpha: 0.5), 
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
            // Left Accent Border
            Positioned(
              left: 0, top: 0, bottom: 0,
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
                        style: GoogleFonts.inter(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF16212B),
                        ),
                      ),
                      Icon(icon, size: 24, color: accentColor.withValues(alpha: 0.8)),
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
    );
  }

  Widget _buildPipelineHorizontalList(Map<String, dynamic> data, bool isDark) {
    final stats = (data['pipeline_stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final stages = [
      {'n': 'Applied', 'c': stats['Applied']?.toString() ?? '0', 'col': Colors.blue, 'sub': 'Candidates'},
      {'n': 'Screening', 'c': stats['Screening']?.toString() ?? '0', 'col': Colors.orange, 'sub': 'Pending'},
      {'n': 'Shortlisted', 'c': stats['Shortlisted']?.toString() ?? '0', 'col': Colors.teal, 'sub': 'Selected'},
      {'n': 'Interview', 'c': stats['Interview']?.toString() ?? '0', 'col': Colors.indigo, 'sub': 'Scheduled'},
      {'n': 'Offer', 'c': stats['Offer']?.toString() ?? '0', 'col': Colors.purple, 'sub': 'Sent'},
      {'n': 'Hired', 'c': stats['Hired']?.toString() ?? '0', 'col': Colors.green, 'sub': 'Onboarded'},
      {'n': 'Rejected', 'c': stats['Rejected']?.toString() ?? '0', 'col': Colors.redAccent, 'sub': 'Archived'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: stages.map((s) => Container(
          width: Responsive.scale(130),
          margin: EdgeInsets.only(right: Responsive.spacing(12)),
          padding: EdgeInsets.all(Responsive.spacing(12)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (s['col'] as Color).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (s['col'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (s['n'] as String).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: Responsive.fontSize(8),
                          fontWeight: FontWeight.w700,
                          color: s['col'] as Color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['c'] as String,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.fontSize(16),
                        fontWeight: FontWeight.w800,
                        color: AppColors.getText(isDark),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      s['sub'] as String,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.fontSize(10),
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextMuted(isDark),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.withValues(alpha: 0.3)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInterviewList(List<dynamic> interviews, bool isDark) {
    final lang = Provider.of<LanguageController>(context);
    if (interviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.spacing(20)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note_rounded, size: 32, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(lang.translate('no_upcoming_interviews'), 
              style: GoogleFonts.inter(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w500, color: AppColors.getTextMuted(isDark))
            ),
          ],
        ),
      );
    }

    return Column(
      children: interviews.take(2).map((item) => _buildInterviewItem(item, isDark)).toList(),
    );
  }

  Widget _buildInterviewItem(Map<String, dynamic> item, bool isDark) {
    final date = DateTime.tryParse(item['interview_date'] ?? '') ?? DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(date);
    final type = item['interview_type'] ?? 'Round';
    final mode = item['interview_mode'] ?? 'Online';
    final meetingLink = item['meeting_link'];
    final bool isBooked = item['is_booked'] == true || item['is_booked'] == 'true';

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
                backgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                child: Text(item['candidate_name']?[0] ?? 'C', style: TextStyle(color: AppColors.getPrimary(isDark), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['candidate_name'] ?? 'Candidate', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${item['job_title'] ?? 'Role'} • $type', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
                    Text(timeStr, style: GoogleFonts.inter(fontSize: 10, color: AppColors.getPrimary(isDark), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: (mode.toLowerCase() == 'online' ? Colors.blue : Colors.orange).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(mode.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: mode.toLowerCase() == 'online' ? Colors.blue : Colors.orange)),
              ),
            ],
          ),
          if (isBooked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                     onTap: mode.toLowerCase() == 'online' ? () => _joinMeeting(meetingLink) : null,
                     child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: mode.toLowerCase() == 'online' ? AppColors.getPrimary(isDark) : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(Provider.of<LanguageController>(context, listen: false).translate('join_meeting'), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
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
                      child: Text(Provider.of<LanguageController>(context, listen: false).translate('reschedule'), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Waiting for candidate booking...',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link unavailable'), backgroundColor: AppColors.error));
      return;
    }
    final url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch meeting link'), backgroundColor: AppColors.error));
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
                Icon(Icons.history_rounded, size: 32, color: Colors.grey.withValues(alpha: 0.1)),
                const SizedBox(height: 8),
                Text('No recent activity.', 
                  style: GoogleFonts.inter(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w500, color: AppColors.getTextMuted(isDark))
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 4 ? 4 : activities.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]!),
            itemBuilder: (context, index) {
              final act = activities[index];
              return ListTile(
                dense: true,
                minLeadingWidth: 0,
                leading: Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.getPrimary(isDark).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                title: Text(act['action'] ?? 'Recruiter Activity', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                subtitle: Text(act['details'] ?? '', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.getTextMuted(isDark))),
                trailing: Text(
                  DateFormat('hh:mm a').format(DateTime.tryParse(act['created_at'] ?? '') ?? DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w800, color: AppColors.getText(isDark)),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text('View all', style: GoogleFonts.inter(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: AppColors.getPrimary(isDark))),
                const SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.getPrimary(isDark)),
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
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reschedule Interview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Select New Date'),
          _buildPickerTile(
            icon: Icons.calendar_today_rounded,
            text: _selectedDate == null ? 'Choose Date' : DateFormat('dd MMM, yyyy').format(_selectedDate!),
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
            text: _selectedTime == null ? 'Choose Time' : _selectedTime!.format(context),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (time != null) setState(() => _selectedTime = time);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildLabel('Interview Mode'),
          Row(
            children: ['Online', 'Offline', 'Hybrid'].map((m) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(m),
                selected: _mode == m,
                onSelected: (val) => setState(() => _mode = m),
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _mode == m ? Colors.white : Colors.grey),
                selectedColor: AppColors.getPrimary(isDark),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          _buildLabel('Update Meeting Link (if Online)'),
           TextField(
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://meet.google.com/...',
              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isUpdating ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
               minimumSize: const Size(double.infinity, 48),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUpdating 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Reschedule'),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)));

  Widget _buildPickerTile({required IconData icon, required String text, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 12),
            Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _handleUpdate() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
      return;
    }

    setState(() => _isUpdating = true);
    
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    final finalDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    final success = await Provider.of<DashboardController>(context, listen: false).rescheduleInterview({
      'interview_id': widget.interview['id'],
      'recruiter_id': recruiterId,
      'interview_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime),
      'interview_mode': _mode,
    });

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interview rescheduled successfully'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reschedule'), backgroundColor: AppColors.error));
      }
    }
  }
}
