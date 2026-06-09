import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/career_transition_controller.dart';

class CourseContentScreen extends StatefulWidget {
  final Map<String, dynamic> module;
  const CourseContentScreen({super.key, required this.module});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  final controller = Get.find<CareerTransitionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchLessons(widget.module['id']);
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
      final subtitleColor = isDark ? Colors.grey[400]! : const Color(0xFF475569);
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
            widget.module['title'] ?? 'Module Content',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        body: controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(isDark)),
                ),
              )
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => controller.fetchLessons(widget.module['id']),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModuleSummary(isDark, cardColor, textColor, subtitleColor, borderColor),
                        const SizedBox(height: 20),
                        _buildLessonsList(isDark, cardColor, textColor, subtitleColor, borderColor),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildModuleSummary(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Module ${widget.module['module_number']}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.module['title'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.module['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: subtitleColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: subtitleColor),
              const SizedBox(width: 6),
              Text(
                'Duration: ${widget.module['duration_weeks']} week(s)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    if (controller.lessonsList.isEmpty) {
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
            'No lessons available in this module.',
            style: GoogleFonts.inter(color: subtitleColor),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.lessonsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final lesson = controller.lessonsList[index];

        // Format content paragraphs nicely
        final String content = lesson['content'] ?? '';
        final List<String> paragraphs = content.split('\n\n');

        // Extract resources and exercises
        final resources = lesson['resources'] ?? [];
        final exercises = lesson['exercises'] ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Title Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${lesson['lesson_number']}',
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
                    child: Text(
                      lesson['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Content Body
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paragraphs.map((para) {
                  if (para.trim().isEmpty) return const SizedBox.shrink();
                  // Check if it starts with markdown headers
                  final trimmed = para.trim();
                  if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
                    final headerText = trimmed.replaceAll('## ', '').replaceAll('### ', '');
                    return Padding(
                      padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                      child: Text(
                        headerText,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      para,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Learning Resources
              Text(
                'Learning Resources',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (resources is List && resources.isNotEmpty)
                ...resources.map<Widget>((resource) {
                  final String r = resource.toString();
                  final bool isUrl = Uri.tryParse(r)?.hasAbsolutePath ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: isUrl ? Colors.blue : subtitleColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isUrl
                              ? InkWell(
                                  onTap: () async {
                                    final uri = Uri.parse(r);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    r,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              : Text(
                                  r,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: subtitleColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                })
              else
                Text(
                  'No additional resources for this lesson.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
                ),

              const SizedBox(height: 16),

              // Practice Exercises
              Text(
                'Practice Exercises',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (exercises is List && exercises.isNotEmpty)
                ...exercises.asMap().entries.map<Widget>((entry) {
                  final index = entry.key;
                  final ex = entry.value.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ex ${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ex,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
              else
                Text(
                  'No exercises for this lesson.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
                ),
            ],
          ),
        );
      },
    );
  }
}
