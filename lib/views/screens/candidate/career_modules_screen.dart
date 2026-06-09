import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/career_transition_controller.dart';
import 'package:hirematrix/views/screens/candidate/course_content_screen.dart';
import 'package:hirematrix/core/constants/api_constants.dart';

class CareerModulesScreen extends StatefulWidget {
  const CareerModulesScreen({super.key});

  @override
  State<CareerModulesScreen> createState() => _CareerModulesScreenState();
}

class _CareerModulesScreenState extends State<CareerModulesScreen> {
  final controller = Get.find<CareerTransitionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchModules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
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
            'Course Modules',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getPrimary(isDark),
                  ),
                ),
              )
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchModules(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark, textColor, subtitleColor),
                        const SizedBox(height: 20),
                        _buildCourseDownloadBox(
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                        const SizedBox(height: 20),
                        _buildModulesList(
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
              ),
      );
    });
  }

  Widget _buildHeader(bool isDark, Color textColor, Color subtitleColor) {
    final trans = controller.transition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school_outlined,
              color: AppColors.getPrimary(isDark),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Career learning path',
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
          'Your Learning Journey',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${trans['current_role'] ?? ''} to ${trans['target_role'] ?? ''}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.getPrimary(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Open any module to start learning. Course content is available for offline-ready usage.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDownloadBox(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Download Offline PDF',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Get a complete PDF with modules, lessons, resources, and exercises.',
            style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final rawUrl = controller.pdfUrl.value;
                debugPrint('Modules Screen PDF Raw URL: $rawUrl');
                if (rawUrl.isNotEmpty) {
                  final urlStr = ApiConstants.resolveImageUrl(rawUrl);
                  debugPrint('Modules Screen PDF Resolved URL: $urlStr');
                  final uri = Uri.parse(urlStr);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Modules PDF Launch Exception: $e');
                    Get.snackbar(
                      'Error',
                      'Could not download PDF right now',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Complete Course PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    if (controller.modulesList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'No course modules available.',
            style: GoogleFonts.inter(color: subtitleColor),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.modulesList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final module = controller.modulesList[index];

        return InkWell(
          onTap: () {
            Get.to(() => CourseContentScreen(module: module));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Module Number Circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${module['module_number']}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Module Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module['title'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: subtitleColor),
                          const SizedBox(width: 4),
                          Text(
                            '${module['duration_weeks']} week(s)',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
