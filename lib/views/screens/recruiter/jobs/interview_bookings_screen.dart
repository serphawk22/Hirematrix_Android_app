import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';

class InterviewBookingsScreen extends StatefulWidget {
  const InterviewBookingsScreen({super.key});

  @override
  State<InterviewBookingsScreen> createState() =>
      _InterviewBookingsScreenState();
}

class _InterviewBookingsScreenState extends State<InterviewBookingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  Map<String, dynamic> _metrics = {
    'total': '0',
    'upcoming': '0',
    'completed': '0',
    'rescheduled': '0',
  };

  String? _selectedJobId;
  String? _selectedStatus;

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
      final response = await _apiService.fetchInterviewBookings(
        recruiterId,
        jobId: _selectedJobId,
        status: _selectedStatus,
      );
      if (response['success'] == true) {
        final List<dynamic> bookingsList = response['bookings'] ?? [];
        final Map<String, dynamic> stats = response['stats'] ?? {};

        setState(() {
          _bookings = bookingsList;
          _metrics = {
            'total': (stats['total_bookings'] ?? bookingsList.length).toString(),
            'upcoming': (stats['upcoming'] ?? 0).toString(),
            'completed': (stats['completed'] ?? 0).toString(),
            'rescheduled': (stats['rescheduled'] ?? 0).toString(),
          };
        });
      }
    }
    setState(() => _isLoading = false);
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
          'Interview Bookings',
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
                    child: _bookings.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _bookings.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildBookingCard(_bookings[index], isDark),
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
            'Interview Bookings',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF16212B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track confirmed interviews, manage reschedules, and complete finished booking flows.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
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
            'Total Bookings',
            _metrics['total'],
            Icons.book_online_rounded,
            Colors.blue,
            isDark,
          ),
          _buildMetricCard(
            'Upcoming',
            _metrics['upcoming'],
            Icons.schedule_rounded,
            Colors.green,
            isDark,
          ),
          _buildMetricCard(
            'Completed',
            _metrics['completed'],
            Icons.check_circle_outline_rounded,
            Colors.teal,
            isDark,
          ),
          _buildMetricCard(
            'Rescheduled',
            _metrics['rescheduled'],
            Icons.history_rounded,
            Colors.amber,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.getCard(isDark) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedJobId,
                      hint: Text(
                        'Filter by Job',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
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
              const SizedBox(width: 10),
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.getCard(isDark) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFD9ECE5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    hint: Text(
                      'Status',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Status', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text('Confirmed', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'rescheduled',
                        child: Text('Rescheduled', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'no_show',
                        child: Text('No Show', style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled', style: GoogleFonts.inter(fontSize: 12)),
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

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark) {
    final status = (booking['booking_status'] ?? 'confirmed').toString().toUpperCase();
    final reviewDecision = booking['review_decision']?.toString();
    final hasReview = booking['review_id'] != null;

    // Check if slot date is past
    bool isPast = false;
    final slotDatetimeStr = booking['slot_datetime']?.toString() ?? '';
    if (slotDatetimeStr.isNotEmpty) {
      final dt = DateTime.tryParse(slotDatetimeStr);
      if (dt != null) {
        isPast = dt.isBefore(DateTime.now());
      }
    }

    final int rescheduleCount = int.tryParse(booking['reschedule_count']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD9ECE5)),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.08),
                child: Text(
                  (booking['candidate_name'] ?? 'C')[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['candidate_name'] ?? 'Candidate',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking['candidate_email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(status),
                  if (rescheduleCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rescheduled: ${rescheduleCount}x',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline_rounded, size: 12, color: Color(0xFF1FB7B5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking['job_title'] ?? 'Role',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppColors.getPrimary(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${booking['slot_date']}  •  ${booking['slot_time']}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLabelValue(
                'BOOKED ON',
                _formatBookedDate(booking['booked_at'] ?? booking['created_at']),
              ),
              const SizedBox(width: 48),
              _buildLabelValue('REVIEW STATUS', hasReview ? 'REVIEWED' : 'PENDING'),
            ],
          ),
          
          if (hasReview) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.01) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INTERVIEW SUMMARY',
                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey),
                      ),
                      if (reviewDecision != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDecisionColor(reviewDecision).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reviewDecision.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: _getDecisionColor(reviewDecision),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (booking['review_attendance_status'] != null) ...[
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white : Colors.black87),
                        children: [
                          TextSpan(
                            text: 'Attendance: ',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: booking['review_attendance_status'].toString().toUpperCase()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (booking['review_notes'] != null && booking['review_notes'].toString().isNotEmpty)
                    Text(
                      booking['review_notes'].toString(),
                      style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.grey[350] : Colors.black54, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          
          Row(
            children: [
              // Reschedule visible only if upcoming and confirmed/booked/rescheduled
              if (!isPast && ['booked', 'confirmed', 'rescheduled'].contains(booking['booking_status']?.toString().toLowerCase())) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRescheduleSheet(context, booking),
                    icon: const Icon(Icons.sync_rounded, size: 14, color: Colors.white),
                    label: Text(
                      'Reschedule',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF1FB7B5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Review visible if past or status completed/no_show/rescheduled
              if (isPast || ['completed', 'no_show', 'rescheduled'].contains(booking['booking_status']?.toString().toLowerCase())) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(context, booking),
                    icon: Icon(Icons.rate_review_rounded, size: 14, color: AppColors.getPrimary(isDark)),
                    label: Text(
                      hasReview ? 'Edit Review' : 'Review Interview',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                ),
              ] else if (isPast == false && !['booked', 'confirmed', 'rescheduled'].contains(booking['booking_status']?.toString().toLowerCase())) ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      '-',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  Color _getDecisionColor(String decision) {
    switch (decision.toLowerCase()) {
      case 'selected':
      case 'shortlisted':
        return Colors.green;
      case 'hold':
        return Colors.amber[800]!;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLabelValue(String label, String value) {
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
          value,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatBookedDate(dynamic createdAt) {
    final dateString = createdAt?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown';
    }
    final parts = dateString.split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      try {
        final parsed = DateTime.parse(parts[0]);
        return DateFormat('MMM dd, yyyy').format(parsed);
      } catch (_) {
        return parts[0];
      }
    }
    return dateString;
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'CANCELLED') color = Colors.redAccent;
    if (status == 'COMPLETED') color = Colors.teal;
    if (status == 'RESCHEDULED') color = Colors.amber;
    if (status == 'NO_SHOW') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 40,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No bookings found.',
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

  void _showRescheduleSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RescheduleFormSheet(
        booking: booking,
        onSuccess: () {
          _loadData();
        },
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Map<String, dynamic> booking) {
    final notesController = TextEditingController(text: booking['review_notes']?.toString() ?? '');
    final strengthsController = TextEditingController(text: booking['review_strengths']?.toString() ?? '');
    final concernsController = TextEditingController(text: booking['review_concerns']?.toString() ?? '');
    
    String attendance = booking['review_attendance_status']?.toString() ?? 'attended';
    String decision = booking['review_decision']?.toString() ?? 'shortlisted';
    
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Interview Evaluation',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Candidate: ${booking['candidate_name']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Role: ${booking['job_title']}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Attendance Dropdown
                  Text(
                    'ATTENDANCE',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: attendance,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'attended', child: Text('Attended', style: TextStyle(fontSize: 12.5))),
                      DropdownMenuItem(value: 'late', child: Text('Late but attended', style: TextStyle(fontSize: 12.5))),
                      DropdownMenuItem(value: 'no_show', child: Text('No Show', style: TextStyle(fontSize: 12.5))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          attendance = val;
                          if (attendance == 'no_show') {
                            decision = 'rejected';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Decision Dropdown
                  Text(
                    'RECRUITER DECISION',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: decision,
                    disabledHint: const Text('Rejected (No Show)', style: TextStyle(fontSize: 12.5)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
                    items: attendance == 'no_show'
                        ? null
                        : const [
                            DropdownMenuItem(value: 'shortlisted', child: Text('Shortlist for next step', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'hold', child: Text('Hold / Revisit Later', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'selected', child: Text('Select / Offer', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'rejected', child: Text('Reject', style: TextStyle(fontSize: 12.5))),
                          ],
                    onChanged: attendance == 'no_show'
                        ? null
                        : (val) {
                            if (val != null) {
                              setDialogState(() => decision = val);
                            }
                          },
                  ),
                  const SizedBox(height: 12),

                  // Strengths field
                  Text(
                    'STRENGTHS',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: strengthsController,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'What did the candidate do well?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Concerns field
                  Text(
                    'CONCERNS',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: concernsController,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Any concerns or gaps to note?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Evaluation notes field
                  Text(
                    'RECRUITER NOTES',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Summary & next steps...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey[50],
                      filled: true,
                    ),
                  ),
                ],
              ),
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
                onPressed: isSaving
                    ? null
                    : () async {
                        final recruiterId = Provider.of<AuthController>(
                          context,
                          listen: false,
                        ).currentRecruiter?.id;

                        if (recruiterId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot evaluate: Missing Recruiter ID'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        final response = await _apiService.saveInterviewReview({
                          'booking_id': booking['id'],
                          'recruiter_id': recruiterId,
                          'attendance_status': attendance,
                          'decision': decision,
                          'strengths': strengthsController.text,
                          'concerns': concernsController.text,
                          'notes': notesController.text,
                        });

                        if (context.mounted) {
                          setDialogState(() => isSaving = false);
                          Navigator.pop(ctx);
                          if (response['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  attendance == 'no_show'
                                      ? 'Interview marked as No Show'
                                      : 'Evaluation review saved successfully',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response['message'] ?? 'Failed to update review',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Review',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RescheduleFormSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const _RescheduleFormSheet({required this.booking, required this.onSuccess});

  @override
  State<_RescheduleFormSheet> createState() => _RescheduleFormSheetState();
}

class _RescheduleFormSheetState extends State<_RescheduleFormSheet> {
  final ApiService _apiService = ApiService();
  bool _isSlotsLoading = true;
  List<dynamic> _availableSlots = [];
  String? _selectedSlotId;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      final response = await _apiService.fetchInterviewSlots(
        recruiterId,
        jobId: widget.booking['job_id']?.toString(),
        status: 'available',
      );
      if (response['success'] == true) {
        setState(() {
          _availableSlots = response['slots'] ?? [];
          _isSlotsLoading = false;
        });
        return;
      }
    }
    setState(() => _isSlotsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSoftDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reschedule Booking',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'SELECT NEW AVAILABLE SLOT',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          
          if (_isSlotsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_availableSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No available interview slots scheduled for this job role. Please create a slot first in the Slots screen.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedSlotId,
              hint: Text(
                'Select new interview slot',
                style: GoogleFonts.inter(fontSize: 12.5),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: isDark ? AppColors.bgCardDark : Colors.white,
              items: _availableSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot['id']?.toString(),
                  child: Text(
                    "${slot['slot_date']} at ${slot['slot_time']} (${slot['booked_count']}/${slot['capacity']} booked)",
                    style: GoogleFonts.inter(fontSize: 12.5),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedSlotId = val);
              },
            ),
          const SizedBox(height: 16),
          
          Text(
            'REASON FOR RESCHEDULING',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter rescheduling reason...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving || _selectedSlotId == null ? null : _handleReschedule,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.getPrimary(isDark),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm Reschedule',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleReschedule() async {
    if (_selectedSlotId == null) {
      return;
    }

    setState(() => _isSaving = true);
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;

    final response = await _apiService.rescheduleInterview({
      'interview_id': widget.booking['id'],
      'recruiter_id': recruiterId,
      'slot_id': _selectedSlotId,
      'reason': _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : 'Rescheduled by recruiter',
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (response['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interview rescheduled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to reschedule'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
