import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/jobs_controller.dart';

class ExternalJobBottomSheet {
  static void show(
    dynamic job,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color? subtitleColor,
  ) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag bar & Header Close
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Job Title',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['company'] ?? 'Company',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick specs cards
                    Row(
                      children: [
                        _buildSpecTile(
                          Icons.location_on_outlined,
                          'Location',
                          job['location'] ?? 'Remote',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecTile(
                          Icons.work_outline,
                          'Type',
                          job['employment_type'] ?? 'Full-time',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSpecTile(
                          Icons.monetization_on_outlined,
                          'Salary Range',
                          job['salary_range'] != null
                              ? '${job['salary_range']} LPA'
                              : 'Competitive',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildSpecTile(
                          Icons.star_border,
                          'Exp Required',
                          job['experience_level'] ?? 'Not Specified',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    if (job['required_skills'] != null &&
                        job['required_skills']
                            .toString()
                            .trim()
                            .isNotEmpty) ...[
                      Text(
                        'Required Skills',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job['required_skills']
                            .toString()
                            .split(',')
                            .map<Widget>(
                              (s) => _buildChip(
                                s.trim(),
                                AppColors.getPrimary(isDark),
                                isDark,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    Text(
                      'Job Description',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job['description'] ?? 'No description provided.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Footer Apply block
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final id =
                          int.tryParse(job['id']?.toString() ?? '0') ?? 0;
                      if (id > 0) {
                        _runAtsAnalysis(id);
                      }
                    },
                    icon: Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: AppColors.getPrimary(isDark),
                    ),
                    label: Text(
                      'ATS Score',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.getPrimary(isDark).withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final id =
                          int.tryParse(job['id']?.toString() ?? '0') ?? 0;
                      if (id > 0) {
                        _generateCoverLetter(id);
                      }
                    },
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                    label: Text(
                      'AI Cover Letter',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyToJob(job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Apply Now',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildSpecTile(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getBackground(isDark) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Future<void> _applyToJob(dynamic job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.isEmpty) return;

    final isExternal =
        (job['posted_for']?.toString() == 'client' ||
        job['external_apply_url'] != null);
    final extUrl = job['external_apply_url']?.toString() ?? '';

    // Calculate apply URL dynamically from baseUrl
    final apiBase = ApiConstants.baseUrl;
    String targetUrl;
    if (isExternal && extUrl.isNotEmpty) {
      targetUrl = extUrl;
    } else {
      if (apiBase.endsWith('/api')) {
        targetUrl = '${apiBase.substring(0, apiBase.length - 4)}/job/$jobId';
      } else {
        targetUrl = '$apiBase/job/$jobId';
      }
    }

    final uri = Uri.parse(targetUrl);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        Get.snackbar(
          'Error',
          'Could not redirect to apply page: $targetUrl',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error opening link: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  static void _runAtsAnalysis(int jobId) async {
    final jobsController = Get.find<JobsController>();
    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getPrimary(Get.isDarkMode),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await jobsController.analyzeAtsMatch(jobId);
    Get.back(); // close loading dialog

    if (res == null) {
      Get.snackbar(
        'Error',
        'Could not run ATS Score check. Make sure you have uploaded a resume.',
      );
      return;
    }

    final score = int.tryParse(res['score']?.toString() ?? '0') ?? 0;
    final keywords = List<String>.from(res['keywords'] ?? []);
    final suggestions = List<String>.from(res['suggestions'] ?? []);
    final gap = res['gap']?.toString() ?? '';

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? AppColors.getCard(Get.isDarkMode)
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppColors.getPrimary(Get.isDarkMode)),
            const SizedBox(width: 8),
            Text(
              'ATS Score Analysis',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score dial
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.getPrimary(Get.isDarkMode),
                            width: 4,
                          ),
                        ),
                        child: Text(
                          '$score%',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrimary(Get.isDarkMode),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Match Index Score',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Critical Gap
                if (gap.isNotEmpty) ...[
                  Text(
                    'Critical Gap Analysis',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gap,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Missing Keywords
                if (keywords.isNotEmpty) ...[
                  Text(
                    'Missing Keywords',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: keywords
                        .map(
                          (kw) =>
                              _buildChip(kw, Colors.redAccent, Get.isDarkMode),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optimization suggestions
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'How to improve match:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...suggestions.map(
                    (sug) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sug,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  static void _generateCoverLetter(int jobId) async {
    final jobsController = Get.find<JobsController>();
    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getPrimary(Get.isDarkMode),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await jobsController.generateCoverLetter(jobId);
    Get.back(); // close loading dialog

    if (res == null) {
      Get.snackbar(
        'Error',
        'Failed to generate cover letter. Try again later.',
      );
      return;
    }

    String letter = res['cover_letter']?.toString().trim() ?? '';
    if (letter.isEmpty) {
      letter =
          'Unable to generate cover letter. Please verify that the OPENAI_API_KEY is configured in your server\'s .env file and that the AI service is online.';
    }
    final title = res['job_title']?.toString() ?? 'Job';
    final company = res['company']?.toString() ?? 'Company';

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? AppColors.getCard(Get.isDarkMode)
            : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Cover Letter Draft',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tailored for $title at $company',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 320,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? AppColors.getBackground(Get.isDarkMode)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Get.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: letter));
              Get.snackbar(
                'Success',
                'Cover letter copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.getPrimary(Get.isDarkMode),
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text(
              'Copy Text',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(Get.isDarkMode),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }
}
