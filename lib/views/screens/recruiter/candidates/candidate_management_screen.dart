import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/candidates_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/candidate.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'candidate_profile_view_screen.dart';

class CandidateManagementScreen extends StatefulWidget {
  final String? jobId;
  final String? jobTitle;
  final bool isStandalone;

  const CandidateManagementScreen({
    super.key,
    this.jobId,
    this.jobTitle,
    this.isStandalone = false,
  });

  @override
  State<CandidateManagementScreen> createState() =>
      _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _expMinController = TextEditingController();
  final TextEditingController _expMaxController = TextEditingController();

  String _selectedJobId = '';
  String _selectedResumeFilter =
      ''; // '' (All), 'yes' (With Resume), 'no' (Without Resume)
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _selectedJobId = widget.jobId!;
    }
    _updateTabController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _updateTabController() {
    final hasJobSelected = _selectedJobId.isNotEmpty;
    final desiredLength = hasJobSelected ? 2 : 1;

    if (_tabController == null || _tabController!.length != desiredLength) {
      _tabController?.dispose();
      _tabController = TabController(length: desiredLength, vsync: this);
    }
  }

  void _loadData() {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId != null) {
      Provider.of<CandidatesController>(context, listen: false)
          .fetchCandidates(
            recruiterId,
            keyword: _keywordController.text.trim(),
            skills: _skillsController.text.trim(),
            location: _locationController.text.trim(),
            expMin: _expMinController.text.trim(),
            expMax: _expMaxController.text.trim(),
            resume: _selectedResumeFilter,
            jobId: _selectedJobId,
          )
          .then((_) {
            if (mounted) {
              setState(() {
                _updateTabController();
              });
            }
          });
    }
  }

  void _resetFilters() {
    setState(() {
      _keywordController.clear();
      _skillsController.clear();
      _locationController.clear();
      _expMinController.clear();
      _expMaxController.clear();
      _selectedResumeFilter = '';
      _selectedJobId = widget.jobId ?? '';
      _updateTabController();
    });
    _loadData();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _skillsController.dispose();
    _locationController.dispose();
    _expMinController.dispose();
    _expMaxController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Consumer<CandidatesController>(
      builder: (context, controller, child) {
        final hasJobSelected = _selectedJobId.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.jobTitle != null && _selectedJobId == widget.jobId)
              _buildJobContextBar(isDark),
            _buildSearchRow(isDark),
            if (hasJobSelected && _tabController != null) _buildTabBar(isDark),
            Expanded(
              child: controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : controller.errorMessage != null &&
                        controller.candidates.isEmpty
                  ? _buildErrorState(controller.errorMessage!, isDark)
                  : _tabController == null
                  ? const SizedBox()
                  : TabBarView(
                      controller: _tabController,
                      children: hasJobSelected
                          ? [
                              _buildCandidatesListView(
                                controller.aiSuggestions,
                                isAi: true,
                                isDark: isDark,
                              ),
                              _buildCandidatesListView(
                                controller.candidates,
                                isAi: false,
                                isDark: isDark,
                              ),
                            ]
                          : [
                              _buildCandidatesListView(
                                controller.candidates,
                                isAi: false,
                                isDark: isDark,
                              ),
                            ],
                    ),
            ),
          ],
        );
      },
    );

    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Candidate Database',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        body: content,
      );
    }

    return Container(
      color: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      child: content,
    );
  }

  Widget _buildJobContextBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.paddingH,
        vertical: 8,
      ),
      color: AppColors.getPrimary(isDark).withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(
            Icons.business_center_rounded,
            size: 14,
            color: AppColors.getPrimary(isDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aligning suggestions for: ${widget.jobTitle}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _selectedJobId = '';
                _updateTabController();
              });
              _loadData();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.paddingH,
        12,
        Responsive.paddingH,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: TextField(
                controller: _keywordController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadData(),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search candidate name, skills...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _openFiltersBottomSheet(isDark),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: _hasActiveAdvancedFilters()
                    ? AppColors.getPrimary(isDark)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveAdvancedFilters() {
    return _skillsController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _expMinController.text.isNotEmpty ||
        _expMaxController.text.isNotEmpty ||
        _selectedResumeFilter.isNotEmpty ||
        _selectedJobId.isNotEmpty;
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[100]!,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.getPrimary(isDark),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.getPrimary(isDark),
        unselectedLabelColor: AppColors.getTextMuted(isDark),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'AI Match Suggestions'),
          Tab(text: 'All Candidates'),
        ],
      ),
    );
  }

  Widget _buildCandidatesListView(
    List<Candidate> list, {
    required bool isAi,
    required bool isDark,
  }) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.getCard(isDark)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAi
                          ? Icons.auto_awesome_rounded
                          : Icons.person_search_rounded,
                      size: 40,
                      color: AppColors.getPrimary(
                        isDark,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAi ? 'No AI Matches Found' : 'No Candidates Found',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      isAi
                          ? 'Try modifying the selected job details or parameters.'
                          : 'Try broadening your search query or filters.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.paddingH,
          vertical: 10,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final candidate = list[index];
          return _buildCandidateCard(candidate, isAi, isDark);
        },
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate, bool isAi, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: ApiService().getImageUrl(candidate.profilePhoto),
                builder: (context, snapshot) {
                  final imgUrl = snapshot.data ?? '';
                  if (imgUrl.isNotEmpty) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      backgroundImage: CachedNetworkImageProvider(imgUrl),
                    );
                  }
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.getPrimary(
                      isDark,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      candidate.name.isNotEmpty
                          ? candidate.name[0].toUpperCase()
                          : 'C',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.email,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAi)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${candidate.matchScore.toInt()}% Match',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, candidate.location, isDark),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.work_history_outlined,
            'Experience: ${candidate.experienceDisplay}',
            isDark,
          ),
          if (candidate.skillName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidate.skillName
                  .split(',')
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        skill.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.blueGrey[800],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (isAi && candidate.matchReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI REASONING',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    candidate.matchReason,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _viewCandidateProfile(candidate, isDark),
                  icon: const Icon(Icons.person_search_rounded, size: 14),
                  label: const Text('View Profile'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.getPrimary(isDark),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (candidate.resumePath.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _downloadResume(candidate),
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: const Text('Resume'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.getPrimary(isDark),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _openInvitationDialog(candidate, isDark),
                  icon: const Icon(Icons.mail_outline_rounded, size: 14),
                  label: const Text('Invite'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          text.isEmpty ? 'N/A' : text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: isDark ? Colors.grey[400] : Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _openFiltersBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final controller = Provider.of<CandidatesController>(context);
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSoftDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Advanced Filters',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _resetFilters();
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Skills (e.g. PHP, Java)', isDark),
                    _buildInputField(_skillsController, 'e.g. PHP', isDark),
                    const SizedBox(height: 12),
                    _buildLabel('Location', isDark),
                    _buildInputField(
                      _locationController,
                      'City / State',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Exp Min (Years)', isDark),
                              _buildInputField(
                                _expMinController,
                                'e.g. 1',
                                isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Exp Max (Years)', isDark),
                              _buildInputField(
                                _expMaxController,
                                'e.g. 5',
                                isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Job Role Match', isDark),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedJobId.isEmpty ? null : _selectedJobId,
                          hint: Text(
                            'Select Job',
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
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'None (General search)',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                            ...controller.recruiterJobs.map((job) {
                              return DropdownMenuItem<String>(
                                value: job['id']?.toString() ?? '',
                                child: Text(
                                  job['title'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setSheetState(() {
                              _selectedJobId = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Resume Uploaded', isDark),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedResumeFilter,
                          dropdownColor: isDark
                              ? AppColors.bgSoftDark
                              : Colors.white,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(
                                'All Candidates',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'yes',
                              child: Text(
                                'With Resume',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'no',
                              child: Text(
                                'Without Resume',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setSheetState(() {
                              _selectedResumeFilter = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  void _viewCandidateProfile(Candidate candidate, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateProfileViewScreen(
          candidateId: candidate.id,
          candidateName: candidate.name,
          jobId: _selectedJobId.isNotEmpty ? _selectedJobId : widget.jobId,
        ),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildDetailItem(
    IconData icon,
    String title,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'N/A' : value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadResume(Candidate candidate) async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    final baseUrl = await ApiService().getBaseUrl();
    final downloadUrl =
        "$baseUrl/candidates/${candidate.id}/resume"
        "?recruiter_id=$recruiterId"
        "&application_id="
        "&job_id=";

    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not trigger resume download')),
        );
      }
    }
  }

  void _openInvitationDialog(Candidate candidate, bool isDark) {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    final controller = Provider.of<CandidatesController>(
      context,
      listen: false,
    );
    final openJobs = controller.recruiterJobs;

    if (openJobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must have at least one open job to invite candidates.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String inviteJobId = _selectedJobId;
    if (inviteJobId.isEmpty) {
      inviteJobId = openJobs.first['id']?.toString() ?? '';
    }

    final jobTitle =
        openJobs.firstWhere(
          (j) => j['id']?.toString() == inviteJobId,
          orElse: () => openJobs.first,
        )['title'] ??
        'this position';

    final textController = TextEditingController(
      text:
          "Hi ${candidate.name}, we would love for you to apply to the $jobTitle role on our team!",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.bgSoftDark : Colors.white,
              title: Text(
                'Invite to Apply',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Job Role:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        value: inviteJobId,
                        dropdownColor: isDark
                            ? AppColors.bgSoftDark
                            : Colors.white,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: openJobs.map((job) {
                          return DropdownMenuItem<String>(
                            value: job['id']?.toString() ?? '',
                            child: Text(
                              job['title'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              inviteJobId = val;
                              final selectedJobTitle =
                                  openJobs.firstWhere(
                                    (j) => j['id']?.toString() == val,
                                  )['title'] ??
                                  'this position';
                              textController.text =
                                  "Hi ${candidate.name}, we would love for you to apply to the $selectedJobTitle role on our team!";
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Custom Message (Optional):',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                    ),
                    child: TextField(
                      controller: textController,
                      maxLines: 3,
                      maxLength: 500,
                      style: GoogleFonts.inter(fontSize: 12.5),
                      decoration: const InputDecoration(
                        hintText: 'Add an invitation note...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success =
                        await Provider.of<CandidatesController>(
                          context,
                          listen: false,
                        ).inviteCandidate(
                          recruiterId: recruiterId,
                          candidateId: candidate.id,
                          jobId: inviteJobId,
                          message: textController.text.trim(),
                        );
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invitation sent successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        final errMsg =
                            Provider.of<CandidatesController>(
                              context,
                              listen: false,
                            ).errorMessage ??
                            'Failed to send invitation.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errMsg),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Send',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
