import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/saved_jobs_controller.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';
import 'package:hirematrix/core/constants/api_constants.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  late final SavedJobsController _savedJobsController;

  @override
  void initState() {
    super.initState();
    _savedJobsController = Get.put(SavedJobsController());
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          'Error',
          'Could not open application link.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Invalid application link.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _navigateToBrowseJobs() {
    try {
      final dashCtrl = Get.find<DashboardController>();
      dashCtrl.currentIndex.value = 1; // Index 1 is Jobs (SmartJobsScreen)
    } catch (_) {}
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
      final subtitleColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF374151);

      return Scaffold(
        backgroundColor: mainBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Replica of saved_jobs.php
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
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          color: AppColors.getPrimary(isDark),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'YOUR SHORTLIST',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved Jobs',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Jobs you bookmarked for later. Open a card to review details or remove from shortlist.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: subtitleColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _navigateToBrowseJobs,
                          icon: Icon(Icons.search, size: 16),
                          label: Text(
                            'Browse',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimary(isDark),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results count / Content list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _savedJobsController.fetchSavedJobs,
                  color: AppColors.getPrimary(isDark),
                  child: Obx(() {
                    if (_savedJobsController.isLoading.value &&
                        _savedJobsController.savedJobsList.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getPrimary(isDark),
                          ),
                        ),
                      );
                    }

                    if (_savedJobsController.savedJobsList.isEmpty) {
                      return _buildEmptyState(textColor, subtitleColor);
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Text(
                          '${_savedJobsController.savedJobsList.length} saved job${_savedJobsController.savedJobsList.length != 1 ? "s" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _savedJobsController.savedJobsList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final job =
                                _savedJobsController.savedJobsList[index];
                            return _buildSavedJobCard(
                              job,
                              isDark,
                              cardColor,
                              textColor,
                              subtitleColor,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(Get.isDarkMode).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline,
                color: AppColors.getPrimary(Get.isDarkMode),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved jobs yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save jobs from listings and they will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, color: subtitleColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToBrowseJobs,
              icon: const Icon(Icons.search, size: 16),
              label: Text(
                'Browse Jobs',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(Get.isDarkMode),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedJobCard(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final title = job['title'] ?? 'Untitled Role';
    final company = job['company'] ?? 'Company';
    final location = job['location'] ?? 'N/A';
    final experience = job['experience_level']?.toString() ?? '';
    final salary = job['salary_range']?.toString() ?? '';
    final isExternal =
        job['is_external'] == true ||
        job['is_external'] == 1 ||
        job['is_external'] == '1';
    final logoUrl = job['company_logo'] ?? '';
    final initial = company.isNotEmpty ? company[0].toUpperCase() : 'J';

    final postedDate = job['created_at'] != null
        ? job['created_at'].toString()
        : '';
    String postedAt = 'Recently';
    if (postedDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(postedDate);
        postedAt =
            '${parsed.day} ${_getMonthName(parsed.month)} ${parsed.year}';
      } catch (_) {}
    }

    final jobIdInt = int.tryParse(job['id']?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
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
          // Bookmark & Icon row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.getBackground(isDark)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  image: logoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            ApiConstants.resolveImageUrl(logoUrl.toString()),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl.isEmpty
                    ? Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.getPrimary(isDark),
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

              // Active Bookmark toggle button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.bookmark,
                  color: AppColors.getPrimary(isDark),
                  size: 24,
                ),
                onPressed: () {
                  // Confirm dialog
                  Get.defaultDialog(
                    title: 'Remove Bookmark?',
                    middleText:
                        'Are you sure you want to remove this job from your saved list?',
                    textCancel: 'Cancel',
                    textConfirm: 'Remove',
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.redAccent,
                    onConfirm: () {
                      Get.back();
                      _savedJobsController.handleUnsaveJob(
                        jobIdInt,
                        isExternal,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metadata row
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildMetaTile(Icons.location_on_outlined, location, isDark),
              if (experience.isNotEmpty)
                _buildMetaTile(Icons.work_outline, experience, isDark),
              if (salary.isNotEmpty)
                _buildMetaTile(Icons.monetization_on_outlined, salary, isDark),
              _buildMetaTile(Icons.access_time, postedAt, isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Tags & View detail row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tags
              Row(
                children: [
                  _buildTagBadge(
                    job['employment_type']?.toString() ??
                        (isExternal ? 'External' : 'Full Time'),
                    AppColors.getPrimary(isDark),
                    isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTagBadge(
                    isExternal ? 'MNC Discovery' : 'Local Job',
                    const Color(0xFF10B981),
                    isDark,
                  ),
                ],
              ),

              // Action view details link
              TextButton(
                onPressed: () {
                  if (isExternal) {
                    final applyUrl =
                        job['apply_url']?.toString() ??
                        job['details_url']?.toString() ??
                        '';
                    _launchURL(applyUrl);
                  } else {
                    Get.to(() => JobDetailsScreen(job: job));
                  }
                },
                child: Row(
                  children: [
                    Text(
                      isExternal ? 'Apply Now' : 'View Details',
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

  Widget _buildMetaTile(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTagBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? color.withOpacity(0.9) : color,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  void _showJobDetailsBottomSheet(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
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
                    const SizedBox(height: 16),

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
                          'Salary',
                          job['salary_range'] != null &&
                                  job['salary_range'].toString().isNotEmpty
                              ? '${job['salary_range']} LPA'
                              : 'Competitive',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecTile(
                          Icons.star_border,
                          'Experience',
                          job['experience_level'] ?? 'Not Specified',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Job Description',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      job['description'] ?? 'No description provided.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subtitleColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (job['required_skills'] != null &&
                        job['required_skills'].toString().isNotEmpty) ...[
                      Text(
                        'Required Skills',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job['required_skills']
                            .toString()
                            .split(',')
                            .map<Widget>(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimary(
                                    isDark,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.getPrimary(
                                      isDark,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  skill.trim(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.getPrimary(isDark),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getBackground(isDark) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.getPrimary(isDark), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : AppColors.getBackground(isDark),
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
}
