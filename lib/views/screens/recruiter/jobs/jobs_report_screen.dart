import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';

class JobsReportScreen extends StatefulWidget {
  const JobsReportScreen({super.key});

  @override
  State<JobsReportScreen> createState() => _JobsReportScreenState();
}

class _JobsReportScreenState extends State<JobsReportScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _status = '';
  String _category = '';
  String _employmentType = '';
  final TextEditingController _keywordController = TextEditingController();

  final List<String> _statusOptions = [
    '',
    'open',
    'closed',
    'draft',
    'archived',
  ];
  final List<String> _categoryOptions = [
    '',
    'Software Development',
    'Data Science',
    'DevOps',
    'Quality Assurance',
    'UI/UX Design',
    'Product Management',
    'Project Management',
    'Marketing',
    'Sales',
    'Human Resources',
    'Finance',
    'Operations',
    'Customer Support',
    'Business Analysis',
    'Cybersecurity',
  ];
  final List<String> _employmentTypeOptions = [
    '',
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
  ];

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.getPrimary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _generateReport({String? period}) async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId == null) return;

    final params = <String, String>{'recruiter_id': recruiterId.toString()};

    if (period != null) {
      params['period'] = period;
    } else {
      if (_status.isNotEmpty) params['status'] = _status;
      if (_category.isNotEmpty) params['category'] = _category;
      if (_employmentType.isNotEmpty)
        params['employment_type'] = _employmentType;
      if (_keywordController.text.isNotEmpty)
        params['keyword'] = _keywordController.text.trim();
      if (_dateFrom != null)
        params['date_from'] = DateFormat('yyyy-MM-dd').format(_dateFrom!);
      if (_dateTo != null)
        params['date_to'] = DateFormat('yyyy-MM-dd').format(_dateTo!);
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.exportJobsReport}',
    ).replace(queryParameters: params);

    await Permission.storage.request();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Downloading report...',
              style: TextStyle(fontSize: 16),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final fileName =
              'jobs_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Saved to Downloads',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                action: SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: () {
                    OpenFile.open(file.path);
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Jobs Report',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.getText(isDark),
          ),
        ),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getText(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Generate customised excel reports for your jobs.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.getTextMuted(isDark),
              ),
            ),
            const SizedBox(height: 24),

            // One Click Reports Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getCard(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'One Click Reports',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quickly generate reports for recent periods.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildOneClickButton(
                    'Yesterday',
                    'yesterday',
                    Icons.today,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildOneClickButton(
                    'This Week',
                    'week',
                    Icons.date_range,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildOneClickButton(
                    'This Month',
                    'month',
                    Icons.calendar_month,
                    isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Customised Report Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getCard(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customised Report',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          context,
                          'Date From',
                          _dateFrom,
                          true,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          context,
                          'Date To',
                          _dateTo,
                          false,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    'Status',
                    _status,
                    _statusOptions,
                    (v) => setState(() => _status = v!),
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    'Job Category',
                    _category,
                    _categoryOptions,
                    (v) => setState(() => _category = v!),
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    'Employment Type',
                    _employmentType,
                    _employmentTypeOptions,
                    (v) => setState(() => _employmentType = v!),
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField('Keyword', _keywordController, isDark),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateReport(),
                      icon: const Icon(
                        Icons.file_download_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Generate Customised Report',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime? date,
    bool isFrom,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextMuted(isDark),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context, isFrom),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FCFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.getBorder(isDark)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : 'Select',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: date != null
                        ? AppColors.getText(isDark)
                        : AppColors.getTextMuted(isDark),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.getTextMuted(isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextMuted(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFF8FCFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.getBorder(isDark)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.getTextMuted(isDark),
              ),
              dropdownColor: AppColors.getCard(isDark),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.getText(isDark),
              ),
              onChanged: onChanged,
              items: options.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val.isEmpty ? 'All' : val),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextMuted(isDark),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.getText(isDark),
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Developer',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.getTextMuted(isDark),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF000000)
                : const Color(0xFFF8FCFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.getBorder(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.getBorder(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.getPrimary(isDark),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOneClickButton(
    String label,
    String period,
    IconData icon,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => _generateReport(period: period),
        icon: Icon(icon, size: 18, color: AppColors.getText(isDark)),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.getText(isDark),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.getBorder(isDark)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
