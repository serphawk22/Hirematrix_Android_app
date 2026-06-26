import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/job_details_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/views/screens/candidate/company_profile_screen.dart';
import 'package:hirematrix/views/screens/candidate/resume_studio_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final themeController = Get.find<ThemeController>();
  final authController = Get.find<AuthController>();

  late final JobDetailsController _controller;
  final _formKey = GlobalKey<FormState>();

  late Map<String, dynamic> _job;
  bool _isLoadingJob = false;

  @override
  void initState() {
    super.initState();
    _job = Map<String, dynamic>.from(widget.job);
    _controller = Get.put(JobDetailsController());

    if (_job['title'] == null || _job['title'].toString().isEmpty) {
      _fetchFullJob();
    } else {
      _initControllerData();
    }
  }

  void _initControllerData() {
    _controller.decodeQuestionnaire(_job['application_questionnaire']);
    _controller.checkAppliedStatus(_job['id']);
    _controller.runAtsAnalysisOnLoad(_job['id']);
    _controller.fetchCompanyDetails(_job['company_id']);
    _controller.fetchJobInvitation(_job['id']);
  }

  Future<void> _fetchFullJob() async {
    setState(() => _isLoadingJob = true);
    try {
      final userId = authController.currentUser['id'];
      final url =
          '${ApiConstants.baseUrl}/jobs/detail/${_job['id']}?candidate_id=$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' &&
            data['data'] != null &&
            data['data']['job'] != null) {
          setState(() {
            _job = Map<String, dynamic>.from(data['data']['job']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching job: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingJob = false);
        _initControllerData();
      }
    }
  }

  bool get isCheckingApplied => _controller.isCheckingApplied.value;
  bool get hasApplied => _controller.hasApplied.value;
  bool get isRunningAts => _controller.isRunningAts.value;
  int? get atsScore => _controller.atsScore.value;
  List<String> get atsKeywords => _controller.atsKeywords;
  List<String> get atsSuggestions => _controller.atsSuggestions;
  String get atsGap => _controller.atsGap.value;
  String? get atsErrorMessage => _controller.atsErrorMessage.value;
  String? get atsResumeVersionTitle => _controller.atsResumeVersionTitle.value;
  List<String> get atsMatchedSkills => _controller.atsMatchedSkills;
  List<String> get atsMissingSkills => _controller.atsMissingSkills;
  String get atsSummarySuggestion => _controller.atsSummarySuggestion.value;
  bool get isLoadingCompany => _controller.isLoadingCompany.value;
  Map<String, dynamic>? get companyInfo => _controller.companyInfo.value;
  bool get isGeneratingCoverLetter => _controller.isGeneratingCoverLetter.value;
  String get coverLetterContent => _controller.coverLetterContent.value;
  Map<String, dynamic>? get invitationData => _controller.invitationData.value;
  bool get isLoadingInvitation => _controller.isLoadingInvitation.value;
  List<dynamic> get questionnaireList => _controller.questionnaireList;
  Map<String, TextEditingController> get _questionControllers =>
      _controller.questionControllers;
  int? getCompanyId() {
    final raw = _job['company_id'];
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  Future<void> handleApply() async {
    await _controller.handleApply(
      jobId: _job['id'],
      formKey: _formKey,
      context: context,
    );
  }

  Future<void> generateCoverLetter() async {
    await _controller.generateCoverLetter(
      jobId: _job['id'],
      jobTitle: _job['title'] ?? 'Role',
      companyName: _job['company'] ?? 'Company',
      showModal: (title, company) {
        _showCoverLetterModal(title, company);
      },
    );
  }

  void _showCoverLetterModal(String title, String company) {
    final isDark = themeController.isDarkMode;
    final cardBg = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Cover Letter Draft',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$title at $company',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: SelectableText(
                    coverLetterContent,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: coverLetterContent),
                      );
                      Get.snackbar(
                        'Copied',
                        'Cover letter copied to clipboard!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF10B981),
                        colorText: Colors.white,
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                    label: Text(
                      'Copy to Clipboard',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode;
    final mainBg = AppColors.getBackground(isDark);
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.grey[400]! : const Color(0xFF475569);

    final title = _job['title'] ?? 'Role Details';
    final company = _job['company'] ?? 'Company';
    final location = _job['location'] ?? 'Not Specified';
    final type = _job['employment_type'] ?? 'Full-time';
    final salary = _job['salary_range']?.toString() ?? '';
    final experience = _job['experience_level']?.toString() ?? '';
    final logoUrl = _job['company_logo'] ?? '';
    final initial = company.isNotEmpty ? company[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Job Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingJob
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.getPrimary(isDark),
                  ),
                ),
              )
            : Obx(
                () => isCheckingApplied
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getPrimary(isDark),
                          ),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecruiterInvitationBanner(
                                isDark,
                                cardColor,
                                textColor,
                                subtitleColor,
                              ),
                              // Header Card
                              _buildHeaderCard(
                                cardColor,
                                textColor,
                                subtitleColor,
                                logoUrl,
                                initial,
                                title,
                                company,
                                location,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // Quick Specs
                              _buildSpecsGrid(
                                cardColor,
                                textColor,
                                subtitleColor,
                                type,
                                salary,
                                experience,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // AI Interview Policy
                              _buildAiPolicyCard(
                                cardColor,
                                textColor,
                                subtitleColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // ATS Match Card
                              _buildAtsScoreCard(
                                cardColor,
                                textColor,
                                subtitleColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // Description
                              _buildSectionCard(
                                title: 'Job Description',
                                cardColor: cardColor,
                                textColor: textColor,
                                child: Text(
                                  _job['description'] ??
                                      'No description provided.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : const Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Skills
                              if (_job['required_skills'] != null &&
                                  _job['required_skills']
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ...[
                                _buildSectionCard(
                                  title: 'Required Skills',
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _job['required_skills']
                                        .toString()
                                        .split(',')
                                        .map<Widget>(
                                          (s) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.getPrimary(
                                                isDark,
                                              ).withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.getPrimary(
                                                  isDark,
                                                ).withOpacity(0.15),
                                              ),
                                            ),
                                            child: Text(
                                              s.trim(),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.getPrimary(
                                                  isDark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Company Snapshot
                              if (companyInfo != null) ...[
                                _buildCompanySnapshotCard(
                                  cardColor,
                                  textColor,
                                  isDark,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Job Summary
                              _buildJobSummaryCard(
                                cardColor,
                                textColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // About Company
                              _buildAboutCompanyCard(
                                cardColor,
                                textColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),

                              // Questionnaire Section (If not applied yet)
                              if (!hasApplied &&
                                  questionnaireList.isNotEmpty) ...[
                                _buildSectionCard(
                                  title: 'Additional Questions (Required)',
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: questionnaireList.map<Widget>((
                                      q,
                                    ) {
                                      final id = q['id']?.toString() ?? '';
                                      final label =
                                          q['label']?.toString() ?? 'Question';
                                      final required =
                                          q['required'] == true ||
                                          q['required'] == 1 ||
                                          q['required'] == 'true';
                                      final type =
                                          q['type']?.toString() ?? 'textarea';

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    label,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                if (required)
                                                  Text(
                                                    ' *',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.redAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller:
                                                  _questionControllers[id],
                                              maxLines: type == 'text' ? 1 : 4,
                                              style: GoogleFonts.inter(
                                                color: textColor,
                                                fontSize: 14,
                                              ),
                                              decoration: InputDecoration(
                                                hintText:
                                                    q['placeholder']
                                                        ?.toString() ??
                                                    'Type your answer here...',
                                                hintStyle: GoogleFonts.inter(
                                                  color: Colors.grey[500],
                                                  fontSize: 13,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                filled: true,
                                                fillColor: isDark
                                                    ? Colors.black26
                                                    : Colors.grey[50],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? Colors.grey[800]!
                                                        : Colors.grey[300]!,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: isDark
                                                            ? Colors.grey[800]!
                                                            : Colors.grey[300]!,
                                                      ),
                                                    ),
                                              ),
                                              validator: (value) {
                                                if (required &&
                                                    (value == null ||
                                                        value.trim().isEmpty)) {
                                                  return 'Please answer this question';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Action buttons
                              _buildActionButtons(isDark, textColor),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildRecruiterInvitationBanner(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    if (invitationData == null) return const SizedBox();

    final status = invitationData!['status']?.toString() ?? 'sent';
    final recruiterName =
        invitationData!['recruiter_name']?.toString() ?? 'A recruiter';
    final message =
        invitationData!['message']?.toString() ??
        'A recruiter believes your profile aligns with this role.';

    final isApplied = status == 'applied';
    final heading = isApplied
        ? 'You already responded to this invitation'
        : 'You were personally invited to apply';

    final accentColor = isApplied ? Colors.green : AppColors.getPrimary(isDark);
    final bannerBg = isApplied
        ? Colors.green.withOpacity(0.06)
        : AppColors.getPrimary(isDark).withOpacity(0.06);
    final borderC = isApplied
        ? Colors.green.withOpacity(0.25)
        : AppColors.getPrimary(isDark).withOpacity(0.25);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderC, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Direct recruiter signal',
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            heading,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.account_box_outlined,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 5),
              Text(
                recruiterName,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.business_center_outlined,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _job['company'] ?? 'Company',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    Color cardBg,
    Color textC,
    Color subtitleC,
    String logoUrl,
    String initial,
    String title,
    String company,
    String location,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              image: logoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        ApiConstants.resolveImageUrl(logoUrl.toString()),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: logoUrl.isEmpty
                ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textC,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: GoogleFonts.inter(
                    color: AppColors.getPrimary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(
    Color cardBg,
    Color textC,
    Color subtitleC,
    String type,
    String salary,
    String experience,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSpecItem(
                Icons.work_outline,
                'Employment Type',
                type.replaceAll('-', ' ').capitalizeFirst ?? type,
                isDark,
              ),
              const SizedBox(width: 16),
              _buildSpecItem(
                Icons.monetization_on_outlined,
                'Salary Range',
                salary.isNotEmpty ? '$salary LPA' : 'Competitive',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSpecItem(
                Icons.star_border,
                'Experience',
                experience.isNotEmpty ? experience : 'Not Specified',
                isDark,
              ),
              const SizedBox(width: 16),
              _buildSpecItem(
                Icons.verified_outlined,
                'Listing Type',
                'Internal Verified',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: themeController.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPolicyCard(
    Color cardBg,
    Color textC,
    Color subtitleC,
    bool isDark,
  ) {
    final policyRaw =
        _job['ai_interview_policy']?.toString().toUpperCase() ??
        'REQUIRED_HARD';

    Color policyColor;
    String policyTitle;
    String policyDesc;
    IconData policyIcon;

    switch (policyRaw) {
      case 'OFF':
        policyColor = const Color(0xFF10B981); // Green
        policyTitle = 'AI Interview: Not Required';
        policyDesc =
            'You can apply directly. No AI round is needed for this job.';
        policyIcon = Icons.check_circle_outline;
        break;
      case 'OPTIONAL':
        policyColor = const Color(0xFFF59E0B); // Amber
        policyTitle = 'AI Interview: Optional';
        policyDesc =
            'Optional AI round is available and may improve your visibility.';
        policyIcon = Icons.lightbulb_outline;
        break;
      case 'REQUIRED_SOFT':
        policyColor = const Color(0xFF3B82F6); // Blue
        policyTitle = 'AI Interview: Required + Review';
        policyDesc =
            'AI round is required, and recruiter can still make the final decision.';
        policyIcon = Icons.assignment_ind_outlined;
        break;
      case 'REQUIRED_HARD':
      default:
        policyColor = const Color(0xFFEF4444); // Red
        policyTitle = 'AI Interview: Mandatory';
        policyDesc =
            'AI interview is mandatory and works as the primary screening gate.';
        policyIcon = Icons.shield_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: policyColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: policyColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(policyIcon, color: policyColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policyTitle,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: policyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  policyDesc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtsScoreCard(
    Color cardBg,
    Color textC,
    Color subtitleC,
    bool isDark,
  ) {
    if (isRunningAts) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Analyzing ATS match and fetching coach suggestions...'),
            ],
          ),
        ),
      );
    }

    if (atsErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                atsErrorMessage!,
                style: GoogleFonts.inter(fontSize: 13, color: subtitleC),
              ),
            ),
          ],
        ),
      );
    }

    if (atsScore == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
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
                    Icons.auto_awesome,
                    color: AppColors.getPrimary(isDark),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ATS Resume Coach',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textC,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$atsScore% Match',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (atsResumeVersionTitle != null &&
              atsResumeVersionTitle!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 12,
                    color: AppColors.getPrimary(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Using Resume: $atsResumeVersionTitle',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtitleC,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (atsMatchedSkills.isNotEmpty) ...[
            Text(
              'Matched Skills',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: atsMatchedSkills
                  .take(8)
                  .map(
                    (kw) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kw,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (atsMissingSkills.isNotEmpty) ...[
            Text(
              'Missing Skills',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: atsMissingSkills
                  .take(8)
                  .map(
                    (kw) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kw,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (atsSummarySuggestion.isNotEmpty) ...[
            Text(
              'Suggested Summary Direction',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black26
                    : Colors.blue[50]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.grey[850]!
                      : Colors.blue[100]!.withOpacity(0.5),
                ),
              ),
              child: Text(
                atsSummarySuggestion,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey[300] : Colors.blue[900],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (atsSuggestions.isNotEmpty) ...[
            Text(
              'What to Improve',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: atsSuggestions
                  .map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            color: AppColors.getPrimary(isDark),
                            size: 16,
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final jobId = int.tryParse(_job['id']?.toString() ?? '');
                final jobTitle = _job['title']?.toString() ?? 'Job';
                Get.to(
                  () => ResumeStudioScreen(jobId: jobId, jobTitle: jobTitle),
                );
              },
              icon: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Improve Resume for This Job',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color cardColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeController.isDarkMode
              ? Colors.grey[850]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final resolvedUrl = ApiConstants.resolveImageUrl(urlString);
      final uri = Uri.parse(resolvedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open link.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildSummaryRow(String label, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildJobSummaryCard(Color cardBg, Color textC, bool isDark) {
    final created = _job['created_at']?.toString() ?? '';
    String publishedStr = 'Not Specified';
    if (created.isNotEmpty) {
      try {
        final dt = DateTime.parse(created);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        publishedStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }

    final deadline = _job['application_deadline']?.toString() ?? '';
    String deadlineStr = 'Not Specified';
    if (deadline.isNotEmpty) {
      try {
        final dt = DateTime.parse(deadline);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        deadlineStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }

    final companyName = _job['company']?.toString() ?? 'Company';
    final type = _job['employment_type']?.toString() ?? 'Full-time';
    final experience = _job['experience_level']?.toString() ?? '';
    final location = _job['location']?.toString() ?? 'Not Specified';
    final category = _job['category']?.toString() ?? '';
    final salary = _job['salary_range']?.toString() ?? '';
    final openings = _job['openings']?.toString() ?? '';

    return _buildSectionCard(
      title: 'Job Summary',
      cardColor: cardBg,
      textColor: textC,
      child: Column(
        children: [
          _buildSummaryRow('Published on', publishedStr, textC),
          const Divider(height: 16),
          _buildSummaryRow('Company', companyName, textC),
          const Divider(height: 16),
          _buildSummaryRow(
            'Employment',
            (() {
              final clean = type.replaceAll('-', ' ');
              if (clean.isEmpty) return clean;
              return clean[0].toUpperCase() + clean.substring(1);
            })(),
            textC,
          ),
          if (experience.isNotEmpty) ...[
            const Divider(height: 16),
            _buildSummaryRow('Experience', experience, textC),
          ],
          const Divider(height: 16),
          _buildSummaryRow('Location', location, textC),
          if (category.isNotEmpty) ...[
            const Divider(height: 16),
            _buildSummaryRow('Category', category, textC),
          ],
          if (salary.isNotEmpty) ...[
            const Divider(height: 16),
            _buildSummaryRow('Salary Range', '$salary LPA', textC),
          ],
          if (deadline.isNotEmpty) ...[
            const Divider(height: 16),
            _buildSummaryRow('Deadline', deadlineStr, textC),
          ],
          if (openings.isNotEmpty) ...[
            const Divider(height: 16),
            _buildSummaryRow('Openings', openings, textC),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanySnapshotCard(Color cardBg, Color textC, bool isDark) {
    if (companyInfo == null) return const SizedBox();

    final cultureSummary = companyInfo!['culture_summary']?.toString() ?? '';
    final benefitsRaw = companyInfo!['employee_benefits']?.toString() ?? '';
    final photosUrls = List<String>.from(
      companyInfo!['workplace_photos_urls'] ?? [],
    );

    List<String> benefits = [];
    if (benefitsRaw.isNotEmpty) {
      benefits = benefitsRaw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (cultureSummary.isEmpty && benefits.isEmpty && photosUrls.isEmpty) {
      return const SizedBox();
    }

    return _buildSectionCard(
      title: 'Company Snapshot',
      cardColor: cardBg,
      textColor: textC,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cultureSummary.isNotEmpty) ...[
            Text(
              cultureSummary,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (benefits.isNotEmpty) ...[
            Text(
              'Benefits & Perks',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: benefits
                  .take(6)
                  .map(
                    (benefit) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(fontSize: 11.5, color: textC),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (photosUrls.isNotEmpty) ...[
            Text(
              'Workplace Photos',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textC,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photosUrls.length,
                itemBuilder: (context, index) {
                  final photo = photosUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(photo),
                        width: 150,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 150,
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCompanyCard(Color cardBg, Color textC, bool isDark) {
    final companyName = _job['company']?.toString() ?? 'Company';
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C';
    final logoUrl = companyInfo != null ? (companyInfo!['logo_url'] ?? '') : '';
    final rawIsExternal = _job['is_external'];
    bool isExternal = false;
    if (rawIsExternal != null) {
      if (rawIsExternal is num) {
        isExternal = rawIsExternal.toInt() == 1;
      } else {
        isExternal =
            rawIsExternal.toString() == '1' ||
            rawIsExternal.toString().toLowerCase() == 'true';
      }
    }

    return _buildSectionCard(
      title: 'Company Details',
      cardColor: cardBg,
      textColor: textC,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
              image: logoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        ApiConstants.resolveImageUrl(logoUrl),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: logoUrl.isEmpty
                ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: textC,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isExternal)
                  GestureDetector(
                    onTap: () {
                      final companyId = getCompanyId();
                      if (companyId != null) {
                        Get.to(
                          () => CompanyProfileScreen(companyId: companyId),
                        );
                      }
                    },
                    child: Text(
                      'View Company Profile',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.getPrimary(isDark),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    'External Company listing',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isGeneratingCoverLetter ? null : generateCoverLetter,
                icon: isGeneratingCoverLetter
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
                      ),
                label: Text(
                  isGeneratingCoverLetter
                      ? 'Generating Letter...'
                      : 'AI Cover Letter',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                onPressed: hasApplied ? null : handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasApplied
                      ? Colors.grey
                      : AppColors.getPrimary(isDark),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  hasApplied ? 'Already Applied' : 'Apply Now',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
