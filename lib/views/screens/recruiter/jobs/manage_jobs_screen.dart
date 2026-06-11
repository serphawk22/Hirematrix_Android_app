import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';
import '../candidates/candidate_management_screen.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All Jobs', 'Active', 'Drafts', 'Expired', 'Closed'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<JobsController>(context, listen: false).fetchJobs(recruiterId);
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

    if (recruiter == null) return const Scaffold(body: Center(child: Text('Please login to manage jobs')));

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildOperationalStatsGrid(isDarkMode),
            _buildSearchRow(isDarkMode),
            _buildEnterpriseFilterTabs(isDarkMode),
            Expanded(
              child: Consumer<JobsController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((status) => _buildJobWorkspace(controller.jobs, status, isDarkMode)).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalStatsGrid(bool isDark) {
    return Consumer<JobsController>(
      builder: (context, controller, child) {
        int active = controller.jobs.where((j) => j.status == 'Active').length;
        int draft = controller.jobs.where((j) => j.status == 'Draft').length;
        int expired = controller.jobs.where((j) => j.status == 'Expired').length;
        int closed = controller.jobs.where((j) => j.status == 'Closed').length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Responsive.paddingH, vertical: 8),
          child: Row(
            children: [
              _buildCompactStatCard('Active', active.toString(), Icons.bolt_rounded, Colors.green, isDark),
              _buildCompactStatCard('Drafts', draft.toString(), Icons.edit_note_rounded, Colors.orange, isDark),
              _buildCompactStatCard('Expired', expired.toString(), Icons.history_rounded, Colors.redAccent, isDark),
              _buildCompactStatCard('Closed', closed.toString(), Icons.lock_outline_rounded, Colors.blueGrey, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatCard(String label, String count, IconData icon, Color color, bool isDark) {
    return Container(
      width: 136,
      height: 82,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
          width: 1,
        ),
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
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: color.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Responsive.paddingH, 8, Responsive.paddingH, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
                  if (recruiterId != null) {
                    Provider.of<JobsController>(context, listen: false).fetchJobs(recruiterId, query: v);
                  }
                },
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search workspace roles...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.grey),
              onPressed: () {},
            ),
          ),
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
          borderSide: BorderSide(width: 3, color: AppColors.getPrimary(isDark)),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelColor: AppColors.getPrimary(isDark),
        unselectedLabelColor: Colors.grey[500],
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
      filteredJobs = allJobs.where((j) => j.status.toLowerCase() == filterStatus).toList();
    }

    if (filteredJobs.isEmpty) return _buildEmptyATSState(isDark);

    return RefreshIndicator(
      onRefresh: () async {
         final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
         if (recruiterId != null) {
            await Provider.of<JobsController>(context, listen: false).fetchJobs(recruiterId);
         }
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: filteredJobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildAtsJobCard(filteredJobs[index], isDark),
      ),
    );
  }

  Widget _buildAtsJobCard(Job job, bool isDark) {
    final status = job.status.toUpperCase();
    final pipeline = job.pipeline ?? {};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey[200]!.withValues(alpha: 0.45)),
        boxShadow: [
          if (!isDark) BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.08), 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Icon(Icons.business_center_rounded, size: 20, color: AppColors.getPrimary(isDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.jobTitle, 
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.getText(isDark), height: 1.1, letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(job.location ?? 'Remote', 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(job.jobType, 
                          maxLines: 1,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[200]!.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(pipeline['Applied']?.toString() ?? '0', 'Applied', isDark, compact: true),
                _buildMetric(pipeline['Shortlisted']?.toString() ?? '0', 'Shortlisted', isDark, compact: true),
                _buildMetric(pipeline['Interview']?.toString() ?? '0', 'Interviews', isDark, compact: true),
                _buildMetric(pipeline['Hired']?.toString() ?? '0', 'Hires', isDark, compact: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                   appBar: AppBar(title: Text(job.jobTitle, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800))),
                   body: CandidateManagementScreen(jobId: job.jobId, jobTitle: job.jobTitle),
                 )));
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.getPrimary(isDark),
                side: BorderSide(color: AppColors.getPrimary(isDark).withValues(alpha: 0.12)),
                elevation: 0,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Manage workspace', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.getPrimary(isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color = Colors.green;
    if (status == 'DRAFT') color = Colors.orange;
    if (status == 'EXPIRED' || status == 'CLOSED') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildMetric(String val, String label, bool isDark, {bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: compact ? 14 : 16, fontWeight: FontWeight.w800, color: AppColors.getText(isDark))),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: compact ? 10 : 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyATSState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business_center_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          Text('No roles found in this status.', 
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Try refining your search or filters.', 
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
