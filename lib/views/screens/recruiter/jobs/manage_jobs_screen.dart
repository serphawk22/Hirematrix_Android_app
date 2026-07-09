import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';
import 'job_detail_responses_screen.dart';
import 'edit_job_screen.dart';
import 'preview_job_screen.dart';
import '../dashboard/candidate_insights_screen.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'All Jobs',
    'Active',
    'Drafts',
    'Expired',
    'Closed',
  ];
  final TextEditingController _searchController = TextEditingController();

  String? _selectedWorkMode;
  String? _selectedExperience;
  String? _selectedDepartment;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<JobsController>(
        context,
        listen: false,
      ).fetchJobs(recruiterId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final recruiter = Provider.of<AuthController>(context).currentRecruiter;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (recruiter == null)
      return const Scaffold(
        body: Center(child: Text('Please login to manage jobs')),
      );

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildAttentionInbox(isDarkMode),
            _buildOperationalStatsGrid(isDarkMode),
            _buildSearchRow(isDarkMode),
            _buildEnterpriseFilterTabs(isDarkMode),
            Expanded(
              child: Consumer<JobsController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: _tabs
                        .map(
                          (status) => _buildJobWorkspace(
                            controller.jobs,
                            status,
                            isDarkMode,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionInbox(bool isDark) {
    return Consumer<JobsController>(
      builder: (context, controller, _) {
        final alerts = controller.recruiterAlerts;
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: EdgeInsets.fromLTRB(Responsive.paddingH, 0, Responsive.paddingH, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.getBorder(isDark) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        size: 16, color: AppColors.getPrimary(isDark)),
                    const SizedBox(width: 7),
                    Text('Attention Inbox',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getText(isDark),
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.getPrimary(isDark).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text('${alerts.length} active',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getPrimary(isDark),
                          )),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _buildAlertCard(alerts[i], isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _toneColors = {
    'danger': Color(0xFFEF4444),
    'warning': Color(0xFFF59E0B),
    'info': Color(0xFF1FB7B5),
  };

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final tone = alert['tone']?.toString() ?? 'info';
    final toneColor = _toneColors[tone] ?? const Color(0xFF1FB7B5);
    final bgColor = isDark
        ? AppColors.getBorder(isDark).withValues(alpha: 0.18)
        : toneColor.withValues(alpha: 0.04);
    return GestureDetector(
      onTap: () {
        final jobIdStr = alert['job_id']?.toString();
        if (jobIdStr != null && jobIdStr.isNotEmpty) {
          final jobsController = Provider.of<JobsController>(context, listen: false);
          try {
            final job = jobsController.jobs.firstWhere(
              (j) => j.jobId.toString() == jobIdStr,
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailResponsesScreen(job: job)),
            );
          } catch (e) {
            // job not found in loaded list
          }
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? AppColors.getBorder(isDark)
                : toneColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    alert['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alert['meta']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextMuted(isDark),
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                alert['detail']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.getTextMuted(isDark),
                ),
              ),
            ),
            Text(
              alert['action']?.toString() ?? 'Open →',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttentionBlock(Job job, bool isDark) {
    final isCritical = job.attentionLevel == 'critical';
    final pillBg = isCritical
        ? (isDark ? const Color(0xFF3B0A0A) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF3B2E00) : const Color(0xFFFFFBEB));
    final pillBorder = isCritical
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
        : (isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D));
    final pillText = isCritical
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
        : (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E));

    final summaryParts = <String>[
      if ((job.shortlistedCount ?? 0) == 0 && (job.applicationsCount ?? 0) > 0) '0 shortlisted',
      if (job.averageAtsScore > 0) '${job.averageAtsScore}% avg match',
      ...job.attentionFacts,
    ];

    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: pillBorder),
            ),
            child: Text(
              isCritical ? 'Critical priority' : 'Watch',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: pillText,
              ),
            ),
          ),
          if (summaryParts.isNotEmpty) ...[  
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                summaryParts.join(' · '),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.getTextMuted(isDark),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ];
  }

  Widget _buildOperationalStatsGrid(bool isDark) {
    return Consumer<JobsController>(
      builder: (context, controller, child) {
        int active = controller.jobs.where((j) => j.status == 'Active').length;
        int draft = controller.jobs.where((j) => j.status == 'Draft').length;
        int expired = controller.jobs
            .where((j) => j.status == 'Expired')
            .length;
        int closed = controller.jobs.where((j) => j.status == 'Closed').length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.paddingH,
            vertical: 8,
          ),
          child: Row(
            children: [
              _buildCompactStatCard(
                'Active',
                active.toString(),
                Icons.bolt_rounded,
                Colors.green,
                isDark,
              ),
              _buildCompactStatCard(
                'Drafts',
                draft.toString(),
                Icons.edit_note_rounded,
                Colors.orange,
                isDark,
              ),
              _buildCompactStatCard(
                'Expired',
                expired.toString(),
                Icons.history_rounded,
                Colors.redAccent,
                isDark,
              ),
              _buildCompactStatCard(
                'Closed',
                closed.toString(),
                Icons.lock_outline_rounded,
                Colors.blueGrey,
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    String subtext = '';
    if (label == 'Active') {
      subtext = 'Live on portal';
    } else if (label == 'Drafts') {
      subtext = 'Unpublished';
    } else if (label == 'Expired') {
      subtext = 'Needs renewal';
    } else {
      subtext = 'Filled & closed';
    }

    return Container(
      width: 142,
      height: 94,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(bool isDark) {
    final hasActiveFilters =
        _selectedWorkMode != null ||
        _selectedExperience != null ||
        _selectedDepartment != null ||
        _selectedLocation != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.paddingH,
        8,
        Responsive.paddingH,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  final recruiterId = Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).currentRecruiter?.id;
                  if (recruiterId != null) {
                    Provider.of<JobsController>(
                      context,
                      listen: false,
                    ).fetchJobs(recruiterId, query: v);
                  }
                },
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search workspace roles...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          // const SizedBox(width: 10),
          // Container(
          //   height: 44,
          //   width: 44,
          //   decoration: BoxDecoration(
          //     color: isDark ? AppColors.getCard(isDark) : Colors.white,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: hasActiveFilters
          //           ? AppColors.getPrimary(isDark)
          //           : (isDark ? Colors.white10 : Colors.grey[200]!),
          //       width: hasActiveFilters ? 1.5 : 1,
          //     ),
          //   ),
          //   child: IconButton(
          //     icon: Icon(
          //       Icons.tune_rounded,
          //       size: 20,
          //       color: hasActiveFilters
          //           ? AppColors.getPrimary(isDark)
          //           : Colors.grey,
          //     ),
          //     onPressed: () => _showFilterBottomSheet(isDark),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseFilterTabs(bool isDark) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2.5,
            color: AppColors.getPrimary(isDark),
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelColor: AppColors.getPrimary(isDark),
        unselectedLabelColor: Colors.grey[500],
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildJobWorkspace(List<Job> allJobs, String status, bool isDark) {
    var filteredJobs = allJobs;
    if (status != 'All Jobs') {
      String filterStatus = status.toLowerCase();
      if (filterStatus == 'drafts') {
        filterStatus = 'draft';
      }
      filteredJobs = filteredJobs
          .where((j) => j.status.toLowerCase() == filterStatus)
          .toList();
    }

    if (_selectedWorkMode != null) {
      filteredJobs = filteredJobs
          .where(
            (j) => j.workMode.toLowerCase() == _selectedWorkMode!.toLowerCase(),
          )
          .toList();
    }

    if (_selectedExperience != null) {
      filteredJobs = filteredJobs
          .where(
            (j) =>
                j.experience.toLowerCase() ==
                _selectedExperience!.toLowerCase(),
          )
          .toList();
    }

    if (_selectedDepartment != null) {
      filteredJobs = filteredJobs
          .where(
            (j) =>
                (j.department ?? 'Engineering').toLowerCase() ==
                _selectedDepartment!.toLowerCase(),
          )
          .toList();
    }

    if (_selectedLocation != null) {
      filteredJobs = filteredJobs
          .where(
            (j) =>
                (j.location ?? 'Remote').toLowerCase() ==
                _selectedLocation!.toLowerCase(),
          )
          .toList();
    }

    if (filteredJobs.isEmpty) return _buildEmptyATSState(isDark);

    return RefreshIndicator(
      onRefresh: () async {
        final recruiterId = Provider.of<AuthController>(
          context,
          listen: false,
        ).currentRecruiter?.id;
        if (recruiterId != null) {
          await Provider.of<JobsController>(
            context,
            listen: false,
          ).fetchJobs(recruiterId);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: filteredJobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildAtsJobCard(filteredJobs[index], isDark),
      ),
    );
  }

  Widget _buildAtsJobCard(Job job, bool isDark) {
    final status = job.status.toUpperCase();
    final pipeline = job.pipeline ?? {};

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.getBorder(isDark) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(
                          isDark,
                        ).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.business_center_rounded,
                        size: 20,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getText(isDark),
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.getTextMuted(isDark),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  job.location ?? 'Remote',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppColors.getTextMuted(isDark),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.apartment_rounded,
                                size: 13,
                                color: AppColors.getTextMuted(isDark),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  job.department ?? 'Engineering',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppColors.getTextMuted(isDark),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusIndicator(status, isDark),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildMetadataBadge('💼 ${job.experience}', isDark),
                      const SizedBox(width: 8),
                      _buildMetadataBadge('📍 ${job.workMode}', isDark),
                      if (job.salary != null && job.salary!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildMetadataBadge('💰 ${job.salary}', isDark),
                      ],
                      const SizedBox(width: 8),
                      _buildMetadataBadge(
                        '📅 Posted ${_formatDate(job.createdAt)}',
                        isDark,
                      ),
                    ],
                  ),
                ),
                // Attention pill + summary + quick actions
                if (job.attentionLevel == 'critical' || job.attentionLevel == 'watch') ..._buildAttentionBlock(job, isDark),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.getBorder(isDark).withValues(alpha: 0.15)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.getBorder(isDark).withValues(alpha: 0.3)
                    : const Color(0xFFEDF2F7),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'APPLICANT PIPELINE',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextMuted(isDark),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (job.averageAtsScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${job.averageAtsScore}% avg match',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.trending_up_rounded,
                        size: 13,
                        color: AppColors.getTextMuted(isDark),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPipelineSegment(
                      (job.applicationsCount ?? 0).toString(),
                      'Applied',
                      isDark,
                    ),
                    _buildPipelineDivider(isDark),
                    _buildPipelineSegment(
                      (job.shortlistedCount ?? 0).toString(),
                      'Shortlisted',
                      isDark,
                    ),
                    _buildPipelineDivider(isDark),
                    _buildPipelineSegment(
                      pipeline['Interview']?.toString() ?? '0',
                      'Interviews',
                      isDark,
                    ),
                    _buildPipelineDivider(isDark),
                    _buildPipelineSegment(
                      pipeline['Hired']?.toString() ?? '0',
                      'Hires',
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                // Row 1: Edit + Pipeline
                Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditJobScreen(job: job),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionBtn(
                        label: 'Pipeline',
                        icon: Icons.account_tree_outlined,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailResponsesScreen(job: job),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Preview + Leaderboard
                Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        label: 'Preview',
                        icon: Icons.visibility_outlined,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewJobScreen(job: job),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionBtn(
                        label: 'Leaderboard',
                        icon: Icons.leaderboard_rounded,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidateInsightsScreen(
                              preselectedJobId: job.jobId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Close / Reopen (full width)
                Builder(
                  builder: (ctx) {
                    final isOpen = job.status.toLowerCase() == 'active';
                    return SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                isOpen ? 'Close Job?' : 'Reopen Job?',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                isOpen
                                    ? 'Closing this job will prevent new applications.'
                                    : 'Reopening will allow candidates to apply again.',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOpen
                                        ? Colors.red
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    isOpen ? 'Close' : 'Reopen',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && ctx.mounted) {
                            final recruiterId = Provider.of<AuthController>(
                              ctx,
                              listen: false,
                            ).currentRecruiter?.id;
                            if (recruiterId != null) {
                              final ok =
                                  await Provider.of<JobsController>(
                                    ctx,
                                    listen: false,
                                  ).updateJobStatus(
                                    job.jobId,
                                    recruiterId,
                                    isOpen ? 'closed' : 'open',
                                  );
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? (isOpen
                                                ? 'Job closed successfully'
                                                : 'Job reopened successfully')
                                          : 'Failed to update job status',
                                    ),
                                    backgroundColor: ok
                                        ? (isOpen
                                              ? Colors.orange
                                              : Colors.green)
                                        : Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(
                          isOpen
                              ? Icons.lock_outline_rounded
                              : Icons.lock_open_rounded,
                          size: 15,
                          color: isOpen ? Colors.red : Colors.green,
                        ),
                        label: Text(
                          isOpen ? 'Close Job' : 'Reopen Job',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? Colors.red : Colors.green,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? (isOpen
                                    ? Colors.red.withValues(alpha: 0.05)
                                    : Colors.green.withValues(alpha: 0.05))
                              : (isOpen
                                    ? Colors.red.withValues(alpha: 0.03)
                                    : Colors.green.withValues(alpha: 0.03)),
                          side: BorderSide(
                            color: isOpen
                                ? Colors.red.withValues(alpha: 0.4)
                                : Colors.green.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white,
          foregroundColor: AppColors.getPrimary(isDark),
          side: BorderSide(
            color: isDark
                ? AppColors.getPrimary(isDark).withValues(alpha: 0.3)
                : AppColors.getPrimary(isDark).withValues(alpha: 0.4),
            width: 1.2,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status, bool isDark) {
    Color dotColor = Colors.green;
    if (status == 'DRAFT') dotColor = Colors.orange;
    if (status == 'EXPIRED' || status == 'CLOSED') dotColor = Colors.redAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          status[0].toUpperCase() + status.substring(1).toLowerCase(),
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.getTextMuted(isDark),
        ),
      ),
    );
  }

  Widget _buildPipelineSegment(String count, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: isDark ? Colors.white24 : Colors.grey[350]!,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  Widget _buildEmptyATSState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_center_outlined,
              size: 40,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No roles found in this status.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try refining your search or filters.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(bool isDark) {
    final controller = Provider.of<JobsController>(context, listen: false);
    final allJobs = controller.jobs;

    final departments = allJobs
        .map((j) => j.department ?? 'Engineering')
        .where((d) => d.trim().isNotEmpty)
        .toSet()
        .toList();
    departments.sort();

    final locations = allJobs
        .map((j) => j.location ?? 'Remote')
        .where((l) => l.trim().isNotEmpty)
        .toSet()
        .toList();
    locations.sort();

    String? tempWorkMode = _selectedWorkMode;
    String? tempExperience = _selectedExperience;
    String? tempDepartment = _selectedDepartment;
    String? tempLocation = _selectedLocation;

    int currentTabIdx = _tabController.index;
    String? tempStatus = _tabs[currentTabIdx];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Workspace Roles',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getText(isDark),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempWorkMode = null;
                              tempExperience = null;
                              tempDepartment = null;
                              tempLocation = null;
                              tempStatus = 'All Jobs';
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    _buildFilterSectionTitle('STATUS', isDark),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tabs.map((status) {
                        final isSelected = tempStatus == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => tempStatus = status);
                            }
                          },
                          selectedColor: AppColors.getPrimary(
                            isDark,
                          ).withOpacity(0.15),
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.getPrimary(isDark)
                                : AppColors.getTextMuted(isDark),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.getPrimary(isDark)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildFilterSectionTitle('WORK MODE', isDark),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Onsite', 'Hybrid', 'Remote'].map((mode) {
                        final isSelected = tempWorkMode == mode;
                        return ChoiceChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              tempWorkMode = selected ? mode : null;
                            });
                          },
                          selectedColor: AppColors.getPrimary(
                            isDark,
                          ).withOpacity(0.15),
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.getPrimary(isDark)
                                : AppColors.getTextMuted(isDark),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.getPrimary(isDark)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _buildFilterSectionTitle('EXPERIENCE REQUIRED', isDark),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ['Fresher', '1-2 Years', '3-5 Years', '5+ Years'].map(
                            (exp) {
                              final isSelected = tempExperience == exp;
                              return ChoiceChip(
                                label: Text(exp),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    tempExperience = selected ? exp : null;
                                  });
                                },
                                selectedColor: AppColors.getPrimary(
                                  isDark,
                                ).withOpacity(0.15),
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.03)
                                    : const Color(0xFFF1F5F9),
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.getPrimary(isDark)
                                      : AppColors.getTextMuted(isDark),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.getPrimary(isDark)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                showCheckmark: false,
                              );
                            },
                          ).toList(),
                    ),
                    const SizedBox(height: 20),

                    if (departments.isNotEmpty) ...[
                      _buildFilterSectionTitle('DEPARTMENT', isDark),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: tempDepartment,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: isDark
                              ? AppColors.bgCardDark
                              : Colors.white,
                          hint: Text(
                            'Select Department',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey,
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getText(isDark),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Departments',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.getTextMuted(isDark),
                                ),
                              ),
                            ),
                            ...departments.map(
                              (d) => DropdownMenuItem<String>(
                                value: d,
                                child: Text(d),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() => tempDepartment = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (locations.isNotEmpty) ...[
                      _buildFilterSectionTitle('LOCATION', isDark),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: tempLocation,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: isDark
                              ? AppColors.bgCardDark
                              : Colors.white,
                          hint: Text(
                            'Select Location',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey,
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getText(isDark),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Locations',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.getTextMuted(isDark),
                                ),
                              ),
                            ),
                            ...locations.map(
                              (l) => DropdownMenuItem<String>(
                                value: l,
                                child: Text(l),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() => tempLocation = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedWorkMode = tempWorkMode;
                            _selectedExperience = tempExperience;
                            _selectedDepartment = tempDepartment;
                            _selectedLocation = tempLocation;
                            if (tempStatus != null) {
                              int tabIdx = _tabs.indexOf(tempStatus!);
                              if (tabIdx != -1) {
                                _tabController.animateTo(tabIdx);
                              }
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.getTextMuted(isDark),
        letterSpacing: 0.5,
      ),
    );
  }
}
