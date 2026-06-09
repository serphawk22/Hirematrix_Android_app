import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.getBackground(isDark)
              : const Color(0xFFF5F7FB),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Top Custom AppBar (Floating)
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.getPrimary(isDark),
                              AppColors.getSecondary(isDark),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'H',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HireMatrix Portal',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : AppColors.getText(isDark),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),

                // Hero Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            'Portal Experience',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.grey[300]
                                  : const Color(0xFF667085),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            'Everything Your Hiring Journey Needs',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A structured candidate-recruiter ecosystem with preparation, interview, and hiring workflows connected in one platform.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Pinned Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: isDark
                          ? Colors.white
                          : AppColors.getPrimary(isDark),
                      unselectedLabelColor: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF667085),
                      indicatorColor: AppColors.getPrimary(isDark),
                      indicatorWeight: 3.0,
                      labelStyle: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Showcase'),
                        Tab(text: 'AI & Roles'),
                        Tab(text: 'Snapshot'),
                      ],
                    ),
                    isDark: isDark,
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                // Tab 1: Showcase
                _buildShowcaseTab(isDark),

                // Tab 2: AI & Roles
                _buildAiAndRolesTab(isDark),

                // Tab 3: Snapshot & CTA
                _buildSnapshotTab(isDark),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildShowcaseTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        _buildSectionHeader(
          'Feature Showcase',
          'Portal Features. Clear Differentiation.',
          isDark,
        ),
        _buildFeatureCard(
          title: 'Career Transition + Resume Studio + AI Interview Flow',
          badge: 'Candidate Journey',
          whatPeopleFace:
              'Switching roles usually means fragmented planning, resume edits, and interview preparation.',
          whatToExplore:
              'Transition planning, role-focused resume versions, and structured AI interview rounds in one path.',
          uniqueAdvantage:
              'Most portals stop at job listing. Here, role-change preparation is a core product journey.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          title: 'AI Coaching Suite for Readiness',
          badge: 'Preparation Layer',
          whatPeopleFace:
              'Candidates apply without role-tuned resume guidance, interview structure, or post-application strategy.',
          whatToExplore:
              'Job-specific Resume Coach, Pre-interview Preparation Coach with detailed mock support, and Job Search Strategy Coach.',
          uniqueAdvantage:
              'Coaching spans before and after applying, so readiness improves continuously across the full cycle.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          title: 'Connected Candidate + Recruiter Workflows',
          badge: 'Two-Sided Design',
          whatPeopleFace:
              'Candidate progress and recruiter decisions often live in disconnected systems.',
          whatToExplore:
              'Applications, review actions, messaging, and status updates aligned between both user roles.',
          uniqueAdvantage:
              'Both sides experience mirrored workflow stages, reducing confusion and unnecessary follow-ups.',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          title: 'Interview Slot + Application Stage Coordination',
          badge: 'Execution Layer',
          whatPeopleFace:
              'Interview scheduling is usually separate from application stage management.',
          whatToExplore:
              'Slot booking, rescheduling, and stage visibility tied directly to interview progress.',
          uniqueAdvantage:
              'Scheduling and progression are linked, making momentum easier to maintain for both sides.',
          isDark: isDark,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAiAndRolesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        _buildSectionHeader(
          'AI Pipelines',
          '5 Candidate AI Pipelines Built In',
          isDark,
        ),
        _buildPipelineCard(
          '01 Resume Coach',
          'Role-targeted resume improvement guidance per job context.',
          isDark,
        ),
        _buildPipelineCard(
          '02 Prep Coach',
          'Pre-interview readiness plan with likely questions and checklist.',
          isDark,
        ),
        _buildPipelineCard(
          '03 Mock Interview',
          'Detailed multi-round mock structure and answer framing support.',
          isDark,
        ),
        _buildPipelineCard(
          '04 Job Strategy Coach',
          'Application strategy before and after applying to improve traction.',
          isDark,
        ),
        _buildPipelineCard(
          '05 Candidate-Job Fit',
          'Contextual fit cues that help prioritize where to spend effort first.',
          isDark,
        ),
        const SizedBox(height: 30),
        _buildSectionHeader(
          'Role Matrix',
          '4 Roles. Clear Responsibilities.',
          isDark,
        ),
        _buildPipelineCard(
          'Candidate',
          'Profile, resume, coaching, applications, interview flow, and alerts.',
          isDark,
        ),
        _buildPipelineCard(
          'Recruiter',
          'Jobs, applications, candidate actions, interview slots, and shortlist views.',
          isDark,
        ),
        _buildPipelineCard(
          'Platform Admin',
          'Operational visibility on user activity and API usage trends.',
          isDark,
        ),
        _buildPipelineCard(
          'System',
          'Automated workflows for reminders, matching, and status progression.',
          isDark,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSnapshotTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        _buildSectionHeader('Platform Snapshot', 'Platform Statistics', isDark),
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard('36+', 'Key Features', isDark),
              _buildStatCard('15', 'Core Modules', isDark),
              _buildStatCard('20+', 'Workflow Screens', isDark),
              _buildStatCard('14', 'Candidate Flows', isDark),
              _buildStatCard('3', 'Major User Types', isDark),
              _buildStatCard('8+', 'AI Touchpoints', isDark),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // CTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF2FF), Color(0xFFF7EDFF), Color(0xFFFFF5EA)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                'Ready to Explore the HireMatrix Experience?',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getText(isDark),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'See how preparation, interviews, and hiring coordination can feel more connected for both candidates and recruiters.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Return to Home',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String kicker, String title, bool isDark) {
    return Column(
      children: [
        Text(
          kicker.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.getPrimary(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.getText(isDark),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String badge,
    required String whatPeopleFace,
    required String whatToExplore,
    required String uniqueAdvantage,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark).withOpacity(0.09),
                  AppColors.getSecondary(isDark).withOpacity(0.08),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.getText(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildPoint('What people face', whatPeopleFace, isDark),
                const SizedBox(height: 10),
                _buildPoint('What to explore', whatToExplore, isDark),
                const SizedBox(height: 10),
                _buildUniquePoint('Unique Advantage', uniqueAdvantage, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(String label, String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getBackground(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniquePoint(String label, String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getPrimary(isDark).withOpacity(0.12),
            AppColors.getSecondary(isDark).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.getText(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(String title, String text, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.getBackground(isDark)
                  : const Color(0xFFF8FBFF),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.getText(isDark),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              style: GoogleFonts.manrope(
                color: isDark ? Colors.grey[400] : const Color(0xFF667085),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, bool isDark) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.getText(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.isDark});

  final TabBar _tabBar;
  final bool isDark;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.getBackground(isDark) : const Color(0xFFF5F7FB),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
