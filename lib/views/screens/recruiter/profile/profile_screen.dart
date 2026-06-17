import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<DashboardController>(
        context,
        listen: false,
      ).fetchDashboard(recruiterId, auth: auth);
      Provider.of<JobsController>(
        context,
        listen: false,
      ).fetchJobs(recruiterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final recruiter = Provider.of<AuthController>(context).currentRecruiter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = Provider.of<DashboardController>(context);
    final jobsController = Provider.of<JobsController>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.paddingH,
        vertical: Responsive.spacing(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeaderCard(recruiter, isDark),
          SizedBox(height: Responsive.spacing(16)),
          _buildSectionTitle('Contact Details'),
          SizedBox(height: Responsive.spacing(10)),
          _buildContactCard(recruiter, isDark),
          SizedBox(height: Responsive.spacing(24)),
          _buildSectionTitle('About & Expertise'),
          SizedBox(height: Responsive.spacing(10)),
          _buildAboutCard(isDark),
          SizedBox(height: Responsive.spacing(24)),
          _buildSectionTitle('Recruiter Activity'),
          SizedBox(height: Responsive.spacing(10)),
          _buildActivityGrid(dashboard, jobsController, isDark),
          SizedBox(height: Responsive.spacing(100)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: Responsive.fontSize(14),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildProfileHeaderCard(Recruiter? recruiter, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.scale(34),
            backgroundColor: AppColors.getPrimary(
              isDark,
            ).withValues(alpha: 0.1),
            child: Text(
              (recruiter != null && recruiter.fullName.isNotEmpty)
                  ? recruiter.fullName.substring(0, 1).toUpperCase()
                  : 'R',
              style: TextStyle(
                fontSize: Responsive.fontSize(24),
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recruiter?.fullName ?? 'Recruiter Name',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.fontSize(16),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recruiter?.designation ?? 'Senior Talent Partner',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.fontSize(12),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recruiter?.companyName ?? 'Organization',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.fontSize(10),
                      fontWeight: FontWeight.w800,
                      color: Colors.blueAccent,
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

  Widget _buildContactCard(Recruiter? recruiter, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.email_outlined,
            'Work Email',
            recruiter?.email ?? '-',
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone_outlined, 'Phone', recruiter?.phone ?? '-'),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Location',
            recruiter?.companyLocation ?? 'Bangalore, India',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: Responsive.scale(18), color: Colors.blueAccent),
        SizedBox(width: Responsive.spacing(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: Responsive.fontSize(10),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                val,
                style: GoogleFonts.inter(
                  fontSize: Responsive.fontSize(13),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specializing in high-growth startup leadership and engineering hiring. Professional recruiter workspace.',
            style: GoogleFonts.inter(
              fontSize: Responsive.fontSize(13),
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: Responsive.spacing(14)),
          Wrap(
            spacing: Responsive.spacing(8),
            runSpacing: Responsive.spacing(8),
            children: [
              'Product Hiring',
              'Strategy',
              'Executive Search',
            ].map((s) => _buildTag(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: Responsive.fontSize(11),
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildActivityGrid(
    DashboardController dashboard,
    JobsController jobsController,
    bool isDark,
  ) {
    final stats = dashboard.dashboardData['stats'] as Map<String, dynamic>?;
    final pipelineStats =
        dashboard.dashboardData['pipeline_stats'] as Map<String, dynamic>?;

    final String interviews = dashboard.isLoading
        ? '...'
        : (stats?['interview_bookings']?.toString() ?? '0');

    final String jobsPosted = jobsController.isLoading
        ? '...'
        : jobsController.jobs.length.toString();

    final String offersMade = dashboard.isLoading
        ? '...'
        : (pipelineStats?['Offer']?.toString() ?? '0');

    return Row(
      children: [
        _buildActivityTile(interviews, 'Interviews', Colors.blue, isDark),
        SizedBox(width: Responsive.spacing(12)),
        _buildActivityTile(jobsPosted, 'Jobs Posted', Colors.orange, isDark),
        SizedBox(width: Responsive.spacing(12)),
        _buildActivityTile(offersMade, 'Offers Made', Colors.green, isDark),
      ],
    );
  }

  Widget _buildActivityTile(
    String val,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: Responsive.fontSize(18),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
