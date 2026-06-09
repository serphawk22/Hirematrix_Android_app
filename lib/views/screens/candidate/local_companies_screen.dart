import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/local_companies_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/controllers/jobs_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';

class LocalCompaniesScreen extends StatefulWidget {
  const LocalCompaniesScreen({super.key});

  @override
  State<LocalCompaniesScreen> createState() => _LocalCompaniesScreenState();
}

class _LocalCompaniesScreenState extends State<LocalCompaniesScreen> {
  final controller = Get.put(LocalCompaniesController());
  final themeController = Get.find<ThemeController>();

  final TextEditingController roleController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  final FocusNode roleFocusNode = FocusNode();
  final FocusNode cityFocusNode = FocusNode();

  @override
  void dispose() {
    roleController.dispose();
    cityController.dispose();
    roleFocusNode.dispose();
    cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Error',
        'Could not launch URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _triggerSearch() {
    roleFocusNode.unfocus();
    cityFocusNode.unfocus();
    controller.searchCompanies(roleController.text, cityController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subtitleColor = isDark
          ? Colors.grey[400]!
          : const Color(0xFF475569);
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
            'Local Hiring Companies',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            if (controller.hasSearched.value)
              IconButton(
                icon: Icon(Icons.clear_all, color: textColor),
                onPressed: () {
                  roleController.clear();
                  cityController.clear();
                  controller.clearSearch();
                },
                tooltip: 'Clear Search',
              ),
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: () {
                if (controller.hasSearched.value) {
                  _triggerSearch();
                } else {
                  controller.fetchInitData();
                }
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          child: controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.getPrimary(isDark),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    roleFocusNode.unfocus();
                    cityFocusNode.unfocus();
                    controller.showRoleSuggestions.value = false;
                    controller.showCitySuggestions.value = false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Section
                        _buildHeroSection(
                          isDark,
                          textColor,
                          subtitleColor,
                          cardColor,
                          borderColor,
                        ),
                        const SizedBox(height: 20),

                        // Search Card Section
                        _buildSearchCard(
                          isDark,
                          textColor,
                          subtitleColor,
                          cardColor,
                          borderColor,
                        ),
                        const SizedBox(height: 24),

                        // Section Head (Featured Title / Search Results Title)
                        _buildSectionHead(
                          isDark,
                          textColor,
                          subtitleColor,
                          cardColor,
                          borderColor,
                        ),
                        const SizedBox(height: 16),

                        // List of Companies
                        _buildCompaniesList(
                          isDark,
                          textColor,
                          subtitleColor,
                          cardColor,
                          borderColor,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildHeroSection(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business,
                  color: AppColors.getPrimary(isDark),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Local company finder',
                  style: GoogleFonts.inter(
                    color: AppColors.getPrimary(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find companies hiring for your role in your city',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search the companies and jobs already inside HireMatrix first, then use company profiles and open-role links to move faster from discovery to application.',
            style: GoogleFonts.inter(
              color: subtitleColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1A3D)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        controller.companyCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Featured companies',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1A3D)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        controller.openJobsCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open jobs represented',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role field
          Text(
            'Role or skill',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: roleController,
            focusNode: roleFocusNode,
            decoration: InputDecoration(
              hintText: 'Frontend Developer, PHP, UI UX',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.work_outline,
                color: Colors.grey[400],
                size: 18,
              ),
              suffixIcon: roleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          roleController.clear();
                        });
                        controller.getSuggestions('', 'role');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.getPrimary(isDark),
                  width: 1.5,
                ),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: textColor),
            onChanged: (val) {
              setState(() {});
              controller.getSuggestions(val, 'role');
            },
            onSubmitted: (_) => _triggerSearch(),
          ),
          // Role Suggestions dropdown
          _buildSuggestionsDropdown('role', isDark, textColor, borderColor),

          const SizedBox(height: 14),

          // City field
          Text(
            'City',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: cityController,
            focusNode: cityFocusNode,
            decoration: InputDecoration(
              hintText: 'Bangalore, Pune, Hyderabad',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: Colors.grey[400],
                size: 18,
              ),
              suffixIcon: cityController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          cityController.clear();
                        });
                        controller.getSuggestions('', 'city');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.getPrimary(isDark),
                  width: 1.5,
                ),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: textColor),
            onChanged: (val) {
              setState(() {});
              controller.getSuggestions(val, 'city');
            },
            onSubmitted: (_) => _triggerSearch(),
          ),
          // City Suggestions dropdown
          _buildSuggestionsDropdown('city', isDark, textColor, borderColor),

          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _triggerSearch,
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                'Find Companies',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Popular Chips
          _buildPopularChips(isDark, textColor, subtitleColor),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown(
    String type,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    return Obx(() {
      final show = type == 'role'
          ? controller.showRoleSuggestions.value
          : controller.showCitySuggestions.value;
      final items = type == 'role'
          ? controller.roleSuggestions
          : controller.citySuggestions;

      if (!show || items.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A3D) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: borderColor),
          itemBuilder: (context, index) {
            final suggestion = items[index];
            return InkWell(
              onTap: () {
                setState(() {
                  if (type == 'role') {
                    roleController.text = suggestion;
                    controller.showRoleSuggestions.value = false;
                    controller.roleSuggestions.clear();
                  } else {
                    cityController.text = suggestion;
                    controller.showCitySuggestions.value = false;
                    controller.citySuggestions.clear();
                  }
                });
                if (roleController.text.trim().isNotEmpty &&
                    cityController.text.trim().isNotEmpty) {
                  _triggerSearch();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  suggestion,
                  style: GoogleFonts.inter(fontSize: 13.5, color: textColor),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPopularChips(bool isDark, Color textColor, Color subtitleColor) {
    // Slices popular roles & cities to 4 elements each to match the web dashboard design
    final roles = controller.popularRoles.take(4).toList();
    final cities = controller.popularCities.take(4).toList();

    if (roles.isEmpty && cities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular searches',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...roles.map((role) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    roleController.text = role;
                  });
                  if (cityController.text.trim().isNotEmpty) {
                    _triggerSearch();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.getPrimary(isDark).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      color: AppColors.getPrimary(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
            ...cities.map((city) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    cityController.text = city;
                  });
                  if (roleController.text.trim().isNotEmpty) {
                    _triggerSearch();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getSecondary(isDark).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.getSecondary(isDark).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    city,
                    style: GoogleFonts.inter(
                      color: AppColors.getSecondary(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHead(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color borderColor,
  ) {
    final title = controller.hasSearched.value
        ? 'Companies hiring for ${controller.lastSearchRole.value}'
        : 'Featured Local Companies';

    final subtitle = controller.hasSearched.value
        ? 'Showing employers connected to ${controller.lastSearchCity.value}.'
        : 'A starting point for discovering local employers and active openings.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            // Replicates routing to company-job-discovery/browse jobs in mobile app
            try {
              final dashboardController = Get.find<DashboardController>();
              dashboardController.currentIndex.value = 1; // jobs screen
            } catch (_) {}
            Get.back();
          },
          icon: Icon(
            Icons.explore_outlined,
            size: 14,
            color: AppColors.getPrimary(isDark),
          ),
          label: Text(
            'Discovery',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.getPrimary(isDark),
            side: BorderSide(color: AppColors.getPrimary(isDark)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompaniesList(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color borderColor,
  ) {
    if (controller.isSearching.value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding relevant companies...',
              style: GoogleFonts.inter(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final companies = controller.hasSearched.value
        ? controller.searchResults
        : controller.featuredCompanies;

    if (companies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.domain_disabled,
              size: 48,
              color: subtitleColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching companies found yet.',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a broader role like "Developer" or another nearby city. You can also browse all jobs.',
              style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                try {
                  final dashboardController = Get.find<DashboardController>();
                  dashboardController.currentIndex.value = 1;
                } catch (_) {}
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Browse All Jobs',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyCard(
          company,
          isDark,
          textColor,
          subtitleColor,
          cardColor,
          borderColor,
        );
      },
    );
  }

  Widget _buildCompanyCard(
    dynamic company,
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color cardColor,
    Color borderColor,
  ) {
    final name = company['name']?.toString() ?? 'Company';
    final industry = company['industry']?.toString() ?? 'Hiring lead';
    final location = company['location']?.toString() ?? 'India';
    final description =
        company['description']?.toString() ??
        'Explore this company profile and current job openings on HireMatrix.';
    final openJobs = int.tryParse(company['open_jobs']?.toString() ?? '0') ?? 0;
    final website = company['website']?.toString() ?? '';
    final logo = company['logo']?.toString() ?? '';

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: logo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          ApiConstants.resolveImageUrl(logo),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Name & Industry
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      industry,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pills Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 12, color: subtitleColor),
                    const SizedBox(width: 4),
                    Text(
                      openJobs > 0 ? '$openJobs open' : 'Verify openings',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: openJobs > 0
                            ? AppColors.getSecondary(isDark)
                            : textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : const Color(0xFF334155),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Website Button
          if (website.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchURL(website),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(
                  'Website',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getPrimary(isDark),
                  side: BorderSide(color: AppColors.getPrimary(isDark)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
