import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';
import 'interview_bookings_screen.dart';

class InterviewSlotsScreen extends StatefulWidget {
  const InterviewSlotsScreen({super.key});

  @override
  State<InterviewSlotsScreen> createState() => _InterviewSlotsScreenState();
}

class _InterviewSlotsScreenState extends State<InterviewSlotsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _slots = [];
  Map<String, dynamic> _metrics = {
    'total': '0',
    'available': '0',
    'booked': '0',
    'total_bookings': '0',
  };

  String? _selectedJobId;
  String? _selectedStatus;
  DateTime? _selectedDate;
  final TextEditingController _dateFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dateFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId != null) {
      final jobsCtrl = Provider.of<JobsController>(context, listen: false);
      if (jobsCtrl.jobs.isEmpty) {
        await jobsCtrl.fetchJobs(recruiterId);
      }

      final response = await _apiService.fetchInterviewSlots(
        recruiterId,
        jobId: _selectedJobId,
        status: _selectedStatus,
        date: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
      );
      if (response['success'] == true) {
        setState(() {
          _slots = response['slots'] ?? [];
          _metrics = response['metrics'] ?? _metrics;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Create Slot Modal (mirrors create.php) ─────────────────────────────────
  void _showAddSlotModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobs = Provider.of<JobsController>(context, listen: false).jobs;

    String? selectedJobId;
    DateTime? startDate;
    DateTime? endDate;
    List<TimeOfDay> times = [TimeOfDay.now()];
    int capacity = 1;
    bool excludeWeekends = true;
    bool isSaving = false;
    String? errorMsg;

    // Helpers
    String countSlots(
      DateTime? start,
      DateTime? end,
      List<TimeOfDay> tms,
      bool excWeekends,
    ) {
      if (start == null || tms.isEmpty) return '0';
      final endD = end ?? start;
      int days = 0;
      DateTime cur = start;
      while (!cur.isAfter(endD)) {
        final wd = cur.weekday;
        if (!excWeekends || (wd != DateTime.saturday && wd != DateTime.sunday)) {
          days++;
        }
        cur = cur.add(const Duration(days: 1));
      }
      return (days * tms.length).toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final totalSlots = countSlots(
            startDate,
            endDate,
            times,
            excludeWeekends,
          );

          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSoftDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
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

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Interview Slots',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.getText(isDark),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Generate booking windows for a job',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.getTextMuted(isDark),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.getTextMuted(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Error banner
                      if (errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Section: Job Selection ──────────────────────────────
                      _sheetSectionLabel('Select Job *', isDark),
                      DropdownButtonFormField<String>(
                        decoration: _sheetInputDecoration(
                          'Select job position',
                          Icons.work_outline_rounded,
                          isDark,
                        ),
                        dropdownColor:
                            isDark ? AppColors.bgCardDark : Colors.white,
                        value: selectedJobId,
                        items: jobs
                            .map(
                              (j) => DropdownMenuItem(
                                value: j.jobId,
                                child: Text(
                                  j.jobTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.getText(isDark),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedJobId = val),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.getText(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the job position for these interview slots',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),

                      const SizedBox(height: 18),
                      // ── Section: Date Range ─────────────────────────────────
                      _sheetSectionLabel('Date Range', isDark),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerTile(
                              label: 'Start Date *',
                              hint: 'Select date',
                              value: startDate,
                              isDark: isDark,
                              onPick: (date) =>
                                  setSheetState(() => startDate = date),
                              firstDate: DateTime.now(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickerTile(
                              label: 'End Date (Optional)',
                              hint: 'Single day',
                              value: endDate,
                              isDark: isDark,
                              onPick: (date) =>
                                  setSheetState(() => endDate = date),
                              firstDate: startDate ?? DateTime.now(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'First date for slots',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.getTextMuted(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Leave empty for single day',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.getTextMuted(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      // ── Section: Time Slots ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sheetSectionLabel('Time Slots *', isDark),
                          GestureDetector(
                            onTap: () =>
                                setSheetState(() => times.add(TimeOfDay.now())),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: AppColors.getPrimary(isDark),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Time',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getPrimary(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: times.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final t = await showTimePicker(
                                        context: ctx,
                                        initialTime: times[index],
                                      );
                                      if (t != null) {
                                        setSheetState(() => times[index] = t);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.bgCardDark
                                            : const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDark
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 16,
                                            color: AppColors.getPrimary(isDark),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            times[index].format(ctx),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.getText(isDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (times.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => setSheetState(
                                      () => times.removeAt(index),
                                    ),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        'Add multiple time slots for each day',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),

                      const SizedBox(height: 18),
                      // ── Section: Settings ───────────────────────────────────
                      _sheetSectionLabel('Capacity per Slot *', isDark),
                      TextFormField(
                        key: ValueKey(capacity),
                        initialValue: capacity.toString(),
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.getText(isDark),
                        ),
                        decoration: _sheetInputDecoration(
                          'e.g. 1',
                          Icons.group_outlined,
                          isDark,
                        ),
                        onChanged: (v) {
                          setSheetState(
                            () => capacity = int.tryParse(v) ?? 1,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Number of candidates that can book each slot',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // ── Exclude Weekends toggle ─────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.bgCardDark
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          title: Text(
                            'Exclude Weekends',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getText(isDark),
                            ),
                          ),
                          subtitle: Text(
                            'Do not create slots on Saturday & Sunday',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.getTextMuted(isDark),
                            ),
                          ),
                          value: excludeWeekends,
                          activeThumbColor: AppColors.getPrimary(isDark),
                          onChanged: (v) =>
                              setSheetState(() => excludeWeekends = v),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // ── Summary Card ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(isDark).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.getPrimary(isDark).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.getPrimary(isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                startDate == null || times.isEmpty
                                    ? 'Fill in the form to see the summary of slots to be created.'
                                    : '$totalSlots slot(s) will be created across ${endDate != null ? "the selected date range" : "1 day"} with ${times.length} time slot(s) each.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.getPrimary(isDark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      // ── Submit Button ───────────────────────────────────────
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (selectedJobId == null) {
                                  setSheetState(
                                    () => errorMsg = 'Please select a job',
                                  );
                                  return;
                                }
                                if (startDate == null) {
                                  setSheetState(
                                    () => errorMsg =
                                        'Start date is required',
                                  );
                                  return;
                                }
                                if (times.isEmpty) {
                                  setSheetState(
                                    () => errorMsg =
                                        'At least one time slot is required',
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isSaving = true;
                                  errorMsg = null;
                                });

                                final recruiterId =
                                    Provider.of<AuthController>(
                                  context,
                                  listen: false,
                                ).currentRecruiter?.id;

                                final formattedTimes = times.map((t) {
                                  final now = DateTime.now();
                                  final dt = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    t.hour,
                                    t.minute,
                                  );
                                  return DateFormat('HH:mm').format(dt);
                                }).toList();

                                final payload = {
                                  'recruiter_id': recruiterId.toString(),
                                  'job_id': selectedJobId!,
                                  'start_date': DateFormat('yyyy-MM-dd')
                                      .format(startDate!),
                                  'end_date': endDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(endDate!)
                                      : '',
                                  'times': formattedTimes,
                                  'capacity': capacity.toString(),
                                  'exclude_weekends':
                                      excludeWeekends ? '1' : '0',
                                };

                                final res = await _apiService
                                    .addInterviewSlot(payload);

                                if (!ctx.mounted) return;
                                setSheetState(() => isSaving = false);
                                if (res['success'] == true) {
                                  Navigator.pop(ctx);
                                  _loadData();
                                  if (recruiterId != null) {
                                    Provider.of<DashboardController>(
                                      context,
                                      listen: false,
                                    ).refresh(recruiterId);
                                  }
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Interview slot(s) created successfully',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                        ),
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else {
                                  setSheetState(
                                    () => errorMsg = res['message']
                                            ?.toString() ??
                                        'Failed to create slots',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppColors.getPrimary(isDark),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create Slots',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sheetSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.getText(isDark),
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(
    String hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.getTextMuted(isDark),
      ),
      prefixIcon: Icon(icon, size: 16, color: AppColors.getTextMuted(isDark)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true,
      fillColor: isDark ? AppColors.bgCardDark : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.getPrimary(isDark),
          width: 1.5,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Responsive().init(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : const Color(0xFFF4FBFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Interview Slots',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          // View All Bookings action
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InterviewBookingsScreen(),
                ),
              );
            },
            child: Text(
              'Bookings',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: AppColors.getPrimary(isDark),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                // Stat cards
                _buildStatCards(isDark),
                // Filter bar
                _buildFilterBar(isDark),
                // Slot table
                Expanded(
                  child: _slots.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildSlotsTable(isDark),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSlotModal,
        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
        label: Text(
          'New Slots',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.getPrimary(isDark),
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Stat Cards ─────────────────────────────────────────────────────────────
  Widget _buildStatCards(bool isDark) {
    final items = [
      _StatItem(
        'Total Slots',
        _metrics['total']?.toString() ?? '0',
        Icons.event_note_rounded,
        Colors.blue,
      ),
      _StatItem(
        'Available',
        _metrics['available']?.toString() ?? '0',
        Icons.event_available_rounded,
        AppColors.success,
      ),
      _StatItem(
        'Fully Booked',
        _metrics['booked']?.toString() ?? '0',
        Icons.event_busy_rounded,
        AppColors.warning,
      ),
      _StatItem(
        'Bookings',
        _metrics['total_bookings']?.toString() ?? '0',
        Icons.people_outline_rounded,
        Colors.purple,
      ),
    ];

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: items.map((item) => _buildStatCard(item, isDark)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFD9ECE5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF16212B),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 14, color: item.color),
              ),
            ],
          ),
          Text(
            item.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(bool isDark) {
    final jobs = Provider.of<JobsController>(context, listen: false).jobs;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFD9ECE5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 14,
                color: AppColors.getPrimary(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getText(isDark),
                ),
              ),
              const Spacer(),
              if (_selectedJobId != null ||
                  _selectedStatus != null ||
                  _selectedDate != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedJobId = null;
                      _selectedStatus = null;
                      _selectedDate = null;
                      _dateFilterController.clear();
                    });
                    _loadData();
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Job filter
              Expanded(
                flex: 5,
                child: _FilterDropdown<String>(
                  hint: 'All Jobs',
                  value: _selectedJobId,
                  isDark: isDark,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Jobs')),
                    ...jobs.map(
                      (j) => DropdownMenuItem(
                        value: j.jobId,
                        child: Text(
                          j.jobTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedJobId = v);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Status filter
              Expanded(
                flex: 4,
                child: _FilterDropdown<String>(
                  hint: 'Status',
                  value: _selectedStatus,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(value: 'full', child: Text('Fully Booked')),
                    DropdownMenuItem(value: 'past', child: Text('Past Slots')),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date filter
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _dateFilterController.text =
                      DateFormat('MMM dd, yyyy').format(date);
                });
                _loadData();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.bgCardDark
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: _selectedDate != null
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getTextMuted(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                        : 'Filter by date',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _selectedDate != null
                          ? AppColors.getText(isDark)
                          : AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slot Table / List ──────────────────────────────────────────────────────
  Widget _buildSlotsTable(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFD9ECE5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: isDark ? AppColors.borderDark : const Color(0xFFEEF2F7),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                isDark ? Colors.black : const Color(0xFFEDF8F5),
              ),
              dataRowColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return isDark ? const Color(0x081FB7B5) : const Color(0xFFF4FBFA);
                }
                return isDark ? Colors.transparent : Colors.white;
              }),
              headingTextStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              dataTextStyle: GoogleFonts.inter(
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF16212B),
              ),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('JOB')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('TIME')),
                DataColumn(label: Text('CAPACITY')),
                DataColumn(label: Text('BOOKED')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('CREATED BY')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: _slots.map((slot) => _buildDataRow(slot, isDark)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> slot, bool isDark) {
    final rawStatus = (slot['status'] ?? 'available').toString().toLowerCase();
    final isPast = rawStatus == 'past';
    final isFull = rawStatus == 'full' ||
        rawStatus == 'fully booked' ||
        (slot['booked_count'] != null &&
            slot['capacity'] != null &&
            (int.tryParse(slot['booked_count'].toString()) ?? 0) >=
                (int.tryParse(slot['capacity'].toString()) ?? 1));

    Color statusColor;
    String statusLabel;
    if (isPast) {
      statusColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      statusLabel = 'Past';
    } else if (isFull) {
      statusColor = isDark ? const Color(0xFFB5D84E) : const Color(0xFF6B7B0E);
      statusLabel = 'Full';
    } else {
      statusColor = isDark ? const Color(0xFF1FB7B5) : const Color(0xFF0D8A90);
      statusLabel = 'Available';
    }
    
    Color statusBgColor;
    if (isPast) {
      statusBgColor = isDark ? const Color(0xFF1B2A2F) : const Color(0xFFEDF8F5);
    } else if (isFull) {
      statusBgColor = isDark ? const Color(0x1AB5D84E) : const Color(0x26B5D84E);
    } else {
      statusBgColor = isDark ? const Color(0x261FB7B5) : const Color(0x260D8A90);
    }

    final hasBookings = (int.tryParse(
              slot['booked_count']?.toString() ?? '0',
            ) ??
            0) >
        0;

    final cellStyle = GoogleFonts.inter(
      fontSize: 13.5,
      color: isPast 
          ? (isDark ? Colors.white : const Color(0xFF94A3B8))
          : (isDark ? Colors.white : const Color(0xFF16212B)),
    );

    return DataRow(
      color: MaterialStateProperty.resolveWith((states) {
        if (isPast) {
          return isDark ? Colors.black : Colors.white;
        } else if (isFull) {
          return isDark ? Colors.black : const Color(0x0FB5D84E); // Light warning bg
        }
        return isDark ? Colors.transparent : Colors.white;
      }),
      cells: [
        DataCell(Text(slot['slot_id']?.toString() ?? slot['id']?.toString() ?? '-', style: cellStyle)),
        DataCell(Text(slot['job_title'] ?? 'General Role', style: cellStyle)),
        DataCell(Text(_formatSlotDate(slot['slot_date']), style: cellStyle)),
        DataCell(Text(_formatSlotTime(slot['slot_time']), style: cellStyle.copyWith(fontWeight: FontWeight.bold))),
        DataCell(Text(slot['capacity']?.toString() ?? '1', style: cellStyle)),
        DataCell(Text(slot['booked_count']?.toString() ?? '0', style: cellStyle)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
        DataCell(Text(slot['created_by_name']?.toString() ?? '-', style: cellStyle)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasBookings) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: AppColors.getPrimary(isDark),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditSlotModal(slot),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.error,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteSlot(context, slot),
                ),
              ] else ...[
                Text(
                  'Has bookings',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.event_note_outlined,
              size: 32,
              color: AppColors.getPrimary(isDark).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No interview slots scheduled.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextMuted(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "New Slots" to create interview windows.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete Confirm ─────────────────────────────────────────────────────────
  void _confirmDeleteSlot(
    BuildContext context,
    Map<String, dynamic> slot,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Slot',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete this interview slot? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final recruiterId = Provider.of<AuthController>(
                context,
                listen: false,
              ).currentRecruiter?.id;
              final response = await _apiService.deleteInterviewSlot(
                slot['slot_id']?.toString() ?? slot['id']?.toString() ?? '',
                recruiterId!,
              );
              if (response['success'] == true) {
                _loadData();
                if (mounted) {
                  Provider.of<DashboardController>(
                    context,
                    listen: false,
                  ).refresh(recruiterId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Interview slot deleted successfully',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response['message'] ?? 'Failed to delete slot',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Slot Modal ─────────────────────────────────────────────────────────
  void _showEditSlotModal(Map<String, dynamic> slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobs = Provider.of<JobsController>(context, listen: false).jobs;
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;

    DateTime? slotDate;
    try {
      slotDate = DateTime.parse(slot['slot_date'].toString());
    } catch (_) {}

    TimeOfDay? slotTime;
    try {
      final parts = slot['slot_time'].toString().split(':');
      slotTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {}

    int capacity = int.tryParse(slot['capacity']?.toString() ?? '1') ?? 1;
    final bookedCount = int.tryParse(slot['booked_count']?.toString() ?? '0') ?? 0;
    
    bool isSaving = false;
    String? errorMsg;

    Widget buildSectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.getText(isDark),
          ),
        ),
      );
    }

    Widget buildInfoRow(String label, String value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextMuted(isDark),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.getText(isDark),
              ),
            ),
          ),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSoftDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Interview Slot',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getText(isDark),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.getTextMuted(isDark),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update the timing and capacity of this interview slot.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (errorMsg != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      buildSectionLabel('Job Position'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgCardDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                slot['job_title']?.toString() ?? 'Job',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.getTextMuted(isDark),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: AppColors.getTextMuted(isDark),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 16),
                        child: Text(
                          'Job position cannot be changed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.getTextMuted(isDark),
                          ),
                        ),
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DatePickerTile(
                              label: 'Date *',
                              hint: 'Select Date',
                              value: slotDate,
                              isDark: isDark,
                              firstDate: DateTime.now(),
                              onPick: (d) {
                                if (d != null) setSheetState(() => slotDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildSectionLabel('Time *'),
                                InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(
                                      context: ctx,
                                      initialTime: slotTime ?? TimeOfDay.now(),
                                    );
                                    if (t != null) setSheetState(() => slotTime = t);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.bgCardDark
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: slotTime != null
                                              ? AppColors.getPrimary(isDark)
                                              : AppColors.getTextMuted(isDark),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          slotTime?.format(ctx) ?? 'Time',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: slotTime != null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: slotTime != null
                                                ? AppColors.getText(isDark)
                                                : AppColors.getTextMuted(isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      buildSectionLabel('Capacity *'),
                      TextFormField(
                        key: ValueKey(capacity),
                        initialValue: capacity.toString(),
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.getText(isDark),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 5',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getTextMuted(isDark),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.bgCardDark
                              : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          final p = int.tryParse(val);
                          if (p != null) capacity = p;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 20),
                        child: Text(
                          bookedCount > 0 
                              ? 'Cannot reduce capacity below current bookings ($bookedCount)'
                              : 'Number of candidates that can book this slot',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.getTextMuted(isDark),
                          ),
                        ),
                      ),
                      
                      buildSectionLabel('Current Status'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.getCard(isDark) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFD9ECE5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booked',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$bookedCount / $capacity',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getText(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.getTextMuted(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (slot['is_available'] == true || slot['is_available'] == 1 || slot['is_available'] == "1") && slotDate != null && slotDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)))
                                        ? 'Yes'
                                        : 'No',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getText(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      buildSectionLabel('Additional Information'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFD9ECE5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildInfoRow('Slot ID', '#${slot['id'] ?? slot['slot_id']}'),
                            const SizedBox(height: 6),
                            buildInfoRow('Created', slot['created_at'] != null ? DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(slot['created_at'].toString())) : 'N/A'),
                            if (slot['updated_at'] != null) ...[
                              const SizedBox(height: 6),
                              buildInfoRow('Last Updated', DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(slot['updated_at'].toString()))),
                            ]
                          ],
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (slotDate == null) {
                                    setSheetState(() => errorMsg = 'Start date is required');
                                    return;
                                  }
                                  if (slotTime == null) {
                                    setSheetState(() => errorMsg = 'Time slot is required');
                                    return;
                                  }
                                  if (capacity < bookedCount) {
                                    setSheetState(() => errorMsg = 'Capacity cannot be less than current bookings');
                                    return;
                                  }

                                  setSheetState(() {
                                    isSaving = true;
                                    errorMsg = null;
                                  });

                                  final now = DateTime.now();
                                  final dt = DateTime(now.year, now.month, now.day, slotTime!.hour, slotTime!.minute);
                                  final formattedTime = DateFormat('HH:mm:ss').format(dt);

                                  final payload = {
                                    'slot_id': slot['id']?.toString() ?? slot['slot_id']?.toString() ?? '',
                                    'recruiter_id': recruiterId.toString(),
                                    'job_id': slot['job_id']?.toString() ?? '',
                                    'slot_date': DateFormat('yyyy-MM-dd').format(slotDate!),
                                    'slot_time': formattedTime,
                                    'capacity': capacity.toString(),
                                  };

                                  final response = await _apiService.updateInterviewSlot(payload);

                                  if (response['success'] == true) {
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      _loadData();
                                      if (recruiterId != null) {
                                        Provider.of<DashboardController>(
                                          context,
                                          listen: false,
                                        ).refresh(recruiterId);
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Interview slot updated successfully',
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    setSheetState(() {
                                      isSaving = false;
                                      errorMsg = response['message'] ?? 'Failed to update slot';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimary(isDark),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Update Slot',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextMuted(isDark),
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
      ),
    );
  }

  // ── Date/Time formatting helpers ───────────────────────────────────────────
  String _formatSlotDate(dynamic raw) {
    try {
      if (raw == null) return 'N/A';
      final d = DateTime.parse(raw.toString());
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatSlotTime(dynamic raw) {
    try {
      if (raw == null) return 'N/A';
      final parts = raw.toString().split(':');
      if (parts.length < 2) return raw.toString();
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final tod = TimeOfDay(hour: h, minute: m);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }
}

// ── Model helper ──────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

// ── Reusable filter dropdown ──────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final bool isDark;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.getPrimary(isDark),
          ),
          dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Date picker tile used inside the create slot modal ────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? value;
  final bool isDark;
  final ValueChanged<DateTime?> onPick;
  final DateTime firstDate;

  const _DatePickerTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.isDark,
    required this.onPick,
    required this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getText(isDark),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? firstDate,
              firstDate: firstDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            onPick(date);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: value != null
                      ? AppColors.getPrimary(isDark)
                      : AppColors.getTextMuted(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('MMM dd, yyyy').format(value!)
                        : hint,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: value != null
                          ? AppColors.getText(isDark)
                          : AppColors.getTextMuted(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
