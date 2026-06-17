import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/resume_studio_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/api_constants.dart';

class ResumeStudioScreen extends StatefulWidget {
  final int? jobId;
  final String? jobTitle;

  const ResumeStudioScreen({super.key, this.jobId, this.jobTitle});

  @override
  State<ResumeStudioScreen> createState() => _ResumeStudioScreenState();
}

class _ResumeStudioScreenState extends State<ResumeStudioScreen> {
  final controller = Get.put(ResumeStudioController());
  final _formKey = GlobalKey<FormState>();

  String _generationMode = 'role'; // 'role' or 'job'
  String? _selectedTargetRole;
  int? _selectedJobId;
  String _selectedTemplateKey = 'modern_professional';
  bool _makePrimary = true;

  final Map<int, bool> _expandedVersions = {};

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
    if (widget.jobId != null) {
      _generationMode = 'job';
      _selectedJobId = widget.jobId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchStudioData();
      if (widget.jobId != null && widget.jobTitle != null) {
        final exists = controller.resumeTargets.any(
          (item) =>
              int.tryParse(item['job_id']?.toString() ?? '') == widget.jobId,
        );
        if (!exists) {
          controller.resumeTargets.insert(0, {
            'job_id': widget.jobId,
            'title': widget.jobTitle,
          });
        }
        setState(() {
          _generationMode = 'job';
          _selectedJobId = widget.jobId;
        });
      }
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
            'Resume Studio AI',
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
                  onRefresh: () => controller.fetchStudioData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark, textColor, subtitleColor),
                        const SizedBox(height: 20),

                        // Profile Readiness Checks
                        if (controller.profileReadiness['is_ready'] == false)
                          _buildReadinessWarning(textColor, subtitleColor)
                        else ...[
                          // Sync Active Transition Card
                          if (controller.activeTransition.isNotEmpty)
                            _buildSyncTransitionCard(
                              isDark,
                              textColor,
                              subtitleColor,
                            ),

                          // AI Resume Generator Form Card
                          _buildGeneratorForm(
                            isDark,
                            cardColor,
                            textColor,
                            subtitleColor,
                            borderColor,
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Saved Versions Section
                        _buildSavedVersionsList(
                          isDark,
                          cardColor,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                        const SizedBox(height: 32),
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
              Icons.description_outlined,
              color: AppColors.getPrimary(isDark),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Resume Studio',
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
          'Resume Studio AI',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tailor and output high-scoring AI resumes matching specialized roles or live listings.',
          style: GoogleFonts.inter(
            color: subtitleColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReadinessWarning(Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Readiness Required',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your core profile details before generating an AI resume version:',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                ...?((controller.profileReadiness['missing_details'] as List?)
                    ?.map((detail) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detail.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTransitionCard(
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F766E).withOpacity(0.2),
                  const Color(0xFF0F172A),
                ]
              : [const Color(0xFFCCFBF1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0F766E).withOpacity(0.4)
              : const Color(0xFF99F6E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                'Sync Active Transition',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have an active transition plan to become a "${controller.activeTransition['target_role'] ?? 'Target Role'}". Sync your resume to reflect this transition direction.',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isActionLoading.value
                  ? null
                  : () async {
                      await controller.syncTransition();
                    },
              icon: controller.isActionLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                controller.isActionLoading.value
                    ? 'Syncing...'
                    : 'Sync Transition Resume',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorForm(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Container(
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
              'Generate Targeted AI Resume',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a customized version tailored for a specific role or listing.',
              style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 20),

            // Mode Selector
            Text(
              'Target Source',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('By Target Role'),
                    selected: _generationMode == 'role',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _generationMode = 'role';
                        });
                      }
                    },
                    selectedColor: AppColors.getPrimary(
                      isDark,
                    ).withOpacity(0.15),
                    checkmarkColor: AppColors.getPrimary(isDark),
                    labelStyle: TextStyle(
                      color: _generationMode == 'role'
                          ? AppColors.getPrimary(isDark)
                          : textColor,
                      fontWeight: _generationMode == 'role'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('For Job Post'),
                    selected: _generationMode == 'job',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _generationMode = 'job';
                        });
                      }
                    },
                    selectedColor: AppColors.getPrimary(
                      isDark,
                    ).withOpacity(0.15),
                    checkmarkColor: AppColors.getPrimary(isDark),
                    labelStyle: TextStyle(
                      color: _generationMode == 'job'
                          ? AppColors.getPrimary(isDark)
                          : textColor,
                      fontWeight: _generationMode == 'job'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode-specific input
            if (_generationMode == 'role') ...[
              Text(
                'Target Role Selection',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedTargetRole,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTargetRole = val;
                  });
                },
                validator: (val) =>
                    _generationMode == 'role' && (val == null || val.isEmpty)
                    ? 'Target role is required'
                    : null,
              ),
            ] else ...[
              Text(
                'Select Specific Job Match',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              controller.resumeTargets.isEmpty
                  ? Text(
                      'No matching or applied jobs found. Save some job listings first.',
                      style: TextStyle(color: Colors.amber[700], fontSize: 13),
                    )
                  : DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedJobId,
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      iconEnabledColor: textColor,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Choose from matches / saved jobs',
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
                      items: controller.resumeTargets.map((item) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(item['job_id']?.toString() ?? ''),
                          child: Text(
                            item['title'] ?? 'Untitled Job',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedJobId = val;
                        });
                      },
                      validator: (val) =>
                          _generationMode == 'job' && val == null
                          ? 'Selecting a job target is required'
                          : null,
                    ),
            ],
            const SizedBox(height: 20),

            // Template Selector
            Text(
              'Select Resume Template',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.resumeTemplates.length,
                itemBuilder: (context, index) {
                  final tpl = controller.resumeTemplates[index];
                  final isSelected = _selectedTemplateKey == tpl['key'];
                  final isBlocked = tpl['is_blocked'] ?? false;
                  final blockReason = tpl['block_reason'] ?? '';

                  return GestureDetector(
                    onTap: isBlocked
                        ? () {
                            Get.snackbar(
                              'Template Restricted',
                              blockReason,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.amber[800],
                              colorText: Colors.white,
                            );
                          }
                        : () {
                            setState(() {
                              _selectedTemplateKey = tpl['key'];
                            });
                          },
                    child: Opacity(
                      opacity: isBlocked ? 0.4 : 1.0,
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.getPrimary(isDark).withOpacity(0.08)
                              : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.getPrimary(isDark)
                                : (isBlocked
                                      ? Colors.redAccent.withOpacity(0.3)
                                      : borderColor),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tpl['label'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tpl['badge'] != null &&
                                    tpl['badge'].toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tpl['badge'],
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                tpl['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: subtitleColor,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Make Primary Checkbox
            Row(
              children: [
                Checkbox(
                  value: _makePrimary,
                  activeColor: AppColors.getPrimary(isDark),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _makePrimary = val;
                      });
                    }
                  },
                ),
                Text(
                  'Set as primary AI resume version',
                  style: GoogleFonts.inter(fontSize: 13, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isActionLoading.value
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await controller.generateAiResume(
                            mode: _generationMode,
                            targetRole: _generationMode == 'role'
                                ? (_selectedTargetRole ?? '')
                                : '',
                            jobId: _generationMode == 'job'
                                ? (_selectedJobId ?? 0)
                                : 0,
                            templateKey: _selectedTemplateKey,
                            makePrimary: _makePrimary,
                          );
                          if (success) {
                            setState(() {
                              _selectedTargetRole = null;
                              _selectedJobId = null;
                            });
                          }
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
                          Text('Tailoring details with AI...'),
                        ],
                      )
                    : Text(
                        'Generate AI Resume',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedVersionsList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Resume Versions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        controller.resumeVersions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No saved AI resume versions yet. Use the tool above to generate one.',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.resumeVersions.length,
                itemBuilder: (context, index) {
                  final version = controller.resumeVersions[index];
                  final versionId =
                      int.tryParse(version['id']?.toString() ?? '') ?? 0;
                  final isPrimary =
                      (version['is_primary'] ?? 0) == 1 ||
                      (version['is_primary']?.toString() == '1');
                  final isExpanded = _expandedVersions[versionId] ?? false;

                  Color strengthColor = Colors.green;
                  if (version['strength_class'] == 'warning') {
                    strengthColor = Colors.amber[700]!;
                  } else if (version['strength_class'] == 'danger') {
                    strengthColor = Colors.redAccent;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPrimary
                            ? AppColors.getPrimary(isDark)
                            : borderColor,
                        width: isPrimary ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Clickable to Toggle Summary
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedVersions[versionId] = !isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        version['title'] ?? 'AI Resume Version',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (isPrimary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Primary',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Target Info
                                    Expanded(
                                      child: Text(
                                        version['generation_source'] ==
                                                'job_version'
                                            ? 'Targeting: ${version['job_title'] ?? 'Job Match'}'
                                            : 'Targeting: ${version['target_role'] ?? 'Role'}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ),
                                    // Strength Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: strengthColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt,
                                            size: 12,
                                            color: strengthColor,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Score: ${version['strength_score'] ?? 0}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: strengthColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.style_outlined,
                                      size: 12,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Template: ${version['template_label'] ?? 'Modern'}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: subtitleColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded summary snippet
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Text(
                                  'AI Executive Summary Highlight',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  version['summary'] ?? 'No summary available.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtitleColor,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Skills Highlighted',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  version['highlight_skills'] ?? 'None',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),

                        // Actions Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withOpacity(0.3)
                                : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Set Primary
                              if (!isPrimary)
                                TextButton.icon(
                                  onPressed: controller.isActionLoading.value
                                      ? null
                                      : () async {
                                          await controller.setPrimary(
                                            versionId,
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.star_outline,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Make Primary',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.getPrimary(
                                      isDark,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),

                              const Spacer(),

                              // Preview Button
                              IconButton(
                                tooltip: 'Preview Layout',
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final previewRawUrl =
                                      version['preview_url'] ?? '';
                                  if (previewRawUrl.isNotEmpty) {
                                    final resolved =
                                        ApiConstants.resolveImageUrl(
                                          previewRawUrl,
                                        );
                                    await launchUrl(
                                      Uri.parse(resolved),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),

                              // Download PDF
                              IconButton(
                                tooltip: 'Download PDF',
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final downloadRawUrl =
                                      version['download_url'] ?? '';
                                  if (downloadRawUrl.isNotEmpty) {
                                    final resolved =
                                        ApiConstants.resolveImageUrl(
                                          downloadRawUrl,
                                        );
                                    await launchUrl(
                                      Uri.parse(resolved),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                              ),

                              // Delete Button
                              IconButton(
                                tooltip: 'Delete Version',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: controller.isActionLoading.value
                                    ? null
                                    : () {
                                        Get.defaultDialog(
                                          title: 'Delete Resume Version',
                                          middleText:
                                              'Are you sure you want to delete this version? This action is permanent.',
                                          textConfirm: 'Delete',
                                          textCancel: 'Cancel',
                                          confirmTextColor: Colors.white,
                                          buttonColor: Colors.redAccent,
                                          onConfirm: () async {
                                            Get.back();
                                            await controller.deleteVersion(
                                              versionId,
                                            );
                                          },
                                        );
                                      },
                              ),
                            ],
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
