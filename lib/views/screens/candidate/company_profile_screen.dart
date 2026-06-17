import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/company_profile_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/views/screens/candidate/job_details_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  final int companyId;

  const CompanyProfileScreen({super.key, required this.companyId});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final themeController = Get.find<ThemeController>();
  final authController = Get.find<AuthController>();

  late final CompanyProfileController _controller;

  bool get isLoading => _controller.isLoading.value;
  String? get errorMessage => _controller.errorMessage.value;
  Map<String, dynamic>? get companyData => _controller.companyData.value;
  List<dynamic> get openJobs => _controller.openJobs;
  Map<String, dynamic> get reviewSummary => _controller.reviewSummary;
  List<dynamic> get reviews => _controller.reviews;
  Map<String, dynamic> get eligibility => _controller.eligibility;
  Map<String, dynamic>? get currentUserReview =>
      _controller.currentUserReview.value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller = Get.put(CompanyProfileController());
    _controller.fetchCompanyProfile(widget.companyId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          'Error',
          'Could not open link.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode;
    final mainBg = AppColors.getBackground(isDark);
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Obx(() {
      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            companyData != null
                ? (companyData!['name'] ?? 'Company Profile')
                : 'Company Profile',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: () =>
                  _controller.fetchCompanyProfile(widget.companyId),
            ),
          ],
        ),
        body: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.getPrimary(isDark),
                    ),
                  ),
                )
              : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent.withOpacity(0.8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _controller.fetchCompanyProfile(widget.companyId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimary(isDark),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildProfileContent(cardColor, textColor, isDark),
        ),
      );
    });
  }

  Widget _buildProfileContent(Color cardColor, Color textColor, bool isDark) {
    final name = companyData!['name'] ?? 'Company';
    final logoUrl = companyData!['logo_url'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final industry = companyData!['industry'] ?? 'Not Specified';
    final hq = companyData!['hq'] ?? 'Not Specified';

    return Column(
      children: [
        // Company Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          color: cardColor,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                      image: logoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                ApiConstants.resolveImageUrl(logoUrl),
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
                                fontSize: 28,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          industry,
                          style: GoogleFonts.inter(
                            color: AppColors.getPrimary(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hq,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons Row
              Row(
                children: [
                  if (companyData!['website'] != null &&
                      companyData!['website'].toString().trim().isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchURL(companyData!['website']),
                        icon: const Icon(Icons.language, size: 16),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.getPrimary(isDark),
                          side: BorderSide(color: AppColors.getPrimary(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (companyData!['website'] != null &&
                      companyData!['website'].toString().trim().isNotEmpty)
                    const SizedBox(width: 12),
                  if (companyData!['career_page'] != null &&
                      companyData!['career_page'].toString().trim().isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _launchURL(companyData!['career_page']),
                        icon: const Icon(
                          Icons.work_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('Careers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Tabs Header
        Container(
          color: cardColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.getPrimary(isDark),
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorColor: AppColors.getPrimary(isDark),
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'About Us'),
              Tab(text: 'Culture & Benefits'),
              Tab(text: 'Open Jobs'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),

        // Tab View Body
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAboutUsTab(textColor, isDark),
              _buildCultureBenefitsTab(textColor, isDark),
              _buildOpenJobsTab(textColor, isDark),
              _buildReviewsTab(textColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 1: ABOUT US ---
  Widget _buildAboutUsTab(Color textColor, bool isDark) {
    final shortDesc = companyData!['short_description'] ?? '';
    final whatWeDo = companyData!['what_we_do'] ?? '';
    final size = companyData!['size'] ?? 'Not Specified';
    final founded = companyData!['founded_year'] ?? 'Not Specified';
    final branches = companyData!['branches'] ?? 'Not Specified';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          if (shortDesc.isNotEmpty) ...[
            _buildSectionHeader('Overview'),
            const SizedBox(height: 8),
            Text(
              shortDesc,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // What we do Card
          if (whatWeDo.isNotEmpty) ...[
            _buildSectionHeader('What We Do'),
            const SizedBox(height: 8),
            Text(
              whatWeDo,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Company Details
          _buildSectionHeader('Company Insights'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.people_outline,
                  'Company Size',
                  size,
                  isDark,
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Founded',
                  founded.toString(),
                  isDark,
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  Icons.business_outlined,
                  'Branches',
                  branches,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Social Links Card
          _buildSocialSection(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: themeController.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(bool isDark) {
    final linkedin = companyData!['linkedin'] ?? '';
    final twitter = companyData!['twitter'] ?? '';
    final facebook = companyData!['facebook'] ?? '';
    final instagram = companyData!['instagram'] ?? '';
    final youtube = companyData!['youtube'] ?? '';

    final hasSocial =
        linkedin.isNotEmpty ||
        twitter.isNotEmpty ||
        facebook.isNotEmpty ||
        instagram.isNotEmpty ||
        youtube.isNotEmpty;
    if (!hasSocial) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Connect With Us'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (linkedin.isNotEmpty)
              _buildSocialChip(
                'LinkedIn',
                Icons.link,
                () => _launchURL(linkedin),
                isDark,
              ),
            if (twitter.isNotEmpty)
              _buildSocialChip(
                'X / Twitter',
                Icons.link,
                () => _launchURL(twitter),
                isDark,
              ),
            if (facebook.isNotEmpty)
              _buildSocialChip(
                'Facebook',
                Icons.link,
                () => _launchURL(facebook),
                isDark,
              ),
            if (instagram.isNotEmpty)
              _buildSocialChip(
                'Instagram',
                Icons.link,
                () => _launchURL(instagram),
                isDark,
              ),
            if (youtube.isNotEmpty)
              _buildSocialChip(
                'YouTube',
                Icons.video_library_outlined,
                () => _launchURL(youtube),
                isDark,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialChip(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 14, color: AppColors.getPrimary(isDark)),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.getPrimary(isDark),
        ),
      ),
      backgroundColor: AppColors.getPrimary(isDark).withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.getPrimary(isDark).withOpacity(0.15)),
      ),
    );
  }

  // --- TAB 2: CULTURE & BENEFITS ---
  Widget _buildCultureBenefitsTab(Color textColor, bool isDark) {
    final culture =
        companyData!['culture_summary'] ?? companyData!['mission_values'] ?? '';
    final benefitsRaw = companyData!['employee_benefits'] ?? '';
    final photosUrls = List<String>.from(
      companyData!['workplace_photos_urls'] ?? [],
    );

    List<String> benefits = [];
    if (benefitsRaw.toString().isNotEmpty) {
      benefits = benefitsRaw
          .toString()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Culture overview
          if (culture.isNotEmpty) ...[
            _buildSectionHeader('Our Culture & Values'),
            const SizedBox(height: 8),
            Text(
              culture,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Workplace Photos Gallery
          if (photosUrls.isNotEmpty) ...[
            _buildSectionHeader('Workplace Gallery'),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photosUrls.length,
                itemBuilder: (context, index) {
                  final photo = photosUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(photo),
                        width: 200,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Employee Benefits
          if (benefits.isNotEmpty) ...[
            _buildSectionHeader('Employee Benefits'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: benefits
                  .map(
                    (benefit) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Office Tour section (Video or details)
          _buildOfficeTourSection(isDark),
        ],
      ),
    );
  }

  Widget _buildOfficeTourSection(bool isDark) {
    final tourUrl = companyData!['office_tour_url'] ?? '';
    final tourTitle = companyData!['office_tour_title'] ?? 'Office Video Tour';
    final tourSummary = companyData!['office_tour_summary'] ?? '';

    if (tourUrl.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_library_outlined,
                color: AppColors.getPrimary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                tourTitle,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (tourSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tourSummary,
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _launchURL(tourUrl),
            icon: const Icon(
              Icons.play_circle_outline,
              size: 18,
              color: Colors.white,
            ),
            label: const Text('Watch Virtual Tour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: OPEN JOBS ---
  Widget _buildOpenJobsTab(Color textColor, bool isDark) {
    if (openJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No active job listings right now.',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: openJobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = openJobs[index];
        final title = job['title'] ?? 'Role';
        final location = job['location'] ?? 'Not Specified';
        final salary = job['salary_range']?.toString() ?? '';
        final type = job['employment_type'] ?? 'Full-time';

        return InkWell(
          onTap: () {
            Get.to(() => JobDetailsScreen(job: job));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
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
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.work_outline,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (() {
                              final clean = type.replaceAll('-', ' ');
                              if (clean.isEmpty) return clean;
                              return clean[0].toUpperCase() +
                                  clean.substring(1);
                            })(),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      if (salary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '$salary LPA',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 4: REVIEWS ---
  Widget _buildReviewsTab(Color textColor, bool isDark) {
    final avgRating =
        double.tryParse(reviewSummary['average_rating']?.toString() ?? '0.0') ??
        0.0;
    final totalReviews =
        int.tryParse(reviewSummary['total_reviews']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Dashboard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < avgRating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on $totalReviews reviews',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Write a review alert or button
                _buildReviewCallToAction(isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Review list
          _buildSectionHeader('Latest Reviews'),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No reviews published yet.',
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: reviews.map((review) {
                final headline = review['headline'] ?? 'Review';
                final rating =
                    double.tryParse(review['rating']?.toString() ?? '') ?? 0.0;
                final text = review['review_text'] ?? '';
                final pros = review['pros'] ?? '';
                final cons = review['cons'] ?? '';
                final type = review['review_type'] == 'employee'
                    ? 'Employee'
                    : 'Interview';
                final author =
                    review['candidate_name'] ?? 'Anonymous Candidate';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
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
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.getPrimary(
                                isDark,
                              ).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        headline,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by $author',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                      if (pros.toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pros: $pros',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (cons.toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Cons: $cons',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.redAccent[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCallToAction(bool isDark) {
    final canInterview = eligibility['can_interview_review'] == true;
    final canEmployee = eligibility['can_employee_review'] == true;

    if (!canInterview && !canEmployee) {
      return Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
        ),
        child: Text(
          'Apply or interview to review this company.',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.orange[800]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _showWriteReviewBottomSheet(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getPrimary(isDark),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(currentUserReview != null ? 'Update Review' : 'Review Us'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: themeController.isDarkMode
            ? Colors.white
            : const Color(0xFF111827),
      ),
    );
  }

  void _showWriteReviewBottomSheet(BuildContext context) {
    final isDark = themeController.isDarkMode;
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final primaryColor = AppColors.getPrimary(isDark);

    final existingReview = currentUserReview;
    final canInterview = eligibility['can_interview_review'] == true;
    final canEmployee = eligibility['can_employee_review'] == true;

    String selectedType = 'interview';
    if (existingReview != null) {
      selectedType = existingReview['review_type']?.toString() ?? 'interview';
    } else if (!canInterview && canEmployee) {
      selectedType = 'employee';
    }

    int selectedRating = 0;
    if (existingReview != null) {
      selectedRating =
          int.tryParse(existingReview['rating']?.toString() ?? '0') ?? 0;
    }

    final headlineController = TextEditingController(
      text: existingReview?['headline']?.toString() ?? '',
    );
    final textController = TextEditingController(
      text: existingReview?['review_text']?.toString() ?? '',
    );
    final prosController = TextEditingController(
      text: existingReview?['pros']?.toString() ?? '',
    );
    final consController = TextEditingController(
      text: existingReview?['cons']?.toString() ?? '',
    );

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      existingReview != null
                          ? 'Update Your Review'
                          : 'Write a Review',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share your experience at ${companyData!['name']}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Review Type',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: cardColor,
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 14,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'interview',
                              enabled: canInterview,
                              child: Text(
                                'Interview Experience',
                                style: GoogleFonts.inter(
                                  color: canInterview
                                      ? textColor
                                      : Colors.grey[500],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'employee',
                              enabled: canEmployee,
                              child: Text(
                                'Work Experience (Employee)',
                                style: GoogleFonts.inter(
                                  color: canEmployee
                                      ? textColor
                                      : Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Overall Rating',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedRating = starRating;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              starRating <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Headline',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: headlineController,
                      maxLength: 180,
                      style: GoogleFonts.inter(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Strong interview process and clear communication',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Review (Min 20 characters)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      style: GoogleFonts.inter(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Describe your experience with this company.',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Pros (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: prosController,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'What stood out positively?',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Cons (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: consController,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Anything candidates should know?',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final headline = headlineController.text.trim();
                                final text = textController.text.trim();
                                final pros = prosController.text.trim();
                                final cons = consController.text.trim();
                                final userId = authController.currentUser['id'];

                                if (userId == null) return;

                                if (selectedRating < 1 || selectedRating > 5) {
                                  Get.snackbar(
                                    'Validation Error',
                                    'Please select a rating between 1 and 5.',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }

                                if (headline.length < 4) {
                                  Get.snackbar(
                                    'Validation Error',
                                    'Headline must be at least 4 characters.',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }

                                if (text.length < 20) {
                                  Get.snackbar(
                                    'Validation Error',
                                    'Review text must be at least 20 characters.',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  await _controller.submitReview(
                                    companyId: widget.companyId,
                                    reviewType: selectedType,
                                    rating: selectedRating.toDouble(),
                                    headline: headline,
                                    reviewText: text,
                                    pros: pros,
                                    cons: cons,
                                  );
                                } catch (e) {
                                  Get.snackbar(
                                    'Error',
                                    'Could not save review.',
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } finally {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                existingReview != null
                                    ? 'Update Review'
                                    : 'Publish Review',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
