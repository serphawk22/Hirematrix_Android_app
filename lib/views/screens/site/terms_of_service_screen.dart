import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7083);
      final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/hirematrix_logo.png', width: 24, height: 24, errorBuilder: (context, error, stackTrace) => Icon(Icons.bolt, color: AppColors.getPrimary(isDark))),
              const SizedBox(width: 8),
              Text('HireMatrix', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textColor, fontSize: 18)),
            ],
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.scaleBalanced, size: 14, color: AppColors.getPrimary(isDark)),
                    const SizedBox(width: 8),
                    Text('Legal', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Terms of Service',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'The rules, responsibilities, and acceptable use standards for candidates, recruiters, and employers using HireMatrix.',
                style: GoogleFonts.inter(fontSize: 16, color: subtitleColor, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Effective Date: June 16, 2026',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 48),

              // Sections
              _buildSection('1. Acceptance of Terms', [
                'By accessing or using HireMatrix, you agree to be bound by these Terms of Service and any policies incorporated by reference. If you do not agree, you should not use the portal.',
              ], textColor, subtitleColor),
              _buildSection('2. Eligibility and Accounts', [
                'You are responsible for ensuring that the information you submit is accurate, current, and complete. You are also responsible for maintaining the confidentiality of your account credentials and for activity carried out through your account.',
              ], textColor, subtitleColor),
              _buildSection('3. Candidate Use of the Portal', [
                'Candidates may use the platform to create profiles, upload resumes, receive job suggestions, apply to roles, and participate in assessments or interviews where enabled.',
                'Candidates must provide truthful professional information and must not impersonate another person, misrepresent qualifications, or attempt to manipulate rankings, assessments, or interview outcomes.',
              ], textColor, subtitleColor),
              _buildSection('4. Recruiter and Employer Use', [
                'Recruiters and employers are responsible for posting lawful job opportunities, handling candidate data appropriately, and using the platform in a fair, professional, and non-discriminatory manner.',
                'Job listings, outreach, and hiring actions must comply with applicable employment laws, privacy obligations, and internal company policies.',
              ], textColor, subtitleColor),
              _buildSection('5. Acceptable Use', [
                'You may not use HireMatrix to upload unlawful, infringing, abusive, misleading, fraudulent, defamatory, or malicious content, or to interfere with platform security, availability, or normal operation.',
                'You may not attempt unauthorized access, data extraction beyond permitted use, automated abuse, reverse engineering where prohibited, or any activity that harms users, companies, or the platform.',
              ], textColor, subtitleColor),
              _buildSection('6. AI-Assisted Features', [
                'HireMatrix may provide AI-assisted functionality such as resume analysis, job matching, interview generation, or candidate screening support. These features are intended to assist workflows and should not be treated as guaranteed outcomes, legal advice, or professional certification.',
              ], textColor, subtitleColor),
              _buildSection('7. External Jobs and Third-Party Content', [
                'The portal may display external job listings, third-party links, or integrated services. HireMatrix does not guarantee the accuracy, availability, legitimacy, or continued existence of third-party opportunities or external content.',
              ], textColor, subtitleColor),
              _buildSection('8. Intellectual Property', [
                'The platform, including its software, branding, interface, and related materials, remains the property of HireMatrix or its licensors. Users retain ownership of content they submit, but grant the platform the rights reasonably necessary to host, process, display, and operate that content within the service.',
              ], textColor, subtitleColor),
              _buildSection('9. Suspension and Termination', [
                'We may suspend, restrict, or terminate access where necessary to protect the platform, enforce these terms, respond to abuse, investigate suspicious activity, or comply with legal obligations.',
              ], textColor, subtitleColor),
              _buildSection('10. Disclaimers', [
                'HireMatrix is provided on an as-available basis. To the maximum extent permitted by law, we do not guarantee uninterrupted access, error-free operation, hiring success, candidate placement, recruiter response rates, or specific business outcomes.',
              ], textColor, subtitleColor),
              _buildSection('11. Limitation of Liability', [
                'To the extent permitted by law, HireMatrix and its operators will not be liable for indirect, incidental, special, consequential, or punitive damages arising out of or related to the use of the portal, third-party content, hiring decisions, or service interruptions.',
              ], textColor, subtitleColor),
              _buildSection('12. Changes to These Terms', [
                'We may revise these Terms of Service from time to time. Updated terms become effective when posted unless a later effective date is stated. Continued use of the portal after updates means the revised terms apply.',
              ], textColor, subtitleColor),
              _buildSection('13. Contact', [
                'Questions about these Terms of Service can be directed to the HireMatrix team through the support or contact channel published on the portal.',
              ], textColor, subtitleColor),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSection(String title, List<String> paragraphs, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          ...paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(p, style: GoogleFonts.inter(fontSize: 14.5, color: subtitleColor, height: 1.6)),
              )),
        ],
      ),
    );
  }
}
