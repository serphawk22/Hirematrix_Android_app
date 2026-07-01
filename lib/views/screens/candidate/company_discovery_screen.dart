import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/company_discovery_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/screens/candidate/company_profile_screen.dart';

class CompanyDiscoveryScreen extends StatelessWidget {
  const CompanyDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final controller = Get.put(CompanyDiscoveryController());

    final searchController = TextEditingController(
      text: controller.searchQuery.value,
    );
    final locationController = TextEditingController(
      text: controller.locationQuery.value,
    );

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF475569);
      final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Company Intelligence',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchCompanyDiscovery(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(isDark, textColor, subtitleColor),
                _buildSearchFilterSection(
                  context,
                  controller,
                  searchController,
                  locationController,
                  isDark,
                  cardColor,
                  textColor,
                  subtitleColor,
                  borderColor,
                ),
                _buildSegmentsSection(
                  controller,
                  isDark,
                  cardColor,
                  textColor,
                  borderColor,
                ),
                _buildCompanyListSection(
                  controller,
                  isDark,
                  cardColor,
                  textColor,
                  subtitleColor,
                  borderColor,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeroSection(bool isDark, Color textColor, Color? subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162327) : const Color(0xFFE8F9F8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF23343A) : const Color(0xFFD9ECE5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, size: 14, color: AppColors.getPrimary(isDark)),
              const SizedBox(width: 8),
              Text(
                'Company Intelligence',
                style: GoogleFonts.inter(
                  color: AppColors.getPrimary(isDark),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover companies before you apply',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore Indian MNCs, corporate employers, global Indian companies, startups, and their portal-posted jobs.',
            style: GoogleFonts.inter(
              color: subtitleColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterSection(
    BuildContext context,
    CompanyDiscoveryController controller,
    TextEditingController searchController,
    TextEditingController locationController,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            'Company, skill, or keyword',
            'Zoho, fintech, PHP, Bangalore',
            searchController,
            isDark,
            textColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            'Industry',
            controller.selectedIndustry.value,
            ['', ...controller.industries],
            (val) => controller.selectedIndustry.value = val ?? '',
            isDark,
            textColor,
            borderColor,
            hint: 'All industries',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Location',
            'Bangalore, Kochi, Chennai',
            locationController,
            isDark,
            textColor,
            borderColor,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            'Hiring status',
            controller.selectedHiringStatus.value,
            ['', 'active'],
            (val) => controller.selectedHiringStatus.value = val ?? '',
            isDark,
            textColor,
            borderColor,
            hint: 'All companies',
            displayMap: {'': 'All companies', 'active': 'Actively hiring'},
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.updateFilters(
                  query: searchController.text,
                  location: locationController.text,
                );
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController textController,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: textController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.getPrimary(isDark),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0D0F)
                : const Color(0xFFF8FCFA),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
    Color textColor,
    Color borderColor, {
    String? hint,
    Map<String, String>? displayMap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value)
              ? value
              : (items.isNotEmpty ? items.first : null),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.getPrimary(isDark),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A0D0F)
                : const Color(0xFFF8FCFA),
          ),
          dropdownColor: isDark ? const Color(0xFF162327) : Colors.white,
          style: TextStyle(color: textColor, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: textColor),
          items: items.map((item) {
            final displayText =
                displayMap != null && displayMap.containsKey(item)
                ? displayMap[item]!
                : (item.isEmpty ? (hint ?? 'Select') : item);
            return DropdownMenuItem(value: item, child: Text(displayText));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSegmentsSection(
    CompanyDiscoveryController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    if (controller.segments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSegmentCard(
                  controller,
                  '',
                  'All Companies',
                  Icons.layers,
                  controller.allCompanyCount.value,
                  isDark,
                  cardColor,
                  textColor,
                  borderColor,
                ),
                const SizedBox(width: 12),
                ...controller.segments.map((segment) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildSegmentCard(
                      controller,
                      segment['key'] ?? '',
                      segment['label'] ?? 'Companies',
                      _getIconData(segment['icon']),
                      segment['count'] ?? 0,
                      isDark,
                      cardColor,
                      textColor,
                      borderColor,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(
    CompanyDiscoveryController controller,
    String key,
    String label,
    dynamic icon,
    int count,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    final isActive = controller.activeSegment.value == key;
    final activeBg = isDark ? const Color(0xFF1B2A2F) : const Color(0xFFE8F9F8);
    final activeBorder = isDark
        ? AppColors.getPrimary(isDark)
        : const Color(0xFFD9ECE5);

    return GestureDetector(
      onTap: () => controller.setSegment(key),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? activeBg : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeBorder : borderColor,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.getPrimary(isDark).withOpacity(0.1)
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: icon is IconData
                  ? Icon(
                      icon,
                      size: 16,
                      color: isActive
                          ? AppColors.getPrimary(isDark)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    )
                  : FaIcon(
                      icon,
                      size: 16,
                      color: isActive
                          ? AppColors.getPrimary(isDark)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? AppColors.getPrimary(isDark) : textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count profiles',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  dynamic _getIconData(String? iconClass) {
    switch (iconClass) {
      case 'fa-building-flag':
        return FontAwesomeIcons.buildingFlag;
      case 'fa-globe-asia':
        return FontAwesomeIcons.earthAsia;
      case 'fa-city':
        return FontAwesomeIcons.city;
      case 'fa-rocket':
        return FontAwesomeIcons.rocket;
      case 'fa-cube':
        return FontAwesomeIcons.cube;
      case 'fa-people-carry-box':
        return FontAwesomeIcons.peopleCarryBox;
      case 'fa-laptop-house':
        return FontAwesomeIcons.laptopHouse;
      case 'fa-user-graduate':
        return FontAwesomeIcons.userGraduate;
      default:
        return FontAwesomeIcons.building;
    }
  }

  Widget _buildCompanyListSection(
    CompanyDiscoveryController controller,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.activeSegment.value.isNotEmpty
                        ? 'Filtered Companies'
                        : 'Company Directory',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view open jobs',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => controller.resetFilters(),
                child: Text(
                  'Reset',
                  style: TextStyle(color: AppColors.getPrimary(isDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.isLoading.value)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: AppColors.getPrimary(isDark),
                ),
              ),
            )
          else if (controller.companies.isEmpty)
            _buildEmptyState(isDark, cardColor, textColor, borderColor)
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.companies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final company = controller.companies[index];
                    return _buildCompanyCard(
                      company,
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                      borderColor,
                    );
                  },
                ),
                if (controller.hasMore.value)
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            controller.fetchCompanyDiscovery(isLoadMore: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.getPrimary(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isLoadingMore.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'View More Companies',
                                style: TextStyle(
                                  color: AppColors.getPrimary(isDark),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.building,
            size: 48,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No companies found',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another category, city, industry, or company name.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
    Map<String, dynamic> company,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
    Color borderColor,
  ) {
    final name = company['name']?.toString() ?? 'Company';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final logo = company['logo']?.toString() ?? '';
    final hq = company['hq']?.toString() ?? '';
    final tags =
        (company['discovery_tags'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final description =
        company['short_description']?.toString() ??
        'Explore company details, hiring locations, and portal-posted jobs.';

    return InkWell(
      onTap: () {
        final idStr = company['id']?.toString() ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        if (id > 0) {
          Get.to(() => CompanyProfileScreen(companyId: id));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: logo.isNotEmpty
                      ? Image.network(
                          logo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
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
                        name,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hq.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            hq,
                            style: GoogleFonts.inter(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2A2F)
                            : const Color(0xFFE8F9F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF1FB7B5)
                              : const Color(0xFF0D8A90),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.inter(
                color: subtitleColor,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
