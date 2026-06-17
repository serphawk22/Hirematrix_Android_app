import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';

class RecruitmentPipelineScreen extends StatefulWidget {
  const RecruitmentPipelineScreen({super.key});

  @override
  State<RecruitmentPipelineScreen> createState() =>
      _RecruitmentPipelineScreenState();
}

class _RecruitmentPipelineScreenState extends State<RecruitmentPipelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _stages = [
    'Applied',
    'Screening',
    'Shortlisted',
    'Interview',
    'Offer',
    'Hired',
    'Rejected',
    'Withdrawn',
  ];
  final ApiService _apiService = ApiService();
  List<dynamic> _allApplications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  Future<void> _loadApplications() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Recruiter session is missing. Please sign in again.';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apps = await _apiService.fetchApplications(recruiterId);
      if (mounted) {
        setState(() {
          _allApplications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Talent Pipeline',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[100]!,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.getPrimary(isDark),
              labelColor: AppColors.getPrimary(isDark),
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _stages.map((s) => Tab(text: s)).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _errorMessage != null
          ? _buildErrorState(isDark, _errorMessage!)
          : TabBarView(
              controller: _tabController,
              children: _stages
                  .map((s) => _buildCandidateList(s, isDark))
                  .toList(),
            ),
    );
  }

  Widget _buildCandidateList(String stage, bool isDark) {
    final filteredCandidates = _allApplications
        .where(
          (app) =>
              _normalizeStage(app['status']?.toString() ?? '') ==
              _normalizeStage(stage),
        )
        .toList();

    if (filteredCandidates.isEmpty) {
      return _buildEmptyState(isDark, stage);
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: filteredCandidates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = filteredCandidates[index];
          return _buildCandidateCard(c, isDark, stage);
        },
      ),
    );
  }

  Widget _buildCandidateCard(
    Map<String, dynamic> c,
    bool isDark,
    String stage,
  ) {
    final matchScore = c['match_score']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.getPrimary(
                  isDark,
                ).withValues(alpha: 0.1),
                child: Text(
                  (c['candidate_name']?[0] ?? 'C').toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
                      c['candidate_name'] ?? 'Candidate',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      c['job_title'] ?? 'Role',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$matchScore% Match',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetaItem(
                Icons.work_history_rounded,
                c['experience'] ?? 'N/A',
              ),
              const SizedBox(width: 12),
              _buildMetaItem(Icons.email_outlined, c['candidate_email'] ?? ''),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Skills: ${_formatSkills(c['skills'])}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'Resume',
                  Icons.description_outlined,
                  isDark,
                  () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  'Move Stage',
                  Icons.input_rounded,
                  isDark,
                  () => _showStagePicker(c),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(Icons.more_horiz_rounded, isDark, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String stage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No candidates in $stage',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem_rounded,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not sync pipeline',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStagePicker(Map<String, dynamic> app) {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Move to Stage',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ..._stages.map(
                  (stage) => ListTile(
                    title: Text(stage),
                    trailing:
                        _normalizeStage(app['status']?.toString() ?? '') ==
                            _normalizeStage(stage)
                        ? Icon(
                            Icons.check_circle,
                            color: AppColors.getPrimary(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          )
                        : null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final response = await _apiService
                          .updateApplicationStatus(
                            app['application_id'].toString(),
                            stage,
                            recruiterId,
                          );
                      if (!mounted) return;
                      if (response['success'] == true) {
                        Provider.of<DashboardController>(
                          context,
                          listen: false,
                        ).refresh(recruiterId);
                        try {
                          Provider.of<ApplicationsController>(
                            context,
                            listen: false,
                          ).fetchApplications(recruiterId);
                          Provider.of<JobsController>(
                            context,
                            listen: false,
                          ).fetchJobs(recruiterId);
                        } catch (_) {}
                        await _loadApplications();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response['message']?.toString() ??
                                  'Update failed',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeStage(String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    switch (normalized) {
      case 'interview_slot_booked':
      case 'interview_scheduled':
        return 'interview';
      case 'ai_interview_started':
      case 'ai_interview_completed':
      case 'ai_evaluated':
        return 'screening';
      case 'selected':
        return 'offer';
      case 'on_hold':
        return 'hold';
      default:
        return normalized;
    }
  }

  String _formatSkills(dynamic skills) {
    if (skills is List) {
      final text = skills
          .map((skill) => skill.toString())
          .where((skill) => skill.trim().isNotEmpty)
          .join(', ');
      return text.isEmpty ? 'Not specified' : text;
    }
    final text = skills?.toString() ?? '';
    return text.trim().isEmpty ? 'Not specified' : text;
  }
}
