import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';
import 'package:hirematrix/views/widgets/job_card.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/views/screens/candidate/profile_screen.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/views/screens/candidate/smart_jobs_screen.dart';
import 'package:hirematrix/controllers/jobs_controller.dart';
import 'package:hirematrix/views/screens/candidate/saved_jobs_screen.dart';
import 'package:hirematrix/views/screens/candidate/settings_screen.dart';
import 'package:hirematrix/views/screens/candidate/blog_detail_screen.dart';
import 'package:hirematrix/views/screens/candidate/applications_screens.dart';
import 'package:hirematrix/views/screens/candidate/my_interview_bookings_screen.dart';
import 'package:hirematrix/controllers/applications_controller.dart';
import 'package:hirematrix/views/widgets/candidate_chatbot_bottom_sheet.dart';
import 'package:hirematrix/views/widgets/external_job_bottom_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController dashboardController = Get.put(
    DashboardController(),
  );
  final AuthController authController = Get.find<AuthController>();
  final _isExploreExpanded = false.obs;
  final _isCompaniesExpanded = false.obs;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final currentIdx = dashboardController.currentIndex.value;

      return Scaffold(
        backgroundColor: isDark
            ? AppColors.getBackground(isDark)
            : AppColors.getBackground(isDark),
        appBar: currentIdx == 0 ? _buildAppBar(isDark, themeController) : null,
        drawer: currentIdx == 0 ? _buildDrawer(context, isDark) : null,
        body: IndexedStack(
          index: currentIdx,
          children: [
            dashboardController.isLoading.value &&
                    dashboardController.userProfile.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getPrimary(isDark),
                      ),
                    ),
                  )
                : _buildBody(context, isDark),
            const SmartJobsScreen(showBackButton: false), // Jobs Screen
            const ApplicationsScreen(), // Applied Screen
            const SavedJobsScreen(), // Saved Screen
            const ProfileScreen(), // Profile Screen
            const SettingsScreen(), // Settings Screen
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const CandidateChatbotBottomSheet(),
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1FB7B5), Color(0xFF53B86C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.chat_outlined, color: Colors.white),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    bool isDark,
    ThemeController themeController,
  ) {
    return AppBar(
      backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF111827),
      ),
      title: Row(
        children: [
          Text(
            'HireMatrix',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
      actions: [
        Obx(() {
          final unreadNotifs =
              dashboardController.stats['unread_notifications']?.toString() ??
              '0';
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Get.toNamed(AppRoutes.notifications),
              ),
              if (unreadNotifs != '0')
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadNotifs,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Obx(() {
          final userName =
              dashboardController.userProfile['name'] ??
              authController.currentUser['name'] ??
              'Candidate';
          final userHeadline =
              dashboardController.userProfile['headline'] ??
              'Candidate Profile';
          final completionPct = dashboardController.profileStrength.value;
          final initial = userName.trim().isNotEmpty
              ? userName.trim()[0].toUpperCase()
              : 'C';
          final photoPath =
              dashboardController.userProfile['profile_photo']?.toString() ??
              authController.currentUser['profile_photo']?.toString() ??
              '';

          final cleanPhotoPath = photoPath.startsWith('/')
              ? photoPath.substring(1)
              : photoPath;
          final photoUrl = photoPath.isNotEmpty
              ? (photoPath.startsWith('http')
                    ? photoPath
                    : '${ApiConstants.baseUrl.replaceAll('/api', '')}/$cleanPhotoPath')
              : '';

          final currentIdx = dashboardController.currentIndex.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'HireMatrix',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.getPrimary(
                                isDark,
                              ).withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.getPrimary(
                              isDark,
                            ).withValues(alpha: 0.1),
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isNotEmpty
                                ? null
                                : Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getPrimary(isDark),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userHeadline,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile Strength',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$completionPct%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completionPct / 100.0,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getPrimary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Drawer Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 8,
                        bottom: 6,
                      ),
                      child: Text(
                        'MAIN MENU',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      isDark: isDark,
                      isActive: currentIdx == 0,
                      onTap: () {
                        Get.back();
                        dashboardController.currentIndex.value = 0;
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.work_outline,
                      title: 'My Applications',
                      isDark: isDark,
                      isActive: currentIdx == 2,
                      trailing: dashboardController.stats['total_applications']
                          ?.toString(),
                      onTap: () {
                        Get.back();
                        dashboardController.currentIndex.value = 2;
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.calendar_month_outlined,
                      title: 'Interviews',
                      isDark: isDark,
                      isActive: false,
                      onTap: () {
                        Get.back();
                        Get.to(() => const MyInterviewBookingsScreen());
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.business_outlined,
                      title: 'Local Companies',
                      isDark: isDark,
                      isActive: false,
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.localCompanies);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.hub_outlined, // Replaces FontAwesome building
                      title: 'Company Intelligence',
                      isDark: isDark,
                      isActive: false,
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.companyDiscovery);
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 16,
                        bottom: 6,
                      ),
                      child: Text(
                        'AI SUITE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Career Transition AI',
                      isDark: isDark,
                      onTap: () {
                        Get.back();
                        if (dashboardController
                            .currentSubscription
                            .isNotEmpty) {
                          Get.toNamed(AppRoutes.careerTransition);
                        } else {
                          Get.toNamed(AppRoutes.plans);
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.description_outlined,
                      title: 'Resume Studio',
                      isDark: isDark,
                      onTap: () {
                        Get.back();
                        if (dashboardController
                            .currentSubscription
                            .isNotEmpty) {
                          Get.toNamed(AppRoutes.resumeStudio);
                        } else {
                          Get.toNamed(AppRoutes.plans);
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.psychology_outlined,
                      title: 'Job Search Strategy',
                      isDark: isDark,
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.jobSearchStrategy);
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 16,
                        bottom: 6,
                      ),
                      child: Text(
                        'PREFERENCES',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      isDark: isDark,
                      isActive: currentIdx == 5,
                      onTap: () {
                        Get.back();
                        dashboardController.currentIndex.value = 5;
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isDark: isDark,
                      color: Colors.redAccent,
                      onTap: () async {
                        Get.back(); // close drawer first
                        try {
                          await Get.find<AuthController>().clearUserSession();
                        } catch (e) {
                          // ignore
                        }
                        Get.offAllNamed(AppRoutes.landing);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isActive = false,
    String? trailing,
    Color? color,
  }) {
    final activeColor = AppColors.getPrimary(isDark);
    final textColor =
        color ?? (isDark ? Colors.grey[300] : const Color(0xFF374151));
    final selectedBg = activeColor.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: isActive
              ? activeColor
              : (color ?? (isDark ? Colors.grey[400] : Colors.grey[500])),
          size: 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? activeColor : textColor,
          ),
        ),
        trailing: trailing != null && trailing != '0'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailing,
                  style: GoogleFonts.inter(
                    color: isActive
                        ? activeColor
                        : (isDark ? Colors.grey[300] : Colors.grey[600]),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    final rawIndex = dashboardController.currentIndex.value;
    final displayIndex = rawIndex > 4 ? 4 : rawIndex;
    return BottomNavigationBar(
      currentIndex: displayIndex,
      onTap: (index) {
        dashboardController.currentIndex.value = index;
        if (index == 0) {
          dashboardController.fetchDashboardData();
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
      selectedItemColor: AppColors.getPrimary(isDark),
      unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.whatshot_outlined),
          activeIcon: Icon(Icons.whatshot),
          label: 'Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          activeIcon: Icon(Icons.work),
          label: 'Applied',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          activeIcon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await dashboardController.fetchDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProBanner(context, isDark),
              const SizedBox(height: 32),
              // _buildSummaryCard(isDark),
              // const SizedBox(height: 24),
              // _buildMetricGrid(isDark),
              const SizedBox(height: 32),
              _buildSectionHeader(
                'Jobs Matching Your Profile',
                'Based on your skills and preferences',
                isDark,
                onSeeAll: () {
                  try {
                    final jobsController = Get.find<JobsController>();
                    if (jobsController.animateToTab != null) {
                      jobsController.animateToTab!(0); // 0 = Matching Profile
                    }
                    if (jobsController.setSubTab != null) {
                      jobsController.setSubTab!(1); // 1 = Based on Skills
                    }
                  } catch (_) {}
                  dashboardController.currentIndex.value = 1;
                },
              ),
              const SizedBox(height: 16),
              Obx(() => _buildJobsHorizontalList(isDark)),
              const SizedBox(height: 32),
              // Explore by Role
              if (dashboardController.jobCategories.isNotEmpty) ...[
                _buildSectionHeader(
                  'Explore by Role',
                  'Quickly find openings in your preferred specialized domains.',
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildExploreByRoleGrid(isDark),
                const SizedBox(height: 32),
              ],

              // Top Companies Hiring Now
              if (dashboardController.topHiringCompanies.isNotEmpty) ...[
                _buildSectionHeader(
                  'Top Companies Hiring Now',
                  'Discover companies matching your career goals',
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildTopCompaniesGrid(isDark),
                const SizedBox(height: 32),
              ],

              // _buildStrategyBanner(isDark),
              // const SizedBox(height: 32),
              const SizedBox(height: 32),
              _buildBlogSection(isDark),
              _buildSectionHeader(
                'Recent Applications',
                'Track your status',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildApplicationsList(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'My Dashboard',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Focus on the jobs most likely to move forward.',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Track your profile strength, recent applications, saved opportunities, and recruiter-facing activity from one compact workspace.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      final jobsController = Get.find<JobsController>();
                      if (jobsController.animateToTab != null) {
                        jobsController.animateToTab!(0); // 0 = Matching Profile
                      }
                      if (jobsController.setSubTab != null) {
                        jobsController.setSubTab!(1); // 1 = Based on Skills
                      }
                    } catch (_) {}
                    dashboardController.currentIndex.value = 1;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Matches',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    dashboardController.currentIndex.value = 2;
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF111827),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Track Applications',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    String value,
    String label,
    Color badgeColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(bool isDark) {
    return Obx(() {
      final stats = dashboardController.stats;
      final completionPct = dashboardController.profileStrength.value;

      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        children: [
          _buildMetricCard(
            'Profile strength',
            '$completionPct%',
            completionPct >= 80
                ? 'Recruiter-ready profile. Keep momentum.'
                : 'Complete details to get sharper matches.',
            isDark,
          ),
          _buildMetricCard(
            'Active matches',
            dashboardController.topSuggestedJobs.length.toString(),
            'Roles currently aligned to your profile',
            isDark,
          ),
          _buildMetricCard(
            'Interviews booked',
            stats['interviews_scheduled']?.toString() ?? '0',
            'Confirmed interview slots on your calendar',
            isDark,
          ),
          _buildMetricCard(
            'Applications in progress',
            stats['active_applications']?.toString() ?? '0',
            'Open applications still moving forward',
            isDark,
          ),
        ],
      );
    });
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String note,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const Spacer(),
          Text(
            note,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    bool isDark, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.inter(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExploreByRoleGrid(bool isDark) {
    return Obx(() {
      final categories = dashboardController.jobCategories;
      final isExpanded = _isExploreExpanded.value;
      final displayCount = isExpanded
          ? categories.length
          : (categories.length > 4 ? 4 : categories.length);

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final category = categories[index];
              final name = category['name'] ?? 'Role';
              final jobCount =
                  int.tryParse(category['job_count']?.toString() ?? '0') ?? 0;
              final iconStr = category['icon'] ?? 'fas fa-briefcase';

              return InkWell(
                onTap: () {
                  try {
                    final jobsController = Get.find<JobsController>();
                    jobsController.selectedCategory.value = name;
                    jobsController.currentPage.value = 1;
                    jobsController.activeMainTab.value = 1; // 1 = Browse Jobs
                    jobsController.fetchJobs();
                  } catch (_) {}
                  dashboardController.currentIndex.value =
                      1; // Switch bottom tab to Jobs (SmartJobsScreen)
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(
                            isDark,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: FaIcon(
                            _mapFontAwesomeIcon(iconStr),
                            color: AppColors.getPrimary(isDark),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$jobCount ${jobCount == 1 ? "opening" : "openings"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (categories.length > 4) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                _isExploreExpanded.toggle();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Show Less' : 'Show More',
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.getPrimary(isDark),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildTopCompaniesGrid(bool isDark) {
    return Obx(() {
      final companies = dashboardController.topHiringCompanies;
      final isExpanded = _isCompaniesExpanded.value;
      final displayCount = isExpanded
          ? companies.length
          : (companies.length > 4 ? 4 : companies.length);

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final company = companies[index];
              final name = company['name'] ?? 'Company';
              final dbLogo = company['logo']?.toString().trim() ?? '';
              final website = company['website']?.toString().trim() ?? '';
              final industry = company['industry'] ?? '';
              final jobCount =
                  int.tryParse(company['job_count']?.toString() ?? '0') ?? 0;
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

              String googleLogoUrl = '';
              if (website.isNotEmpty) {
                try {
                  var uri = Uri.parse(
                    website.startsWith('http') ? website : 'https://$website',
                  );
                  var host = uri.host.replaceAll('www.', '');
                  if (host.isNotEmpty) {
                    googleLogoUrl =
                        'https://www.google.com/s2/favicons?domain=$host&sz=96';
                  }
                } catch (_) {}
              }

              final logoUrl = dbLogo.isNotEmpty
                  ? ApiConstants.resolveImageUrl(dbLogo)
                  : googleLogoUrl;

              return InkWell(
                onTap: () {
                  try {
                    final jobsController = Get.find<JobsController>();
                    jobsController.selectedCompany.value = name;
                    // Reset other filter elements to make it a clean company browse
                    jobsController.selectedCategory.value = '';
                    jobsController.searchQuery.value = '';
                    jobsController.selectedLocation.value = '';
                    jobsController.selectedWorkMode.value = '';
                    jobsController.selectedSalaryRange.value = '';
                    jobsController.selectedEmploymentTypes.clear();
                    jobsController.selectedExperienceLevels.clear();
                    jobsController.selectedPostedWithin.value = '';
                    jobsController.currentPage.value = 1;

                    jobsController.activeMainTab.value = 1; // 1 = Browse Jobs
                    if (jobsController.animateToTab != null) {
                      jobsController.animateToTab!(1);
                    }
                    jobsController.fetchJobs();
                  } catch (_) {}
                  dashboardController.currentIndex.value = 1;
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (industry.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                industry,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '$jobCount ${jobCount == 1 ? "opening" : "openings"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (companies.length > 4) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                _isCompaniesExpanded.toggle();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Show Less' : 'Show More',
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.getPrimary(isDark),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildJobsHorizontalList(bool isDark) {
    if (dashboardController.topSuggestedJobs.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 36,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No matching jobs found yet',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height:
          320, // Expanded height to prevent bottom overflow when titles wrap
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dashboardController.topSuggestedJobs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final job = dashboardController.topSuggestedJobs[index];
          final title = job['title'] ?? 'Untitled Role';
          final company = job['company'] ?? 'Company';
          final location = job['location'] ?? 'Remote';
          final postedAt = job['posted_at'] != null
              ? job['posted_at'].toString()
              : 'Recently';
          final scoreDouble =
              double.tryParse(job['match_score']?.toString() ?? '') ?? 0.0;
          final matchScore = scoreDouble > 0
              ? (scoreDouble.round()).clamp(10, 100)
              : 80;
          final isVisited =
              job['visited_flag'] == 1 || job['visited_flag'] == '1';

          return SizedBox(
            width: 280,
            child: JobCard(
              title: title,
              company: company,
              location: location,
              postedAt: postedAt,
              matchScore: matchScore,
              isDark: isDark,
              isVisited: isVisited,
              onTap: () {
                final isExternal =
                    (job['posted_for']?.toString() == 'client' ||
                    job['external_apply_url'] != null);

                job['visited_flag'] = 1;
                dashboardController.topSuggestedJobs.refresh();

                if (!isExternal) {
                  Get.to(() => JobDetailsScreen(job: job));
                } else {
                  final cardColor = isDark
                      ? AppColors.getCard(isDark)
                      : Colors.white;
                  final textColor = isDark
                      ? Colors.white
                      : const Color(0xFF111827);
                  final subtitleColor = isDark
                      ? Colors.grey[400]
                      : const Color(0xFF475569);
                  ExternalJobBottomSheet.show(
                    job,
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStrategyBanner(bool isDark) {
    final strategy = dashboardController.strategy;
    final source = strategy['source']?.toString() ?? 'fallback';
    final isAi = source == 'ai';
    final title = strategy['title'] ?? 'Job Search Strategy Coach';
    final summary =
        strategy['summary'] ??
        'Use a focused plan to refine your resume, prioritize applications, and target roles that align with your strongest skills.';
    final targetRoles =
        strategy['target_roles'] as List? ??
        ['Data Scientist', 'Machine Learning Engineer'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAi
              ? const [
                  Color(0xFF064E3B),
                  Color(0xFF0F766E),
                ] // Deep emerald/teal for AI
              : const [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ], // Deep slate/navy for standard coach
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isAi ? const Color(0xFF064E3B) : const Color(0xFF0F172A))
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compass_calibration,
                color: isAi
                    ? const Color(0xFF34D399)
                    : const Color(
                        0xFF38BDF8,
                      ), // Brighter colors for contrast on dark bg
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAi ? 'AI-generated strategy' : 'Job Search Strategy Coach',
                style: GoogleFonts.inter(
                  color: isAi
                      ? const Color(0xFF34D399)
                      : const Color(0xFF38BDF8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: targetRoles
                .map((role) => _buildRolePill(role.toString()))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.jobSearchStrategy),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAi
                  ? const Color(0xFF10B981)
                  : const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Full Strategy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBlogSection(bool isDark) {
    return Obx(() {
      final posts = dashboardController.blogPosts;
      if (posts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Latest Career Insights',
            'Stay updated with our expert advice and industry trends.',
            isDark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                final title = post['title'] ?? '';
                final coverImage = post['cover_image'] ?? '';
                final isFeatured =
                    post['featured'] == 1 ||
                    post['featured'] == true ||
                    post['featured'] == '1';
                final author = post['author_name'] ?? 'HireMatrix Team';
                final excerpt = post['excerpt'] ?? '';
                final publishedAt =
                    post['published_at'] ?? post['created_at'] ?? '';

                String formattedDate = '';
                try {
                  if (publishedAt.isNotEmpty) {
                    final dt = DateTime.parse(publishedAt.toString());
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
                    formattedDate =
                        '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
                  }
                } catch (_) {
                  formattedDate = 'Recently';
                }

                return Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image
                        Expanded(
                          flex: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              coverImage.isNotEmpty
                                  ? Image.network(
                                      coverImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: AppColors.getPrimary(
                                                  isDark,
                                                ).withValues(alpha: 0.1),
                                                child: Icon(
                                                  Icons.newspaper,
                                                  color: AppColors.getPrimary(
                                                    isDark,
                                                  ),
                                                  size: 40,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: AppColors.getPrimary(
                                        isDark,
                                      ).withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.newspaper,
                                        color: AppColors.getPrimary(isDark),
                                        size: 40,
                                      ),
                                    ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFeatured
                                        ? AppColors.getSecondary(isDark)
                                        : AppColors.getPrimary(isDark),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isFeatured ? 'Featured' : 'Blog',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content info
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'By $author',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.getTextMuted(isDark),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (formattedDate.isNotEmpty)
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.getTextMuted(isDark),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    excerpt,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(isDark),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Get.to(() => BlogDetailScreen(post: post));
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Read Article',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getPrimary(isDark),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                        color: AppColors.getPrimary(isDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    });
  }

  Widget _buildProBanner(BuildContext context, bool isDark) {
    if (dashboardController.currentSubscription.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final proFeatureSlides = [
      {
        'eyebrow': 'AI Interview Practice',
        'title': 'Practice with the AI Interview',
        'rows': [
          'Role-specific mock interview rounds',
          'Structured answer frameworks',
          'Instant post-round feedback',
        ],
        'cta_label': 'Start practising',
        'icon': Icons.video_call,
      },
      {
        'eyebrow': 'Career Transition AI',
        'title': 'Plan Your Next Career Move',
        'rows': [
          'Personalised role-change roadmap',
          'Skill gap analysis vs target role',
          'Certification & learning path guide',
        ],
        'cta_label': 'Generate my roadmap',
        'icon': Icons.route,
      },
      {
        'eyebrow': 'Resume Studio',
        'title': 'Build a Resume That Gets Noticed',
        'rows': [
          'Role-targeted resume per job',
          'ATS-friendly formatting checks',
          'AI rewrite & positioning tips',
        ],
        'cta_label': 'Build my resume',
        'icon': Icons.description,
      },
      {
        'eyebrow': 'Job Search Strategy Coach',
        'title': 'Search Smarter, Not Harder',
        'rows': [
          'Weekly application priorities',
          'Post-application follow-up plan',
          'Traction-focused role targeting',
        ],
        'cta_label': 'Open Full Strategy',
        'icon': Icons.psychology,
      },
      {
        'eyebrow': 'AI Career Mentor',
        'title': 'Get Guidance, Anytime You Need It',
        'rows': [
          'Unlimited mentor chat sessions',
          'Personalised career guidance',
          'Interview & negotiation tips',
        ],
        'cta_label': 'Chat with mentor',
        'icon': Icons.chat,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF4FBFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark),
                  AppColors.getPrimaryDark(isDark),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'PRO TOOLS',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock more with PRO',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    Color(0xFF1FB7B5),
                    Color(0xFF53B86C),
                    Color(0xFFB5D84E),
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered tools to help you land your next role faster.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.plans),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              elevation: 4,
            ),
            child: Text(
              'Become a Pro',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: proFeatureSlides.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final slide = proFeatureSlides[index];
                return GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.plans),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    padding: const EdgeInsets.all(
                      1.5,
                    ), // Gradient ring thickness
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1FB7B5),
                          Color(0xFF53B86C),
                          Color(0xFFB5D84E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1FB7B5,
                          ).withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.5),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimary(
                                    isDark,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  slide['icon'] as IconData,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                              Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Text(
                              slide['eyebrow'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Column(
                              children: (slide['rows'] as List<String>).map((
                                row,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          row,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                slide['cta_label'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(bool isDark) {
    final apps = dashboardController.recentApplications;

    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 40,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No applications yet',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: apps.length > 5 ? 5 : apps.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          height: 1,
        ),
        itemBuilder: (context, index) {
          final app = apps[index];
          final title = app['job_title'] ?? '-';
          final company = app['company'] ?? '-';
          final date = app['applied_at'] != null
              ? app['applied_at'].toString().split(' ').first
              : '-';
          final status = app['status'] ?? 'applied';

          Color statusColor;
          switch (status.toString().toLowerCase()) {
            case 'shortlisted':
            case 'selected':
            case 'hired':
              statusColor = const Color(0xFF10B981);
              break;
            case 'interview_slot_booked':
            case 'interviewing':
              statusColor = AppColors.getPrimary(isDark);
              break;
            case 'rejected':
              statusColor = const Color(0xFFEF4444);
              break;
            case 'hold':
              statusColor = const Color(0xFFF59E0B);
              break;
            default:
              statusColor = AppColors.getPrimary(isDark);
          }

          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  company,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applied: $date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toString().replaceAll('_', ' ').capitalizeFirst ??
                    status.toString(),
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              try {
                final ApplicationsController appsController =
                    Get.isRegistered<ApplicationsController>()
                    ? Get.find<ApplicationsController>()
                    : Get.put(ApplicationsController());
                final appId = int.tryParse(app['id']?.toString() ?? '');
                if (appId != null) {
                  appsController.selectedApplicationIdForDetails.value = appId;
                }
              } catch (_) {}
              dashboardController.currentIndex.value =
                  2; // Switch to Applications tab (index 2)
            },
          );
        },
      ),
    );
  }

  FaIconData _mapFontAwesomeIcon(String faIcon) {
    switch (faIcon.toLowerCase()) {
      case 'fas fa-chart-line':
        return FontAwesomeIcons.chartLine;
      case 'fas fa-microchip':
        return FontAwesomeIcons.microchip;
      case 'fas fa-robot':
        return FontAwesomeIcons.robot;
      case 'fas fa-code':
        return FontAwesomeIcons.code;
      case 'fas fa-laptop-code':
        return FontAwesomeIcons.laptopCode;
      case 'fas fa-bezier-curve':
        return FontAwesomeIcons.bezierCurve;
      case 'fas fa-cloud':
        return FontAwesomeIcons.cloud;
      case 'fas fa-database':
        return FontAwesomeIcons.database;
      case 'fas fa-pencil-ruler':
        return FontAwesomeIcons.pencil;
      case 'fas fa-briefcase':
      default:
        return FontAwesomeIcons.briefcase;
    }
  }
}
