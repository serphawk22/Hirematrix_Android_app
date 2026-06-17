import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';

class CandidateProfileViewScreen extends StatefulWidget {
  final String candidateId;
  final String? applicationId;
  final String? jobId;
  final String candidateName;

  const CandidateProfileViewScreen({
    super.key,
    required this.candidateId,
    this.applicationId,
    this.jobId,
    required this.candidateName,
  });

  @override
  State<CandidateProfileViewScreen> createState() =>
      _CandidateProfileViewScreenState();
}

class _CandidateProfileViewScreenState extends State<CandidateProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _showContact = false;

  // Notes controller
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;

  // Invite controller
  String? _selectedJobId;
  final TextEditingController _inviteMessageController =
      TextEditingController();
  bool _isSendingInvite = false;

  // Message controller
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    _inviteMessageController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recruiterId = Provider.of<AuthController>(
        context,
        listen: false,
      ).currentRecruiter?.id;
      if (recruiterId == null) {
        setState(() {
          _error = "Session expired. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      final res = await ApiService().fetchCandidateProfile(
        recruiterId,
        widget.candidateId,
        applicationId: widget.applicationId,
        jobId: widget.jobId,
      );

      if (res['success'] == true) {
        setState(() {
          _data = res;
          _isLoading = false;
          _showContact = res['application_id'] != null || res['job_id'] != null;
          // Set tags and notes if present
          final note = res['recruiter_note'];
          if (note != null) {
            _tagsController.text = note['tags']?.toString() ?? '';
            _notesController.text = note['notes']?.toString() ?? '';
          }
        });
      } else {
        setState(() {
          _error =
              res['message']?.toString() ?? "Failed to load candidate details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _revealContact() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    try {
      final res = await ApiService().logCandidateAction(
        recruiterId,
        widget.candidateId,
        'contact',
        applicationId: widget.applicationId,
        jobId: widget.jobId,
      );

      if (res['success'] == true) {
        setState(() {
          _showContact = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact details unlocked and viewed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unlock contact: $e')));
    }
  }

  Future<void> _downloadResume() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    try {
      final baseUrl = await ApiService().getBaseUrl();
      final url =
          "$baseUrl/candidates/${widget.candidateId}/resume"
          "?recruiter_id=$recruiterId"
          "&application_id=${widget.applicationId ?? ''}"
          "&job_id=${widget.jobId ?? ''}";

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening resume download link...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open resume link.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading resume: $e')));
    }
  }

  Future<void> _saveNotes() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isSavingNotes = true;
    });

    try {
      final res = await ApiService().saveCandidateNotes(
        recruiterId,
        widget.candidateId,
        _tagsController.text.trim(),
        _notesController.text.trim(),
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes and tags saved successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save notes.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSavingNotes = false;
      });
    }
  }

  Future<void> _sendInvitation() async {
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an open job role.')),
      );
      return;
    }

    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isSendingInvite = true;
    });

    try {
      final res = await ApiService().inviteCandidate(
        recruiterId,
        widget.candidateId,
        _selectedJobId!,
        _inviteMessageController.text.trim(),
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent to candidate successfully.'),
          ),
        );
        _inviteMessageController.clear();
        _loadProfileData(); // reload invitations list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to send invitation.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSendingInvite = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final res = await ApiService().sendCandidateMessage(
        recruiterId,
        widget.candidateId,
        body,
        applicationId: widget.applicationId,
        jobId: widget.jobId,
      );

      if (res['success'] == true) {
        _messageController.clear();
        _loadProfileData(); // reload thread
        // Scroll to bottom after loading completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to send message.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.candidateName,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          labelColor: AppColors.getPrimary(isDark),
          indicatorColor: AppColors.getPrimary(isDark),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Notes & Invite'),
            Tab(text: 'Messages'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
          ? _buildErrorScreen(isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isDark),
                _buildNotesInviteTab(isDark),
                _buildMessagesTab(isDark),
              ],
            ),
    );
  }

  Widget _buildErrorScreen(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Profile',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    final candidate = _data?['candidate'] ?? {};
    final photoUrl = candidate['profile_photo_url'] ?? '';
    final resumePath = candidate['resume_path'] ?? '';
    final bio = candidate['bio'] ?? '';
    final videoUrl = candidate['intro_video_url'] ?? '';
    final pitch = candidate['intro_video_pitch'] ?? '';
    final targetRole = candidate['intro_video_target_role'] ?? '';

    final workExperiences = _data?['work_experiences'] as List? ?? [];
    final education = _data?['education'] as List? ?? [];
    final certifications = _data?['certifications'] as List? ?? [];
    final projects = _data?['projects'] as List? ?? [];
    final skillsRow = _data?['skills']?['skill_name']?.toString() ?? '';
    final github = _data?['github'] ?? {};
    final interests = _data?['interests'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Avatar, Name, Quick Meta)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (photoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.transparent,
                          backgroundImage: CachedNetworkImageProvider(photoUrl),
                        )
                      else
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.getPrimary(
                            isDark,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            widget.candidateName.isNotEmpty
                                ? widget.candidateName[0].toUpperCase()
                                : 'C',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.candidateName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (candidate['location'] != null &&
                                candidate['location']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    candidate['location'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getPrimary(
                                  isDark,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (candidate['is_fresher_candidate'] == 1 ||
                                        candidate['is_fresher_candidate'] ==
                                            '1')
                                    ? 'Fresher'
                                    : 'Experienced',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!_showContact)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _revealContact,
                            icon: const Icon(Icons.contacts_outlined, size: 16),
                            label: const Text('View Contact'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.getPrimary(isDark),
                              side: BorderSide(
                                color: AppColors.getPrimary(isDark),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (_showContact)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        candidate['email'] ?? 'No email',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (candidate['phone'] != null &&
                                    candidate['phone']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        candidate['phone'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (resumePath.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _downloadResume,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Download Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getPrimary(isDark),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ),
          const SizedBox(height: 16),

          // About / Bio
          if (bio.isNotEmpty) ...[
            _buildSectionHeader('About'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  bio,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.blueGrey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Video Introduction
          if (videoUrl.isNotEmpty || pitch.isNotEmpty) ...[
            _buildSectionHeader('Video Introduction'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (targetRole.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Target Role: $targetRole',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    if (videoUrl.isNotEmpty) ...[
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(videoUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/video_placeholder.png',
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.3,
                            ),
                          ),
                          child: const Center(
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 36,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (pitch.isNotEmpty)
                      Text(
                        pitch,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.blueGrey[800],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Questionnaire Response
          if (_data?['questionnaire_responses'] != null) ...[
            _buildSectionHeader('Questionnaire Responses'),
            // Questionnaire decoding is usually done backend side and exposed
            // If questionnaire items list is passed, render them
          ],

          // Professional Summary
          _buildSectionHeader('Professional Summary'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGridItem(
                      'Experience',
                      _data?['experience_display'] ?? '-',
                      isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  Expanded(
                    child: _buildGridItem(
                      'Joined Portal',
                      candidate['created_at'] != null
                          ? candidate['created_at'].toString().substring(0, 10)
                          : '-',
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skills Badges
          if (skillsRow.isNotEmpty) ...[
            _buildSectionHeader('Skills & Technologies'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skillsRow.split(',').map((skill) {
                return Chip(
                  label: Text(
                    skill.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                  backgroundColor: AppColors.getPrimary(
                    isDark,
                  ).withValues(alpha: 0.08),
                  elevation: 0,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Work Experience
          if (workExperiences.isNotEmpty) ...[
            _buildSectionHeader('Work Experience'),
            ...workExperiences.map((exp) {
              final isCurrent =
                  exp['is_current'] == 1 || exp['is_current'] == '1';
              return _buildTimelineCard(
                title: exp['job_title'] ?? 'Role',
                subtitle:
                    "${exp['company_name'] ?? 'Company'} • ${exp['employment_type'] ?? ''}",
                meta:
                    "${exp['start_date'] ?? ''} - ${isCurrent ? 'Present' : (exp['end_date'] ?? '')}",
                description: exp['description']?.toString(),
                isDark: isDark,
              );
            }),
            const SizedBox(height: 16),
          ],

          // Projects
          if (projects.isNotEmpty) ...[
            _buildSectionHeader('Projects'),
            ...projects.map((proj) {
              return _buildTimelineCard(
                title: proj['project_name'] ?? 'Project',
                subtitle: proj['role_name'] ?? '',
                meta: proj['tech_stack'] ?? '',
                description: proj['project_summary']?.toString(),
                isDark: isDark,
                actionText:
                    proj['project_url'] != null &&
                        proj['project_url'].toString().isNotEmpty
                    ? 'View Project'
                    : null,
                onActionTap:
                    proj['project_url'] != null &&
                        proj['project_url'].toString().isNotEmpty
                    ? () async {
                        final uri = Uri.parse(proj['project_url']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    : null,
              );
            }),
            const SizedBox(height: 16),
          ],

          // Education
          if (education.isNotEmpty) ...[
            _buildSectionHeader('Education'),
            ...education.map((edu) {
              return _buildTimelineCard(
                title: edu['degree'] ?? 'Degree',
                subtitle: edu['institution'] ?? 'Institution',
                meta:
                    "${edu['field_of_study'] ?? ''} • ${edu['start_year'] ?? ''} - ${edu['end_year'] ?? ''}",
                description:
                    edu['grade'] != null && edu['grade'].toString().isNotEmpty
                    ? "Grade: ${edu['grade']}"
                    : null,
                isDark: isDark,
              );
            }),
            const SizedBox(height: 16),
          ],

          // Certifications
          if (certifications.isNotEmpty) ...[
            _buildSectionHeader('Certifications'),
            ...certifications.map((cert) {
              return _buildTimelineCard(
                title: cert['certification_name'] ?? 'Certificate',
                subtitle: cert['issuing_organization'] ?? '',
                meta: "Issued: ${cert['issue_date'] ?? ''}",
                description:
                    cert['credential_id'] != null &&
                        cert['credential_id'].toString().isNotEmpty
                    ? "Credential ID: ${cert['credential_id']}"
                    : null,
                isDark: isDark,
                actionText:
                    cert['credential_url'] != null &&
                        cert['credential_url'].toString().isNotEmpty
                    ? 'View Credential'
                    : null,
                onActionTap:
                    cert['credential_url'] != null &&
                        cert['credential_url'].toString().isNotEmpty
                    ? () async {
                        final uri = Uri.parse(cert['credential_url']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    : null,
              );
            }),
            const SizedBox(height: 16),
          ],

          // GitHub Stats Card
          if (github.isNotEmpty &&
              github['github_username'] != null &&
              github['github_username'].toString().isNotEmpty) ...[
            _buildSectionHeader('GitHub Profile'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(
                    "https://github.com/${github['github_username']}",
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "@${github['github_username']}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Repositories',
                            github['repo_count']?.toString() ?? '0',
                          ),
                          _buildStatColumn(
                            'Commits',
                            github['commit_count']?.toString() ?? '0',
                          ),
                          _buildStatColumn(
                            'GitHub Score',
                            "${github['github_score']?.toString() ?? '0'}/10",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Job Interests
          if (interests.isNotEmpty) ...[
            _buildSectionHeader('Job Interests'),
            ...interests.map((interest) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.getCard(isDark) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interest['job_title'] ?? 'Role Interest',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Type: ${interest['job_type'] ?? 'N/A'} • Expected Salary: ${interest['expected_salary'] ?? 'N/A'}",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.grey,
                      ),
                    ),
                    if (interest['preferred_locations'] != null &&
                        interest['preferred_locations']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Preferred Locations: ${interest['preferred_locations']}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimelineCard({
    required String title,
    required String subtitle,
    required String meta,
    String? description,
    required bool isDark,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                meta,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.grey[300] : Colors.blueGrey[800],
              ),
            ),
          ],
          if (actionText != null && onActionTap != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: AppColors.getPrimary(isDark),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildNotesInviteTab(bool isDark) {
    final recruiterJobs = _data?['recruiter_jobs'] as List? ?? [];
    final rawInvitations = _data?['job_invitations'];
    final Map<dynamic, dynamic> jobInvitations = (rawInvitations is Map)
        ? rawInvitations
        : {};

    // Extract saved tags for the display badges
    final recruiterNoteData = _data?['recruiter_note'] as Map?;
    final savedTagsRaw = recruiterNoteData?['tags']?.toString() ?? '';
    final List<String> existingTags = savedTagsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invite to Apply section
          _buildSectionHeader('Invite to Apply'),
          Text(
            'Send a direct invitation for one of your open roles. The candidate gets an in-app alert and an email if their notification settings allow it.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose open job role',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedJobId,
                        hint: Text(
                          'Select an open job',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        dropdownColor: isDark
                            ? AppColors.bgSoftDark
                            : Colors.white,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: recruiterJobs.map<DropdownMenuItem<String>>((
                          job,
                        ) {
                          final jobIdStr = job['id']?.toString() ?? '';
                          final invite = jobInvitations[jobIdStr];
                          final suffix = invite != null
                              ? " [${invite['status'].toString().toUpperCase()}]"
                              : "";
                          return DropdownMenuItem<String>(
                            value: jobIdStr.isEmpty ? null : jobIdStr,
                            child: Text(
                              "${job['title']}$suffix",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedJobId = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Optional note (Max 500 chars)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(
                    _inviteMessageController,
                    'Add a short personal note about why this role could fit them.',
                    isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSendingInvite ? null : _sendInvitation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSendingInvite
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Invitation'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Notes & Tags section
          _buildSectionHeader('Recruiter Notes & Tags'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existingTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: existingTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Tags (comma separated)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(
                    _tagsController,
                    'e.g. Strong communication, Backend, Immediate joiner',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Private Notes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextInput(
                    _notesController,
                    'Add private notes for this candidate...',
                    isDark,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSavingNotes
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Notes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesTab(bool isDark) {
    final messages = _data?['messages'] as List? ?? [];

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No conversation yet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send a direct message below to start a thread.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isRecruiter = msg['sender_role'] == 'recruiter';
                    final time = msg['created_at'] != null
                        ? DateFormat(
                            'MMM dd, hh:mm a',
                          ).format(DateTime.parse(msg['created_at']))
                        : '';

                    return Column(
                      crossAxisAlignment: isRecruiter
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isRecruiter
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Text(
                              isRecruiter ? 'You' : widget.candidateName,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRecruiter
                                ? AppColors.getPrimary(isDark)
                                : (isDark
                                      ? AppColors.getCard(isDark)
                                      : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['message'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: isRecruiter
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSoftDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Write a message to candidate...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSendingMessage ? null : _sendMessage,
                icon: Icon(
                  Icons.send_rounded,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
