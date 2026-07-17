import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7083);

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: AppColors.getPrimary(isDark)),
                    const SizedBox(width: 8),
                    Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Built to make hiring clearer, faster, and more human.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, height: 1.2),
              ),
              const SizedBox(height: 16),
              Text(
                'HireMatrix is a job portal designed to support both sides of the hiring process: candidates who want sharper direction and recruiters who need better signal. We bring together job discovery, structured profiles, AI-assisted screening, and workflow tools in one connected platform.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: subtitleColor, height: 1.5),
              ),
              const SizedBox(height: 48),

              // Story Grid
              _buildSectionTitle('What HireMatrix is for', textColor),
              const SizedBox(height: 12),
              _buildParagraph('Modern hiring often breaks down because information is scattered, screening is inconsistent, and both candidates and recruiters lose time moving between disconnected tools. HireMatrix is built to reduce that friction.', subtitleColor),
              _buildParagraph('For candidates, the platform supports profile building, job applications, resume-led workflows, and assessment experiences that help them present their strengths more clearly. For recruiters, it supports structured job posting, application review, AI interview policy controls, and better visibility into applicant activity.', subtitleColor),
              _buildParagraph('The goal is not just automation. It is a hiring experience that feels more organized, more transparent, and easier to act on.', subtitleColor),
              const SizedBox(height: 32),

              _buildSectionTitle('Who it serves', textColor),
              const SizedBox(height: 12),
              _buildParagraphRich('Candidates:', ' People exploring roles, building stronger profiles, and moving through applications with better guidance.', textColor, subtitleColor),
              _buildParagraphRich('Recruiters:', ' Hiring teams who need cleaner workflows, faster shortlisting, and more confidence in early-stage screening.', textColor, subtitleColor),
              _buildParagraphRich('Employers:', ' Companies that want a practical recruitment platform with room for AI-assisted evaluation without losing human judgment.', textColor, subtitleColor),
              const SizedBox(height: 48),

              // Values Grid
              _buildValueCard(FontAwesomeIcons.compass, 'Clarity first', 'We focus on interfaces and workflows that make the next step obvious for both candidates and recruiters.', isDark, textColor, subtitleColor),
              const SizedBox(height: 16),
              _buildValueCard(FontAwesomeIcons.sitemap, 'Useful structure', 'Profiles, jobs, assessments, and communication are organized so decisions can happen with less back-and-forth.', isDark, textColor, subtitleColor),
              const SizedBox(height: 16),
              _buildValueCard(FontAwesomeIcons.shieldHalved, 'Responsible automation', 'AI features are used to support workflows, not to replace human accountability in hiring decisions.', isDark, textColor, subtitleColor),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildParagraph(String text, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14.5, color: subtitleColor, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildParagraphRich(String boldText, String normalText, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14.5, height: 1.6),
            children: [
              TextSpan(text: boldText, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              TextSpan(text: normalText, style: TextStyle(color: subtitleColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard(dynamic icon, String title, String description, bool isDark, Color textColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: AppColors.getPrimary(isDark), size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(description, style: GoogleFonts.inter(fontSize: 14, color: subtitleColor, height: 1.5)),
        ],
      ),
    );
  }
}
