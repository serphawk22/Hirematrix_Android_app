import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/resdex_controller.dart';
import 'package:hirematrix/views/screens/recruiter/candidates/candidate_profile_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';

class ResdexFolderDetailScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const ResdexFolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<ResdexFolderDetailScreen> createState() => _ResdexFolderDetailScreenState();
}

class _ResdexFolderDetailScreenState extends State<ResdexFolderDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _candidates = [];
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final resdex = Provider.of<ResdexController>(context, listen: false);
    
    if (auth.currentRecruiter?.id != null) {
      final response = await resdex.getFolderDetails(
        auth.currentRecruiter!.id.toString(),
        widget.folderId,
      );
      if (mounted) {
        setState(() {
          _candidates = response['candidates'] ?? [];
          _isLoading = false;
        });
      }
    }
  }

  void _removeSelected() async {
    if (_selectedIds.isEmpty) return;

    final auth = Provider.of<AuthController>(context, listen: false);
    final resdex = Provider.of<ResdexController>(context, listen: false);

    if (auth.currentRecruiter?.id != null) {
      final response = await resdex.removeFromFolder(
        auth.currentRecruiter!.id.toString(),
        widget.folderId,
        _selectedIds.toList(),
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidates removed from folder.')),
          );
          setState(() {
            _candidates.removeWhere((c) => _selectedIds.contains(int.parse(c['user_id'].toString())));
            _selectedIds.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to remove.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folderName,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark), fontSize: 18),
            ),
            if (!_isLoading)
              Text(
                '${_candidates.length} candidate${_candidates.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark), fontSize: 13),
              ),
          ],
        ),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _candidates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: AppColors.getTextMuted(isDark)),
                      const SizedBox(height: 16),
                      Text(
                        'No candidates in this folder',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.getTextMuted(isDark)),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedIds.length == _candidates.length && _candidates.isNotEmpty,
                              activeColor: AppColors.getPrimary(isDark),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.clear();
                                    _selectedIds.addAll(_candidates.map((c) => int.parse(c['user_id'].toString())));
                                  } else {
                                    _selectedIds.clear();
                                  }
                                });
                              },
                            ),
                            Text('Select all', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.getTextMuted(isDark), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getCard(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${_selectedIds.length} selected',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark)),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() => _selectedIds.clear()),
                                child: Text('Clear', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark), decoration: TextDecoration.underline)),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: _removeSelected,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                label: const Text('Remove'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildCandidateCard(_candidates[index], isDark);
                          },
                          childCount: _candidates.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate, bool isDark) {
    final candidateId = int.parse(candidate['user_id'].toString());
    final isSelected = _selectedIds.contains(candidateId);
    
    final name = candidate['name'] ?? 'Candidate';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final headline = candidate['headline'] ?? 'No headline provided';
    final location = candidate['location'] ?? '';
    final totalMonths = int.tryParse(candidate['total_experience_months']?.toString() ?? '0') ?? 0;
    final expYears = (totalMonths / 12).floor();
    final addedAtStr = candidate['added_at']?.toString() ?? '';
    String addedDate = '';
    if (addedAtStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(addedAtStr);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        addedDate = 'Added ${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }
    final resumePath = candidate['resume_path']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.getPrimary(isDark).withOpacity(0.05) : AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.getPrimary(isDark) : AppColors.getBorder(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(candidateId);
                    } else {
                      _selectedIds.remove(candidateId);
                    }
                  });
                },
                activeColor: AppColors.getPrimary(isDark),
              ),
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12, top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.getPrimary(isDark), AppColors.getPrimary(isDark).withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getText(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headline,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (location.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 14, color: AppColors.getTextMuted(isDark)),
                              const SizedBox(width: 4),
                              Text(location, style: GoogleFonts.inter(fontSize: 13, color: AppColors.getTextMuted(isDark))),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_center, size: 14, color: AppColors.getTextMuted(isDark)),
                            const SizedBox(width: 4),
                            Text('$expYears yrs exp', style: GoogleFonts.inter(fontSize: 13, color: AppColors.getTextMuted(isDark))),
                          ],
                        ),
                        if (addedDate.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: AppColors.getTextMuted(isDark)),
                              const SizedBox(width: 4),
                              Text(addedDate, style: GoogleFonts.inter(fontSize: 13, color: AppColors.getTextMuted(isDark))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.remove_red_eye, size: 14),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CandidateProfileViewScreen(
                                  candidateId: candidateId.toString(),
                                  candidateName: name,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.getBorder(isDark)),
                            foregroundColor: AppColors.getText(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          label: const Text('View Profile'),
                        ),
                        if (resumePath.isNotEmpty)
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                final apiService = ApiService();
                                final baseUrl = await apiService.getBaseUrl();
                                final auth = Provider.of<AuthController>(context, listen: false);
                                final recruiterId = auth.currentRecruiter?.id ?? '';
                                final uri = Uri.parse('$baseUrl/candidates/$candidateId/resume?recruiter_id=$recruiterId');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open resume URL')));
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.getBorder(isDark)),
                              foregroundColor: AppColors.getText(isDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                            child: const Text('Resume'),
                          ),
                        OutlinedButton(
                          onPressed: () async {
                            final auth = Provider.of<AuthController>(context, listen: false);
                            final resdex = Provider.of<ResdexController>(context, listen: false);
                            if (auth.currentRecruiter?.id != null) {
                              final res = await resdex.removeFromFolder(auth.currentRecruiter!.id.toString(), widget.folderId, [candidateId]);
                              if (mounted) {
                                if (res['success'] == true) {
                                  setState(() {
                                    _candidates.removeWhere((c) => c['user_id'].toString() == candidateId.toString());
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate removed from folder')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to remove')));
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
