import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/resdex_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';
import 'package:hirematrix/views/screens/recruiter/candidates/candidate_profile_view_screen.dart';

class ResdexSearchScreen extends StatefulWidget {
  const ResdexSearchScreen({super.key});

  @override
  State<ResdexSearchScreen> createState() => _ResdexSearchScreenState();
}

class _ResdexSearchScreenState extends State<ResdexSearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _keywordsCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _expMinCtrl = TextEditingController();
  final TextEditingController _expMaxCtrl = TextEditingController();
  
  final TextEditingController _keywordExcludeCtrl = TextEditingController();
  final TextEditingController _itSkillsCtrl = TextEditingController();
  final TextEditingController _salaryMinCtrl = TextEditingController();
  final TextEditingController _salaryMaxCtrl = TextEditingController();
  final TextEditingController _educationCtrl = TextEditingController();
  final TextEditingController _mustHaveSkillsCtrl = TextEditingController();
  
  String? _noticePeriod;
  String? _employmentType;
  String? _gender;

  bool _booleanOn = false;
  bool _mandatory = false;

  Set<int> _selectedCandidates = {};
  Map<int, int?> _candidateFolderSelections = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final resdexCtrl = Provider.of<ResdexController>(context, listen: false);
      if (auth.currentRecruiter?.id != null) {
        if (!resdexCtrl.hasSearched) {
          resdexCtrl.performSearch(auth.currentRecruiter!.id.toString(), {});
        }
        if (resdexCtrl.folders.isEmpty) {
          resdexCtrl.fetchFolders(auth.currentRecruiter!.id.toString());
        }
      }
    });
  }

  void _runSearch() {
    setState(() {
      _selectedCandidates.clear();
    });
    final auth = Provider.of<AuthController>(context, listen: false);
    final resdexCtrl = Provider.of<ResdexController>(context, listen: false);
    if (auth.currentRecruiter?.id == null) return;
    
    Map<String, String> filters = {};
    if (_keywordsCtrl.text.isNotEmpty) filters['keywords'] = _keywordsCtrl.text;
    if (_locationCtrl.text.isNotEmpty) filters['location'] = _locationCtrl.text;
    if (_expMinCtrl.text.isNotEmpty) filters['exp_min'] = _expMinCtrl.text;
    if (_expMaxCtrl.text.isNotEmpty) filters['exp_max'] = _expMaxCtrl.text;
    if (_keywordExcludeCtrl.text.isNotEmpty) filters['keyword_exclude'] = _keywordExcludeCtrl.text;
    if (_itSkillsCtrl.text.isNotEmpty) filters['it_skills'] = _itSkillsCtrl.text;
    if (_salaryMinCtrl.text.isNotEmpty) filters['salary_min'] = _salaryMinCtrl.text;
    if (_salaryMaxCtrl.text.isNotEmpty) filters['salary_max'] = _salaryMaxCtrl.text;
    if (_educationCtrl.text.isNotEmpty) filters['education'] = _educationCtrl.text;
    if (_mustHaveSkillsCtrl.text.isNotEmpty) filters['must_have_skills'] = _mustHaveSkillsCtrl.text;
    
    if (_noticePeriod != null && _noticePeriod!.isNotEmpty) filters['notice_period'] = _noticePeriod!;
    if (_employmentType != null && _employmentType!.isNotEmpty) filters['employment_type'] = _employmentType!;
    if (_gender != null && _gender!.isNotEmpty) filters['gender'] = _gender!;

    if (_booleanOn) filters['boolean_on'] = '1';
    if (_mandatory) filters['mandatory'] = '1';

    resdexCtrl.performSearch(auth.currentRecruiter!.id.toString(), filters);
  }

  void _openFiltersDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      endDrawer: _buildFilterDrawer(isDark),
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Search Resumes',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark)),
        ),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFiltersDrawer,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Consumer<ResdexController>(
        builder: (context, resdex, child) {
          if (resdex.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (resdex.searchResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.getTextMuted(isDark)),
                  const SizedBox(height: 16),
                  Text(
                    'No candidates found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openFiltersDrawer,
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    label: Text(
                      'Modify Search',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                    ),
                  )
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${resdex.searchResults.length} candidates found',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark)),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _selectedCandidates.length == resdex.searchResults.length && resdex.searchResults.isNotEmpty,
                          activeColor: AppColors.getPrimary(isDark),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedCandidates = resdex.searchResults.map((c) => int.parse(c['user_id'].toString())).toSet();
                              } else {
                                _selectedCandidates.clear();
                              }
                            });
                          },
                        ),
                        Text('Select All', style: GoogleFonts.inter(color: AppColors.getText(isDark), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              if (_selectedCandidates.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.getPrimary(isDark)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedCandidates.length} selected',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _selectedCandidates.clear()),
                        child: Text('Clear', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark), decoration: TextDecoration.underline)),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.create_new_folder, size: 16),
                        onPressed: () {
                          _showBulkAddToFolderDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Save to Folder'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.mail_outline, size: 16),
                        onPressed: () {
                          _showBulkInviteDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Bulk Invite'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resdex.searchResults.length,
                  itemBuilder: (context, index) {
                    final candidate = resdex.searchResults[index];
                    return _buildCandidateCard(candidate, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate, bool isDark) {
    final name = candidate['name'] ?? 'Candidate';
    final headline = candidate['headline'] ?? 'No headline provided';
    final location = candidate['location'] ?? 'Location not specified';
    final isSaved = (candidate['is_search_saved'] == '1');
    final totalMonths = int.tryParse(candidate['total_experience_months']?.toString() ?? '0') ?? 0;
    final expYears = (totalMonths / 12).toStringAsFixed(1);
    final noticePeriod = candidate['notice_period'] ?? '';
    final salary = candidate['expected_salary'] != null ? '\$${candidate['expected_salary']}' : '';
    final String skillsString = candidate['key_skills']?.toString() ?? '';
    final List<String> skills = skillsString.split(',').map((String s) => s.trim()).where((String s) => s.isNotEmpty).take(6).toList();

    final int candidateId = int.tryParse(candidate['user_id']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedCandidates.contains(candidateId) ? AppColors.getPrimary(isDark).withOpacity(0.05) : AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selectedCandidates.contains(candidateId) ? AppColors.getPrimary(isDark) : AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _selectedCandidates.contains(candidateId),
                activeColor: AppColors.getPrimary(isDark),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedCandidates.add(candidateId);
                    } else {
                      _selectedCandidates.remove(candidateId);
                    }
                  });
                },
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.getPrimary(isDark).withOpacity(0.1),
                backgroundImage: candidate['profile_picture'] != null && candidate['profile_picture'].toString().isNotEmpty
                  ? NetworkImage(candidate['profile_picture']) 
                  : null,
                child: (candidate['profile_picture'] == null || candidate['profile_picture'].toString().isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(isDark),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getText(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.getTextMuted(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.getPrimary(isDark) : AppColors.getTextMuted(isDark),
                ),
                onPressed: () {
                  final auth = Provider.of<AuthController>(context, listen: false);
                  final resdex = Provider.of<ResdexController>(context, listen: false);
                  resdex.toggleSaveSearch(auth.currentRecruiter!.id.toString(), int.parse(candidate['user_id'].toString()), name, resdex.searchFilters.map((k, v) => MapEntry(k, v.toString())));
                },
                tooltip: isSaved ? 'Unsave Candidate Search' : 'Save Candidate Search',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (location.isNotEmpty)
                _buildIconText(Icons.location_on, location, isDark),
              if (totalMonths > 0)
                _buildIconText(Icons.business_center, '$expYears yrs exp', isDark),
              if (noticePeriod.isNotEmpty)
                _buildIconText(Icons.access_time, '$noticePeriod notice', isDark),
              if (salary.isNotEmpty)
                _buildIconText(Icons.account_balance_wallet, 'Exp. $salary', isDark),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getPrimary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CandidateProfileViewScreen(
                        candidateId: candidate['user_id'].toString(),
                        candidateName: name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.remove_red_eye),
                color: AppColors.getPrimary(isDark),
                tooltip: 'View Profile',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.getPrimary(isDark))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  try {
                    final apiService = ApiService();
                    final baseUrl = await apiService.getBaseUrl();
                    final auth = Provider.of<AuthController>(context, listen: false);
                    final recruiterId = auth.currentRecruiter?.id ?? '';
                    final uri = Uri.parse('$baseUrl/candidates/${candidate['user_id']}/resume?recruiter_id=$recruiterId');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download URL')));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                icon: const Icon(Icons.download),
                color: AppColors.getPrimary(isDark),
                tooltip: 'Download Resume',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.getPrimary(isDark))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer<ResdexController>(
                  builder: (context, resdex, child) {
                    if (resdex.folders.isEmpty) {
                      return Text('No folders found', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark), fontSize: 12));
                    }
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _candidateFolderSelections[candidateId],
                      items: resdex.folders.map<DropdownMenuItem<int>>((f) {
                        return DropdownMenuItem<int>(
                          value: int.parse(f['id'].toString()),
                          child: Text(f['folder_name'] ?? 'Unknown', style: GoogleFonts.inter(color: AppColors.getText(isDark), fontSize: 12), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _candidateFolderSelections[candidateId] = val),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                      ),
                      dropdownColor: AppColors.getCard(isDark),
                      hint: Text('Select Folder', style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                    );
                  }
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final folderId = _candidateFolderSelections[candidateId];
                  if (folderId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a folder')));
                    return;
                  }
                  final resdex = Provider.of<ResdexController>(context, listen: false);
                  final auth = Provider.of<AuthController>(context, listen: false);
                  if (auth.currentRecruiter?.id != null) {
                    final res = await resdex.addToFolder(
                      auth.currentRecruiter!.id.toString(), 
                      candidateId, 
                      folderId, 
                      ''
                    );
                    if (res['success'] == true && mounted) {
                      final folderName = resdex.folders.firstWhere((f) => f['id'].toString() == folderId.toString(), orElse: () => {'folder_name': 'Folder'})['folder_name'];
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Candidate added to folder $folderName')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Save'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.getTextMuted(isDark)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.getTextMuted(isDark),
          ),
        ),
      ],
    );
  }


  void _showBulkAddToFolderDialog() {
    final resdex = Provider.of<ResdexController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int? selectedFolderId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: AppColors.getCard(isDark),
              title: Text('Save ${_selectedCandidates.length} to Folder', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resdex.folders.isEmpty)
                      Text('No folders found. Please create one on a single candidate first.', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)))
                    else
                      DropdownButtonFormField<int>(
                        value: selectedFolderId,
                        items: resdex.folders.map<DropdownMenuItem<int>>((f) {
                          return DropdownMenuItem<int>(
                            value: int.parse(f['id'].toString()),
                            child: Text(f['folder_name'] ?? 'Unknown', style: GoogleFonts.inter(color: AppColors.getText(isDark))),
                          );
                        }).toList(),
                        onChanged: (val) => setStateSB(() => selectedFolderId = val),
                        decoration: InputDecoration(
                          labelText: 'Select Folder',
                          labelStyle: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                        ),
                        dropdownColor: AppColors.getCard(isDark),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFolderId == null) return;
                    Navigator.pop(context);
                    if (auth.currentRecruiter?.id != null) {
                      final res = await resdex.bulkAddToFolder(
                        auth.currentRecruiter!.id.toString(), 
                        _selectedCandidates.toList(), 
                        selectedFolderId!
                      );
                      if (res['success'] == true && mounted) {
                        final folderName = resdex.folders.firstWhere((f) => f['id'].toString() == selectedFolderId.toString(), orElse: () => {'folder_name': 'Folder'})['folder_name'];
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedCandidates.length} candidate(s) added to folder $folderName')));
                        setState(() {
                          _selectedCandidates.clear();
                        });
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save to folder')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.getPrimary(isDark)),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }
  
  void _showBulkInviteDialog() {
    final resdex = Provider.of<ResdexController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int? selectedJobId;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: AppColors.getCard(isDark),
              title: Text('Invite ${_selectedCandidates.length} Candidate(s)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resdex.recruiterJobs.isEmpty)
                      Text('You have no open jobs. Please post a job first.', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)))
                    else ...[
                      DropdownButtonFormField<int>(
                        value: selectedJobId,
                        items: resdex.recruiterJobs.map<DropdownMenuItem<int>>((j) {
                          return DropdownMenuItem<int>(
                            value: int.parse(j['id'].toString()),
                            child: Text(j['title'] ?? 'Unknown Job', style: GoogleFonts.inter(color: AppColors.getText(isDark))),
                          );
                        }).toList(),
                        onChanged: (val) => setStateSB(() => selectedJobId = val),
                        decoration: InputDecoration(
                          labelText: 'Select Job',
                          labelStyle: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                        ),
                        dropdownColor: AppColors.getCard(isDark),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(color: AppColors.getText(isDark)),
                        decoration: InputDecoration(
                          labelText: 'Message (optional)',
                          labelStyle: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark))),
                ),
                ElevatedButton(
                  onPressed: resdex.recruiterJobs.isEmpty ? null : () async {
                    if (selectedJobId == null) return;
                    Navigator.pop(context);
                    if (auth.currentRecruiter?.id != null) {
                      final res = await resdex.bulkInviteCandidates(
                        auth.currentRecruiter!.id.toString(), 
                        _selectedCandidates.toList(), 
                        selectedJobId!,
                        noteCtrl.text.trim()
                      );
                      if (res['success'] == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedCandidates.length} candidate(s) invited!')));
                        setState(() {
                          _selectedCandidates.clear();
                        });
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to invite candidates')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.getPrimary(isDark)),
                  child: const Text('Send Invites', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildFilterDrawer(bool isDark) {
    return Drawer(
      backgroundColor: AppColors.getBackground(isDark),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Filters',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.getText(isDark),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.getBorder(isDark)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField('Keywords', _keywordsCtrl, isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _booleanOn,
                        onChanged: (val) => setState(() => _booleanOn = val ?? false),
                        activeColor: AppColors.getPrimary(isDark),
                      ),
                      Text('Boolean logic (AND/OR)', style: GoogleFonts.inter(color: AppColors.getText(isDark), fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatory,
                        onChanged: (val) => setState(() => _mandatory = val ?? false),
                        activeColor: AppColors.getPrimary(isDark),
                      ),
                      Text('Mandatory keywords', style: GoogleFonts.inter(color: AppColors.getText(isDark), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Exclude Keywords', _keywordExcludeCtrl, isDark),
                  const SizedBox(height: 16),
                  _buildTextField('IT Skills', _itSkillsCtrl, isDark),
                  const SizedBox(height: 16),
                  _buildTextField('Location', _locationCtrl, isDark),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Min Exp (Yrs)', _expMinCtrl, isDark, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Max Exp (Yrs)', _expMaxCtrl, isDark, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Min Salary', _salaryMinCtrl, isDark, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Max Salary', _salaryMaxCtrl, isDark, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown('Notice Period', ['Immediate', '15 Days', '30 Days', '60 Days', '90 Days'], _noticePeriod, (val) => setState(() => _noticePeriod = val), isDark),
                  const SizedBox(height: 16),
                  _buildDropdown('Employment Type', ['Full-time', 'Part-time', 'Contract', 'Internship'], _employmentType, (val) => setState(() => _employmentType = val), isDark),
                  const SizedBox(height: 16),
                  _buildTextField('Education', _educationCtrl, isDark),
                  const SizedBox(height: 16),
                  _buildDropdown('Gender', ['Male', 'Female', 'Other'], _gender, (val) => setState(() => _gender = val), isDark),
                  const SizedBox(height: 16),
                  _buildTextField('Must-have Skills', _mustHaveSkillsCtrl, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close drawer
                    _runSearch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged, bool isDark) {
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
        DropdownButtonFormField<String>(
          value: value,
          items: [
            DropdownMenuItem(value: null, child: Text('Any', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)))),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(color: AppColors.getText(isDark))))),
          ],
          onChanged: onChanged,
          dropdownColor: AppColors.getCard(isDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FCFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {TextInputType? keyboardType}) {
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
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.getText(isDark)),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FCFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              borderSide: BorderSide(color: AppColors.getPrimary(isDark), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
