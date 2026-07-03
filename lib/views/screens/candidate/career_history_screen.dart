import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/career_transition_controller.dart';

class CareerHistoryScreen extends StatefulWidget {
  const CareerHistoryScreen({super.key});

  @override
  State<CareerHistoryScreen> createState() => _CareerHistoryScreenState();
}

class _CareerHistoryScreenState extends State<CareerHistoryScreen> {
  final controller = Get.find<CareerTransitionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHistory();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr.split(' ')[0];
    }
  }

  List<String> _parseSkillGaps(dynamic skillGapsData) {
    if (skillGapsData == null) return [];
    if (skillGapsData is List) {
      return skillGapsData.map((e) => e.toString()).toList();
    }
    if (skillGapsData is String) {
      if (skillGapsData.isEmpty) return [];
      try {
        final decoded = jsonDecode(skillGapsData);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // If it's not valid JSON, maybe comma separated?
        return skillGapsData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
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
          backgroundColor: cardColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Career Transition History',
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
                  onRefresh: () => controller.fetchHistory(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryStrip(
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                        const SizedBox(height: 24),
                        _buildHistoryList(
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                        const SizedBox(height: 24),
                        // if (controller.historyList.isNotEmpty)
                        //   _buildHowItWorks(isDark, cardColor, textColor, subtitleColor, borderColor),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildSummaryStrip(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    final transitions = controller.historyList;
    final totalPaths = transitions.length;
    final activePaths = transitions
        .where((t) => t['status'] == 'active')
        .length;
    final savedPaths = totalPaths > activePaths ? totalPaths - activePaths : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Saved Paths',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Switch back to a previous path without regenerating the plan.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.getPrimaryDark(isDark)
                : AppColors.getPrimary(isDark).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.transparent
                  : AppColors.getPrimary(isDark).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                totalPaths.toString(),
                'total',
                isDark,
                textColor,
              ),
              _buildMetricItem(
                activePaths.toString(),
                'active',
                isDark,
                textColor,
              ),
              _buildMetricItem(
                savedPaths.toString(),
                'saved',
                isDark,
                textColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String count,
    String label,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.getPrimary(isDark),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    if (controller.historyList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Career Transitions Yet',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first career transition to see it here.',
              style: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.offNamed('/candidate/career-transition'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Career Transition'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final path = controller.historyList[index];
        final bool isActive = path['status'] == 'active';
        final countVal = path['reactivation_count'];
        final int reactivationCount = countVal is int
            ? countVal
            : int.tryParse(countVal?.toString() ?? '0') ?? 0;

        final skillGaps = _parseSkillGaps(path['skill_gaps']);
        final deactivatedAt = path['deactivated_at'];
        final reactivatedAt = path['reactivated_at'];
        final createdAt = path['created_at'];

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.getPrimary(isDark).withOpacity(0.6)
                  : borderColor,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.getPrimary(isDark).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                            ? AppColors.getPrimary(isDark).withOpacity(0.1)
                            : AppColors.getPrimary(isDark).withOpacity(0.05))
                      : (isDark ? const Color(0xFF1E293B) : Colors.grey[50]),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.archive,
                          size: 16,
                          color: isActive
                              ? AppColors.getPrimary(isDark)
                              : subtitleColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active Path' : 'Saved Path',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.getPrimary(isDark)
                                : subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        _formatDate(createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Flow
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              path['current_role'] ?? 'Current Role',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: subtitleColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              path['target_role'] ?? 'Target Role',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skill Gaps Block
                    Text(
                      'Skill Gaps',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (skillGaps.isEmpty)
                      Text(
                        'No skill gaps recorded',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtitleColor,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...skillGaps
                              .take(3)
                              .map(
                                (skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1F2937)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    skill,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                          if (skillGaps.length > 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF111827)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                '+ ${skillGaps.length - 3} more',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Meta Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetaItem(
                            icon: Icons.refresh_rounded,
                            value: reactivationCount.toString(),
                            label: 'Times Reused',
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (!isActive &&
                                  deactivatedAt != null &&
                                  deactivatedAt.toString().isNotEmpty) {
                                return _buildMetaItem(
                                  icon: Icons.event_busy,
                                  value: _formatDate(deactivatedAt),
                                  label: 'Deactivated',
                                  isDark: isDark,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                );
                              } else if (reactivatedAt != null &&
                                  reactivatedAt.toString().isNotEmpty) {
                                return _buildMetaItem(
                                  icon: Icons.event_available,
                                  value: _formatDate(reactivatedAt),
                                  label: 'Last Active',
                                  isDark: isDark,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                );
                              } else {
                                return _buildMetaItem(
                                  icon: Icons.event_note,
                                  value: _formatDate(createdAt),
                                  label: 'Created',
                                  isDark: isDark,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: isActive
                          ? ElevatedButton.icon(
                              onPressed: null, // Disabled
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Currently Active'),
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                disabledForegroundColor: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                Get.dialog(
                                  AlertDialog(
                                    backgroundColor: cardColor,
                                    title: Text(
                                      'Reactivate Path',
                                      style: GoogleFonts.inter(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Reactivate this career path? Your current active path will be saved to history.',
                                      style: GoogleFonts.inter(
                                        color: subtitleColor,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.inter(
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Get.back();
                                          final success = await controller
                                              .reactivateTransition(path['id']);
                                          if (success) {
                                            Get.back(); // return to main transition screen
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.getPrimary(
                                            isDark,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Reactivate'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Reactivate This Path'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getPrimary(isDark),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: subtitleColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowItWorks(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.getPrimary(isDark),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How It Works',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Reactivate',
            'Resume any previous learning journey instantly.',
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'No API Calls',
            'Uses your saved course content immediately.',
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Fresh Start',
            'Task progress resets when reactivating a path.',
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Flexible',
            'Switch between different career paths anytime.',
            textColor,
            subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String desc,
    Color textColor,
    Color subtitleColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 8),
          child: Icon(Icons.circle, size: 6, color: subtitleColor),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtitleColor,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
