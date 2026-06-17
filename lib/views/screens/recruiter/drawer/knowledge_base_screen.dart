import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final List<Map<String, String>> _articles = [
    {
      'title': 'How to post a private job',
      'content':
          'Use the job creation flow and switch off Public Visibility. This keeps the job hidden from the public job board and accessible only by direct candidate link.',
    },
    {
      'title': 'Updating company profile',
      'content':
          'Open Company Profile from the drawer, then update your company logo, website, description, and location details. Save changes before leaving the page.',
    },
    {
      'title': 'Exporting applicant data',
      'content':
          'Go to the Candidate Database or Recruitment Pipeline screen and tap the export icon at the top right. You can choose CSV or Excel export formats.',
    },
    {
      'title': 'Managing interview slots',
      'content':
          'Open Interviews > Interview Slots from the drawer. Add or edit availability blocks, then save to make them active for scheduling.',
    },
    {
      'title': 'Adding team members',
      'content':
          'Visit Team Management and invite new recruiters by email. They will receive a workspace invite to join your company account.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Knowledge Base',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Browse support articles and best practices for using HireMatrix recruiter tools.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
          const SizedBox(height: 20),
          ..._articles.map((article) => _buildArticleCard(article, isDark)),
          const SizedBox(height: 24),
          Text(
            'Need more help?',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'If the articles do not answer your question, return to Help & Support and use Live Chat or Email Support to contact our team directly.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, String> article, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article['title']!,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            article['content']!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
