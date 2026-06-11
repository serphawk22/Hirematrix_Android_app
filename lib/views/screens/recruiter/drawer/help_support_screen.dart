import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'knowledge_base_screen.dart';
import 'support_chat_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> _allFaqs = [
    {
      'q': 'How to post a private job?',
      'a': 'To post a private job, toggle the "Public Visibility" switch to off during the job creation process. Private jobs are only accessible via a direct link you share with candidates.'
    },
    {
      'q': 'Changing company settings?',
      'a': 'Go to the "Company Profile" from the sidebar. You can update your company logo, description, website, and location details there.'
    },
    {
      'q': 'Exporting applicant data?',
      'a': 'In the "Candidate Database" or "Recruitment Pipeline", look for the export icon at the top right. You can export filtered candidate lists to CSV or Excel formats.'
    },
    {
      'q': 'How to manage interview slots?',
      'a': 'Navigate to "Interviews" > "Interview Slots" from the sidebar. Here you can add new availability blocks and view existing ones.'
    },
    {
      'q': 'Can I add team members?',
      'a': 'Yes, use the "Team Management" section in the sidebar to invite other recruiters to your company workspace.'
    },
  ];

  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _allFaqs;
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _allFaqs;
      } else {
        _filteredFaqs = _allFaqs.where((faq) {
          return faq['q']!.toLowerCase().contains(query) || 
                 faq['a']!.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _launchEmail() async {
    final subject = Uri.encodeComponent('Support Request - Recruiter App');
    final uriString = 'mailto:support@hirematrix.com?subject=$subject';
    final Uri emailLaunchUri = Uri.parse(uriString);

    try {
      final launched = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(emailLaunchUri);
        if (!fallbackLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(isDark),
            const SizedBox(height: 24),
            _buildActionTile(
              icon: Icons.chat_bubble_outline_rounded, 
              title: 'Live Chat', 
              val: 'Start conversation', 
              color: Colors.blue, 
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportChatScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.email_outlined, 
              title: 'Email Support', 
              val: 'support@hirematrix.com', 
              color: Colors.green, 
              isDark: isDark,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.help_outline_rounded, 
              title: 'Knowledge Base', 
              val: 'Documentation', 
              color: Colors.orange, 
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen()),
              ),
            ),
            const SizedBox(height: 32),
            Text('Frequently Asked Questions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No matching results found.', style: GoogleFonts.inter(color: Colors.grey)),
                ),
              )
            else
              ..._filteredFaqs.map((faq) => _FAQAccordionItem(faq: faq, isDark: isDark)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon, 
    required String title, 
    required String val, 
    required Color color, 
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(val, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _FAQAccordionItem extends StatefulWidget {
  final Map<String, String> faq;
  final bool isDark;

  const _FAQAccordionItem({required this.faq, required this.isDark});

  @override
  State<_FAQAccordionItem> createState() => _FAQAccordionItemState();
}

class _FAQAccordionItemState extends State<_FAQAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.getCard(widget.isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.faq['q']!, 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.125 : 0, // Rotates "+" to "x" slightly, or just use icons
                    child: Icon(
                      _isExpanded ? Icons.remove_rounded : Icons.add_rounded, 
                      size: 20, 
                      color: _isExpanded ? AppColors.getPrimary(widget.isDark) : Colors.grey
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.faq['a']!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.5),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
