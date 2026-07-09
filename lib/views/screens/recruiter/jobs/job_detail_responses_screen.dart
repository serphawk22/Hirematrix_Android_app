import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';
import '../candidates/candidate_profile_view_screen.dart';
import 'add_slot_screen.dart';
import 'edit_slot_screen.dart';
import 'recruiter_reschedule_interview.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class JobDetailResponsesScreen extends StatefulWidget {
  final Job job;

  const JobDetailResponsesScreen({super.key, required this.job});

  @override
  State<JobDetailResponsesScreen> createState() =>
      _JobDetailResponsesScreenState();
}

class _JobDetailResponsesScreenState extends State<JobDetailResponsesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // State / Tabs
  bool _isLoadingApps = true;
  String? _appsError;
  List<dynamic> _applications = [];
  Map<String, dynamic> _pipelineStats = {};
  String _selectedStage = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Advanced filters state
  final Map<String, String> _advancedFilters = {
    'skills': '',
    'location': '',
    'experience': '',
    'last_active': '',
    'ats_min': '',
    'ats_max': '',
    'sort': 'applied_desc',
  };

  // Multi-select for bulk actions
  final Set<String> _selectedAppIds = {};
  final Set<String> _selectedCandidateIds = {};

  // Interviews Tab
  bool _isLoadingInterviews = true;
  String? _interviewsError;
  List<dynamic> _interviews = [];
  List<dynamic> _slots = [];

  // Leaderboard Tab
  bool _isLoadingLeaderboard = true;
  String? _leaderboardError;
  List<dynamic> _leaderboard = [];

  final List<String> _stages = [
    'All',
    'Applied',
    'Shortlisted',
    'Screening',
    'Interview',
    'Offer',
    'Hired',
    'Rejected',
    'Withdrawn',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _loadApplications();
    } else if (_tabController.index == 1) {
      _loadInterviews();
    } else if (_tabController.index == 2) {
      _loadLeaderboard();
    }
  }

  Future<void> _loadApplications() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isLoadingApps = true;
      _appsError = null;
    });

    try {
      final Map<String, String> activeFilters = {};
      _advancedFilters.forEach((key, val) {
        if (val.isNotEmpty) {
          activeFilters[key] = val;
        }
      });

      final res = await _apiService.fetchApplicationsWithStage(
        recruiterId.toString(),
        jobId: widget.job.jobId,
        stage: _selectedStage == 'All' ? null : _selectedStage,
        query: _searchQuery.isEmpty ? null : _searchQuery,
        filters: activeFilters,
      );

      if (res['success'] == true) {
        setState(() {
          _applications = res['applications'] ?? [];
          _pipelineStats = res['pipeline_stats'] ?? {};
          _isLoadingApps = false;
        });
      } else {
        setState(() {
          _appsError =
              res['message']?.toString() ?? 'Failed to load candidates.';
          _isLoadingApps = false;
        });
      }
    } catch (e) {
      setState(() {
        _appsError = e.toString();
        _isLoadingApps = false;
      });
    }
  }

  Future<void> _loadInterviews() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isLoadingInterviews = true;
      _interviewsError = null;
    });

    try {
      final res = await _apiService.fetchInterviewsForJob(
        recruiterId.toString(),
        jobId: widget.job.jobId,
      );
      setState(() {
        _interviews = res['interviews'] ?? [];
        _slots = res['slots'] ?? [];
        _isLoadingInterviews = false;
      });
    } catch (e) {
      setState(() {
        _interviewsError = e.toString();
        _isLoadingInterviews = false;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isLoadingLeaderboard = true;
      _leaderboardError = null;
    });

    try {
      final res = await _apiService.fetchLeaderboard(
        recruiterId.toString(),
        jobId: widget.job.jobId,
      );
      if (res['success'] == true) {
        setState(() {
          _leaderboard = res['candidates'] ?? [];
          _isLoadingLeaderboard = false;
        });
      } else {
        setState(() {
          _leaderboardError =
              res['message']?.toString() ?? 'Failed to load leaderboard.';
          _isLoadingLeaderboard = false;
        });
      }
    } catch (e) {
      setState(() {
        _leaderboardError = e.toString();
        _isLoadingLeaderboard = false;
      });
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppColors.getCard(isDark),
          title: Text(
            'Delete Slot',
            style: GoogleFonts.inter(
              color: AppColors.getText(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this interview slot?',
            style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _apiService.deleteInterviewSlot(
        slotId,
        recruiterId.toString(),
      );
      Navigator.pop(context); // Close loading dialog

      if (res['success'] == true) {
        _loadInterviews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Slot deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message']?.toString() ?? 'Failed to delete slot',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(String appId, String status) async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _apiService.updateApplicationStatus(
        appId,
        status,
        recruiterId.toString(),
      );
      Navigator.pop(context); // Close loading dialog

      if (res['success'] == true) {
        // ── Optimistic update: patch local list immediately so dropdown reflects new value ──
        setState(() {
          final idx = _applications.indexWhere(
            (a) => a['application_id']?.toString() == appId,
          );
          if (idx != -1) {
            _applications[idx] = Map<String, dynamic>.from(_applications[idx])
              ..['status_key'] =
                  status // raw key — drives the dropdown
              ..['status'] = status; // also keep the display label in sync
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status updated successfully.'),
          ),
        );
        // Background reload to sync fresh server data
        _loadApplications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to update status.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _downloadResume(String candidateId, String? appId) async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    try {
      final baseUrl = await _apiService.getBaseUrl();
      final url =
          "$baseUrl/candidates/$candidateId/resume"
          "?recruiter_id=$recruiterId"
          "&application_id=${appId ?? ''}"
          "&job_id=${widget.job.jobId}";

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open resume link.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error launching resume: $e')));
    }
  }

  Future<void> _exportApplicants() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId == null) return;

    await Permission.storage.request();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Downloading applicants report...',
            style: TextStyle(fontSize: 16),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );

    try {
      final baseUrl = await _apiService.getBaseUrl();
      String cleanedUrl = baseUrl
          .replaceAll('/api/mobile', '')
          .replaceAll('/public/api/mobile', '');
      final url = Uri.parse(
        "$baseUrl/export/excel?recruiter_id=$recruiterId&type=detailed&job_id=${widget.job.jobId}",
      );

      final response = await http.get(url);
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
              'applicants_export_${widget.job.jobId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          if (!mounted) return;
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
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Failed to download report',
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Error: $e', style: const TextStyle(fontSize: 16)),
          ),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }
  }

  // Bulk Actions
  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedAppIds.isEmpty) return;
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _apiService.bulkUpdateStatus(
        recruiterId.toString(),
        _selectedAppIds.toList(),
        status,
      );
      Navigator.pop(context);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Bulk status updated.')),
        );
        setState(() {
          _selectedAppIds.clear();
          _selectedCandidateIds.clear();
        });
        _loadApplications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Bulk update failed.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showBulkEmailDialog() {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    // Get selected candidates details
    final selectedApps = _applications.where((app) {
      final appId = app['application_id']?.toString() ?? '';
      return _selectedAppIds.contains(appId);
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            void applyTemplate(String type) {
              String subject = '';
              String body = '';
              switch (type) {
                case 'interview':
                  subject = 'Interview Invitation - ${widget.job.jobTitle}';
                  body =
                      'Dear candidate,\n\nWe would like to invite you for an interview for the ${widget.job.jobTitle} position.\n\nPlease let us know your availability.';
                  break;
                case 'followup':
                  subject = 'Application Update - ${widget.job.jobTitle}';
                  body =
                      'Dear candidate,\n\nWe are currently reviewing your application for the ${widget.job.jobTitle} position and will get back to you shortly.';
                  break;
                case 'rejection':
                  subject = 'Update regarding your application';
                  body =
                      'Dear candidate,\n\nThank you for applying for the ${widget.job.jobTitle} position. Unfortunately, we have decided to move forward with other candidates at this time.';
                  break;
                case 'offer':
                  subject = 'Offer Letter - ${widget.job.jobTitle}';
                  body =
                      'Dear candidate,\n\nWe are thrilled to offer you the position of ${widget.job.jobTitle}. Please find the details attached.';
                  break;
              }
              setState(() {
                subjectController.text = subject;
                bodyController.text = body;
              });
            }

            return AlertDialog(
              backgroundColor: isDark ? AppColors.bgDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.alternate_email,
                    color: AppColors.getPrimary(isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Send Email to Selected Candidates',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        child: selectedApps.isEmpty
                            ? Text(
                                'No recipients selected',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: selectedApps.length,
                                itemBuilder: (context, index) {
                                  final app = selectedApps[index];
                                  final name =
                                      app['candidate_name'] ?? 'Candidate';
                                  final email = app['candidate_email'] ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '$name ${email.isNotEmpty ? "($email)" : ""}',
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedApps.length} recipients',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: subjectController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          labelStyle: GoogleFonts.inter(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bodyController,
                        maxLines: 8,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Message',
                          alignLabelWithHint: true,
                          labelStyle: GoogleFonts.inter(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Quick Templates:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTemplateChip(
                            'Interview Invitation',
                            () => applyTemplate('interview'),
                            isDark,
                          ),
                          _buildTemplateChip(
                            'Follow-up',
                            () => applyTemplate('followup'),
                            isDark,
                          ),
                          _buildTemplateChip(
                            'Rejection Notice',
                            () => applyTemplate('rejection'),
                            isDark,
                          ),
                          _buildTemplateChip(
                            'Offer Letter',
                            () => applyTemplate('offer'),
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final subject = subjectController.text.trim();
                    final body = bodyController.text.trim();
                    if (subject.isEmpty || body.isEmpty) return;

                    Navigator.pop(context);
                    _executeBulkEmail(subject, body);
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTemplateChip(String label, VoidCallback onTap, bool isDark) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey[100],
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.getPrimary(isDark),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: AppColors.getPrimary(isDark).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Future<void> _executeBulkEmail(String subject, String body) async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _apiService.bulkSendEmail(
        recruiterId.toString(),
        _selectedCandidateIds.toList(),
        subject,
        body,
      );
      Navigator.pop(context);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Emails sent successfully.'),
          ),
        );
        setState(() {
          _selectedAppIds.clear();
          _selectedCandidateIds.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to send emails.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending emails: $e')));
    }
  }

  void _showBulkMessageDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.bgDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.getPrimary(isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Message Selected Candidates',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    hintText: 'Write a message for the selected candidates...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This message will be sent to every selected candidate.',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final message = messageController.text.trim();
                if (message.isEmpty) return;

                Navigator.pop(context); // Close modal
                _executeBulkMessage(message);
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeBulkMessage(String message) async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _apiService.bulkSendMessage(
        recruiterId.toString(),
        _selectedCandidateIds.toList(),
        message,
        jobId: widget.job.jobId,
      );
      Navigator.pop(context);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Messages sent successfully.'),
          ),
        );
        setState(() {
          _selectedAppIds.clear();
          _selectedCandidateIds.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to send messages.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending messages: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.job.jobTitle,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.getPrimary(isDark),
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.getPrimary(isDark),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Candidates'),
                Tab(text: 'Interviews'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCandidatesTab(isDark),
          _buildInterviewsTab(isDark),
          _buildLeaderboardTab(isDark),
        ],
      ),
      bottomNavigationBar: _selectedAppIds.isNotEmpty
          ? _buildBulkActionBar(isDark)
          : null,
    );
  }

  // --- TAB 1: CANDIDATES ---
  Widget _buildCandidatesTab(bool isDark) {
    return Column(
      children: [
        _buildJobMetadataBanner(isDark),
        _buildSearchRow(isDark),
        _buildHiringFunnelStrip(isDark),
        _buildStagesScroller(isDark),
        Expanded(
          child: _isLoadingApps
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _appsError != null
              ? _buildErrorWidget(_appsError!, _loadApplications)
              : _applications.isEmpty
              ? _buildEmptyState('No candidates found matching the criteria.')
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _applications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      return _buildCandidateItemCard(app, isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildJobMetadataBanner(bool isDark) {
    final company =
        Provider.of<AuthController>(
          context,
          listen: false,
        ).currentRecruiter?.companyName ??
        'HireMatrix';
    final location = widget.job.location ?? 'Remote';
    final type = widget.job.workMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Job ID: #${widget.job.jobId}",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.job.status,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.job.status.toLowerCase() == 'active'
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$company • $location ($type)",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetadataStat(
                _applications.length.toString(),
                'Active Candidates',
                isDark,
              ),
              _buildMetadataStat(
                (widget.job.openings ?? 0).toString(),
                'Openings',
                isDark,
              ),
              _buildMetadataStat(
                "${_calculateAverageAtsScore()}%",
                'Avg. ATS Match',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateAverageAtsScore() {
    if (_applications.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (var app in _applications) {
      final scoreStr = app['match_score']?.toString() ?? '0';
      final score = double.tryParse(scoreStr) ?? 0;
      total += score;
      count++;
    }
    return count > 0 ? (total / count).round() : 0;
  }

  Widget _buildMetadataStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchRow(bool isDark) {
    final activeFiltersCount = _getActiveFiltersCount();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                  _loadApplications();
                },
                style: GoogleFonts.inter(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search candidates...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => _showAdvancedFiltersBottomSheet(isDark),
                icon: Icon(
                  Icons.tune_rounded,
                  color: activeFiltersCount > 0
                      ? AppColors.getPrimary(isDark)
                      : Colors.grey,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.getCard(isDark)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: activeFiltersCount > 0
                          ? AppColors.getPrimary(isDark)
                          : (isDark ? Colors.white10 : Colors.grey[200]!),
                    ),
                  ),
                ),
              ),
              if (activeFiltersCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$activeFiltersCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _exportApplicants,
            icon: Icon(
              Icons.file_download_outlined,
              color: AppColors.getPrimary(isDark),
            ),
            tooltip: 'Export Applicants',
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.getCard(isDark)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    _advancedFilters.forEach((key, val) {
      if (key != 'sort' && val.isNotEmpty) {
        count++;
      }
    });
    return count;
  }

  Future<void> _openWebUrl(String path) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      String cleanedUrl = baseUrl
          .replaceAll('/api/mobile', '')
          .replaceAll('/public/api/mobile', '');
      final webUrl = "$cleanedUrl/public/$path";
      final uri = Uri.parse(webUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch web URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAdvancedFiltersBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advanced Filters',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _advancedFilters['skills'] = '';
                              _advancedFilters['location'] = '';
                              _advancedFilters['experience'] = '';
                              _advancedFilters['last_active'] = '';
                              _advancedFilters['ats_min'] = '';
                              _advancedFilters['ats_max'] = '';
                              _advancedFilters['sort'] = 'applied_desc';
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildFilterTextField(
                      label: 'Skills',
                      hint: 'e.g. PHP, React, Flutter',
                      value: _advancedFilters['skills']!,
                      onChanged: (val) {
                        _advancedFilters['skills'] = val.trim();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildFilterTextField(
                      label: 'Location',
                      hint: 'e.g. Bangalore, Remote',
                      value: _advancedFilters['location']!,
                      onChanged: (val) {
                        _advancedFilters['location'] = val.trim();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildFilterTextField(
                      label: 'Experience (Years)',
                      hint: 'e.g. 2, 5',
                      value: _advancedFilters['experience']!,
                      onChanged: (val) {
                        _advancedFilters['experience'] = val.trim();
                      },
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _advancedFilters['last_active']!.isEmpty
                          ? null
                          : _advancedFilters['last_active'],
                      dropdownColor: isDark ? AppColors.bgDark : Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      hint: const Text(
                        'Any time',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '7',
                          child: Text('Last 7 days'),
                        ),
                        DropdownMenuItem(
                          value: '30',
                          child: Text('Last 30 days'),
                        ),
                        DropdownMenuItem(
                          value: '90',
                          child: Text('Last 90 days'),
                        ),
                      ],
                      onChanged: (val) {
                        setSheetState(() {
                          _advancedFilters['last_active'] = val ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ATS Score range',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterTextField(
                            label: 'Min %',
                            hint: '0',
                            value: _advancedFilters['ats_min']!,
                            onChanged: (val) {
                              _advancedFilters['ats_min'] = val.trim();
                            },
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterTextField(
                            label: 'Max %',
                            hint: '100',
                            value: _advancedFilters['ats_max']!,
                            onChanged: (val) {
                              _advancedFilters['ats_max'] = val.trim();
                            },
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sort By',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _advancedFilters['sort']!,
                      dropdownColor: isDark ? AppColors.bgDark : Colors.white,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'applied_desc',
                          child: Text('Most recent application'),
                        ),
                        DropdownMenuItem(
                          value: 'ats_desc',
                          child: Text('Highest ATS Match'),
                        ),
                        DropdownMenuItem(
                          value: 'ats_asc',
                          child: Text('Lowest ATS Match'),
                        ),
                      ],
                      onChanged: (val) {
                        setSheetState(() {
                          _advancedFilters['sort'] = val ?? 'applied_desc';
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {});
                              _loadApplications();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getPrimary(isDark),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTextField({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHiringFunnelStrip(bool isDark) {
    final Map<String, dynamic> pipeline = widget.job.pipeline ?? {};
    final steps = [
      {
        'label': 'APPLIED',
        'count': widget.job.applicationsCount ?? 0,
        'is_leak': false,
      },
      {
        'label': 'SHORTLISTED',
        'count': widget.job.shortlistedCount ?? 0,
        'is_leak': false,
      },
      {
        'label': 'INTERVIEWED',
        'count': int.tryParse(pipeline['Interview']?.toString() ?? '0') ?? 0,
        'is_leak': false,
      },
      {
        'label': 'OFFERED',
        'count': int.tryParse(pipeline['Offer']?.toString() ?? '0') ?? 0,
        'is_leak': false,
      },
      {
        'label': 'HIRED',
        'count': int.tryParse(pipeline['Hired']?.toString() ?? '0') ?? 0,
        'is_leak': false,
      },
    ];

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.getBorder(isDark) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: steps.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: Colors.grey[400],
            ),
          ),
        ),
        itemBuilder: (context, i) {
          final step = steps[i];
          final prevCount = i == 0
              ? (step['count'] as int)
              : (steps[i - 1]['count'] as int);
          final count = step['count'] as int;
          int conv = prevCount > 0 ? ((count / prevCount) * 100).round() : 0;
          if (i == 0) conv = 100;
          final bool isLeak = count == 0 && prevCount > 0 && i > 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                step['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  if (i > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$conv% →',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isLeak
                            ? Colors.amber[700]
                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: isLeak
                      ? Colors.amber[400]
                      : AppColors.getPrimary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStagesScroller(bool isDark) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _stages.length,
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final isSelected = _selectedStage == stage;
          final count = _getStageCount(stage);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text("$stage ($count)"),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStage = stage;
                    _selectedAppIds.clear();
                    _selectedCandidateIds.clear();
                  });
                  _loadApplications();
                }
              },
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white,
              selectedColor: AppColors.getPrimary(isDark),
              labelStyle: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white10 : Colors.grey[300]!),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getStageCount(String stage) {
    if (stage == 'All') {
      int sum = 0;
      _pipelineStats.forEach((key, val) {
        sum += (int.tryParse(val.toString()) ?? 0);
      });
      return sum;
    }

    for (var entry in _pipelineStats.entries) {
      if (entry.key.toString().toLowerCase() == stage.toLowerCase()) {
        return int.tryParse(entry.value.toString()) ?? 0;
      }
    }
    return 0;
  }

  Widget _buildCandidateItemCard(Map<String, dynamic> app, bool isDark) {
    final appId = app['application_id']?.toString() ?? '';
    final candidateId = app['candidate_id']?.toString() ?? '';
    final name = app['candidate_name'] ?? 'Candidate';
    final email = app['candidate_email'] ?? '';
    final matchScore =
        double.tryParse(app['match_score']?.toString() ?? '0') ?? 0;
    final statusKey =
        app['status_key']?.toString() ??
        app['status']?.toString().toLowerCase() ??
        'applied';
    final experience = app['experience']?.toString() ?? '';
    final appliedAt = app['applied_at'] != null
        ? DateFormat(
            'dd MMM, yyyy',
          ).format(DateTime.tryParse(app['applied_at']) ?? DateTime.now())
        : '-';

    final isSelected = _selectedAppIds.contains(appId);
    final isRecommended = matchScore >= 70;

    // Skills
    List<String> matchedSkills =
        (app['matched_skills'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    List<String> missingSkills =
        (app['missing_skills'] as List?)?.map((e) => e.toString()).toList() ??
        [];

    final cardBg = isDark ? AppColors.getCard(isDark) : Colors.white;
    final borderColor = isSelected
        ? AppColors.getPrimary(isDark)
        : (isDark ? Colors.white10 : const Color(0xFFD9ECE5));
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.getPrimary(isDark),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedAppIds.add(appId);
                        _selectedCandidateIds.add(candidateId);
                      } else {
                        _selectedAppIds.remove(appId);
                        _selectedCandidateIds.remove(candidateId);
                      }
                    });
                  },
                ),
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                ),
                // Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF16212B),
                              ),
                            ),
                          ),
                          _buildStagePill(statusKey, isDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          if (experience.isNotEmpty) ...[
                            Icon(Icons.work_outline, size: 12, color: subtext),
                            Text(
                              experience,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: subtext,
                              ),
                            ),
                          ],
                          Text(
                            '•',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subtext,
                            ),
                          ),
                          Text(
                            'Applied $appliedAt',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subtext,
                            ),
                          ),
                        ],
                      ),
                      if (isRecommended) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recommended',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),

          // Body Grid: Left Skills, Right Sidebar
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Skills Panel
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildActivitySection(app, isDark),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
                // Right Sidebar
                Expanded(
                  flex: 2,
                  child: Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ATS Score
                        _buildAtsScoreBar(matchScore, isDark),
                        const SizedBox(height: 12),
                        // Communication Stack
                        _buildCommunicationStack(app, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),

          // Action Icon Bar
          _buildActionIconBar(app, isDark),
        ],
      ),
    );
  }

  Widget _buildActivitySection(Map<String, dynamic> app, bool isDark) {
    int profileViews = 1;
    int resumeDownloads = 1;
    String lastActive = "Jun 17, 2026";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Activity Snapshot',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.getPrimary(isDark),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              '$profileViews profile views',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.download_outlined,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              '$resumeDownloads resume downloads',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              'Last active $lastActive',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillMatchPanel(
    List<String> matched,
    List<String> missing,
    bool isDark,
  ) {
    if (matched.isEmpty && missing.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matched Skills',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.getPrimary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No required skills matched',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matched Skills',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.getPrimary(isDark),
          ),
        ),
        const SizedBox(height: 6),
        if (matched.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: matched
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2A2F)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF23343A)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF1FB7B5)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
        ] else ...[
          Text(
            'No required skills matched',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (missing.isNotEmpty) ...[
          Text(
            'Missing Skills',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.red[300] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: missing
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.red.withValues(alpha: 0.1)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? Colors.red.withValues(alpha: 0.2)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.red[300] : Colors.red[700],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAtsScoreBar(double matchScore, bool isDark) {
    Color scoreColor = Colors.red;
    if (matchScore >= 75)
      scoreColor = const Color(0xFF1FB7B5);
    else if (matchScore >= 50)
      scoreColor = Colors.orange;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATS Match',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: matchScore.clamp(0, 100) / 100,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${matchScore.round()}%',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: scoreColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationStack(Map<String, dynamic> app, bool isDark) {
    final comm = app['communication'] as Map<String, dynamic>? ?? {};
    final emailCount = comm['email_count'] as int? ?? 0;
    final msgCount = comm['message_count'] as int? ?? 0;
    final latestPreview = comm['latest_preview']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showCandidateReviewDrawer(app, isDark),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (emailCount > 0) ...[
                  Icon(Icons.email_outlined, size: 10, color: Colors.blue[400]),
                  const SizedBox(width: 2),
                  Text(
                    '$emailCount',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (msgCount > 0) ...[
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 10,
                    color: Colors.green[400],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$msgCount',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[400],
                    ),
                  ),
                ],
                if (emailCount == 0 && msgCount == 0)
                  Text(
                    'No activity',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                  ),
              ],
            ),
            if (latestPreview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                latestPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconBar(
    Map<String, dynamic> app,
    bool isDark,
  ) {
    final appId = app['application_id']?.toString() ?? '';
    final candidateId = app['candidate_id']?.toString() ?? '';
    final statusKey = app['status_key']?.toString() ?? app['status']?.toString().toLowerCase() ?? 'applied';
    final name = app['candidate_name']?.toString() ?? 'Candidate';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _iconAction(
            Icons.check_circle_outline,
            'Shortlist',
            Colors.green,
            () => _updateStatus(appId, 'shortlisted'),
            isDark,
          ),
          _iconAction(
            Icons.calendar_today_outlined,
            'Schedule',
            Colors.orange,
            () => _showScheduleInterviewModal(app, isDark),
            isDark,
          ),
          _iconAction(
            Icons.pause_circle_outline,
            'Hold',
            Colors.amber,
            () => _updateStatus(appId, 'hold'),
            isDark,
          ),
          _iconAction(
            Icons.cancel_outlined,
            'Reject',
            Colors.red,
            () => _updateStatus(appId, 'rejected'),
            isDark,
          ),
          Container(
            width: 1,
            height: 20,
            color: isDark ? Colors.white10 : Colors.grey[300],
          ),
          _iconAction(
            Icons.person_outline,
            'Profile',
            AppColors.getPrimary(isDark),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandidateProfileViewScreen(
                    candidateId: candidateId,
                    applicationId: appId,
                    jobId: widget.job.jobId,
                    candidateName: name,
                  ),
                ),
              ).then((_) => _loadApplications());
            },
            isDark,
          ),
          _iconAction(
            Icons.description_outlined,
            'Resume',
            AppColors.getPrimary(isDark),
            () => _downloadResume(candidateId, appId),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _iconAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleInterviewModal(Map<String, dynamic> app, bool isDark) {
    final appId = app['application_id']?.toString() ?? '';
    final candidateName = app['candidate_name']?.toString() ?? 'Candidate';

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String duration = '60';
    String mode = 'online';
    TextEditingController locationController = TextEditingController();
    TextEditingController messageController = TextEditingController();
    bool sendEmail = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule Interview',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text('with $candidateName', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildModalField('Date', InkWell(onTap: () async { final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if (date != null) setState(() => selectedDate = date); }, child: _buildInputBox(selectedDate != null ? DateFormat('MMM dd, yyyy').format(selectedDate!) : 'Select date', isDark)), isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildModalField('Time', InkWell(onTap: () async { final time = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (time != null) setState(() => selectedTime = time); }, child: _buildInputBox(selectedTime != null ? selectedTime!.format(context) : 'Select time', isDark)), isDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildModalField('Duration', DropdownButtonFormField<String>(value: duration, dropdownColor: isDark ? const Color(0xFF16212B) : Colors.white, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8))), items: ['30', '45', '60', '90'].map((e) => DropdownMenuItem(value: e, child: Text('$e minutes'))).toList(), onChanged: (v) => setState(() => duration = v!)), isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildModalField('Mode', DropdownButtonFormField<String>(value: mode, dropdownColor: isDark ? const Color(0xFF16212B) : Colors.white, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8))), items: const [DropdownMenuItem(value: 'online', child: Text('Online')), DropdownMenuItem(value: 'phone', child: Text('Phone')), DropdownMenuItem(value: 'in_person', child: Text('In person'))], onChanged: (v) => setState(() => mode = v!)), isDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModalField('Meeting link or location', TextField(controller: locationController, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: 'Google Meet link, office address, etc.', hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8)))), isDark),
                    const SizedBox(height: 16),
                    _buildModalField('Message to candidate', TextField(controller: messageController, maxLines: 3, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: 'Add context, preparation notes, etc.', hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8)))), isDark),
                    const SizedBox(height: 16),
                    CheckboxListTile(title: Text('Send email invitation to candidate', style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black)), value: sendEmail, onChanged: (v) => setState(() => sendEmail = v ?? true), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: const Color(0xFF1FB7B5)),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(icon: const Icon(Icons.send, size: 18), label: Text('Send Invitation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1FB7B5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () { Navigator.pop(context); _updateStatus(appId, 'interview_slot_booked'); })),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField(String label, Widget input, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
        const SizedBox(height: 6),
        input,
      ],
    );
  }

  Widget _buildInputBox(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: text.startsWith('Select') ? Colors.grey : (isDark ? Colors.white : Colors.black))),
    );
  }

  void _showCandidateReviewDrawer(Map<String, dynamic> app, bool isDark) {
    final name = app['candidate_name'] ?? 'Candidate';
    final statusKey =
        app['status_key']?.toString() ??
        app['status']?.toString().toLowerCase() ??
        'applied';
    final matchScore =
        double.tryParse(app['match_score']?.toString() ?? '0') ?? 0;
    final experience = app['experience']?.toString() ?? '';
    final location = app['location']?.toString() ?? '';
    final appliedAt = app['applied_at'] != null
        ? DateFormat(
            'dd MMM, yyyy',
          ).format(DateTime.tryParse(app['applied_at']) ?? DateTime.now())
        : '-';

    // Skills
    final rawSkills = app['skills'];
    List<String> candidateSkills = [];
    if (rawSkills is List) {
      candidateSkills = rawSkills.map((s) => s.toString()).toList();
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      candidateSkills = rawSkills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<String> matchedSkills =
        (app['matched_skills'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    List<String> missingSkills =
        (app['missing_skills'] as List?)?.map((e) => e.toString()).toList() ??
        [];

    final comm = app['communication'] as Map<String, dynamic>? ?? {};
    final items = comm['items'] as List<dynamic>? ?? [];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        bool isLoadingContact = false;
        bool contactVisible = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                elevation: 16,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: double.infinity,
                  color: isDark ? AppColors.bgDark : Colors.white,
                  child: SafeArea(
                    left: false,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.getCard(isDark) : const Color(0xFFF8FAFC),
                            border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildStagePill(statusKey, isDark),
                                        const SizedBox(width: 8),
                                        if (location.isNotEmpty) ...[
                                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 2),
                                          Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]))),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                        // Body
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDrawerStat('${matchScore.round()}%', 'ATS Match', isDark),
                                  _buildDrawerStat(experience.isEmpty ? '-' : experience, 'Experience', isDark),
                                  _buildDrawerStat(appliedAt, 'Applied', isDark),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Skills Section
                              Text('Matched Requirements', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                              const SizedBox(height: 12),
                              if (candidateSkills.isNotEmpty) ...[
                                Text('Key Skills', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: candidateSkills.map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                    child: Text(s, style: GoogleFonts.inter(fontSize: 9.5, color: isDark ? Colors.white70 : Colors.black87)),
                                  )).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildSkillMatchPanel(matchedSkills, missingSkills, isDark),
                              const SizedBox(height: 24),
                              // Timeline
                              Text('Communication Timeline', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                              const SizedBox(height: 12),
                              if (items.isEmpty)
                                Text('No communication history yet.', style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic))
                              else
                                ...items.map((item) => _buildTimelineItem(item, isDark)),
                            ],
                          ),
                        ),
                        // Bottom View Contact Action
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.getCard(isDark) : Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                          ),
                          child: contactVisible
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, color: Colors.blue, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              app['candidate_email']?.toString() ?? 'No email provided',
                                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, color: Colors.green, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              (app['candidate_phone']?.toString() ?? '').isNotEmpty ? app['candidate_phone'].toString() : 'No phone provided',
                                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1FB7B5),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: isLoadingContact
                                        ? null
                                        : () async {
                                            setState(() => isLoadingContact = true);
                                            await Future.delayed(const Duration(seconds: 1)); // Mock loading
                                            setState(() {
                                              isLoadingContact = false;
                                              contactVisible = true;
                                            });
                                          },
                                    child: isLoadingContact
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.remove_red_eye_outlined, size: 18),
                                              const SizedBox(width: 8),
                                              Text('View Contact', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }

  Widget _buildDrawerStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      ],
    );
  }


  Widget _buildTimelineItem(Map<String, dynamic> item, bool isDark) {
    final isIncoming = item['direction'] == 'incoming';
    final type = item['type']?.toString() ?? 'message';
    final icon = type == 'email'
        ? Icons.email_outlined
        : Icons.chat_bubble_outline;
    final color = type == 'email' ? Colors.blue : Colors.green;
    final at = item['at'] != null
        ? DateFormat(
            'MMM dd, hh:mm a',
          ).format(DateTime.tryParse(item['at'].toString()) ?? DateTime.now())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isIncoming ? 'Received from Candidate' : 'Sent by You',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      at,
                      style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
                if (item['subject'] != null &&
                    item['subject'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['subject'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  item['preview']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePill(String status, bool isDark) {
    Color color = Colors.grey;
    String display = status.toUpperCase();

    if (status.contains('applied')) {
      color = Colors.blue;
      display = 'APPLIED';
    } else if (status.contains('shortlisted')) {
      color = Colors.green;
      display = 'SHORTLISTED';
    } else if (status.contains('interview')) {
      color = Colors.orange;
      display = 'INTERVIEW';
    } else if (status.contains('selected') || status.contains('offer')) {
      color = Colors.teal;
      display = 'OFFER';
    } else if (status.contains('hired')) {
      color = Colors.purple;
      display = 'HIRED';
    } else if (status.contains('hold')) {
      color = Colors.amber;
      display = 'ON HOLD';
    } else if (status.contains('rejected')) {
      color = Colors.red;
      display = 'REJECTED';
    } else if (status.contains('withdrawn')) {
      color = Colors.deepOrange;
      display = 'WITHDRAWN';
    } else if (status.contains('screening') || status.contains('ai_')) {
      color = Colors.indigo;
      display = 'SCREENING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        display,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(String appId, String currentStatus, bool isDark) {
    final List<Map<String, String>> statusOptions = [
      {'display': 'Applied', 'value': 'applied'},
      {'display': 'Screening', 'value': 'screening'},
      {'display': 'Shortlist', 'value': 'shortlisted'},
      {'display': 'Interview', 'value': 'interview_slot_booked'},
      {'display': 'Offer', 'value': 'selected'},
      {'display': 'Hired', 'value': 'hired'},
      {'display': 'On Hold', 'value': 'hold'},
      {'display': 'Reject', 'value': 'rejected'},
      {'display': 'Withdrawn', 'value': 'withdrawn'},
    ];

    String selectedVal = 'applied';
    if (statusOptions.any((opt) => opt['value'] == currentStatus)) {
      selectedVal = currentStatus;
    } else if (currentStatus.contains('interview')) {
      selectedVal = 'interview_slot_booked';
    } else if (currentStatus.contains('selected') ||
        currentStatus.contains('offer')) {
      selectedVal = 'selected';
    } else if (currentStatus.contains('hold')) {
      selectedVal = 'hold';
    } else if (currentStatus.contains('screening') ||
        currentStatus.contains('ai_')) {
      selectedVal = 'screening';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVal,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onChanged: (val) {
            if (val != null && val != selectedVal) {
              _updateStatus(appId, val);
            }
          },
          items: statusOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'],
              child: Text(opt['display']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- TAB 2: INTERVIEWS ---
  Map<String, int> _getInterviewStats() {
    int total = _interviews.length;
    int upcoming = 0;
    int completed = 0;
    int bookedSlots = 0;

    final now = DateTime.now();
    for (var booking in _interviews) {
      final status =
          booking['booking_status']?.toString().toLowerCase() ?? 'booked';
      final dtStr = booking['slot_datetime']?.toString() ?? '';
      DateTime? dt;
      if (dtStr.isNotEmpty) {
        dt = DateTime.tryParse(dtStr);
      }

      if (status == 'completed') {
        completed++;
      } else if (dt != null && dt.isAfter(now)) {
        upcoming++;
      } else if (dt != null && dt.isBefore(now)) {
        completed++;
      }
    }

    for (var slot in _slots) {
      final bookedCount =
          int.tryParse(slot['booked_count']?.toString() ?? '0') ?? 0;
      if (bookedCount > 0) {
        bookedSlots++;
      }
    }

    return {
      'total': total,
      'upcoming': upcoming,
      'completed': completed,
      'booked_slots': bookedSlots,
    };
  }

  Widget _buildInterviewStatsRow(Map<String, int> stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard(
            'Total Bookings',
            stats['total'] ?? 0,
            Icons.collections_bookmark_rounded,
            Colors.blue,
            isDark,
          ),
          _buildStatCard(
            'Upcoming',
            stats['upcoming'] ?? 0,
            Icons.upcoming_rounded,
            Colors.orange,
            isDark,
          ),
          _buildStatCard(
            'Completed',
            stats['completed'] ?? 0,
            Icons.check_circle_rounded,
            Colors.green,
            isDark,
          ),
          _buildStatCard(
            'Booked Slots',
            stats['booked_slots'] ?? 0,
            Icons.calendar_today_rounded,
            Colors.purple,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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

  Widget _buildInterviewsTab(bool isDark) {
    if (_isLoadingInterviews) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_interviewsError != null) {
      return _buildErrorWidget(_interviewsError!, _loadInterviews);
    }

    final stats = _getInterviewStats();

    return RefreshIndicator(
      onRefresh: _loadInterviews,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInterviewStatsRow(stats, isDark),
            const SizedBox(height: 20),
            _buildBookedInterviewsList(isDark),
            const SizedBox(height: 28),
            _buildSlotCapacityList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedInterviewsList(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
            child: Text(
              'Booked Interviews',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          if (_interviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No interview bookings yet',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _interviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = _interviews[index];
                final id = booking['id']?.toString() ?? '';
                final name = booking['candidate_name'] ?? 'Candidate';
                final email = booking['candidate_email'] ?? '';
                final status =
                    booking['booking_status'] ??
                    booking['interview_type'] ??
                    'booked';

                final slotDate = booking['slot_date'] ?? '';
                final slotTime = booking['slot_time'] ?? '';
                final slotDatetimeStr =
                    booking['slot_datetime'] ?? booking['interview_date'] ?? '';

                DateTime? dt;
                if (slotDatetimeStr.isNotEmpty) {
                  dt = DateTime.tryParse(slotDatetimeStr);
                } else if (slotDate.isNotEmpty) {
                  dt = DateTime.tryParse("$slotDate $slotTime");
                }

                final formattedDate = dt != null
                    ? DateFormat('MMM dd, yyyy').format(dt)
                    : (slotDate.isNotEmpty ? slotDate : '-');
                final formattedTime = dt != null
                    ? DateFormat('hh:mm a').format(dt)
                    : (slotTime.isNotEmpty ? slotTime : '-');

                final bookingStatus = status.toString().toLowerCase();

                final isPast = dt != null
                    ? dt.isBefore(DateTime.now())
                    : ['completed', 'no_show'].contains(bookingStatus);
                final isUpcoming = dt != null
                    ? dt.isAfter(DateTime.now())
                    : !isPast;

                final hasReview =
                    booking['review_id'] != null ||
                    booking['review_attendance_status'] != null;

                final bookedAtStr =
                    booking['booked_at'] ?? booking['created_at'] ?? '';
                DateTime? bookedDt;
                if (bookedAtStr.isNotEmpty) {
                  bookedDt = DateTime.tryParse(bookedAtStr);
                }
                final formattedBookedAt = bookedDt != null
                    ? DateFormat('MMM dd, yyyy').format(bookedDt)
                    : '-';

                final bool showReschedule =
                    isUpcoming &&
                    [
                      'booked',
                      'confirmed',
                      'rescheduled',
                    ].contains(bookingStatus);
                final bool showReview =
                    isPast ||
                    [
                      'completed',
                      'no_show',
                      'rescheduled',
                    ].contains(bookingStatus);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Date & Time + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: AppColors.getPrimary(isDark),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$formattedDate at $formattedTime',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildInterviewStatusPill(status, isDark),
                              if (hasReview)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Reviewed',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Middle: Candidate Info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bottom Row: Booked On + Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Booked: $formattedBookedAt',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              if (showReschedule) ...[
                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final recruiterId =
                                          Provider.of<AuthController>(
                                            context,
                                            listen: false,
                                          ).currentRecruiter?.id;
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RecruiterRescheduleInterviewScreen(
                                                bookingId: id,
                                                recruiterId:
                                                    recruiterId?.toString() ??
                                                    '',
                                              ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadInterviews();
                                      }
                                    },
                                    icon: const Icon(Icons.sync, size: 14),
                                    label: const Text('Reschedule'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (showReview) ...[
                                SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openWebUrl(
                                      "recruiter/slots/review/$id",
                                    ),
                                    icon: const Icon(
                                      Icons.rate_review,
                                      size: 14,
                                    ),
                                    label: Text(
                                      hasReview ? 'Edit Review' : 'Review',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.getPrimary(
                                        isDark,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      side: BorderSide(
                                        color: AppColors.getPrimary(isDark),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCapacityList(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slot Capacity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSlotScreen(job: widget.job),
                      ),
                    );
                    if (result == true) {
                      _loadInterviews();
                    }
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Create New Slots'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getPrimary(isDark),
                    side: BorderSide(color: AppColors.getPrimary(isDark)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_view_day_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No slots found for this job',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'ID',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Time',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Capacity',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Booked',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Created By',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _slots.map<DataRow>((slot) {
                  final id = slot['id']?.toString() ?? '';
                  final slotDate = slot['slot_date'] ?? '';
                  final slotTime = slot['slot_time'] ?? '';
                  final slotDatetimeStr = slot['slot_datetime'] ?? '';

                  DateTime? dt;
                  if (slotDatetimeStr.isNotEmpty) {
                    dt = DateTime.tryParse(slotDatetimeStr);
                  } else if (slotDate.isNotEmpty) {
                    dt = DateTime.tryParse("$slotDate $slotTime");
                  }

                  final formattedDate = dt != null
                      ? DateFormat('MMM dd, yyyy').format(dt)
                      : slotDate;
                  final formattedTime = dt != null
                      ? DateFormat('hh:mm a').format(dt)
                      : slotTime;

                  final capacity = slot['capacity'] ?? 1;
                  final bookedCount = slot['booked_count'] ?? 0;
                  final createdBy = slot['created_by_name'] ?? 'System';

                  final isPastSlot = dt != null && dt.isBefore(DateTime.now());
                  final isFull = bookedCount >= capacity;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isPastSlot
                          ? (isDark ? Colors.white10 : Colors.grey[50])
                          : (isFull && !isDark ? Colors.orange[50] : null),
                    ),
                    cells: [
                      DataCell(Text(id, style: GoogleFonts.inter())),
                      DataCell(Text(formattedDate, style: GoogleFonts.inter())),
                      DataCell(
                        Text(
                          formattedTime,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(capacity.toString(), style: GoogleFonts.inter()),
                      ),
                      DataCell(
                        Text(
                          bookedCount.toString(),
                          style: GoogleFonts.inter(),
                        ),
                      ),
                      DataCell(
                        _buildSlotStatusPill(isPastSlot, isFull, isDark),
                      ),
                      DataCell(Text(createdBy, style: GoogleFonts.inter())),
                      DataCell(
                        Row(
                          children: [
                            if (bookedCount == 0) ...[
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditSlotScreen(
                                        slot: slot,
                                        job: widget.job,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadInterviews();
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.getPrimary(isDark),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.getPrimary(isDark),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _deleteSlot(id),
                                icon: const Icon(Icons.delete, size: 14),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Has bookings',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterviewStatusPill(String status, bool isDark) {
    Color color = Colors.grey;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'booked':
        color = Colors.blue;
        label = 'Booked';
        break;
      case 'confirmed':
        color = Colors.green;
        label = 'Confirmed';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'Completed';
        break;
      case 'rescheduled':
        color = Colors.orange;
        label = 'Rescheduled';
        break;
      case 'no_show':
        color = Colors.red;
        label = 'No Show';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSlotStatusPill(bool isPast, bool isFull, bool isDark) {
    Color color = Colors.grey;
    String label = 'Available';

    if (isPast) {
      color = Colors.grey;
      label = 'Past';
    } else if (isFull) {
      color = Colors.red;
      label = 'Full';
    } else {
      color = Colors.teal;
      label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- TAB 3: LEADERBOARD ---
  Widget _buildLeaderboardTab(bool isDark) {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_leaderboardError != null) {
      return _buildErrorWidget(_leaderboardError!, _loadLeaderboard);
    }
    if (_leaderboard.isEmpty) {
      return _buildEmptyState('No candidates ranked on the leaderboard.');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _leaderboard[index];
          final rank = index + 1;
          final name = item['candidate_name'] ?? item['name'] ?? 'Candidate';
          final email = item['candidate_email'] ?? item['email'] ?? '';
          final jobTitle = item['job_title'] ?? widget.job.jobTitle;

          final overall =
              double.tryParse(item['overall_rating']?.toString() ?? '0') ?? 0;
          final technical =
              double.tryParse(item['technical_score']?.toString() ?? '0') ?? 0;
          final communication =
              double.tryParse(item['communication_score']?.toString() ?? '0') ??
              0;
          final atsScore =
              double.tryParse(item['ats_score']?.toString() ?? '0') ?? 0;
          final skillMatch =
              int.tryParse(item['skill_match']?.toString() ?? '0') ?? 0;

          final candidateId = item['candidate_id']?.toString() ?? '';
          final appId =
              item['id']?.toString() ??
              item['application_id']?.toString() ??
              '';
          final statusKey = item['status']?.toString() ?? 'applied';

          // Extract arrays
          List<String> candSkills = [];
          if (item['candidate_skills'] is List) {
            candSkills = (item['candidate_skills'] as List)
                .map((e) => e.toString())
                .toList();
          }
          List<String> reqSkills = [];
          if (item['required_skills'] is List) {
            reqSkills = (item['required_skills'] as List)
                .map((e) => e.toString())
                .toList();
          }
          List<String> github = [];
          if (item['github_stack'] is List) {
            github = (item['github_stack'] as List)
                .map((e) => e.toString())
                .toList();
          }

          final candSkillsLower = candSkills
              .map((s) => s.toLowerCase())
              .toList();
          final matchedCount = reqSkills
              .where((s) => candSkillsLower.contains(s.toLowerCase()))
              .length;

          final cardBg = isDark ? AppColors.getCard(isDark) : Colors.white;
          final borderColor = rank <= 3
              ? (rank == 1
                    ? Colors.amber.withValues(alpha: 0.6)
                    : (rank == 2
                          ? Colors.blueGrey.withValues(alpha: 0.6)
                          : Colors.brown.withValues(alpha: 0.6)))
              : (isDark ? Colors.white10 : const Color(0xFFD9ECE5));
          final subtext = isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B);

          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: rank <= 3 ? 1.5 : 1,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Rank + Name/Email + Job Title + ATS
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRankBadge(rank),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF16212B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: subtext,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.getPrimary(isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildLeaderboardAtsCell(atsScore, isDark),
                    ],
                  ),
                ),

                // 2. Skills Match (Required Skills)
                if (reqSkills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1B2A2F)
                                    : const Color(0xFFEDF8F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$skillMatch% Match',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($matchedCount/${reqSkills.length})',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: subtext,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: reqSkills.map((skill) {
                            final hasSkill = candSkillsLower.contains(
                              skill.toLowerCase(),
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF162327)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF23343A)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill,
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      color: subtext,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    hasSkill
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 10,
                                    color: hasSkill ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                // 3. GitHub Stack
                if (github.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.code, size: 14, color: subtext),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children:
                                github.take(6).map((lang) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1B2A2F)
                                          : const Color(0xFFEDF8F5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      lang,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        color: AppColors.getPrimary(isDark),
                                      ),
                                    ),
                                  );
                                }).toList()..addAll(
                                  github.length > 6
                                      ? [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white10
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+${github.length - 6}',
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                color: subtext,
                                              ),
                                            ),
                                          ),
                                        ]
                                      : [],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 4. Scores Row (Technical, Communication, Overall)
                Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildLeaderboardScoreMetric(
                          'Technical',
                          technical,
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildLeaderboardScoreMetric(
                          'Communication',
                          communication,
                          isDark,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Overall',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: subtext,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.getPrimary(
                                isDark,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.getPrimary(isDark),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  overall.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getPrimary(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Bottom Row: Status Pill + Actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildStagePill(statusKey, isDark),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _downloadResume(
                          candidateId,
                          appId.isNotEmpty ? appId : null,
                        ),
                        icon: Icon(
                          Icons.description_outlined,
                          size: 13,
                          color: AppColors.getPrimary(isDark),
                        ),
                        label: Text(
                          'Resume',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: AppColors.getPrimary(isDark),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CandidateProfileViewScreen(
                                candidateId: candidateId,
                                applicationId: appId.isNotEmpty ? appId : null,
                                jobId: widget.job.jobId,
                                candidateName: name,
                              ),
                            ),
                          ).then((_) => _loadLeaderboard());
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Colors.white,
                        ),
                        label: Text(
                          'View',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color = Colors.grey[700]!;
    if (rank == 1) {
      color = Colors.amber[700]!;
    } else if (rank == 2) {
      color = Colors.blueGrey[400]!;
    } else if (rank == 3) {
      color = Colors.brown[400]!;
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "#$rank",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardAtsCell(double score, bool isDark) {
    Color scoreTextColor = const Color(0xFF991B1B);
    Color scoreBarColor = Colors.red;
    if (score >= 75) {
      scoreTextColor = const Color(0xFF065F46);
      scoreBarColor = const Color(0xFF1FB7B5);
    } else if (score >= 50) {
      scoreTextColor = const Color(0xFF92400E);
      scoreBarColor = Colors.orange;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${score.round()}%',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: scoreTextColor,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 50,
            height: 4,
            child: LinearProgressIndicator(
              value: score.clamp(0, 100) / 100,
              backgroundColor: isDark
                  ? const Color(0xFF23343A)
                  : const Color(0xFFD9ECE5),
              valueColor: AlwaysStoppedAnimation<Color>(scoreBarColor),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ATS Match',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: isDark ? const Color(0xFF4A5C63) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardScoreMetric(String label, double score, bool isDark) {
    Color scoreTextColor = const Color(0xFF991B1B);
    Color scoreBarColor = Colors.red;
    if (score >= 80) {
      scoreTextColor = const Color(0xFF065F46);
      scoreBarColor = const Color(0xFF1FB7B5);
    } else if (score >= 60) {
      scoreTextColor = const Color(0xFF92400E);
      scoreBarColor = Colors.orange;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          score.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scoreTextColor,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 45,
            height: 4,
            child: LinearProgressIndicator(
              value: score.clamp(0, 100) / 100,
              backgroundColor: isDark
                  ? const Color(0xFF23343A)
                  : const Color(0xFFD9ECE5),
              valueColor: AlwaysStoppedAnimation<Color>(scoreBarColor),
            ),
          ),
        ),
      ],
    );
  }

  // --- FLOATING BULK ACTION BAR ---
  Widget _buildBulkActionBar(bool isDark) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getPrimary(isDark).withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${_selectedAppIds.length}",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Candidates Selected",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent, width: 1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAppIds.clear();
                              _selectedCandidateIds.clear();
                            });
                          },
                          child: Text(
                            'Clear Selections',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildActionIconButton(
                  icon: Icons.mail_rounded,
                  label: 'Email',
                  color: AppColors.getPrimary(isDark),
                  isDark: isDark,
                  onTap: _showBulkEmailDialog,
                ),
                _buildActionIconButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Msg',
                  color: Colors.blue,
                  isDark: isDark,
                  onTap: _showBulkMessageDialog,
                ),
                _buildActionIconButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Shortlist',
                  color: Colors.green,
                  isDark: isDark,
                  onTap: () => _bulkUpdateStatus('shortlisted'),
                ),
                _buildActionIconButton(
                  icon: Icons.cancel_rounded,
                  label: 'Reject',
                  color: Colors.red,
                  isDark: isDark,
                  onTap: () => _bulkUpdateStatus('rejected'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GENERAL WIDGETS ---
  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'An error occurred',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
