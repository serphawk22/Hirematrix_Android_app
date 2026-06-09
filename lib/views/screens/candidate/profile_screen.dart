import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/profile_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          'Error',
          'Could not open file URL: $urlString',
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;

      if (controller.isLoading.value && controller.user.isEmpty) {
        return Scaffold(
          backgroundColor: isDark
              ? AppColors.getBackground(isDark)
              : AppColors.getBackground(isDark),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final user = controller.user;
      final stats = controller.stats;
      final completion = controller.completion;

      final profilePhotoPath = user['profile_photo'] ?? '';
      final profilePhotoUrl = profilePhotoPath.isNotEmpty
          ? (profilePhotoPath.startsWith('http')
                ? profilePhotoPath
                : '${ApiConstants.baseUrl.replaceAll('/api', '')}/$profilePhotoPath')
          : '';

      final resumePath = user['resume_path'] ?? '';
      final resumeUrl = resumePath.isNotEmpty
          ? (resumePath.startsWith('http')
                ? resumePath
                : '${ApiConstants.baseUrl.replaceAll('/api', '')}/$resumePath')
          : '';

      final videoPath = user['intro_video_path'] ?? '';
      final videoUrl = videoPath.isNotEmpty
          ? (videoPath.startsWith('http')
                ? videoPath
                : '${ApiConstants.baseUrl.replaceAll('/api', '')}/$videoPath')
          : '';

      return Scaffold(
        backgroundColor: isDark
            ? AppColors.getBackground(isDark)
            : AppColors.getBackground(isDark),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.getCard(isDark) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: AppColors.getPrimary(isDark),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CANDIDATE PROFILE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'My Profile',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your personal details, career information, resume, and preferences.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                // Profile Completion Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.show_chart,
                            color: AppColors.getPrimary(isDark),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profile health',
                            style: GoogleFonts.inter(
                              color: AppColors.getPrimary(isDark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Keep your profile ready for matching jobs',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your profile to improve matching accuracy and recruiter visibility.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (completion['percentage'] ?? 0) / 100,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getPrimary(isDark),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${completion['percentage'] ?? 0}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoActionSheet(context, controller, isDark, profilePhotoUrl.isNotEmpty),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              backgroundImage: profilePhotoUrl.isNotEmpty
                                  ? NetworkImage(profilePhotoUrl)
                                  : null,
                              child: profilePhotoUrl.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimary(isDark),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user['name'] ?? 'Candidate',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Job Seeker',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '${stats['applications'] ?? 0}',
                            'Applications',
                            isDark,
                          ),
                          _buildStatItem(
                            '${stats['interviews'] ?? 0}',
                            'Interviews',
                            isDark,
                          ),
                          _buildStatItem(
                            '${stats['offers'] ?? 0}',
                            'Offers',
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Info Card
                _buildSectionCard(
                  'Personal Information',
                  Icons.person_outline,
                  isDark,
                  onEdit: () =>
                      _showPersonalEditDialog(context, controller, isDark),
                  children: [
                    _buildInfoRow(
                      'Full Name',
                      user['name'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Email',
                      user['email'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Phone',
                      user['phone'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Location',
                      user['location'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Gender',
                      user['gender'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Date of Birth',
                      user['date_of_birth'] ?? 'Not provided',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Career Details Card
                _buildSectionCard(
                  'Career Details',
                  Icons.work_outline,
                  isDark,
                  onEdit: () =>
                      _showCareerEditDialog(context, controller, isDark),
                  children: [
                    _buildInfoRow(
                      'Resume Headline',
                      user['resume_headline'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Candidate Type',
                      ((user['is_fresher_candidate'] ?? '0') == '1' ||
                              (user['is_fresher_candidate'] ?? 0) == 1)
                          ? 'Fresher'
                          : 'Experienced',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Notice Period',
                      user['notice_period'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Current Salary (LPA)',
                      user['current_salary'] != null
                          ? '${user['current_salary']}'
                          : 'Not provided',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preferences Card
                _buildSectionCard(
                  'Preferences',
                  Icons.settings_outlined,
                  isDark,
                  onEdit: () =>
                      _showPreferencesEditDialog(context, controller, isDark),
                  children: [
                    _buildInfoRow(
                      'Preferred Job Titles',
                      user['preferred_job_titles'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Preferred Locations',
                      user['preferred_locations'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Preferred Employment Type',
                      user['preferred_employment_type'] ?? 'Not provided',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Expected Salary (LPA)',
                      user['expected_salary'] != null
                          ? '${user['expected_salary']}'
                          : 'Not provided',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Resume Card
                _buildSectionCard(
                  'Resume',
                  Icons.description_outlined,
                  isDark,
                  children: [
                    if (resumeUrl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50]!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['resume_path']
                                        .toString()
                                        .split('/')
                                        .last,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PDF/Word Document',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchURL(resumeUrl),
                              icon: Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: const Text('Preview'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchURL(resumeUrl),
                              icon: Icon(
                                Icons.download_outlined,
                                size: 18,
                              ),
                              label: const Text('Download'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        'No resume uploaded yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => controller.uploadFile(
                        'upload_resume',
                        'resume',
                        ['pdf', 'doc', 'docx'],
                      ),
                      icon: Icon(Icons.upload_file),
                      label: Text(
                        resumeUrl.isNotEmpty
                            ? 'Update Resume'
                            : 'Upload Resume',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Video Card
                _buildSectionCard(
                  'Video Introduction',
                  Icons.videocam_outlined,
                  isDark,
                  children: [
                    if (videoUrl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50]!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.video_library,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['intro_video_path']
                                        .toString()
                                        .split('/')
                                        .last,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'MP4/MOV/WebM Video',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchURL(videoUrl),
                              icon: Icon(
                                Icons.play_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Preview'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchURL(videoUrl),
                              icon: Icon(
                                Icons.download_outlined,
                                size: 18,
                              ),
                              label: const Text('Download'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        'No video uploaded yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => controller.uploadFile(
                        'upload_video',
                        'intro_video',
                        ['mp4', 'mov', 'webm'],
                      ),
                      icon: Icon(Icons.video_call),
                      label: Text(
                        videoUrl.isNotEmpty ? 'Update Video' : 'Upload Video',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // GitHub Card
                _buildSectionCard(
                  'GitHub Analysis',
                  Icons.code,
                  isDark,
                  onEdit: () => _showGithubDialog(context, controller, isDark),
                  children: [
                    _buildInfoRow(
                      'Username',
                      controller.github['github_username'] ?? 'Not connected',
                      isDark,
                    ),
                    if (controller.github['github_username'] != null) ...[
                      _buildInfoRow(
                        'Repositories',
                        '${controller.github['repo_count'] ?? 0}',
                        isDark,
                      ),
                      _buildInfoRow(
                        'Total Commits',
                        '${controller.github['commit_count'] ?? 0}',
                        isDark,
                      ),
                      _buildInfoRow(
                        'Languages',
                        controller.github['languages_used'] ?? 'None',
                        isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Skills Card
                _buildSectionCard(
                  'Skills',
                  Icons.star_outline,
                  isDark,
                  onEdit: () => _showSkillsDialog(context, controller, isDark),
                  children: [
                    if (controller.skills['skill_name'] != null &&
                        controller.skills['skill_name'].toString().isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.skills['skill_name']
                            .toString()
                            .split(',')
                            .map(
                              (s) => Chip(
                                label: Text(s.trim()),
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    else
                      Text(
                        'No skills added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Interests Card
                _buildSectionCard(
                  'Interests',
                  Icons.favorite_outline,
                  isDark,
                  onEdit: () =>
                      _showInterestsDialog(context, controller, isDark),
                  children: [
                    if (controller.interests.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.interests
                            .map(
                              (s) => Chip(
                                label: Text(s.toString().trim()),
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    else
                      Text(
                        'No interests added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Experience Card
                _buildSectionCard(
                  'Work Experience',
                  Icons.business_center_outlined,
                  isDark,
                  onAdd: () =>
                      _showExperienceDialog(context, controller, isDark, null),
                  children: [
                    if (controller.workExperiences.isNotEmpty)
                      ...controller.workExperiences
                          .map(
                            (exp) => _buildExperienceItem(
                              exp,
                              isDark,
                              controller,
                              context,
                            ),
                          )
                          .toList()
                    else
                      Text(
                        'No work experience added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Projects Card
                _buildSectionCard(
                  'Projects',
                  Icons.folder_open_outlined,
                  isDark,
                  onAdd: () =>
                      _showProjectDialog(context, controller, isDark, null),
                  children: [
                    if (controller.projects.isNotEmpty)
                      ...controller.projects
                          .map(
                            (proj) => _buildProjectItem(
                              proj,
                              isDark,
                              controller,
                              context,
                            ),
                          )
                          .toList()
                    else
                      Text(
                        'No projects added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Education Card
                _buildSectionCard(
                  'Education',
                  Icons.school_outlined,
                  isDark,
                  onAdd: () =>
                      _showEducationDialog(context, controller, isDark, null),
                  children: [
                    if (controller.educations.isNotEmpty)
                      ...controller.educations
                          .map(
                            (edu) => _buildEducationItem(
                              edu,
                              isDark,
                              controller,
                              context,
                            ),
                          )
                          .toList()
                    else
                      Text(
                        'No education added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Certifications Card
                _buildSectionCard(
                  'Certifications',
                  Icons.workspace_premium_outlined,
                  isDark,
                  onAdd: () => _showCertificationDialog(
                    context,
                    controller,
                    isDark,
                    null,
                  ),
                  children: [
                    if (controller.certifications.isNotEmpty)
                      ...controller.certifications
                          .map(
                            (cert) => _buildCertificationItem(
                              cert,
                              isDark,
                              controller,
                              context,
                            ),
                          )
                          .toList()
                    else
                      Text(
                        'No certifications added yet.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ),
        ],
        ),
        if (controller.isLoading.value)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(isDark)),
              ),
            ),
          ),
      ],
    ),
  ),
);
});
}

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    bool isDark, {
    required List<Widget> children,
    VoidCallback? onEdit,
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onAdd != null)
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.getPrimary(isDark),
                      ),
                      onPressed: onAdd,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.getPrimary(isDark),
                      ),
                      onPressed: onEdit,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.getPrimary(isDark), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.getPrimary(isDark), width: 1.5),
      ),
    );
  }

  Widget _buildExperienceItem(
    dynamic exp,
    bool isDark,
    ProfileController controller,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  color: AppColors.getPrimary(isDark),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp['job_title'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exp['company_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${exp['start_date']} - ${exp['is_current'] == 1 ? 'Present' : exp['end_date']}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: Colors.blue[400]),
                    onPressed: () =>
                        _showExperienceDialog(context, controller, isDark, exp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                    onPressed: () => controller.deleteItem(
                      'delete_experience',
                      int.parse(exp['id'].toString()),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          if (exp['description'] != null && exp['description'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                exp['description'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(
    dynamic proj,
    bool isDark,
    ProfileController controller,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proj['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    if (proj['project_url'] != null && proj['project_url'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _launchURL(proj['project_url']),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                proj['project_url'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: Colors.blue[400]),
                    onPressed: () =>
                        _showProjectDialog(context, controller, isDark, proj),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                    onPressed: () => controller.deleteItem(
                      'delete_project',
                      int.parse(proj['id'].toString()),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          if (proj['description'] != null && proj['description'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                proj['description'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(
    dynamic edu,
    bool isDark,
    ProfileController controller,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${edu['degree']} in ${edu['field_of_study']}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      edu['institution'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${edu['start_year'] ?? 'N/A'} - ${edu['end_year'] ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (edu['grade'] != null && edu['grade'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'GPA: ${edu['grade']}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: Colors.blue[400]),
                    onPressed: () =>
                        _showEducationDialog(context, controller, isDark, edu),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                    onPressed: () => controller.deleteItem(
                      'delete_education',
                      int.parse(edu['id'].toString()),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationItem(
    dynamic cert,
    bool isDark,
    ProfileController controller,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cert['issuing_organization'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Issued: ${cert['issue_date'] ?? 'N/A'}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: Colors.blue[400]),
                    onPressed: () => _showCertificationDialog(
                      context,
                      controller,
                      isDark,
                      cert,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                    onPressed: () => controller.deleteItem(
                      'delete_certification',
                      int.parse(cert['id'].toString()),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Edit Dialog Implementations
  void _showFormDialog(
    BuildContext context,
    String title,
    bool isDark,
    List<Widget> Function(StateSetter) buildFields,
    VoidCallback onSave,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...buildFields(setState),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onSave();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _showPersonalEditDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final nameCtrl = TextEditingController(
      text: controller.user['name']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(
      text: controller.user['email']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: controller.user['phone']?.toString() ?? '',
    );
    final locationCtrl = TextEditingController(
      text: controller.user['location']?.toString() ?? '',
    );
    final bioCtrl = TextEditingController(
      text: controller.user['bio']?.toString() ?? '',
    );
    final dobCtrl = TextEditingController(
      text: controller.user['date_of_birth']?.toString() ?? '',
    );

    String? gender = controller.user['gender']?.toString();
    if (!['Male', 'Female', 'Other', 'Prefer not to say'].contains(gender)) {
      gender = null;
    }

    _showFormDialog(
      context,
      'Edit Personal Info',
      isDark,
      (setState) => [
        TextField(
          controller: nameCtrl,
          decoration: _inputDecoration('Full Name', Icons.person_outline, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailCtrl,
          decoration: _inputDecoration('Email Address', Icons.email_outlined, isDark),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneCtrl,
          decoration: _inputDecoration('Phone', Icons.phone_outlined, isDark),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: locationCtrl,
          decoration: _inputDecoration('Location', Icons.location_on_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bioCtrl,
          decoration: _inputDecoration('Bio', Icons.info_outline, isDark),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: gender,
          decoration: _inputDecoration('Gender', Icons.wc_outlined, isDark),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((
            String val,
          ) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (val) => setState(() => gender = val),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: dobCtrl,
          decoration: _inputDecoration('Date of Birth (YYYY-MM-DD)', Icons.calendar_today_outlined, isDark),
          readOnly: true,
          onTap: () => _selectDate(context, dobCtrl),
        ),
      ],
      () {
        controller.updateSection('update_personal', {
          'name': nameCtrl.text,
          'email': emailCtrl.text,
          'phone': phoneCtrl.text,
          'location': locationCtrl.text,
          'bio': bioCtrl.text,
          'gender': gender ?? '',
          'date_of_birth': dobCtrl.text,
        });
      },
    );
  }

  void _showCareerEditDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final headlineCtrl = TextEditingController(
      text: controller.user['resume_headline']?.toString() ?? '',
    );
    final salaryCtrl = TextEditingController(
      text: controller.user['current_salary']?.toString() ?? '',
    );

    String? noticePeriod = controller.user['notice_period']?.toString();
    if (![
      'Immediate',
      '1 Month',
      '2 Months',
      '3 Months',
      'More than 3 Months',
    ].contains(noticePeriod)) {
      noticePeriod = null;
    }

    bool isFresher = ((controller.user['is_fresher_candidate'] ?? 0) == 1);

    _showFormDialog(
      context,
      'Edit Career Details',
      isDark,
      (setState) => [
        TextField(
          controller: headlineCtrl,
          decoration: _inputDecoration('Resume Headline', Icons.badge_outlined, isDark),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'I am a Fresher',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(
              'Check if you have no prior work experience',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            value: isFresher,
            onChanged: (val) => setState(() => isFresher = val),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: noticePeriod,
          decoration: _inputDecoration('Notice Period', Icons.timer_outlined, isDark),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items:
              [
                'Immediate',
                '1 Month',
                '2 Months',
                '3 Months',
                'More than 3 Months',
              ].map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
          onChanged: (val) => setState(() => noticePeriod = val),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: salaryCtrl,
          decoration: _inputDecoration('Current Salary (LPA)', Icons.payments_outlined, isDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
      () {
        controller.updateSection('update_career', {
          'resume_headline': headlineCtrl.text,
          'current_salary': double.tryParse(salaryCtrl.text),
          'notice_period': noticePeriod ?? '',
          'is_fresher_candidate': isFresher ? 1 : 0,
        });
      },
    );
  }

  void _showPreferencesEditDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final titlesCtrl = TextEditingController(
      text: controller.user['preferred_job_titles']?.toString() ?? '',
    );
    final locationsCtrl = TextEditingController(
      text: controller.user['preferred_locations']?.toString() ?? '',
    );
    final salaryCtrl = TextEditingController(
      text: controller.user['expected_salary']?.toString() ?? '',
    );

    String? empType = controller.user['preferred_employment_type']?.toString();
    if (![
      'Full-time',
      'Part-time',
      'Contract',
      'Internship',
      'Freelance',
    ].contains(empType)) {
      empType = null;
    }

    _showFormDialog(
      context,
      'Edit Preferences',
      isDark,
      (setState) => [
        TextField(
          controller: titlesCtrl,
          decoration: _inputDecoration('Preferred Job Titles', Icons.work_outline, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: locationsCtrl,
          decoration: _inputDecoration('Preferred Locations', Icons.location_on_outlined, isDark),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: empType,
          decoration: _inputDecoration('Preferred Employment Type', Icons.work_history_outlined, isDark),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items:
              [
                'Full-time',
                'Part-time',
                'Contract',
                'Internship',
                'Freelance',
              ].map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
          onChanged: (val) => setState(() => empType = val),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: salaryCtrl,
          decoration: _inputDecoration('Expected Salary (LPA)', Icons.payments_outlined, isDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
      () {
        controller.updateSection('update_preferences', {
          'preferred_job_titles': titlesCtrl.text,
          'preferred_locations': locationsCtrl.text,
          'preferred_employment_type': empType ?? '',
          'expected_salary': double.tryParse(salaryCtrl.text),
        });
      },
    );
  }

  void _showGithubDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final usernameCtrl = TextEditingController(
      text: controller.github['github_username']?.toString() ?? '',
    );
    _showFormDialog(
      context,
      'Connect GitHub',
      isDark,
      (setState) => [
        TextField(
          controller: usernameCtrl,
          decoration: _inputDecoration('GitHub Username', Icons.code_rounded, isDark),
        ),
      ],
      () {
        controller.updateSection('analyze_github', {
          'github_username': usernameCtrl.text,
        });
      },
    );
  }

  void _showSkillsDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final skillsCtrl = TextEditingController();
    _showFormDialog(
      context,
      'Add Skill',
      isDark,
      (setState) => [
        TextField(
          controller: skillsCtrl,
          decoration: _inputDecoration('Skill Name', Icons.star_border_rounded, isDark),
        ),
      ],
      () {
        controller.updateSection('add_skill', {'skill_name': skillsCtrl.text});
      },
    );
  }

  void _showInterestsDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
  ) {
    final interestsCtrl = TextEditingController(
      text: controller.interests.join(', '),
    );
    _showFormDialog(
      context,
      'Update Interests',
      isDark,
      (setState) => [
        TextField(
          controller: interestsCtrl,
          decoration: _inputDecoration('Interests (comma separated)', Icons.favorite_border_rounded, isDark),
        ),
      ],
      () {
        controller.updateSection('update_interests', {
          'interests': interestsCtrl.text,
        });
      },
    );
  }

  void _showExperienceDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
    dynamic exp,
  ) {
    final titleCtrl = TextEditingController(
      text: exp?['job_title']?.toString() ?? '',
    );
    final companyCtrl = TextEditingController(
      text: exp?['company_name']?.toString() ?? '',
    );
    final startCtrl = TextEditingController(
      text: exp?['start_date']?.toString() ?? '',
    );
    final endCtrl = TextEditingController(
      text: exp?['end_date']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: exp?['description']?.toString() ?? '',
    );

    bool isCurrent = ((exp?['is_current'] ?? 0) == 1);

    _showFormDialog(
      context,
      exp == null ? 'Add Experience' : 'Edit Experience',
      isDark,
      (setState) => [
        TextField(
          controller: titleCtrl,
          decoration: _inputDecoration('Job Title', Icons.badge_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: companyCtrl,
          decoration: _inputDecoration('Company', Icons.business_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: startCtrl,
          decoration: _inputDecoration('Start Date', Icons.calendar_today_outlined, isDark),
          readOnly: true,
          onTap: () => _selectDate(context, startCtrl),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'I currently work here',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            value: isCurrent,
            onChanged: (val) => setState(() => isCurrent = val),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
        if (!isCurrent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: endCtrl,
            decoration: _inputDecoration('End Date', Icons.calendar_today_outlined, isDark),
            readOnly: true,
            onTap: () => _selectDate(context, endCtrl),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: descCtrl,
          decoration: _inputDecoration('Description', Icons.description_outlined, isDark),
          maxLines: 3,
        ),
      ],
      () {
        final Map<String, dynamic> data = {
          'job_title': titleCtrl.text,
          'company_name': companyCtrl.text,
          'start_date': startCtrl.text,
          'end_date': isCurrent ? null : endCtrl.text,
          'is_current': isCurrent ? 1 : 0,
          'description': descCtrl.text,
        };
        if (exp != null) data['id'] = exp['id'];
        controller.updateSection('save_experience', data);
      },
    );
  }

  void _showProjectDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
    dynamic proj,
  ) {
    final titleCtrl = TextEditingController(
      text: proj?['title']?.toString() ?? '',
    );
    final urlCtrl = TextEditingController(
      text: proj?['project_url']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: proj?['description']?.toString() ?? '',
    );

    _showFormDialog(
      context,
      proj == null ? 'Add Project' : 'Edit Project',
      isDark,
      (setState) => [
        TextField(
          controller: titleCtrl,
          decoration: _inputDecoration('Project Title', Icons.folder_open_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: urlCtrl,
          decoration: _inputDecoration('Project URL', Icons.link_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descCtrl,
          decoration: _inputDecoration('Description', Icons.description_outlined, isDark),
          maxLines: 3,
        ),
      ],
      () {
        final Map<String, dynamic> data = {
          'title': titleCtrl.text,
          'project_url': urlCtrl.text,
          'description': descCtrl.text,
        };
        if (proj != null) data['id'] = proj['id'];
        controller.updateSection('save_project', data);
      },
    );
  }

  void _showEducationDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
    dynamic edu,
  ) {
    final degreeCtrl = TextEditingController(
      text: edu?['degree']?.toString() ?? '',
    );
    final fieldCtrl = TextEditingController(
      text: edu?['field_of_study']?.toString() ?? '',
    );
    final instCtrl = TextEditingController(
      text: edu?['institution']?.toString() ?? '',
    );
    final startYearCtrl = TextEditingController(
      text: edu?['start_year']?.toString() ?? '',
    );
    final endYearCtrl = TextEditingController(
      text: edu?['end_year']?.toString() ?? '',
    );
    final gradeCtrl = TextEditingController(
      text: edu?['grade']?.toString() ?? '',
    );

    _showFormDialog(
      context,
      edu == null ? 'Add Education' : 'Edit Education',
      isDark,
      (setState) => [
        TextField(
          controller: degreeCtrl,
          decoration: _inputDecoration('Degree (e.g., Bachelor\'s)', Icons.school_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: fieldCtrl,
          decoration: _inputDecoration('Field of Study', Icons.science_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: instCtrl,
          decoration: _inputDecoration('Institution Name', Icons.apartment_outlined, isDark),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startYearCtrl,
                decoration: _inputDecoration('Start Year', Icons.calendar_today_outlined, isDark),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: endYearCtrl,
                decoration: _inputDecoration('End Year', Icons.calendar_today_outlined, isDark),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: gradeCtrl,
          decoration: _inputDecoration('Grade / CGPA', Icons.grade_outlined, isDark),
        ),
      ],
      () {
        final Map<String, dynamic> data = {
          'degree': degreeCtrl.text,
          'field_of_study': fieldCtrl.text,
          'institution': instCtrl.text,
          'start_year': startYearCtrl.text,
          'end_year': endYearCtrl.text,
          'grade': gradeCtrl.text,
        };
        if (edu != null) data['id'] = edu['id'];
        controller.updateSection('save_education', data);
      },
    );
  }

  void _showCertificationDialog(
    BuildContext context,
    ProfileController controller,
    bool isDark,
    dynamic cert,
  ) {
    final nameCtrl = TextEditingController(
      text: cert?['name']?.toString() ?? '',
    );
    final orgCtrl = TextEditingController(
      text: cert?['issuing_organization']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text: cert?['issue_date']?.toString() ?? '',
    );

    _showFormDialog(
      context,
      cert == null ? 'Add Certification' : 'Edit Certification',
      isDark,
      (setState) => [
        TextField(
          controller: nameCtrl,
          decoration: _inputDecoration('Certification Name', Icons.workspace_premium_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: orgCtrl,
          decoration: _inputDecoration('Issuing Organization', Icons.verified_outlined, isDark),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: dateCtrl,
          decoration: _inputDecoration('Issue Date', Icons.calendar_today_outlined, isDark),
          readOnly: true,
          onTap: () => _selectDate(context, dateCtrl),
        ),
      ],
      () {
        final Map<String, dynamic> data = {
          'name': nameCtrl.text,
          'issuing_organization': orgCtrl.text,
          'issue_date': dateCtrl.text,
        };
        if (cert != null) data['id'] = cert['id'];
        controller.updateSection('save_certification', data);
      },
    );
  }

  void _showPhotoActionSheet(BuildContext context, ProfileController controller, bool isDark, bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.getPrimary(isDark)),
                title: Text(
                  hasPhoto ? 'Change Profile Photo' : 'Upload Profile Photo',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  controller.uploadFile(
                    'upload_photo',
                    'profile_photo',
                    ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                  );
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    'Remove Profile Photo',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePhoto(context, controller, isDark);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePhoto(BuildContext context, ProfileController controller, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        title: Text(
          'Remove Photo',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove your profile photo?',
          style: GoogleFonts.inter(
            color: isDark ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deletePhoto();
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
