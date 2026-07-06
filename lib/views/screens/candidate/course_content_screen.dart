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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preparing full lesson...',
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                        _buildModuleSummary(
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                        const SizedBox(height: 20),
                        _buildLessonsList(
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

  Widget _buildModuleSummary(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    int completedLessons = 0;
    for (var lesson in controller.lessonsList) {
      if (lesson['is_completed'] == 1 || lesson['is_completed'] == '1' || lesson['is_completed'] == true) {
        completedLessons++;
      }
    }
    final int totalLessons = controller.lessonsList.length;
    final List<dynamic> moduleGaps = widget.module['covered_skill_gaps'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.getPrimary(isDark).withValues(alpha: 0.15),
                  AppColors.getCard(isDark),
                ]
              : [
                  AppColors.getPrimary(isDark).withValues(alpha: 0.05),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Module ${widget.module['module_number'] ?? '1'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
              ),
              Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$completedLessons / ${totalLessons > 0 ? totalLessons : (widget.module['lesson_count'] ?? '?')}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'completed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (moduleGaps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'This module covers',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moduleGaps.map((gap) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    gap.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final lesson = controller.lessonsList[index];

        final String content = lesson['content'] ?? '';
        final List<String> paragraphs = content.split('\n\n');
        final resources = lesson['resources'] ?? [];
        final exercises = lesson['exercises'] ?? [];
        final List<dynamic> gaps = lesson['covered_skill_gaps'] ?? [];
        
        final bool isCompleted = lesson['is_completed'] == 1 || lesson['is_completed'] == '1' || lesson['is_completed'] == true;

        return Container(
          decoration: BoxDecoration(
            color: isCompleted ? (isDark ? cardColor.withOpacity(0.5) : const Color(0xFFF8FAFC)) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? Colors.green.withOpacity(0.5) : borderColor,
              width: isCompleted ? 1.5 : 1.0,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(20),
              childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : AppColors.getPrimary(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${lesson['lesson_number'] ?? (index + 1)}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson['title'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (gaps.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: gaps.map((gap) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimary(isDark).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  gap.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.getPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(),
                const SizedBox(height: 16),
                
                // Content Body
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: paragraphs.map((para) {
                    if (para.trim().isEmpty) return const SizedBox.shrink();
                    final trimmed = para.trim();
                    if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
                      final headerText = trimmed
                          .replaceAll('## ', '')
                          .replaceAll('### ', '');
                      return Padding(
                        padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                        child: _buildRichText(
                          headerText,
                          AppColors.getPrimary(isDark),
                          isDark,
                          fontSize: 14.5,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRichText(para, textColor, isDark),
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
                          Icon(
                            Icons.link,
                            size: 16,
                            color: isUrl ? Colors.blue : subtitleColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: isUrl
                                ? InkWell(
                                    onTap: () async {
                                      final uri = Uri.parse(r);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
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
                                : _buildRichText(r, subtitleColor, isDark),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(
                    'No additional resources for this lesson.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: subtitleColor,
                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ex ',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRichText(ex, textColor, isDark),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(
                    'No exercises for this lesson.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: subtitleColor,
                    ),
                  ),
                  
                const SizedBox(height: 24),
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.completeLesson(lesson['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        'Mark Complete',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
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
  }
  Widget _buildRichText(String text, Color textColor, bool isDark, {Color? boldColor, double fontSize = 13.5}) {
    // Pre-process: if numbering or bullet is immediately before bold text, move it inside the bold markers.
    text = text.replaceAllMapped(
      RegExp(r'(^|\n)(\s*)([\d]+\.[\s]*|[-*•]\s+)\*\*(.*?)\*\*'),
      (match) => '${match.group(1)}${match.group(2)}**${match.group(3)}${match.group(4)}**',
    );
    
    // Also catch numbering that is NOT before bold text but at start of line, and bold the numbering itself
    text = text.replaceAllMapped(
      RegExp(r'(^|\n)(\s*)([\d]+\.)(\s+)(?!\*\*)'),
      (match) => '${match.group(1)}${match.group(2)}**${match.group(3)}**${match.group(4)}',
    );

    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
    int lastMatchEnd = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: GoogleFonts.inter(
            fontSize: fontSize,
            color: textColor,
            height: 1.5,
            fontWeight: fontSize == 14.5 ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: boldColor ?? (isDark ? Colors.white : Colors.black),
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: textColor,
          height: 1.5,
          fontWeight: fontSize == 14.5 ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
