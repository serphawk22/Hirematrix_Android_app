import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
            'Transition History',
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(isDark)),
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
                        _buildHeader(isDark, textColor, subtitleColor),
                        const SizedBox(height: 20),
                        _buildHistoryList(isDark, cardColor, textColor, subtitleColor, borderColor),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildHeader(bool isDark, Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Roadmaps History',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Revisit your past learning paths and reactivate them to refresh your progress.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 13.5,
            height: 1.4,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'No career transition pathways found.',
            style: GoogleFonts.inter(color: subtitleColor),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final path = controller.historyList[index];
        final bool isActive = path['status'] == 'active';
        final countVal = path['reactivation_count'];
        final int reactivationCount = countVal is int
            ? countVal
            : int.tryParse(countVal?.toString() ?? '0') ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.getPrimary(isDark).withOpacity(0.5)
                  : borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created on ${path['created_at'] != null ? path['created_at'].toString().split(' ')[0] : 'N/A'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path['current_role'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.arrow_downward, size: 14, color: AppColors.getPrimary(isDark)),
                            const SizedBox(width: 6),
                            Text(
                              path['target_role'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Reactivate Path'),
                            content: const Text(
                              'Are you sure you want to reactivate this path? This will deactivate your currently active path and reset progress for this one.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Get.back();
                                  final success = await controller.reactivateTransition(path['id']);
                                  if (success) {
                                    Get.back(); // return to main transition screen
                                  }
                                },
                                child: const Text('Reactivate'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 12),
                      label: const Text('Reactivate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              if (reactivationCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Reused $reactivationCount time(s)',
                  style: GoogleFonts.inter(fontSize: 11, color: subtitleColor),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
