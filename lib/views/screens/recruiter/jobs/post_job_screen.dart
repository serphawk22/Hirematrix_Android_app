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
  
  // Company/Client Info
  final _clientCompanyNameController = TextEditingController();
  String _postingFor = 'Own company';
  String _category = 'Technology';
  String _employmentType = 'Full Time';
  String _workMode = 'Onsite';

  // Hiring Preferences
  String _experience = 'Fresher';
  DateTime? _deadline;
  
  // AI Interview Policy
  String _aiPolicy = 'Optional';
  final _aiCutoffController = TextEditingController(text: '0');

  // Questionnaire
  final List<Map<String, String>> _customQuestions = [];

  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Default deadline 30 days from now
    _deadline = DateTime.now().add(const Duration(days: 30));
  }

  void _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId == null) return;
    setState(() => _isPosting = true);

    try {
      final response = await _apiService.addJob({
        'recruiter_id': recruiterId,
        'job_title': _titleController.text.trim(),
        'posting_for': _postingFor,
        'client_company_name': _clientCompanyNameController.text.trim(),
        'category': _category,
        'employment_type': _employmentType,
        'work_mode': _workMode,
        'experience_required': _experience,
        'salary_range': _salaryController.text.trim(),
        'job_location': _locationController.text.trim(),
        'job_description': _descriptionController.text.trim(),
        'skills_required': _skillsController.text.trim(),
        'application_deadline': _deadline != null ? DateFormat('yyyy-MM-dd').format(_deadline!) : '',
        'openings_count': _openingsController.text.trim(),
        'ai_policy': _aiPolicy,
        'ai_cutoff': _aiCutoffController.text.trim(),
        'questions': jsonEncode(_customQuestions),
      });

      if (mounted) {
        if (response['success'] == true) {
          Provider.of<JobsController>(context, listen: false).refreshJobs(recruiterId);
          Provider.of<DashboardController>(context, listen: false).refresh(recruiterId);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job published to workspace!'), backgroundColor: AppColors.success));
        } else {
          throw Exception(response['message'] ?? 'Failed to post job');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppColors.error));
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
        title: Text('New Job Listing', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
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
              _buildSectionCard('Role Information', isDark, [
                _buildTextField(_titleController, 'Job Title *', 'e.g. Senior Software Engineer'),
                const SizedBox(height: 16),
                _buildDropdown('Category *', ['Technology', 'Design', 'Marketing', 'Sales', 'Finance', 'HR', 'Operations'], _category, (v) => setState(() => _category = v!)),
                const SizedBox(height: 16),
                _buildTextField(_locationController, 'Location *', 'e.g. Pune, India (Hybrid)'),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Description *', 'Roles and responsibilities...', maxLines: 5),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Client & Setup', isDark, [
                _buildDropdown('Posting For', ['Own company', 'Client company'], _postingFor, (v) => setState(() => _postingFor = v!)),
                if (_postingFor == 'Client company') ...[
                  const SizedBox(height: 16),
                  _buildTextField(_clientCompanyNameController, 'Client Name *', 'Company name for client'),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Employment Type', ['Full Time', 'Part Time', 'Contract', 'Internship'], _employmentType, (v) => setState(() => _employmentType = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('Work Mode', ['Onsite', 'Hybrid', 'Remote'], _workMode, (v) => setState(() => _workMode = v!))),
                  ],
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Requirements & Budget', isDark, [
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Experience', ['Fresher', '1-2 Years', '2-3 Years', '3-5 Years', '5+ Years'], _experience, (v) => setState(() => _experience = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_openingsController, 'Openings *', '1', type: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_salaryController, 'Salary Range', 'e.g. ₹12L - ₹18L'),
                const SizedBox(height: 16),
                _buildTextField(_skillsController, 'Required Skills *', 'Flutter, Dart, Provider (Comma separated)'),
                const SizedBox(height: 16),
                _buildDatePicker('Application Deadline', isDark),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('AI Interview Policy', isDark, [
                _buildDropdown('Policy Type', ['Mandatory', 'Optional', 'Manual', 'Combined'], _aiPolicy, (v) => setState(() => _aiPolicy = v!)),
                const SizedBox(height: 8),
                Text(_getPolicyHint(), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                _buildTextField(_aiCutoffController, 'Min. Screening Score (0-100)', 'Qualification threshold', type: TextInputType.number),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Custom Questionnaire', isDark, [
                Text('Add screening questions for applicants.', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _buildGhostButton('Add Short Answer', Icons.short_text_rounded, isDark, () {
                      setState(() => _customQuestions.add({'text': '', 'type': 'short_answer'}));
                    }),
                    _buildGhostButton('Add Link/Portfolio', Icons.link_rounded, isDark, () {
                      setState(() => _customQuestions.add({'text': 'Portfolio/Project Link', 'type': 'link'}));
                    }),
                  ],
                ),
                if (_customQuestions.isNotEmpty) ...[
                   const SizedBox(height: 20),
                   ..._customQuestions.asMap().entries.map((e) => Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Expanded(child: _buildTextField(null, 'Question ${e.key + 1} (${e.value['type']})', 'Type here...', 
                           onChanged: (val) => _customQuestions[e.key]['text'] = val)),
                         const SizedBox(width: 8),
                         IconButton(
                           onPressed: () => setState(() => _customQuestions.removeAt(e.key)),
                           icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                         ),
                       ],
                     ),
                   )),
                ]
              ]),

              const SizedBox(height: 24),
              _buildRecruiterGuidance(isDark),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isPosting ? null : _postJob,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppColors.getPrimary(isDark),
                ),
                child: _isPosting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('PUBLISH TO WORKSPACE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  String _getPolicyHint() {
    switch (_aiPolicy) {
      case 'Mandatory': return 'Candidates must complete AI interview before you see them.';
      case 'Optional': return 'Recruiters can trigger AI interviews manually.';
      case 'Manual': return 'Standard human-led screening only.';
      case 'Combined': return 'AI score and recruiter notes are weighted together.';
      default: return '';
    }
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
          Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getPrimary(isDark), letterSpacing: 1)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController? controller, String label, String hint, {int maxLines = 1, TextInputType type = TextInputType.text, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          onChanged: onChanged,
          initialValue: controller == null ? null : null, // Handle null controller if using onChanged only
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
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
                const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 12),
                Text(_deadline == null ? 'Select Date' : DateFormat('dd MMM, yyyy').format(_deadline!), 
                  style: TextStyle(fontSize: 13, color: _deadline == null ? Colors.grey : AppColors.getText(isDark))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostButton(String label, IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.getPrimary(isDark).withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.getPrimary(isDark)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.getPrimary(isDark))),
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
        border: Border.all(color: AppColors.getPrimary(isDark).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.getPrimary(isDark)),
              const SizedBox(width: 8),
              Text('Operational Tip', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.getPrimary(isDark))),
            ],
          ),
          const SizedBox(height: 12),
          Text('Setting a minimum AI score helps you focus only on qualified candidates. You can adjust this later from the job management workspace.', 
            style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey[600], fontWeight: FontWeight.w500, height: 1.4)),
        ],
      ),
    );
  }
}
