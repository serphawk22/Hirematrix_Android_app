import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/application.dart';

class CandidateManagementScreen extends StatefulWidget {
  final String? jobId;
  final String? jobTitle;
  final bool isStandalone;

  const CandidateManagementScreen({
    super.key,
    this.jobId,
    this.jobTitle,
    this.isStandalone = false,
  });

  @override
  State<CandidateManagementScreen> createState() =>
      _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All Roles';
  String _selectedExperience = 'Any Experience';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final recruiterId = Provider.of<AuthController>(context, listen: false)
        .currentRecruiter
        ?.id;
    if (recruiterId != null) {
      Provider.of<ApplicationsController>(context, listen: false)
          .fetchApplications(recruiterId, jobId: widget.jobId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> stages = [
      'Applied',
      'Screening',
      'Shortlisted',
      'Interview',
      'Offer',
      'Hired',
      'Rejected',
      'Withdrawn'
    ];

    Widget content = DefaultTabController(
      length: stages.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.jobTitle != null) _buildJobContextBar(isDark),
          _buildSearchAndFilters(isDark),
          _buildStageTabs(isDark),
          Expanded(
            child: Consumer<ApplicationsController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (controller.errorMessage != null &&
                    controller.applications.isEmpty) {
                  return _buildErrorState(controller.errorMessage!, isDark);
                }
                return TabBarView(
                  children: stages
                      .map((s) => _buildStageContent(
                          context, s, isDark, controller.applications))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Candidate Database',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 20)),
          ],
        ),
        body: content,
      );
    }

    return Container(
      color: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      child: content,
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    final applications =
        Provider.of<ApplicationsController>(context).applications;
    final roles = [
      'All Roles',
      ...applications.map((e) => e.appliedJob).toSet()
    ];
    final expLevels = [
      'Any Experience',
      'Fresher',
      '1-3 Years',
      '3-5 Years',
      '5+ Years'
    ];

    return Padding(
      padding:
          EdgeInsets.fromLTRB(Responsive.paddingH, 12, Responsive.paddingH, 8),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
                if (recruiterId != null) {
                  Provider.of<ApplicationsController>(context, listen: false).fetchApplications(recruiterId, jobId: widget.jobId, query: v);
                }
              },
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by name, email or skills...',
                prefixIcon:
                    Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Role: $_selectedRole',
                  icon: Icons.work_outline_rounded,
                  isDark: isDark,
                  options: roles,
                  currentValue: _selectedRole,
                  onChanged: (val) => setState(() => _selectedRole = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Exp: $_selectedExperience',
                  icon: Icons.history_rounded,
                  isDark: isDark,
                  options: expLevels,
                  currentValue: _selectedExperience,
                  onChanged: (val) => setState(() => _selectedExperience = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Resume: Available',
                  icon: Icons.description_outlined,
                  isDark: isDark,
                  options: ['All', 'Available'],
                  currentValue: 'Available',
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isDark,
    required List<String> options,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options
          .map((o) => PopupMenuItem(
              value: o,
              child: Text(o, style: GoogleFonts.inter(fontSize: 13))))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border:
              Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildJobContextBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.paddingH, vertical: 8),
      color: AppColors.getPrimary(isDark).withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.business_center_rounded,
              size: 14, color: AppColors.getPrimary(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Managing Hiring for: ${widget.jobTitle}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStageTabs(bool isDark) {
    return Container(
      height: Responsive.scale(42),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: isDark ? Colors.white10 : Colors.grey[100]!),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.getPrimary(isDark),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.getPrimary(isDark),
        unselectedLabelColor: AppColors.getTextMuted(isDark),
        labelStyle: GoogleFonts.inter(
          fontSize: Responsive.fontSize(13),
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Applied'),
          Tab(text: 'Screening'),
          Tab(text: 'Shortlisted'),
          Tab(text: 'Interview'),
          Tab(text: 'Offer'),
          Tab(text: 'Hired'),
          Tab(text: 'Rejected'),
          Tab(text: 'Withdrawn'),
        ],
      ),
    );
  }

  Widget _buildStageContent(BuildContext context, String stage, bool isDark,
      List<Application> allApps) {
    var apps =
        allApps.where((a) => _statusMatchesStage(a.status, stage)).toList();

    // Apply Search Filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      apps = apps.where((a) {
        final name = a.candidateName.toLowerCase();
        final email = a.candidateEmail.toLowerCase();
        final skills = a.skills.join(', ').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            skills.contains(query);
      }).toList();
    }

    // Apply Role Filter
    if (_selectedRole != 'All Roles') {
      apps = apps.where((a) => a.appliedJob == _selectedRole).toList();
    }

    // Apply Experience Filter
    if (_selectedExperience != 'Any Experience') {
      final expQuery = _selectedExperience.split(' ')[0].toLowerCase();
      apps = apps
          .where((a) => a.experience.toLowerCase().contains(expQuery))
          .toList();
    }

    if (apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.spacing(20)),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.getCard(isDark) : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_search_rounded,
                      size: Responsive.scale(40),
                      color:
                          AppColors.getPrimary(isDark).withValues(alpha: 0.2),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(16)),
                  Text(
                    'No candidates',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No applications in $stage stage.',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.fontSize(12),
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: Responsive.isTablet
          ? GridView.builder(
              padding: EdgeInsets.all(Responsive.paddingH),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: Responsive.spacing(12),
                mainAxisSpacing: Responsive.spacing(12),
                childAspectRatio: Responsive.gridRatio(2.0),
              ),
              itemCount: apps.length,
              itemBuilder: (c, i) =>
                  _buildCandidateCard(context, apps[i], isDark),
            )
          : ListView.separated(
              padding: EdgeInsets.all(Responsive.paddingH),
              itemCount: apps.length,
              separatorBuilder: (c, i) =>
                  SizedBox(height: Responsive.spacing(12)),
              itemBuilder: (c, i) =>
                  _buildCandidateCard(context, apps[i], isDark),
            ),
    );
  }

  Widget _buildCandidateCard(
      BuildContext context, Application app, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppColors.getPrimary(isDark).withValues(alpha: 0.08),
                child: Text(
                    (app.candidateName.isNotEmpty ? app.candidateName[0] : 'C')
                        .toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.getPrimary(isDark))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.candidateName,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(app.candidateEmail,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              _buildMatchScoreBadge(app.matchScore),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoSnippet(
                  Icons.work_history_rounded, app.experience, isDark),
              const SizedBox(width: 16),
              _buildInfoSnippet(
                  Icons.location_on_outlined,
                  app.location.isEmpty ? 'Location not set' : app.location,
                  isDark),
            ],
          ),
          const SizedBox(height: 12),
          Text('APPLIED FOR:',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(app.appliedJob.isEmpty ? 'General Application' : app.appliedJob,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getPrimary(isDark))),
          const SizedBox(height: 16),
          if (app.skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: app.skills
                  .take(3)
                  .map((s) => _buildSkillTag(s, isDark))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Divider(
              height: 1, color: isDark ? Colors.white10 : Colors.grey[100]!),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildActionBtn(
                      'View Resume', Icons.description_outlined, isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  'Move Stage',
                  Icons.input_rounded,
                  isDark,
                  isPrimary: true,
                  onTap: () => _showStagePicker(context, app),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSnippet(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[600])),
      ],
    );
  }

  Widget _buildSkillTag(String skill, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
          borderRadius: BorderRadius.circular(6)),
      child: Text(skill,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700])),
    );
  }

  void _showStagePicker(BuildContext context, Application app) {
    final stages = [
      'Applied',
      'Screening',
      'Shortlisted',
      'Interview',
      'Offer',
      'Hired',
      'Rejected',
      'Withdrawn'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Move to Stage',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...stages.map((s) => ListTile(
                      title: Text(s, style: GoogleFonts.inter(fontSize: 14)),
                      trailing: _statusMatchesStage(app.status, s)
                          ? Icon(Icons.check_circle,
                              color: AppColors.getPrimary(
                                  Theme.of(context).brightness ==
                                      Brightness.dark))
                          : null,
                      onTap: () async {
                        final recruiterId =
                            Provider.of<AuthController>(context, listen: false)
                                .currentRecruiter
                                ?.id;
                        if (recruiterId != null) {
                          Navigator.of(ctx).pop();
                          final success = await Provider.of<
                                      ApplicationsController>(context,
                                      listen: false)
                              .updateStatus(app.applicationId, s, recruiterId);
                          if (success && context.mounted) {
                            Provider.of<DashboardController>(context,
                                    listen: false)
                                .refresh(recruiterId);
                          } else if (context.mounted) {
                            final message = Provider.of<ApplicationsController>(
                                        context,
                                        listen: false)
                                    .errorMessage ??
                                'Unable to move candidate stage';
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          }
                        }
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _statusMatchesStage(String status, String stage) {
    return _normalizeStage(status) == _normalizeStage(stage);
  }

  String _normalizeStage(String value) {
    final normalized =
        value.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'interview_slot_booked':
      case 'interview_scheduled':
        return 'interview';
      case 'ai_interview_started':
      case 'ai_interview_completed':
      case 'ai_evaluated':
        return 'screening';
      case 'on_hold':
        return 'hold';
      case 'selected':
        return 'offer';
      default:
        return normalized;
    }
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.paddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_problem_rounded,
                size: 44, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              'Could not sync candidates',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getText(isDark)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.getTextMuted(isDark)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreBadge(dynamic score) {
    final val = double.tryParse(score.toString()) ?? 0.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(8),
        vertical: Responsive.spacing(4),
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${val.toInt()}% Match',
        style: GoogleFonts.inter(
          fontSize: Responsive.fontSize(10),
          fontWeight: FontWeight.w800,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, bool isDark,
      {bool isPrimary = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: Responsive.btnHeight,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.getPrimary(isDark) : Colors.transparent,
          border: isPrimary
              ? null
              : Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: Responsive.fontSize(13),
                color: isPrimary ? Colors.white : Colors.grey[700]),
            SizedBox(width: Responsive.spacing(6)),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: Responsive.fontSize(11),
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
