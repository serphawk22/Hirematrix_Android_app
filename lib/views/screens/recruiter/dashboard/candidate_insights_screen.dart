import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/leaderboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import '../candidates/candidate_profile_view_screen.dart';

class CandidateInsightsScreen extends StatefulWidget {
  final String? preselectedJobId;
  const CandidateInsightsScreen({super.key, this.preselectedJobId});

  @override
  State<CandidateInsightsScreen> createState() =>
      _CandidateInsightsScreenState();
}

class _CandidateInsightsScreenState extends State<CandidateInsightsScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final leaderboardCtrl = Provider.of<LeaderboardController>(
        context,
        listen: false,
      );

      if (widget.preselectedJobId != null) {
        leaderboardCtrl.setJobId(widget.preselectedJobId);
      }

      final recruiterId = auth.currentRecruiter?.id;
      if (recruiterId != null) {
        leaderboardCtrl.fetchLeaderboardData(recruiterId);
      }
      _isInit = false;
    }
  }

  void _loadData() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<LeaderboardController>(
        context,
        listen: false,
      ).fetchLeaderboardData(recruiterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.getPrimary(isDark);
    final auth = Provider.of<AuthController>(context);
    final recruiterId = auth.currentRecruiter?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Candidate Insights',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh_rounded, size: 20, color: primary),
          ),
        ],
      ),
      body: Consumer<LeaderboardController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (controller.errorMessage != null &&
              controller.candidates.isEmpty) {
            return _buildErrorState(controller.errorMessage!, isDark);
          }

          return Column(
            children: [
              _buildFiltersCard(controller, isDark),
              if (controller.selectedJobId != null ||
                  controller.selectedSkill != null ||
                  controller.sortBy != 'technical_score')
                _buildActiveFiltersRow(controller, isDark),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: controller.candidates.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: controller.candidates.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAverageMetricsRow(
                                    controller.metrics,
                                    isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      'COMPARISON VIEW - ${controller.sortBy.toUpperCase().replaceAll('_', ' ')}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            final candidate = controller.candidates[index - 1];
                            return _buildCandidateCard(
                              candidate,
                              recruiterId,
                              isDark,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersCard(LeaderboardController controller, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.getCard(isDark) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVIEW FILTERS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Filter by Job Dropdown
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedJobId,
                      hint: Text(
                        'All Jobs',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      dropdownColor: isDark
                          ? AppColors.bgSoftDark
                          : Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'All Jobs',
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                        ...controller.jobs.map((job) {
                          return DropdownMenuItem<String>(
                            value: job['id'].toString(),
                            child: Text(
                              job['title'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        controller.setJobId(val);
                        _loadData();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter by Skill Dropdown
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedSkill,
                      hint: Text(
                        'All Skills',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      dropdownColor: isDark
                          ? AppColors.bgSoftDark
                          : Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'All Skills',
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                        ...controller.skills.map((skill) {
                          return DropdownMenuItem<String>(
                            value: skill,
                            child: Text(skill, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        controller.setSkill(val);
                        _loadData();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Sort By Dropdown
          Container(
            height: 42,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.sortBy,
                dropdownColor: isDark ? AppColors.bgSoftDark : Colors.white,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'technical_score',
                    child: Text(
                      'Sort by: Technical Score',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'overall_rating',
                    child: Text(
                      'Sort by: Overall AI Rating',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'communication_score',
                    child: Text(
                      'Sort by: Communication Score',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    controller.setSortBy(val);
                    _loadData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow(LeaderboardController controller, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.getCard(isDark) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Active:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey[600],
            ),
          ),
          if (controller.selectedJobId != null)
            _buildBadge('Job Filtered', isDark),
          if (controller.selectedSkill != null)
            _buildBadge('Skill: ${controller.selectedSkill}', isDark),
          _buildBadge(
            'Sort: ${controller.sortBy.replaceAll('_', ' ')}',
            isDark,
          ),
          InkWell(
            onTap: () {
              controller.clearFilters();
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[400] : Colors.blueGrey[800],
        ),
      ),
    );
  }

  Widget _buildAverageMetricsRow(Map<String, dynamic> metrics, bool isDark) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(top: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricStatCard(
            'AVG TECH',
            (metrics['avg_technical_score'] ?? 0).toString(),
            Colors.blue,
            isDark,
          ),
          _buildMetricStatCard(
            'AVG COMM',
            (metrics['avg_communication_score'] ?? 0).toString(),
            Colors.green,
            isDark,
          ),
          _buildMetricStatCard(
            'AVG RATING',
            (metrics['avg_overall_rating'] ?? 0).toString(),
            Colors.orange,
            isDark,
          ),
          _buildMetricStatCard(
            'AVG ATS',
            (metrics['avg_ats_score'] ?? 0).toString(),
            Colors.purple,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStatCard(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(
    Map<String, dynamic> candidate,
    String recruiterId,
    bool isDark,
  ) {
    final rank = candidate['rank'] ?? 0;
    final name = candidate['candidate_name'] ?? 'Candidate';
    final email = candidate['candidate_email'] ?? '';
    final jobTitle = candidate['job_title'] ?? '';
    final skillMatch = candidate['skill_match'] ?? 0;
    final githubStack = List<String>.from(candidate['github_stack'] ?? []);
    final requiredSkills = List<String>.from(
      candidate['required_skills'] ?? [],
    );
    final candidateSkills = List<String>.from(
      candidate['candidate_skills'] ?? [],
    );

    final techScore = candidate['technical_score'] != null
        ? (candidate['technical_score'] as num).toDouble()
        : 0.0;
    final commScore = candidate['communication_score'] != null
        ? (candidate['communication_score'] as num).toDouble()
        : 0.0;
    final overallRating = candidate['overall_rating'] != null
        ? (candidate['overall_rating'] as num).toDouble()
        : 0.0;
    final atsScore = candidate['ats_score'] != null
        ? (candidate['ats_score'] as num).toInt()
        : 0;
    final status = candidate['status'] ?? 'applied';

    Widget rankBadge;
    if (rank == 1) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFFEF08A),
        child: Icon(Icons.emoji_events, color: Color(0xFFCA8A04), size: 16),
      );
    } else if (rank == 2) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFE2E8F0),
        child: Icon(
          Icons.workspace_premium,
          color: Color(0xFF64748B),
          size: 16,
        ),
      );
    } else if (rank == 3) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFFFEDD5),
        child: Icon(
          Icons.workspace_premium,
          color: Color(0xFFC2410C),
          size: 16,
        ),
      );
    } else {
      rankBadge = CircleAvatar(
        radius: 14,
        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
        child: Text(
          rank.toString(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[300] : Colors.blueGrey[800],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
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
              rankBadge,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jobTitle.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          // Skills Match section
          _buildSkillsMatchIndicator(
            skillMatch,
            candidateSkills,
            requiredSkills,
            isDark,
          ),
          const SizedBox(height: 12),
          // GitHub Stack section
          if (githubStack.isNotEmpty) ...[
            _buildGitHubStackRow(githubStack, isDark),
            const SizedBox(height: 14),
          ],
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey[100]!,
          ),
          const SizedBox(height: 14),
          // Score Metrics Grid
          _buildScoresGrid(
            techScore,
            commScore,
            overallRating,
            atsScore,
            isDark,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandidateProfileViewScreen(
                    candidateId: candidate['candidate_id']?.toString() ?? '',
                    applicationId: candidate['application_id']?.toString() ??
                        candidate['id']?.toString(),
                    jobId: candidate['job_id']?.toString(),
                    candidateName: candidate['candidate_name'] ?? 'Candidate',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
              elevation: 0,
              minimumSize: const Size(double.infinity, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  'View Application',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.toLowerCase();
    Color bg = Colors.grey[100]!;
    Color text = Colors.grey[800]!;

    if (normalized == 'shortlisted') {
      bg = Colors.blue.withValues(alpha: 0.1);
      text = Colors.blue;
    } else if (normalized == 'selected' || normalized == 'hired') {
      bg = Colors.green.withValues(alpha: 0.1);
      text = Colors.green;
    } else if (normalized == 'rejected' || normalized == 'filtered_out') {
      bg = Colors.red.withValues(alpha: 0.1);
      text = Colors.red;
    } else if (normalized == 'interview_slot_booked') {
      bg = Colors.orange.withValues(alpha: 0.1);
      text = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Widget _buildSkillsMatchIndicator(
    int match,
    List<String> candidateSkills,
    List<String> requiredSkills,
    bool isDark,
  ) {
    final candidateLower = candidateSkills.map((s) => s.toLowerCase()).toList();
    final matchedCount = requiredSkills
        .where((s) => candidateLower.contains(s.toLowerCase()))
        .length;

    Color matchColor = Colors.red;
    if (match >= 80)
      matchColor = Colors.green;
    else if (match >= 60)
      matchColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: matchColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$match% Match',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: matchColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($matchedCount/${requiredSkills.length} skills matched)',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        if (requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: requiredSkills.map((req) {
                final hasIt = candidateLower.contains(req.toLowerCase());
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        req,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey[400]
                              : Colors.blueGrey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        hasIt ? Icons.check_circle : Icons.cancel,
                        size: 11,
                        color: hasIt ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGitHubStackRow(List<String> stack, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GITHUB STACK',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: stack.map((lang) {
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Text(
                  lang,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.grey[300] : Colors.blueGrey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresGrid(
    double tech,
    double comm,
    double rating,
    int ats,
    bool isDark,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildScoreBox(
          'Technical',
          tech.toStringAsFixed(1),
          Colors.blue,
          isDark,
        ),
        _buildScoreBox(
          'Communication',
          comm.toStringAsFixed(1),
          Colors.green,
          isDark,
        ),
        _buildScoreBox(
          'AI Rating',
          rating.toStringAsFixed(1),
          Colors.orange,
          isDark,
          isRating: true,
        ),
        _buildScoreBox('ATS Fit', '$ats%', Colors.purple, isDark),
      ],
    );
  }

  Widget _buildScoreBox(
    String label,
    String value,
    Color color,
    bool isDark, {
    bool isRating = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.01)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (isRating) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewBottomSheet(
    Map<String, dynamic> candidate,
    String recruiterId,
    bool isDark,
  ) {
    final name = candidate['candidate_name'] ?? 'Candidate';
    final email = candidate['candidate_email'] ?? '';
    final jobTitle = candidate['job_title'] ?? '';
    final applicationId = candidate['application_id'] ?? '';
    final resumeUrl = candidate['resume_url'] ?? '';

    final stages = [
      'Applied',
      'Screening',
      'Shortlisted',
      'Interview',
      'Offer',
      'Hired',
      'Rejected',
      'Withdrawn',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSoftDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Application Review',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobTitle.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
                const SizedBox(height: 20),
                if (resumeUrl.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(resumeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open resume link'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Open Candidate Resume',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'TRANSITION STAGE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: stages.firstWhere(
                    (s) =>
                        s.toLowerCase() ==
                        candidate['status'].toString().toLowerCase(),
                    orElse: () => 'Applied',
                  ),
                  dropdownColor: isDark ? AppColors.bgSoftDark : Colors.white,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: stages
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      Navigator.pop(ctx);
                      final success = await Provider.of<ApplicationsController>(
                        context,
                        listen: false,
                      ).updateStatus(applicationId, val, recruiterId);
                      if (success) {
                        _loadData();
                        if (context.mounted) {
                          try {
                            Provider.of<DashboardController>(
                              context,
                              listen: false,
                            ).refresh(recruiterId);
                            Provider.of<JobsController>(
                              context,
                              listen: false,
                            ).fetchJobs(recruiterId);
                          } catch (_) {}
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Candidate moved to $val'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          final err =
                              Provider.of<ApplicationsController>(
                                context,
                                listen: false,
                              ).errorMessage ??
                              'Failed to update status';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No Insights Found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your job or skill filters.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sync_problem_rounded,
              size: 40,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not sync insights',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
