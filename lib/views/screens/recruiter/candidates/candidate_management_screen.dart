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

  String? _lastFetchedRecruiterId;
  final Set<String> _selectedCandidateIds = {};

  void _toggleCandidateSelection(String candidateId) {
    setState(() {
      if (_selectedCandidateIds.contains(candidateId)) {
        _selectedCandidateIds.remove(candidateId);
      } else {
        _selectedCandidateIds.add(candidateId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCandidateIds.clear();
    });
  }

  void _selectAllCandidates(List<Candidate> candidates) {
    setState(() {
      final allSelected = candidates.every((c) => _selectedCandidateIds.contains(c.id));
      if (allSelected) {
        for (var c in candidates) {
          _selectedCandidateIds.remove(c.id);
        }
      } else {
        for (var c in candidates) {
          _selectedCandidateIds.add(c.id);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _selectedJobId = widget.jobId!;
    }
    _updateTabController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthController>(context);
    if (auth.currentRecruiter != null &&
        auth.currentRecruiter!.id != _lastFetchedRecruiterId) {
      _lastFetchedRecruiterId = auth.currentRecruiter!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  void _updateTabController() {
    final hasJobSelected = _selectedJobId.isNotEmpty;
    final desiredLength = hasJobSelected ? 2 : 1;

    if (_tabController == null || _tabController!.length != desiredLength) {
      final oldController = _tabController;
      _tabController = TabController(length: desiredLength, vsync: this);
      if (oldController != null) {
        Future.microtask(() {
          oldController.dispose();
        });
      }
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
            // Data loaded
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
      _selectedCandidateIds.clear();
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

        return CustomScrollView(
          slivers: [
            if (widget.jobTitle != null && _selectedJobId == widget.jobId)
              SliverToBoxAdapter(child: _buildJobContextBar(isDark)),
            SliverToBoxAdapter(child: _buildFilterCard(isDark, controller)),
            if (_selectedCandidateIds.isNotEmpty)
              SliverToBoxAdapter(child: _buildBulkActionBar(isDark, controller)),
            if (hasJobSelected && _tabController != null)
              SliverToBoxAdapter(child: _buildTabBar(isDark)),
            SliverFillRemaining(
              hasScrollBody: true,
              child: controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (controller.errorMessage != null &&
                        controller.candidates.isEmpty)
                  ? _buildErrorState(controller.errorMessage ?? 'An error occurred', isDark)
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

  Widget _buildFilterCard(bool isDark, CandidatesController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.paddingH, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Filters',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (_keywordController.text.isNotEmpty ||
                  _skillsController.text.isNotEmpty ||
                  _locationController.text.isNotEmpty ||
                  _expMinController.text.isNotEmpty ||
                  _expMaxController.text.isNotEmpty ||
                  _selectedJobId.isNotEmpty)
                GestureDetector(
                  onTap: _resetFilters,
                  child: Text(
                    'Reset All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInlineInputField(
                  _keywordController,
                  'Keyword (Name / Email)',
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInlineInputField(
                  _skillsController,
                  'Skills (e.g. PHP)',
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInlineInputField(
                  _locationController,
                  'Location',
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildInlineInputField(
                  _expMinController,
                  'Exp Min',
                  isDark,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildInlineInputField(
                  _expMaxController,
                  'Exp Max',
                  isDark,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
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
                        'Select Job Role',
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
                        setState(() {
                          _selectedJobId = val ?? '';
                          _updateTabController();
                        });
                        _loadData();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    'Search',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInputField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 40,
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
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _loadData(),
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(bool isDark, CandidatesController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.paddingH, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : const Color(0xFFF4FBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedCandidateIds.length} Selected',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0D8A90),
              ),
            ),
          ),
          TextButton(
            onPressed: _clearSelection,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            child: const Text('Clear'),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () => _showBulkInviteDialog(controller, isDark),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
            label: const Text('Invite'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showBulkEmailDialog(controller, isDark),
            icon: const Icon(Icons.mail_outline_rounded, size: 14),
            label: const Text('Email'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.getPrimary(isDark),
              side: BorderSide(color: AppColors.getPrimary(isDark)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.paddingH, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: list.isNotEmpty && list.every((c) => _selectedCandidateIds.contains(c.id)),
                    onChanged: (val) => _selectAllCandidates(list),
                    activeColor: AppColors.getPrimary(isDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.blueGrey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${list.length} Candidates',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.blueGrey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: Responsive.paddingH,
              right: Responsive.paddingH,
              bottom: 20,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final candidate = list[index];
                  return _buildCandidateCard(candidate, isAi, isDark);
                },
                childCount: list.length,
              ),
            ),
          ),
        ],
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
              Checkbox(
                value: _selectedCandidateIds.contains(candidate.id),
                onChanged: (val) {
                  _toggleCandidateSelection(candidate.id);
                },
                activeColor: AppColors.getPrimary(isDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                visualDensity: VisualDensity.compact,
              ),
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

  void _showBulkInviteDialog(CandidatesController controller, bool isDark) {
    String selectedJobId = controller.recruiterJobs.isNotEmpty ? controller.recruiterJobs.first['id'].toString() : '';
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bulk Invite (${_selectedCandidateIds.length})',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (controller.recruiterJobs.isEmpty)
                      const Text('No jobs available.')
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedJobId,
                        decoration: InputDecoration(
                          labelText: 'Select Job',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: controller.recruiterJobs.map((job) {
                          return DropdownMenuItem<String>(
                            value: job['id'].toString(),
                            child: Text(job['title']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedJobId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Optional Invite Note',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting || selectedJobId.isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter!.id;
                                  final res = await controller.bulkInviteCandidates(
                                    recruiterId: recruiterId,
                                    candidateIds: _selectedCandidateIds.toList(),
                                    jobId: selectedJobId,
                                    message: messageController.text.trim(),
                                  );
                                  setModalState(() => isSubmitting = false);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res['message'] ?? 'Invitations sent')),
                                    );
                                    if (res['success'] == true) _clearSelection();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimary(isDark),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Send Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBulkEmailDialog(CandidatesController controller, bool isDark) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void applyTemplate(String type) {
              String jobTitle = 'the position';
              if (_selectedJobId.isNotEmpty) {
                final job = controller.recruiterJobs.firstWhere(
                  (j) => j['id']?.toString() == _selectedJobId,
                  orElse: () => {},
                );
                if (job.isNotEmpty && job['title'] != null) {
                  jobTitle = job['title'];
                }
              }

              String subject = '';
              String body = '';
              switch (type) {
                case 'interview':
                  subject = 'Interview Invitation - $jobTitle';
                  body = 'Dear candidate,\n\nWe would like to invite you for an interview for the $jobTitle position.\n\nPlease let us know your availability.';
                  break;
                case 'followup':
                  subject = 'Application Update - $jobTitle';
                  body = 'Dear candidate,\n\nWe are currently reviewing your application for the $jobTitle position and will get back to you shortly.';
                  break;
                case 'rejection':
                  subject = 'Update regarding your application';
                  body = 'Dear candidate,\n\nThank you for applying for the $jobTitle position. Unfortunately, we have decided to move forward with other candidates at this time.';
                  break;
                case 'offer':
                  subject = 'Offer Letter - $jobTitle';
                  body = 'Dear candidate,\n\nWe are thrilled to offer you the position of $jobTitle. Please find the details attached.';
                  break;
              }
              setModalState(() {
                subjectController.text = subject;
                bodyController.text = body;
              });
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bulk Email (${_selectedCandidateIds.length})',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bodyController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Email Body',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (subjectController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject and Body are required')));
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter!.id;
                                final res = await controller.bulkSendEmail(
                                  recruiterId: recruiterId,
                                  candidateIds: _selectedCandidateIds.toList(),
                                  subject: subjectController.text.trim(),
                                  body: bodyController.text.trim(),
                                );
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message'] ?? 'Emails sent')),
                                  );
                                  if (res['success'] == true) _clearSelection();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Send Email', style: TextStyle(fontWeight: FontWeight.bold)),
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
