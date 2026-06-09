import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/controllers/jobs_controller.dart';
import 'package:hirematrix/controllers/job_search_strategy_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';

class JobSearchStrategyScreen extends StatelessWidget {
  const JobSearchStrategyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final JobSearchStrategyController controller = Get.put(
      JobSearchStrategyController(),
    );

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : AppColors.getBackground(isDark);
      final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF475569);
      final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Search Strategy Coach',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: () => controller.fetchStrategyData(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getPrimary(isDark),
                  ),
                ),
              )
            : controller.strategy.isEmpty
            ? _buildEmptyState(textColor, subtitleColor)
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchStrategyData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header Info (Always visible at top)
                        _buildHeaderCard(isDark, textColor, subtitleColor),
                        const SizedBox(height: 20),

                        // Sticky Segmented Tab Bar (Always visible under header)
                        _buildTabBar(controller, isDark, textColor),
                        const SizedBox(height: 20),

                        // Switchable Tab Content
                        Obx(() {
                          final currentTab = controller.selectedTab.value;
                          switch (currentTab) {
                            case 1:
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Search Roadmap',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Work through these phases to align your application strategy.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRoadmap(
                                    controller,
                                    isDark,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                    borderColor,
                                  ),
                                ],
                              );
                            case 2:
                              return Column(
                                children: [
                                  _buildWeeklyCadence(
                                    controller,
                                    isDark,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                    borderColor,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildWatchouts(
                                    controller,
                                    isDark,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                    borderColor,
                                  ),
                                ],
                              );
                            case 3:
                              if (controller.recommendedJobs.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended Roles to Target',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildRecommendedJobsList(
                                      controller,
                                      isDark,
                                      cardColor,
                                      textColor,
                                      subtitleColor,
                                      borderColor,
                                    ),
                                  ],
                                );
                              } else {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.work_off_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No target roles recommended yet',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Once more matches are active, targeted roles will appear here.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: subtitleColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            case 0:
                            default:
                              return Column(
                                children: [
                                  _buildSnapshotCard(
                                    controller,
                                    isDark,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                    borderColor,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildStrategyHeroCard(
                                    controller,
                                    isDark,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                  ),
                                ],
                              );
                          }
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildTabBar(
    JobSearchStrategyController controller,
    bool isDark,
    Color textColor,
  ) {
    final tabs = [
      {'label': 'Overview', 'icon': Icons.dashboard_outlined},
      {'label': 'Roadmap', 'icon': Icons.route_outlined},
      {'label': 'Checklists', 'icon': Icons.check_circle_outline},
      {'label': 'Target Jobs', 'icon': Icons.work_outline},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return Obx(() {
            final isSelected = controller.selectedTab.value == index;
            final activeColor = AppColors.getPrimary(isDark);
            return GestureDetector(
              onTap: () => controller.selectedTab.value = index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.getCard(isDark) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? Colors.grey[400]
                                : const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.grey[300]
                                  : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compass_calibration, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No strategy generated yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you update your profile or apply to matches, your personalized plan will be generated.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark, Color textColor, Color? subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.explore_outlined,
              color: AppColors.getPrimary(isDark),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Search guidance',
              style: GoogleFonts.inter(
                color: AppColors.getPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Job Search Strategy Coach',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A living roadmap for your next applications, built to help you decide what to do today, this week, and next.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  try {
                    final dashboardController = Get.find<DashboardController>();
                    final jobsController = Get.find<JobsController>();
                    dashboardController.currentIndex.value = 1; // Jobs tab
                    if (jobsController.animateToTab != null) {
                      jobsController.animateToTab!(0); // 0 = Matching Profile
                    }
                  } catch (_) {}
                },
                icon: Icon(Icons.work_outline, size: 16),
                label: const Text('Suggested Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  try {
                    final dashboardController = Get.find<DashboardController>();
                    dashboardController.currentIndex.value = 4;
                  } catch (_) {}
                  Get.back();
                },
                icon: Icon(Icons.edit_note, size: 16),
                label: const Text('Update Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getPrimary(isDark),
                  side: BorderSide(color: AppColors.getPrimary(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    final strategy = controller.strategy;
    final priorityActions = strategy['priority_actions'] as List? ?? [];
    final profileFixes = strategy['profile_fixes'] as List? ?? [];
    final targetRoles = strategy['target_roles'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Snapshot',
            style: GoogleFonts.inter(
              color: AppColors.getPrimary(isDark),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Summary',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This plan centers on ${priorityActions.length} priority actions, ${profileFixes.length} profile fixes, and ${targetRoles.length} target roles. The details live in the roadmap below.',
            style: GoogleFonts.inter(
              color: subtitleColor,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Target Roles',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: targetRoles.map((role) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.getPrimary(isDark).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  role.toString(),
                  style: GoogleFonts.inter(
                    color: AppColors.getPrimary(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyHeroCard(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    final strategy = controller.strategy;
    final source = strategy['source']?.toString() ?? 'fallback';
    final isAi = source == 'ai';
    final planTitle = strategy['title'] ?? 'Job Search Strategy Coach';
    final planSummary =
        strategy['summary'] ??
        'Use this plan to make your next applications more selective.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.getCard(isDark), AppColors.getBackground(isDark)]
              : [const Color(0xFFF3F4F6), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAi
              ? const Color(0xFF10B981).withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAi
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAi
                      ? 'AI-generated strategy'
                      : 'Structured fallback strategy',
                  style: GoogleFonts.inter(
                    color: isAi ? const Color(0xFF10B981) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                'Plan in progress',
                style: GoogleFonts.inter(
                  color: AppColors.getPrimary(isDark),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            planTitle,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            planSummary,
            style: GoogleFonts.inter(
              color: subtitleColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmap(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    final strategy = controller.strategy;
    final targetRoles =
        strategy['target_roles'] as List? ?? ['General Role Search'];
    final profileFixes =
        strategy['profile_fixes'] as List? ?? ['Align resume keywords'];
    final applicationStrategy =
        strategy['application_strategy'] as List? ??
        ['Focus on high-fit listings'];

    final phases = [
      {
        'step': '01',
        'title': 'Set the search boundary',
        'copy':
            'Pick the roles you want to be known for and use them to narrow your search.',
        'items': targetRoles,
      },
      {
        'step': '02',
        'title': 'Strengthen the profile',
        'copy':
            'Close the gaps that recruiters notice first so your profile feels ready to move.',
        'items': profileFixes,
      },
      {
        'step': '03',
        'title': 'Apply in a focused rhythm',
        'copy':
            'Move through your highest-fit roles first, then follow up with intent.',
        'items': applicationStrategy,
      },
    ];

    return Column(
      children: phases.map((phase) {
        final step = phase['step'] as String;
        final title = phase['title'] as String;
        final copy = phase['copy'] as String;
        final items = phase['items'] as List;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getPrimary(isDark),
                          Color(0xFF0EA5E9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        step,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copy,
                          style: GoogleFonts.inter(
                            color: subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1),
              const SizedBox(height: 10),
              Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 6.0,
                            right: 8.0,
                            left: 4.0,
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyCadence(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    final weeklyPlan = controller.strategy['weekly_plan'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.getPrimary(isDark),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Cadence',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (weeklyPlan.isEmpty)
            Text(
              'Set weekly priorities instead of applying broadly.',
              style: GoogleFonts.inter(color: subtitleColor, fontSize: 13),
            )
          else
            Column(
              children: weeklyPlan.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchouts(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    final watchouts = controller.strategy['watchouts'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Watchouts',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (watchouts.isEmpty)
            Text(
              'Keep an eye on role fit, keyword coverage, and follow-up timing as you apply.',
              style: GoogleFonts.inter(
                color: subtitleColor,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            Column(
              children: watchouts.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedJobsList(
    JobSearchStrategyController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    return Column(
      children: controller.recommendedJobs.map((job) {
        final title = job['title'] ?? 'Untitled Role';
        final company = job['company'] ?? 'Company';
        final location = job['location'] ?? 'N/A';
        final scoreDouble =
            double.tryParse(job['match_score']?.toString() ?? '') ?? 0.0;
        final matchScore = scoreDouble > 0
            ? (scoreDouble.round()).clamp(10, 100)
            : 80;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$company • $location • $matchScore% match',
                      style: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  final isExternal =
                      (job['posted_for']?.toString() == 'client' ||
                      job['external_apply_url'] != null);
                  if (!isExternal) {
                    Get.to(() => JobDetailsScreen(job: job));
                  } else {
                    _showJobDetailsBottomSheet(
                      job,
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getPrimary(isDark),
                  side: BorderSide(color: AppColors.getPrimary(isDark)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'Open Job',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showJobDetailsBottomSheet(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    final title = job['title'] ?? 'Job Opportunity';
    final company = job['company'] ?? 'Company';
    final location = job['location'] ?? 'Location';
    final scoreDouble =
        double.tryParse(job['match_score']?.toString() ?? '') ?? 0.0;
    final matchScore = scoreDouble > 0
        ? (scoreDouble.round()).clamp(10, 100)
        : 80;
    final skills = job['required_skills']?.toString() ?? 'N/A';
    final experience = job['experience_level']?.toString() ?? 'N/A';

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: GoogleFonts.inter(
                          color: AppColors.getPrimary(isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$matchScore% Match',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  location,
                  style: GoogleFonts.inter(color: textColor, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.history, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Experience Required: $experience',
                  style: GoogleFonts.inter(color: textColor, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Required Skills',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.split(',').map((skill) {
                    final trimmed = skill.trim();
                    if (trimmed.isEmpty) return const SizedBox();
                    return Chip(
                      label: Text(trimmed),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: textColor,
                      ),
                      backgroundColor: isDark
                          ? AppColors.getBackground(isDark)
                          : Colors.grey[100],
                      side: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  try {
                    final dashboardController = Get.find<DashboardController>();
                    final jobsController = Get.find<JobsController>();
                    dashboardController.currentIndex.value = 1; // Jobs tab
                    if (jobsController.animateToTab != null) {
                      jobsController.animateToTab!(1); // 1 = Browse Jobs
                    }
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Explore Job Listings',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
