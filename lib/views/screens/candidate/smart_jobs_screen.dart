import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/controllers/jobs_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';
import 'package:hirematrix/views/widgets/external_job_bottom_sheet.dart';

class SmartJobsScreen extends StatefulWidget {
  final bool showBackButton;

  const SmartJobsScreen({super.key, this.showBackButton = false});

  @override
  State<SmartJobsScreen> createState() => _SmartJobsScreenState();
}

class _SmartJobsScreenState extends State<SmartJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final JobsController jobsController = Get.put(JobsController());
  int _activeRecSubTab = 0; // Sub-tab pills index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.text = jobsController.searchQuery.value;

    _tabController.index = jobsController.activeMainTab.value;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        jobsController.activeMainTab.value = _tabController.index;
      }
    });

    ever(jobsController.activeMainTab, (int val) {
      if (_tabController.index != val) {
        _tabController.animateTo(val);
      }
    });

    jobsController.animateToTab = (index) {
      if (mounted && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    };

    jobsController.setSubTab = (index) {
      if (mounted) {
        setState(() {
          _activeRecSubTab = index;
        });
      }
    };

    final args = Get.arguments;
    if (args is int) {
      _activeRecSubTab = args;
    }
  }

  @override
  void dispose() {
    jobsController.animateToTab = null;
    jobsController.setSubTab = null;
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF475569);

      return Scaffold(
        backgroundColor: mainBg,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.getCard(isDark) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showBackButton) ...[
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 20, color: textColor),
                            const SizedBox(width: 6),
                            Text(
                              'Back',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: AppColors.getPrimary(isDark),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'JOB DISCOVERY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Jobs Discovery',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Personalized job recommendations matching your profile and career interests.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.getPrimary(isDark),
                  labelColor: AppColors.getPrimary(isDark),
                  unselectedLabelColor: subtitleColor,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Matching Profile'),
                    Tab(text: 'Browse Jobs'),
                  ],
                ),
              ),
              _buildSearchFilterHeader(
                isDark,
                cardColor,
                textColor,
                subtitleColor,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecommendedTab(
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                    ),
                    _buildBrowseTab(
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecommendedTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Obx(() {
      final skills = jobsController.candidateSkills;
      final interests = jobsController.candidateInterests;

      return RefreshIndicator(
        onRefresh: () async {
          await jobsController.fetchJobs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner/Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.getPrimary(isDark),
                      AppColors.getPrimary(isDark),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precision Recommendations',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-time parsing matches your qualifications with live employer postings.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Profile Strength / Skills Strip
              if (skills.isNotEmpty || interests.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matching Signals',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (skills.isNotEmpty) ...[
                        Text(
                          'Skills detected:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: skills
                              .map(
                                (s) => _buildChip(
                                  s,
                                  AppColors.getPrimary(isDark),
                                  isDark,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (interests.isNotEmpty) ...[
                        Text(
                          'Interests:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: interests
                              .map(
                                (i) => _buildChip(
                                  i,
                                  const Color(0xFF10B981),
                                  isDark,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Recommendation sub-tabs pills selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSubTabPill(
                      'Based on Applies',
                      _getFilteredRecommendations(
                        jobsController.recAppliesJobs,
                      ).length,
                      0,
                      isDark,
                    ),
                    _buildSubTabPill(
                      'Based on Skills',
                      _getFilteredRecommendations(
                        jobsController.recSkillsJobs,
                      ).length,
                      1,
                      isDark,
                    ),
                    _buildSubTabPill(
                      'Preferences',
                      _getFilteredRecommendations(
                        jobsController.recPreferencesJobs,
                      ).length,
                      2,
                      isDark,
                    ),
                    _buildSubTabPill(
                      'Other Recommendations',
                      _getFilteredRecommendations(
                        jobsController.recAiJobs,
                      ).length,
                      3,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recommendations List
              _buildRecommendationList(
                isDark,
                cardColor,
                textColor,
                subtitleColor,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubTabPill(String title, int count, int index, bool isDark) {
    final isSelected = _activeRecSubTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeRecSubTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.getPrimary(isDark)
              : (isDark ? AppColors.getCard(isDark) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : (isDark ? Colors.grey[800] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[800]),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    List<dynamic> targetList;
    switch (_activeRecSubTab) {
      case 0:
        targetList = _getFilteredRecommendations(jobsController.recAppliesJobs);
        break;
      case 1:
        targetList = _getFilteredRecommendations(jobsController.recSkillsJobs);
        break;
      case 2:
        targetList = _getFilteredRecommendations(
          jobsController.recPreferencesJobs,
        );
        break;
      case 3:
      default:
        targetList = _getFilteredRecommendations(jobsController.recAiJobs);
        break;
    }

    if (jobsController.isLoading.value) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.getPrimary(isDark),
            ),
          ),
        ),
      );
    }

    if (targetList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No matching jobs found',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try updating your skills or career interests in your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: targetList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = targetList[index];
        return _buildJobCard(job, isDark, cardColor, textColor, subtitleColor);
      },
    );
  }

  Widget _buildBrowseTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        jobsController.currentPage.value = 1;
        await jobsController.fetchJobs();
      },
      child: Obx(() {
        if (jobsController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(isDark),
              ),
            ),
          );
        }

        final list = jobsController.browseJobs;
        if (list.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 54,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No matching jobs found',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try loosening your search filters or queries.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: subtitleColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    jobsController.resetFilters();
                    _searchController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reset Filters'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == list.length) {
              return _buildPaginationControls(isDark, cardColor, textColor);
            }
            final job = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildJobCard(
                job,
                isDark,
                cardColor,
                textColor,
                subtitleColor,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFilterBadgeButton(bool isDark, Color textColor) {
    int activeFiltersCount = 0;
    if (jobsController.selectedCategory.value.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedCompany.value.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedLocation.value.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedWorkMode.value.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedSalaryRange.value.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedEmploymentTypes.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedExperienceLevels.isNotEmpty) {
      activeFiltersCount++;
    }
    if (jobsController.selectedPostedWithin.value.isNotEmpty) {
      activeFiltersCount++;
    }

    return GestureDetector(
      onTap: () => _showFiltersBottomSheet(isDark, textColor),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: activeFiltersCount > 0
              ? AppColors.getPrimary(isDark)
              : (isDark ? AppColors.getBackground(isDark) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activeFiltersCount > 0
                ? AppColors.getPrimary(isDark)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              color: activeFiltersCount > 0 ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Filters',
              style: GoogleFonts.inter(
                color: activeFiltersCount > 0 ? Colors.white : textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (activeFiltersCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  activeFiltersCount.toString(),
                  style: TextStyle(
                    color: AppColors.getPrimary(isDark),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final cur = jobsController.currentPage.value;
    final total = jobsController.totalJobs.value;
    final maxPages = (total / 20).ceil();

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: cur > 1
                ? () {
                    jobsController.currentPage.value = cur - 1;
                    jobsController.fetchJobs();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.getCard(isDark)
                  : Colors.white,
              foregroundColor: textColor,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Previous'),
          ),
          Text(
            'Page $cur of ${maxPages > 0 ? maxPages : 1}',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          ElevatedButton(
            onPressed: cur < maxPages
                ? () {
                    jobsController.currentPage.value = cur + 1;
                    jobsController.fetchJobs();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.getCard(isDark)
                  : Colors.white,
              foregroundColor: textColor,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(bool isDark, Color textColor) {
    // Temporary variables to prevent immediate controller updates on dropdown select
    final tempCategory = jobsController.selectedCategory.value.obs;
    final tempLocation = jobsController.selectedLocation.value.obs;
    final tempWorkMode = jobsController.selectedWorkMode.value.obs;
    final tempSalaryRange = jobsController.selectedSalaryRange.value.obs;
    final tempPostedWithin = jobsController.selectedPostedWithin.value.obs;
    final tempEmploymentTypes = List<String>.from(
      jobsController.selectedEmploymentTypes,
    ).obs;
    final tempExperienceLevels = List<String>.from(
      jobsController.selectedExperienceLevels,
    ).obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    jobsController.resetFilters();
                    _searchController.clear();
                    Get.back();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            Divider(),

            // Scrollable filters form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    _buildFilterDropdown(
                      'Category',
                      tempCategory,
                      jobsController.filterCategories,
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // Locations
                    _buildFilterDropdown(
                      'Location',
                      tempLocation,
                      jobsController.filterLocations,
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // Work Mode
                    _buildFilterDropdown(
                      'Work Mode',
                      tempWorkMode,
                      ['Remote', 'Hybrid', 'Onsite'].obs,
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // Salary range
                    _buildFilterDropdown(
                      'Salary Range (LPA)',
                      tempSalaryRange,
                      {
                        'under_3': 'Under 3 LPA',
                        '3_5': '3 - 5 LPA',
                        '5_8': '5 - 8 LPA',
                        '8_12': '8 - 12 LPA',
                        '12_plus': '12+ LPA',
                      }.obs,
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // Posted within
                    _buildFilterDropdown(
                      'Posted Within',
                      tempPostedWithin,
                      {
                        '1': 'Today',
                        '7': 'This week',
                        '30': 'Last one month',
                      }.obs,
                      textColor,
                    ),
                    const SizedBox(height: 16),

                    // Employment Types Multi-select
                    Text(
                      'Employment Type',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final items = jobsController.filterEmploymentTypes;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((type) {
                          final isSelected = tempEmploymentTypes.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                tempEmploymentTypes.add(type);
                              } else {
                                tempEmploymentTypes.remove(type);
                              }
                            },
                            selectedColor: const Color(
                              0xFF4F46E5,
                            ).withOpacity(0.2),
                            checkmarkColor: AppColors.getPrimary(isDark),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Experience Levels Multi-select
                    Text(
                      'Experience Level',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final items = jobsController.filterExperienceLevels;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items.map((lvl) {
                          final isSelected = tempExperienceLevels.contains(lvl);
                          return FilterChip(
                            label: Text(lvl),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                tempExperienceLevels.add(lvl);
                              } else {
                                tempExperienceLevels.remove(lvl);
                              }
                            },
                            selectedColor: const Color(
                              0xFF4F46E5,
                            ).withOpacity(0.2),
                            checkmarkColor: AppColors.getPrimary(isDark),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Apply Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Save temporary variables back to controller
                  jobsController.selectedCategory.value = tempCategory.value;
                  jobsController.selectedLocation.value = tempLocation.value;
                  jobsController.selectedWorkMode.value = tempWorkMode.value;
                  jobsController.selectedSalaryRange.value =
                      tempSalaryRange.value;
                  jobsController.selectedPostedWithin.value =
                      tempPostedWithin.value;
                  jobsController.selectedEmploymentTypes.assignAll(
                    tempEmploymentTypes,
                  );
                  jobsController.selectedExperienceLevels.assignAll(
                    tempExperienceLevels,
                  );

                  jobsController.currentPage.value = 1;
                  jobsController.fetchJobs();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFilterDropdown(
    String label,
    RxString valHolder,
    dynamic optionsSource,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          List<DropdownMenuItem<String>> menuItems = [
            DropdownMenuItem(value: '', child: Text('All ${label}s')),
          ];

          if (optionsSource is List) {
            menuItems.addAll(
              optionsSource.map<DropdownMenuItem<String>>((o) {
                return DropdownMenuItem(
                  value: o.toString(),
                  child: Text(o.toString()),
                );
              }),
            );
          } else if (optionsSource is RxList) {
            menuItems.addAll(
              optionsSource.map<DropdownMenuItem<String>>((o) {
                return DropdownMenuItem(
                  value: o.toString(),
                  child: Text(o.toString()),
                );
              }),
            );
          } else if (optionsSource is Map || optionsSource is RxMap) {
            final map = optionsSource is RxMap
                ? Map.from(optionsSource)
                : optionsSource;
            map.forEach((key, val) {
              menuItems.add(
                DropdownMenuItem(
                  value: key.toString(),
                  child: Text(val.toString()),
                ),
              );
            });
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: valHolder.value,
                items: menuItems,
                onChanged: (val) {
                  valHolder.value = val ?? '';
                },
                isExpanded: true,
                dropdownColor: Get.isDarkMode
                    ? AppColors.getCard(Get.isDarkMode)
                    : Colors.white,
                style: GoogleFonts.inter(color: textColor, fontSize: 14),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChip(String text, Color baseColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? baseColor.withOpacity(0.9) : baseColor,
        ),
      ),
    );
  }

  Widget _buildJobCard(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    final title = job['title'] ?? 'Job Opportunity';
    final company = job['company'] ?? 'Company';
    final location = job['location'] ?? 'Location';
    final posted = job['created_at'] != null
        ? _formatRelativeDate(job['created_at'].toString())
        : 'Recently';
    final scoreDouble =
        double.tryParse(job['match_score']?.toString() ?? '') ?? 0.0;
    final matchScore = (scoreDouble.round()).clamp(10, 100);
    final logoUrl = job['company_logo'] ?? '';
    final hasLogo = logoUrl.toString().isNotEmpty;
    final isVisited = job['visited_flag'] == 1 || job['visited_flag'] == '1';

    final jobIdInt = int.tryParse(job['id']?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.getBackground(isDark)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  image: hasLogo
                      ? DecorationImage(
                          image: NetworkImage(
                            ApiConstants.resolveImageUrl(logoUrl.toString()),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasLogo
                    ? Center(
                        child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : 'C',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Title and Company
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Bookmark
              Obx(() {
                final isSavedNow = jobsController.savedJobIds.contains(
                  jobIdInt,
                );
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSavedNow ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.getPrimary(isDark),
                    size: 24,
                  ),
                  onPressed: () {
                    final id = int.tryParse(job['id']?.toString() ?? '0');
                    if (id != null && id > 0) {
                      jobsController.toggleSaveJob(id);
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata inline
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.inter(color: subtitleColor, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.access_time_outlined,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                posted,
                style: GoogleFonts.inter(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (job['category'] != null)
                _buildChip(
                  job['category'].toString(),
                  AppColors.getPrimary(isDark),
                  isDark,
                ),
              if (job['employment_type'] != null)
                _buildChip(
                  job['employment_type'].toString(),
                  AppColors.getSecondary(isDark),
                  isDark,
                ),
              if (job['experience_level'] != null)
                _buildChip(
                  job['experience_level'].toString(),
                  AppColors.getPrimary(isDark),
                  isDark,
                ),
              if (job['salary_range'] != null &&
                  job['salary_range'].toString().isNotEmpty)
                _buildChip(
                  '${job['salary_range']} LPA',
                  const Color(0xFF10B981),
                  isDark,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Match Score dial/bar
          if (matchScore > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: matchScore / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.getPrimary(isDark),
                              Color(0xFF10B981),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$matchScore% Match',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimary(isDark),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Footer action triggers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Viewed Tag
                  Row(
                    children: [
                      Icon(
                        isVisited ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: isVisited
                            ? AppColors.getPrimary(isDark)
                            : (isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVisited ? 'Viewed' : 'Not viewed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isVisited
                              ? AppColors.getPrimary(isDark)
                              : (isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // AI Tools trigger
                  PopupMenuButton<String>(
                onSelected: (val) {
                  final id = int.tryParse(job['id']?.toString() ?? '0') ?? 0;
                  if (id <= 0) return;
                  if (val == 'ats') {
                    _runAtsAnalysis(id);
                  } else if (val == 'cover') {
                    _generateCoverLetter(id);
                  } else if (val == 'share') {
                    _shareJob(job);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cover',
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('AI Cover Letter'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('Share Job'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        color: AppColors.getPrimary(isDark),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Tools',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.getPrimary(isDark),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                  ),
                ],
              ),

              // View Details trigger
              TextButton(
                onPressed: () {
                  final isExternal =
                      (job['posted_for']?.toString() == 'client' ||
                      job['external_apply_url'] != null);
                  
                  job['visited_flag'] = 1;
                  jobsController.browseJobs.refresh();
                  jobsController.recSkillsJobs.refresh();
                  jobsController.recAppliesJobs.refresh();
                  jobsController.recPreferencesJobs.refresh();
                  jobsController.recAiJobs.refresh();
                  
                  if (!isExternal) {
                    Get.to(() => JobDetailsScreen(job: job))?.then((_) {
                       // Force UI rebuild when returning
                       // Not easily doable without the exact list name, let's just use Get.forceAppUpdate() or similar if needed.
                    });
                  } else {
                    ExternalJobBottomSheet.show(
                      job,
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
        ],
      ),
    );
  }

  void _showJobDetailsBottomSheet(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag bar & Header Close
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
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Job Title',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['company'] ?? 'Company',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick specs cards
                    Row(
                      children: [
                        _buildSpecTile(
                          Icons.location_on_outlined,
                          'Location',
                          job['location'] ?? 'Remote',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecTile(
                          Icons.work_outline,
                          'Type',
                          job['employment_type'] ?? 'Full-time',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSpecTile(
                          Icons.monetization_on_outlined,
                          'Salary Range',
                          job['salary_range'] != null
                              ? '${job['salary_range']} LPA'
                              : 'Competitive',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecTile(
                          Icons.star_border,
                          'Exp Required',
                          job['experience_level'] ?? 'Not Specified',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    if (job['required_skills'] != null &&
                        job['required_skills']
                            .toString()
                            .trim()
                            .isNotEmpty) ...[
                      Text(
                        'Required Skills',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job['required_skills']
                            .toString()
                            .split(',')
                            .map<Widget>(
                              (s) => _buildChip(
                                s.trim(),
                                AppColors.getPrimary(isDark),
                                isDark,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    Text(
                      'Job Description',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job['description'] ?? 'No description provided.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Footer Apply block
            Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final id =
                          int.tryParse(job['id']?.toString() ?? '0') ?? 0;
                      if (id > 0) {
                        _runAtsAnalysis(id);
                      }
                    },
                    icon: Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: AppColors.getPrimary(isDark),
                    ),
                    label: Text(
                      'ATS Score',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.getPrimary(isDark).withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final id =
                          int.tryParse(job['id']?.toString() ?? '0') ?? 0;
                      if (id > 0) {
                        _generateCoverLetter(id);
                      }
                    },
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    label: Text(
                      'AI Cover Letter',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyToJob(job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Apply Now',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSpecTile(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getBackground(isDark) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Future<void> _applyToJob(dynamic job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.isEmpty) return;

    final isExternal =
        (job['posted_for']?.toString() == 'client' ||
        job['external_apply_url'] != null);
    final extUrl = job['external_apply_url']?.toString() ?? '';

    // Calculate apply URL dynamically from baseUrl
    final apiBase = ApiConstants.baseUrl;
    String targetUrl;
    if (isExternal && extUrl.isNotEmpty) {
      targetUrl = extUrl;
    } else {
      if (apiBase.endsWith('/api')) {
        targetUrl = '${apiBase.substring(0, apiBase.length - 4)}/job/$jobId';
      } else {
        targetUrl = '$apiBase/job/$jobId';
      }
    }

    final uri = Uri.parse(targetUrl);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        Get.snackbar(
          'Error',
          'Could not redirect to apply page: $targetUrl',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error opening link: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _shareJob(dynamic job) {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.isEmpty) return;

    final isExternal =
        (job['posted_for']?.toString() == 'client' ||
        job['external_apply_url'] != null);
    final extUrl = job['external_apply_url']?.toString() ?? '';

    String targetUrl;
    if (isExternal && extUrl.isNotEmpty) {
      targetUrl = extUrl;
    } else {
      final apiBase = ApiConstants.baseUrl;
      if (apiBase.endsWith('/api')) {
        targetUrl = '${apiBase.substring(0, apiBase.length - 4)}/job/$jobId';
      } else {
        targetUrl = '$apiBase/job/$jobId';
      }
    }

    Clipboard.setData(ClipboardData(text: targetUrl))
        .then((_) {
          Get.snackbar(
            'Link Copied',
            'Job link copied to clipboard!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );
        })
        .catchError((err) {
          Get.snackbar(
            'Error',
            'Failed to copy job link: $err',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        });
  }

  void _runAtsAnalysis(int jobId) async {
    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getPrimary(Get.isDarkMode),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await jobsController.analyzeAtsMatch(jobId);
    Get.back(); // close loading dialog

    if (res == null) {
      Get.snackbar(
        'Error',
        'Could not run ATS Score check. Make sure you have uploaded a resume.',
      );
      return;
    }

    final score = int.tryParse(res['score']?.toString() ?? '0') ?? 0;
    final keywords = List<String>.from(res['keywords'] ?? []);
    final suggestions = List<String>.from(res['suggestions'] ?? []);
    final gap = res['gap']?.toString() ?? '';

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? AppColors.getCard(Get.isDarkMode)
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppColors.getPrimary(Get.isDarkMode)),
            const SizedBox(width: 8),
            Text(
              'ATS Score Analysis',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score dial
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.getPrimary(Get.isDarkMode),
                            width: 4,
                          ),
                        ),
                        child: Text(
                          '$score%',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(Get.isDarkMode),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Match Index Score',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Critical Gap
                if (gap.isNotEmpty) ...[
                  Text(
                    'Critical Gap Analysis',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gap,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Missing Keywords
                if (keywords.isNotEmpty) ...[
                  Text(
                    'Missing Keywords',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: keywords
                        .map(
                          (kw) =>
                              _buildChip(kw, Colors.redAccent, Get.isDarkMode),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optimization suggestions
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'How to improve match:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suggestions.map(
                    (sug) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sug,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _generateCoverLetter(int jobId) async {
    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getPrimary(Get.isDarkMode),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await jobsController.generateCoverLetter(jobId);
    Get.back(); // close loading dialog

    if (res == null) {
      Get.snackbar(
        'Error',
        'Failed to generate cover letter. Try again later.',
      );
      return;
    }

    String letter = res['cover_letter']?.toString().trim() ?? '';
    if (letter.isEmpty) {
      letter =
          'Unable to generate cover letter. Please verify that the OPENAI_API_KEY is configured in your server\'s .env file and that the AI service is online.';
    }
    final title = res['job_title']?.toString() ?? 'Job';
    final company = res['company']?.toString() ?? 'Company';

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? AppColors.getCard(Get.isDarkMode)
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Cover Letter Draft',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tailored for $title at $company',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 320,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? AppColors.getBackground(Get.isDarkMode)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Get.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: letter));
              Get.snackbar(
                'Success',
                'Cover letter copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.getPrimary(Get.isDarkMode),
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text(
              'Copy Text',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(Get.isDarkMode),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatRelativeDate(String dbDateStr) {
    try {
      final dbDate = DateTime.parse(dbDateStr);
      final now = DateTime.now();
      final diff = now.difference(dbDate);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          if (diff.inMinutes == 0) {
            return 'Just now';
          }
          return '${diff.inMinutes}m ago';
        }
        return '${diff.inHours}h ago';
      }
      if (diff.inDays == 1) {
        return 'Yesterday';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      }
      if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      }
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } catch (e) {
      return 'Recently';
    }
  }

  List<dynamic> _getFilteredRecommendations(List<dynamic> rawList) {
    List<dynamic> targetList = List<dynamic>.from(rawList);

    // Apply filters to recommendations client-side for maximum effectiveness!
    if (jobsController.selectedCategory.value.isNotEmpty) {
      final filterCat = jobsController.selectedCategory.value
          .toLowerCase()
          .trim();
      targetList = targetList.where((job) {
        final cat = job['category']?.toString().toLowerCase().trim() ?? '';
        return cat.contains(filterCat);
      }).toList();
    }

    if (jobsController.selectedCompany.value.isNotEmpty) {
      final filterCo = jobsController.selectedCompany.value
          .toLowerCase()
          .trim();
      targetList = targetList.where((job) {
        final comp = job['company']?.toString().toLowerCase().trim() ?? '';
        return comp.contains(filterCo);
      }).toList();
    }

    if (jobsController.selectedLocation.value.isNotEmpty) {
      final filterLoc = jobsController.selectedLocation.value
          .toLowerCase()
          .trim();
      targetList = targetList.where((job) {
        final loc = job['location']?.toString().toLowerCase().trim() ?? '';
        return loc.contains(filterLoc);
      }).toList();
    }

    if (jobsController.selectedWorkMode.value.isNotEmpty) {
      final mode = jobsController.selectedWorkMode.value.toLowerCase().trim();
      targetList = targetList.where((job) {
        final loc = job['location']?.toString().toLowerCase() ?? '';
        if (mode == 'remote') {
          return loc.contains('remote') ||
              loc.contains('work from home') ||
              loc.contains('wfh');
        } else if (mode == 'hybrid') {
          return loc.contains('hybrid');
        } else if (mode == 'onsite') {
          return !loc.contains('remote') &&
              !loc.contains('hybrid') &&
              !loc.contains('work from home') &&
              !loc.contains('wfh');
        }
        return true;
      }).toList();
    }

    if (jobsController.selectedSalaryRange.value.isNotEmpty) {
      final range = jobsController.selectedSalaryRange.value;
      targetList = targetList.where((job) {
        final salaryText = job['salary_range']?.toString() ?? '';
        final cleanText = salaryText
            .replaceAll(RegExp(r'[^0-9.\-]'), '')
            .trim();
        double? salaryVal;
        if (cleanText.contains('-')) {
          final parts = cleanText.split('-');
          if (parts.isNotEmpty) {
            salaryVal = double.tryParse(parts[0].trim());
          }
        } else {
          salaryVal = double.tryParse(cleanText);
        }

        if (salaryVal == null) return false;

        if (range == 'under_3') return salaryVal < 3;
        if (range == '3_5') return salaryVal >= 3 && salaryVal < 5;
        if (range == '5_8') return salaryVal >= 5 && salaryVal < 8;
        if (range == '8_12') return salaryVal >= 8 && salaryVal < 12;
        if (range == '12_plus') return salaryVal >= 12;

        return true;
      }).toList();
    }

    if (jobsController.selectedEmploymentTypes.isNotEmpty) {
      targetList = targetList.where((job) {
        final type =
            job['employment_type']?.toString().toLowerCase().trim() ?? '';
        return jobsController.selectedEmploymentTypes.any(
          (t) => type.contains(t.toLowerCase().trim()),
        );
      }).toList();
    }

    if (jobsController.selectedExperienceLevels.isNotEmpty) {
      targetList = targetList.where((job) {
        final exp =
            job['experience_level']?.toString().toLowerCase().trim() ?? '';
        return jobsController.selectedExperienceLevels.any(
          (e) => exp.contains(e.toLowerCase().trim()),
        );
      }).toList();
    }

    if (jobsController.selectedPostedWithin.value.isNotEmpty) {
      final days = int.tryParse(jobsController.selectedPostedWithin.value) ?? 0;
      if (days > 0) {
        targetList = targetList.where((job) {
          final createdAtStr = job['created_at']?.toString() ?? '';
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt == null) return false;
          final diff = DateTime.now().difference(createdAt).inDays;
          return diff <= days;
        }).toList();
      }
    }

    if (jobsController.searchQuery.value.isNotEmpty) {
      final query = jobsController.searchQuery.value.toLowerCase().trim();
      targetList = targetList.where((job) {
        final title = job['title']?.toString().toLowerCase() ?? '';
        final comp = job['company']?.toString().toLowerCase() ?? '';
        final skills = job['required_skills']?.toString().toLowerCase() ?? '';
        final desc = job['description']?.toString().toLowerCase() ?? '';
        return title.contains(query) ||
            comp.contains(query) ||
            skills.contains(query) ||
            desc.contains(query);
      }).toList();
    }

    return targetList;
  }

  Widget _buildActiveFiltersChips(bool isDark) {
    return Obx(() {
      final List<Widget> chips = [];

      if (jobsController.selectedCategory.value.isNotEmpty) {
        chips.add(
          _buildActiveChip(
            'Category: ${jobsController.selectedCategory.value}',
            () {
              jobsController.selectedCategory.value = '';
              jobsController.currentPage.value = 1;
              jobsController.fetchJobs();
            },
            isDark,
          ),
        );
      }
      if (jobsController.selectedCompany.value.isNotEmpty) {
        chips.add(
          _buildActiveChip(
            'Company: ${jobsController.selectedCompany.value}',
            () {
              jobsController.selectedCompany.value = '';
              jobsController.currentPage.value = 1;
              jobsController.fetchJobs();
            },
            isDark,
          ),
        );
      }
      if (jobsController.selectedLocation.value.isNotEmpty) {
        chips.add(
          _buildActiveChip(
            'Location: ${jobsController.selectedLocation.value}',
            () {
              jobsController.selectedLocation.value = '';
              jobsController.currentPage.value = 1;
              jobsController.fetchJobs();
            },
            isDark,
          ),
        );
      }
      if (jobsController.selectedWorkMode.value.isNotEmpty) {
        chips.add(
          _buildActiveChip(
            'Mode: ${jobsController.selectedWorkMode.value}',
            () {
              jobsController.selectedWorkMode.value = '';
              jobsController.currentPage.value = 1;
              jobsController.fetchJobs();
            },
            isDark,
          ),
        );
      }
      if (jobsController.selectedSalaryRange.value.isNotEmpty) {
        final salaryLabels = {
          'under_3': 'Under 3 LPA',
          '3_5': '3 - 5 LPA',
          '5_8': '5 - 8 LPA',
          '8_12': '8 - 12 LPA',
          '12_plus': '12+ LPA',
        };
        final label =
            salaryLabels[jobsController.selectedSalaryRange.value] ??
            jobsController.selectedSalaryRange.value;
        chips.add(
          _buildActiveChip('Salary: $label', () {
            jobsController.selectedSalaryRange.value = '';
            jobsController.currentPage.value = 1;
            jobsController.fetchJobs();
          }, isDark),
        );
      }
      if (jobsController.selectedPostedWithin.value.isNotEmpty) {
        final postedLabels = {
          '1': 'Past 24 Hours',
          '3': 'Past 3 Days',
          '7': 'Past 7 Days',
          '14': 'Past 14 Days',
        };
        final label =
            postedLabels[jobsController.selectedPostedWithin.value] ??
            jobsController.selectedPostedWithin.value;
        chips.add(
          _buildActiveChip('Posted: $label', () {
            jobsController.selectedPostedWithin.value = '';
            jobsController.currentPage.value = 1;
            jobsController.fetchJobs();
          }, isDark),
        );
      }

      for (final type in jobsController.selectedEmploymentTypes) {
        chips.add(
          _buildActiveChip('Type: $type', () {
            jobsController.selectedEmploymentTypes.remove(type);
            jobsController.currentPage.value = 1;
            jobsController.fetchJobs();
          }, isDark),
        );
      }

      for (final lvl in jobsController.selectedExperienceLevels) {
        chips.add(
          _buildActiveChip('Exp: $lvl', () {
            jobsController.selectedExperienceLevels.remove(lvl);
            jobsController.currentPage.value = 1;
            jobsController.fetchJobs();
          }, isDark),
        );
      }

      if (chips.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        ),
      );
    });
  }

  Widget _buildActiveChip(String label, VoidCallback onDelete, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.getPrimary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              color: AppColors.getPrimary(isDark),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterHeader(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    const List<String> kSearchSuggestions = [
      'PHP',
      'PHP Developer',
      'PHP Development',
      'PHP And Web Developer',
      'PHP Laravel',
      'PHP Fresher',
      'Laravel Developer',
      'WordPress Developer',
      'React Developer',
      'Frontend Developer',
      'JavaScript Developer',
      'Full Stack Developer',
      'Backend Developer',
      'Node.js Developer',
      'Python Developer',
      'Java Developer',
      'Data Analyst',
      'Data Scientist',
      'DevOps Engineer',
      'UI UX Designer',
      'Software Developer',
      'Web Developer',
      'MySQL',
      'MongoDB',
      'Remote Developer'
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.getBackground(isDark)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.search, color: Colors.grey, size: 20),
                      ),
                      Expanded(
                        child: Autocomplete<String>(
                          initialValue: TextEditingValue(text: jobsController.searchQuery.value),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            final query = textEditingValue.text.toLowerCase();
                            return kSearchSuggestions.where((option) {
                              return option.toLowerCase().contains(query);
                            });
                          },
                          onSelected: (String selection) {
                            jobsController.searchQuery.value = selection;
                            jobsController.currentPage.value = 1;
                            jobsController.fetchJobs();
                            // Optional: focus unfocus handled by optionsView selection usually
                            FocusScope.of(context).unfocus();
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            // Link controllers: update the provided textEditingController to our _searchController value
                            // or just use the provided textEditingController and listen to changes.
                            // Actually, Autocomplete manages its own controller, but we can sync them.
                            // Let's use the provided textEditingController.
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search title, company, skills...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                suffixIcon: Obx(() {
                                  if (jobsController.searchQuery.value.isEmpty && textEditingController.text.isNotEmpty) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      textEditingController.clear();
                                    });
                                  }
                                  
                                  if (jobsController.searchQuery.value.isNotEmpty) {
                                    return IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        textEditingController.clear();
                                        jobsController.searchQuery.value = '';
                                        jobsController.currentPage.value = 1;
                                        jobsController.fetchJobs();
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ),
                              onChanged: (val) {
                                jobsController.searchQuery.value = val;
                              },
                              onSubmitted: (val) {
                                jobsController.currentPage.value = 1;
                                jobsController.fetchJobs();
                                onFieldSubmitted();
                              },
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                color: isDark ? const Color(0xFF141414) : Colors.white,
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 32, // Match input width approx
                                  constraints: const BoxConstraints(maxHeight: 250),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF272727) : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            option,
                                            style: GoogleFonts.inter(
                                              color: isDark ? Colors.grey[200] : const Color(0xFF142033),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => _buildFilterBadgeButton(isDark, textColor)),
            ],
          ),
        ),
        _buildActiveFiltersChips(isDark),
      ],
    );
  }
}
