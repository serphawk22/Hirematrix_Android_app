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
  String? _selectedDateStr;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId != null) {
      await Provider.of<JobsController>(context, listen: false).fetchJobs(recruiterId);
      final response = await _apiService.fetchInterviewSlots(
        recruiterId,
        jobId: _selectedJobId,
        status: _selectedStatus,
      );
      if (response['success'] == true) {
        List<dynamic> slotsList = response['slots'] ?? [];
        // Apply date filter locally since slots are returned from the api
        if (_selectedDateStr != null && _selectedDateStr!.isNotEmpty) {
          slotsList = slotsList.where((s) => s['slot_date'] == _selectedDateStr).toList();
        }

        setState(() {
          _slots = slotsList;
          _metrics = response['metrics'] ?? _metrics;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddSlotDialog() {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final capacityController = TextEditingController(text: '1');
    String? jobId;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool excludeWeekends = false;
    bool isSaving = false;

    final jobs = Provider.of<JobsController>(context, listen: false).jobs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: isDark ? AppColors.bgSoftDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                  Text(
                    'Create Interview Slot',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionLabel('Job Role'),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'Select job profile',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
                    items: jobs
                        .map(
                          (j) => DropdownMenuItem(
                            value: j.jobId,
                            child: Text(
                              j.jobTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => jobId = val,
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Date'),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Choose date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) {
                        selectedDate = date;
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(date);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Start Time'),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Choose time',
                      prefixIcon: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (time != null && context.mounted) {
                        selectedTime = time;
                        timeController.text = time.format(context);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Candidate Capacity'),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Capacity count',
                      prefixIcon: const Icon(Icons.group_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(
                      'Exclude Weekends',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Skip Saturday & Sunday slots',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    value: excludeWeekends,
                    onChanged: (v) => setDialogState(() => excludeWeekends = v),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.getPrimary(isDark),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (jobId == null ||
                                selectedDate == null ||
                                selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select job, date and time',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            final recruiterId = Provider.of<AuthController>(
                              context,
                              listen: false,
                            ).currentRecruiter?.id;

                            final hourStr = selectedTime!.hour.toString().padLeft(2, '0');
                            final minuteStr = selectedTime!.minute.toString().padLeft(2, '0');

                            final response = await _apiService.addInterviewSlot({
                              'recruiter_id': recruiterId,
                              'job_id': jobId ?? '',
                              'start_date': dateController.text,
                              'times': "[$hourStr:$minuteStr]",
                              'capacity': capacityController.text,
                              'exclude_weekends': excludeWeekends ? '1' : '0'
                            });

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              if (response['success'] == true) {
                                Navigator.pop(context);
                                _loadData();
                                if (recruiterId != null) {
                                  Provider.of<DashboardController>(
                                    context,
                                    listen: false,
                                  ).refresh(recruiterId);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Interview slot created'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response['message'] ??
                                          'Failed to create slot',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.getPrimary(isDark),
                      elevation: 0,
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
                            'Create Slot',
                            style: GoogleFonts.inter(
                              fontSize: 13,
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
      ),
    );
  }

  void _showEditSlotDialog(Map<String, dynamic> slot) {
    final dateController = TextEditingController(text: slot['slot_date']);
    
    // Parse time
    String rawTime = slot['slot_time']?.toString() ?? '10:00 AM';
    DateTime parsedTime;
    try {
      parsedTime = DateFormat('h:i A').parse(rawTime);
    } catch (_) {
      try {
        parsedTime = DateFormat('HH:mm:ss').parse(rawTime);
      } catch (_) {
        parsedTime = DateTime.now();
      }
    }
    
    final timeController = TextEditingController(text: rawTime);
    final capacityController = TextEditingController(text: slot['capacity']?.toString() ?? '1');
    
    DateTime selectedDate = DateTime.tryParse(slot['slot_date']?.toString() ?? '') ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    bool isSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: isDark ? AppColors.bgSoftDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                  Text(
                    'Edit Interview Slot',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionLabel('Date'),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Choose date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) {
                        selectedDate = date;
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(date);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Start Time'),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Choose time',
                      prefixIcon: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null && context.mounted) {
                        selectedTime = time;
                        timeController.text = time.format(context);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Candidate Capacity'),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Capacity count',
                      prefixIcon: const Icon(Icons.group_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setDialogState(() => isSaving = true);
                            final recruiterId = Provider.of<AuthController>(
                              context,
                              listen: false,
                            ).currentRecruiter?.id;

                            final hourStr = selectedTime.hour.toString().padLeft(2, '0');
                            final minuteStr = selectedTime.minute.toString().padLeft(2, '0');

                            final response = await _apiService.updateInterviewSlot({
                              'recruiter_id': recruiterId,
                              'slot_id': slot['id'],
                              'slot_date': dateController.text,
                              'slot_time': "$hourStr:$minuteStr:00",
                              'capacity': capacityController.text,
                            });

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              if (response['success'] == true) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Interview slot updated'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response['message'] ??
                                          'Failed to update slot',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.getPrimary(isDark),
                      elevation: 0,
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
                            'Save Changes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
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
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Responsive().init(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4FBFA),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? null : const LinearGradient(
            colors: [Color(0xFFF4FBFA), Color(0xFFEEF9F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBlock(isDark),
                  _buildMetricsHeader(isDark),
                  _buildFilterBar(isDark),
                  Expanded(
                    child: _slots.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                            itemCount: _slots.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildSlotCard(_slots[index], isDark),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderBlock(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interview Slots Management',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF16212B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create, review, and manage slots before candidates book interview windows.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddSlotDialog,
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Create New Slots',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FB7B5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InterviewBookingsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.book_online_rounded, size: 16, color: const Color(0xFF1FB7B5)),
                  label: Text(
                    'View All Bookings',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: const Color(0xFF1FB7B5),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1FB7B5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildMetricsHeader(bool isDark) {
    return Container(
      height: 94,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricCard(
            'Total Slots',
            _metrics['total'],
            Icons.event_note_rounded,
            Colors.blue,
            isDark,
          ),
          _buildMetricCard(
            'Available',
            _metrics['available'],
            Icons.event_available_rounded,
            Colors.green,
            isDark,
          ),
          _buildMetricCard(
            'Fully Booked',
            _metrics['booked'],
            Icons.event_busy_rounded,
            Colors.orange,
            isDark,
          ),
          _buildMetricCard(
            'Bookings',
            _metrics['total_bookings'],
            Icons.people_outline_rounded,
            Colors.purple,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String val,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 136,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD9ECE5),
          width: 1,
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
                val,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF16212B),
                ),
              ),
              Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final jobs = Provider.of<JobsController>(context, listen: false).jobs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedJobId,
                      hint: Text(
                        'Job Role',
                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All Jobs',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                        ...jobs.map(
                          (j) => DropdownMenuItem(
                            value: j.jobId,
                            child: Text(
                              j.jobTitle,
                              style: GoogleFonts.inter(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedJobId = val);
                        _loadData();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateStr != null
                          ? DateTime.tryParse(_selectedDateStr!) ?? DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDateStr = DateFormat('yyyy-MM-dd').format(date);
                      });
                      _loadData();
                    }
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.getCard(isDark) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDateStr == null
                                ? 'Choose Date'
                                : DateFormat('MMM dd, yyyy').format(DateTime.parse(_selectedDateStr!)),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: _selectedDateStr == null ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDateStr != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedDateStr = null;
                              });
                              _loadData();
                            },
                          )
                        else
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.getCard(isDark) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    hint: Text(
                      'Status',
                      style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All', style: GoogleFonts.inter(fontSize: 11.5)),
                      ),
                      DropdownMenuItem(
                        value: 'available',
                        child: Text(
                          'Available',
                          style: GoogleFonts.inter(fontSize: 11.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'full',
                        child: Text(
                          'Full',
                          style: GoogleFonts.inter(fontSize: 11.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'past',
                        child: Text(
                          'Past',
                          style: GoogleFonts.inter(fontSize: 11.5),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot, bool isDark) {
    final status = (slot['status'] ?? 'Available').toString().toUpperCase();
    final int bookedCount = int.tryParse(slot['booked_count']?.toString() ?? '0') ?? 0;
    
    Color statusColor = Colors.green;
    Color cardBorderColor = isDark ? Colors.white10 : const Color(0xFFD9ECE5);
    Color cardBgColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    double opacity = 1.0;

    if (status == 'PAST') {
      statusColor = Colors.grey;
      opacity = 0.7;
      cardBgColor = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9);
    } else if (status == 'FULLY BOOKED' || status == 'FULL') {
      statusColor = Colors.orange;
      cardBorderColor = Colors.amber.withValues(alpha: 0.4);
      cardBgColor = isDark ? Colors.amber.withValues(alpha: 0.02) : const Color(0xFFFFFBEB);
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot['job_title'] ?? 'General Role',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${slot['slot_date']}  •  ${slot['slot_time']}",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSlotMetric(
                  'CAPACITY',
                  slot['capacity']?.toString() ?? '1',
                  isDark,
                ),
                const SizedBox(width: 32),
                _buildSlotMetric(
                  'BOOKED COUNT',
                  bookedCount.toString(),
                  isDark,
                ),
                const SizedBox(width: 32),
                _buildSlotMetric(
                  'CREATED BY',
                  slot['created_by_name'] ?? 'System',
                  isDark,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InterviewBookingsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      'View Bookings',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (bookedCount == 0 && status != 'PAST') ...[
                  IconButton(
                    onPressed: () => _showEditSlotDialog(slot),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _confirmDeleteSlot(context, slot),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == 'PAST' ? 'Past Slot' : 'Has active bookings',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotMetric(String label, String val, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 40,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No interview slots scheduled.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSlot(BuildContext context, Map<String, dynamic> slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Slot',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete this interview slot?',
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
                slot['slot_id'].toString(),
                recruiterId!,
              );
              if (response['success'] == true) {
                _loadData();
                if (mounted) {
                  Provider.of<DashboardController>(
                    context,
                    listen: false,
                  ).refresh(recruiterId);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Interview slot deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      response['message'] ?? 'Failed to delete slot',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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
}
