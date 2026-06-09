import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/career_transition_controller.dart';
import 'package:hirematrix/views/screens/candidate/career_modules_screen.dart';
import 'package:hirematrix/views/screens/candidate/career_history_screen.dart';

class CareerTransitionScreen extends StatefulWidget {
  const CareerTransitionScreen({super.key});

  @override
  State<CareerTransitionScreen> createState() => _CareerTransitionScreenState();
}

class _CareerTransitionScreenState extends State<CareerTransitionScreen> {
  final controller = Get.put(CareerTransitionController());
  final _currentRoleController = TextEditingController();
  final _targetRoleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedTargetRole;

  final List<String> _suggestedRoles = [
    'Next.js Developer',
    'React Developer',
    'DevOps Engineer',
    'DevOps Developer',
    'Data Scientist',
    'Data Analyst',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Python Developer',
    'Java Developer',
    'Node.js Developer',
    'Cloud Engineer',
    'Machine Learning Engineer',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTransition().then((_) {
        if (controller.currentRole.value.isNotEmpty) {
          _currentRoleController.text = controller.currentRole.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _currentRoleController.dispose();
    _targetRoleController.dispose();
    super.dispose();
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
            'Career Transition AI',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: textColor),
              onPressed: () => Get.to(() => const CareerHistoryScreen()),
              tooltip: 'View History',
            ),
          ],
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
                  onRefresh: () => controller.fetchTransition(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark, textColor, subtitleColor),
                        const SizedBox(height: 20),
                        if (controller.transition.isEmpty)
                          _buildCreatePlanForm(
                            isDark,
                            cardColor,
                            textColor,
                            subtitleColor,
                            borderColor,
                          )
                        else
                          _buildActivePlanView(
                            isDark,
                            cardColor,
                            textColor,
                            subtitleColor,
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

  Widget _buildHeader(bool isDark, Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.route_outlined,
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
          'Career Transition AI',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Get a simple roadmap toward your target role with clear daily steps.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePlanForm(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Your Transition Plan',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your current and target role to generate a roadmap.',
                  style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
                ),
                const SizedBox(height: 20),
                Text(
                  'Current Role',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentRoleController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g., PHP Developer',
                    hintStyle: TextStyle(color: subtitleColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Current role is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Target Role',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTargetRole,
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  iconEnabledColor: textColor,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Select target role',
                    hintStyle: TextStyle(color: subtitleColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  items: _suggestedRoles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(
                        role,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetRole = val;
                      if (val != null) {
                        _targetRoleController.text = val;
                      }
                    });
                  },
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Target role is required'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isActionLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              await controller.createTransition(
                                _currentRoleController.text.trim(),
                                _targetRoleController.text.trim(),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isActionLoading.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Generating AI course...'),
                            ],
                          )
                        : Text(
                            'Generate Roadmap',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.4)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simple guidance',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We keep the flow lightweight: define a target role, generate a plan, and follow daily tasks.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuidanceItem(
                Icons.play_arrow_outlined,
                'Start from your current role',
                isDark,
                textColor,
              ),
              _buildGuidanceItem(
                Icons.play_arrow_outlined,
                'Pick one target role',
                isDark,
                textColor,
              ),
              _buildGuidanceItem(
                Icons.play_arrow_outlined,
                'Follow the generated tasks step by step',
                isDark,
                textColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceItem(
    IconData icon,
    String text,
    bool isDark,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.getPrimary(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanView(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    final active = controller.transition;
    final gapsJson = active['skill_gaps']?.toString() ?? '[]';
    List<dynamic> gaps = [];
    try {
      gaps = jsonDecode(gapsJson);
    } catch (_) {}

    final countVal = active['reactivation_count'];
    final int reactivationCount = countVal is int
        ? countVal
        : int.tryParse(countVal?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Transition flow
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Text(
                'Your Transition Plan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A straightforward path from your current role to your target role.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      active['current_role'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_downward,
                      color: AppColors.getPrimary(isDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      active['target_role'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    if (reactivationCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Reused $reactivationCount time(s)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => const CareerModulesScreen());
                    },
                    icon: const Icon(Icons.book_outlined, size: 18),
                    label: const Text('View Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final rawUrl = controller.pdfUrl.value;
                      debugPrint('PDF Raw URL: $rawUrl');
                      if (rawUrl.isNotEmpty) {
                        final urlStr = ApiConstants.resolveImageUrl(rawUrl);
                        debugPrint('PDF Resolved URL: $urlStr');
                        final uri = Uri.parse(urlStr);
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('PDF Launch Exception: $e');
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
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Change Path'),
                          content: const Text(
                            'Save current path to history and start a new one? Your progress will be preserved.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Get.back();
                                final success = await controller
                                    .resetTransition();
                                if (success) {
                                  _targetRoleController.clear();
                                  setState(() {
                                    _selectedTargetRole = null;
                                  });
                                }
                              },
                              child: const Text(
                                'Reset Path',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Change Path'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
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
        const SizedBox(height: 20),

        // Skill Gaps
        Text(
          'Skill Gaps',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (gaps.isEmpty)
          Text(
            'Analyzing skills...',
            style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gaps.map((gap) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gap.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),

        // Daily Tasks List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tasks',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'One task at a time, in a simple list.',
                  style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.tasks.length} tasks',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tasks are being generated',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait or pull to refresh in a moment.',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = controller.tasks[index];
              final isCompleted =
                  task['is_completed'] == 1 ||
                  task['is_completed'].toString() == '1';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : borderColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day ${task['day_number']}: ${task['task_title']}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green : textColor,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task['task_description'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: subtitleColor,
                              height: 1.4,
                            ),
                          ),
                          if (task['duration_minutes'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${task['duration_minutes']} min',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => controller.completeTask(task['id']),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
