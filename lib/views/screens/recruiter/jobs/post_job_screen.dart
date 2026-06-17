import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Job Details
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingsController = TextEditingController(text: '1');
  final _experienceController = TextEditingController();

  // Company/Client Info
  final _clientCompanyNameController = TextEditingController();
  String _postingFor = 'own_company';
  String _payrollType = '';
  String _clientDisclosure = 'visible';
  String _category = '';
  String _employmentType = 'Full-time';

  // Hiring Preferences
  DateTime? _deadline;

  // AI Interview Policy
  String _aiPolicy = 'REQUIRED_HARD';
  final _aiCutoffController = TextEditingController();

  // Questionnaire
  final List<Map<String, dynamic>> _customQuestions = [];

  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Default deadline 30 days from now
    _deadline = DateTime.now().add(const Duration(days: 30));
  }

  void _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;
    setState(() => _isPosting = true);

    try {
      final response = await _apiService.addJob({
        'recruiter_id': recruiterId,
        'title': _titleController.text.trim(),
        'posted_for': _postingFor,
        'payroll_type': _payrollType,
        'client_company_name': _postingFor == 'client'
            ? _clientCompanyNameController.text.trim()
            : '',
        'client_disclosure': _clientDisclosure,
        'category': _category,
        'employment_type': _employmentType,
        'experience_level': _experienceController.text.trim(),
        'salary_range': _salaryController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'required_skills': _skillsController.text.trim(),
        'application_deadline': _deadline != null
            ? DateFormat('yyyy-MM-dd').format(_deadline!)
            : '',
        'openings': _openingsController.text.trim(),
        'ai_interview_policy': _aiPolicy,
        'min_ai_cutoff_score': _aiCutoffController.text.trim(),
        'questionnaire': jsonEncode(_customQuestions),
      });

      if (mounted) {
        if (response['success'] == true) {
          Provider.of<JobsController>(
            context,
            listen: false,
          ).refreshJobs(recruiterId);
          Provider.of<DashboardController>(
            context,
            listen: false,
          ).refresh(recruiterId);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job published to workspace!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          throw Exception(response['message'] ?? 'Failed to post job');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'New Job Listing',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard('Posting Details', isDark, [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Posting For *',
                        {
                          'own_company': 'Own company',
                          'client': 'Client company',
                        },
                        _postingFor,
                        (v) => setState(() => _postingFor = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        'Payroll Type',
                        {
                          '': 'Select payroll type',
                          'company_payroll': 'Company payroll',
                          'client_payroll': 'Client payroll',
                          'consultancy_payroll': 'Consultancy payroll',
                          'third_party_contract': 'Third-party contract',
                        },
                        _payrollType,
                        (v) => setState(() => _payrollType = v!),
                      ),
                    ),
                  ],
                ),
                if (_postingFor == 'client') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _clientCompanyNameController,
                          'Client Company Name *',
                          'Company name for client',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          'Client Disclosure',
                          {
                            'visible': 'Visible to candidates',
                            'confidential': 'Confidential',
                          },
                          _clientDisclosure,
                          (v) => setState(() => _clientDisclosure = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Job Information', isDark, [
                _buildTextField(_titleController, 'Job Title *', 'Job Title'),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Category *',
                  {
                    '': 'Select Job Category',
                    'Software Development': 'Software Development',
                    'Data Science': 'Data Science',
                    'DevOps': 'DevOps',
                    'Quality Assurance': 'Quality Assurance',
                    'UI/UX Design': 'UI/UX Design',
                    'Product Management': 'Product Management',
                    'Project Management': 'Project Management',
                    'Marketing': 'Marketing',
                    'Sales': 'Sales',
                    'Human Resources': 'Human Resources',
                    'Finance': 'Finance',
                    'Operations': 'Operations',
                    'Customer Support': 'Customer Support',
                    'Business Analysis': 'Business Analysis',
                    'Cybersecurity': 'Cybersecurity',
                  },
                  _category,
                  (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                _buildTextField(_locationController, 'Location *', 'Location'),
                const SizedBox(height: 16),
                _buildTextField(
                  _descriptionController,
                  'Description *',
                  'Job Description',
                  maxLines: 9,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Requirements & Terms', isDark, [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _experienceController,
                        'Experience',
                        'e.g., 2-3 years',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        'Employment Type',
                        {
                          'Full-time': 'Full-time',
                          'Part-time': 'Part-time',
                          'Contract': 'Contract',
                          'Internship': 'Internship',
                        },
                        _employmentType,
                        (v) => setState(() => _employmentType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _salaryController,
                  'Salary Range',
                  'e.g., 5-8 LPA',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker('Application Deadline', isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _openingsController,
                        'Number of Openings *',
                        '1',
                        type: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _skillsController,
                  'Required Skills',
                  'Comma separated skills',
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('AI Interview Policy', isDark, [
                _buildDropdown(
                  'AI Interview Policy',
                  {
                    'REQUIRED_HARD': 'AI Interview: Mandatory (Strict)',
                    'REQUIRED_SOFT':
                        'AI Interview: Mandatory (Recruiter Can Override)',
                    'OPTIONAL': 'AI Interview: Optional',
                    'OFF': 'AI Interview: Not Required',
                  },
                  _aiPolicy,
                  (v) => setState(() => _aiPolicy = v!),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how AI interview affects applications: strict reject, recruiter override, optional, or disabled.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _aiCutoffController,
                  'Minimum AI Cutoff Score',
                  '0-100',
                  type: TextInputType.number,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Application Questionnaire', isDark, [
                Text(
                  'Add optional screening prompts. You can use this for a cover letter, notice period, motivation, or any short written response.',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildGhostButton(
                      'Add Cover Letter Prompt',
                      Icons.article_outlined,
                      isDark,
                      () {
                        setState(
                          () => _customQuestions.add({
                            'label': 'Cover letter / Why are you a fit?',
                            'type': 'textarea',
                            'placeholder':
                                'Share why you are interested in this role and what makes you a strong fit.',
                            'required': true,
                            'knockout': false,
                            'knockout_answer': '',
                            'knockout_match': 'exact',
                          }),
                        );
                      },
                    ),
                    _buildGhostButton(
                      'Add Question',
                      Icons.add_circle_outline,
                      isDark,
                      () {
                        setState(
                          () => _customQuestions.add({
                            'label': '',
                            'type': 'text',
                            'placeholder': '',
                            'required': false,
                            'knockout': false,
                            'knockout_answer': '',
                            'knockout_match': 'exact',
                          }),
                        );
                      },
                    ),
                  ],
                ),
                if (_customQuestions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ..._customQuestions.asMap().entries.map(
                    (e) => _buildQuestionnaireRow(e.key, e.value, isDark),
                  ),
                ],
              ]),

              const SizedBox(height: 24),
              _buildRecruiterGuidance(isDark),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isPosting ? null : _postJob,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: AppColors.getPrimary(isDark),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'PUBLISH TO WORKSPACE',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.getPrimary(isDark),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController? controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          onChanged: onChanged,
          initialValue: controller == null ? initialValue : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (v) {
            if (label.contains('*') && (v == null || v.trim().isEmpty))
              return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    Map<String, String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.containsKey(value)
              ? value
              : (items.isNotEmpty ? items.keys.first : null),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w600,
          ),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _deadline ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _deadline = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  _deadline == null
                      ? 'Select Date'
                      : DateFormat('dd MMM, yyyy').format(_deadline!),
                  style: TextStyle(
                    fontSize: 13,
                    color: _deadline == null
                        ? Colors.grey
                        : AppColors.getText(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostButton(
    String label,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.getPrimary(isDark).withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruiterGuidance(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.getPrimary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                'Operational Tip',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Setting a minimum AI score helps you focus only on qualified candidates. You can adjust this later from the job management workspace.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireRow(
    int index,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A2F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF23343A) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  null,
                  'Question Prompt',
                  'e.g. Why are you a fit?',
                  initialValue: item['label'],
                  onChanged: (val) => item['label'] = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildDropdown(
                  'Field Type',
                  const {'textarea': 'Long answer', 'text': 'Short answer'},
                  item['type'],
                  (val) => setState(() => item['type'] = val!),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _customQuestions.removeAt(index)),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            null,
            'Placeholder (Optional)',
            'Optional helper text',
            initialValue: item['placeholder'],
            onChanged: (val) => item['placeholder'] = val,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: item['required'] ?? false,
                    onChanged: (val) => setState(() => item['required'] = val),
                  ),
                  const Text(
                    'Required question',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: item['knockout'] ?? false,
                    onChanged: (val) {
                      setState(() {
                        item['knockout'] = val;
                        if (val == true) item['required'] = true;
                      });
                    },
                  ),
                  const Text(
                    'Knock-out must-have',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (item['knockout'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      null,
                      'Expected Answer',
                      'e.g. Yes, Y',
                      initialValue: item['knockout_answer'],
                      onChanged: (val) => item['knockout_answer'] = val,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: _buildDropdown(
                      'Match Type',
                      const {
                        'exact': 'Exact answer',
                        'contains': 'Answer contains',
                      },
                      item['knockout_match'],
                      (val) => setState(() => item['knockout_match'] = val!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
