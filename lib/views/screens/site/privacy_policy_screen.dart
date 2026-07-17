import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                'Privacy Policy',
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'How HireMatrix collects, uses, stores, and protects personal information across the job portal.',
                style: GoogleFonts.inter(fontSize: 16, color: subtitleColor, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Effective Date: June 16, 2026',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 48),

              // Sections
              _buildSection('1. Information We Collect', [
                'We may collect information you provide directly, including your name, email address, phone number, resume details, work history, education, skills, profile photo, company information, and communication preferences.',
                'We may also collect platform usage data such as login activity, device and browser information, IP address, pages visited, actions taken within the portal, and technical logs needed for security, analytics, and service improvement.',
              ], textColor, subtitleColor),
              _buildSection('2. How We Use Your Information', [
                'We use personal information to create and manage accounts, support recruitment workflows, enable job applications, match candidates with opportunities, facilitate recruiter communication, process AI-assisted features, maintain platform security, and improve portal performance.',
                'We may also use information to send service-related notifications, verification messages, interview updates, password resets, billing or subscription messages, and other operational communications.',
              ], textColor, subtitleColor),
              _buildSection('3. How Information Is Shared', [
                'Candidate information may be shared with recruiters, employers, or authorized company users when a candidate applies for a role, is shortlisted, joins a hiring workflow, or otherwise chooses to engage with an opportunity on the platform.',
                'We may share limited information with service providers who support hosting, analytics, communication delivery, interview tooling, payment processing, or system operations, subject to appropriate confidentiality and security controls.',
                'We may also disclose information when required by law, to protect legal rights, to enforce portal policies, or to investigate fraud, abuse, or security incidents.',
              ], textColor, subtitleColor),
              _buildSection('4. Cookies and Similar Technologies', [
                'HireMatrix may use cookies, local storage, session tools, and similar technologies to keep users signed in, remember preferences, improve performance, measure engagement, and support essential portal functionality.',
              ], textColor, subtitleColor),
              _buildSection('5. Data Collection', [
                'We retain information for as long as reasonably necessary to operate the job portal, maintain hiring records, comply with legal obligations, resolve disputes, enforce agreements, and support legitimate business needs.',
              ], textColor, subtitleColor),
              _buildSection('6. Security', [
                'We apply reasonable administrative, technical, and organizational measures designed to protect personal information. However, no online platform or storage system can be guaranteed to be completely secure.',
              ], textColor, subtitleColor),
              _buildSection('7. Your Choices and Rights', [
                'Depending on applicable law, users may have rights to access, correct, update, delete, or restrict certain personal information. Users may also update profile details and account preferences within the portal where those features are available.',
              ], textColor, subtitleColor),
              _buildSection('8. Third-Party Services and Links', [
                'The portal may link to third-party websites, external job feeds, or integrated services. We are not responsible for the privacy practices or content of third-party properties that are not controlled by HireMatrix.',
              ], textColor, subtitleColor),
              _buildSection('9. Children’s Privacy', [
                'HireMatrix is intended for professional and career-related use and is not directed to children. Users should only use the platform if they are legally permitted to do so under applicable law.',
              ], textColor, subtitleColor),
              _buildSection('10. Policy Updates', [
                'We may update this Privacy Policy from time to time to reflect operational, legal, or product changes. Continued use of the portal after an update takes effect means the revised policy will apply going forward.',
              ], textColor, subtitleColor),
              _buildSection('11. Contact', [
                'Questions about this Privacy Policy can be directed to the HireMatrix team through the support or contact channel published on the portal.',
              ], textColor, subtitleColor),
              _buildSection('12. Google Ads', [
                'This website uses Google AdSense, a web advertising service provided by Google LLC. Google AdSense uses cookies to serve ads based on your prior visits to this website or other websites. You may opt out of personalized advertising by visiting Google\'s Ads Settings.',
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
