import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';

// ── Booking status meta ────────────────────────────────────────────────────────
class _StatusMeta {
  final Color color;
  final String label;
  const _StatusMeta(this.color, this.label);
}

const _statusMap = {
  'booked': _StatusMeta(Color(0xFF1FB7B5), 'Booked'),
  'confirmed': _StatusMeta(Color(0xFF53B86C), 'Confirmed'),
  'completed': _StatusMeta(Color(0xFF0D8A90), 'Completed'),
  'rescheduled': _StatusMeta(Color(0xFFF59E0B), 'Rescheduled'),
  'no_show': _StatusMeta(Color(0xFFEF4444), 'No Show'),
  'cancelled': _StatusMeta(Color(0xFFEF4444), 'Cancelled'),
};

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
      final response = await _apiService.fetchInterviewBookings(
        recruiterId,
        jobId: _selectedJobId,
        status: _selectedStatus,
      );
      if (response['success'] == true) {
        final List<dynamic> bookingsList = response['bookings'] ?? [];
        final Map<String, dynamic>? metricsData = response['metrics'];

        setState(() {
          _bookings = bookingsList;
          if (metricsData != null) {
            _metrics = {
              'total': metricsData['total']?.toString() ?? '0',
              'upcoming': metricsData['upcoming']?.toString() ?? '0',
              'completed': metricsData['completed']?.toString() ?? '0',
              'rescheduled': metricsData['rescheduled']?.toString() ?? '0',
            };
          }
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Interview Bookings',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                // Summary stat cards
                _buildSummaryCards(isDark),
                // Filter bar
                _buildFilterBar(isDark),
                // Bookings list
                Expanded(
                  child: _bookings.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _bookings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _buildBookingCard(_bookings[i], isDark),
                        ),
                ),
              ],
            ),
    );
  }

  // ── Summary Cards (mirrors bookings.php stats row) ─────────────────────────
  Widget _buildSummaryCards(bool isDark) {
    int upcomingCount = _bookings.where((b) {
      final status = (b['booking_status'] ?? '').toString().toLowerCase();
      if (!['booked', 'confirmed', 'rescheduled'].contains(status)) {
        return false;
      }
      try {
        final slotDt = DateTime.parse(
          '${b['slot_date'] ?? ''} ${b['slot_time'] ?? '00:00:00'}',
        );
        return slotDt.isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).length;

    final items = [
      _CardItem(
        'Total Bookings',
        _metrics['total']?.toString() ?? '0',
        Icons.book_online_rounded,
        Colors.blue,
      ),
      _CardItem(
        'Upcoming',
        upcomingCount.toString(),
        Icons.schedule_rounded,
        AppColors.success,
      ),
      _CardItem(
        'Completed',
        _metrics['completed']?.toString() ?? '0',
        Icons.check_circle_outline_rounded,
        const Color(0xFF0D8A90),
      ),
      _CardItem(
        'Rescheduled',
        _metrics['rescheduled']?.toString() ?? '0',
        Icons.history_rounded,
        AppColors.warning,
      ),
    ];

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: items
            .map(
              (item) => Container(
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF16212B),
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
                        color: isDark
                            ? AppColors.textMutedDark
                            : const Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Filter Bar (mirrors bookings.php filter form) ──────────────────────────
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
              Text(
                'Narrow bookings by job and status.',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.getTextMuted(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Job filter
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextMuted(isDark),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildFilterDropdown<String>(
                      hint: 'All Jobs',
                      value: _selectedJobId,
                      isDark: isDark,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Jobs'),
                        ),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status filter
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextMuted(isDark),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildFilterDropdown<String>(
                      hint: 'All Status',
                      value: _selectedStatus,
                      isDark: isDark,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Status')),
                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('Confirmed'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'rescheduled',
                          child: Text('Rescheduled'),
                        ),
                        DropdownMenuItem(value: 'no_show', child: Text('No Show')),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedStatus = v);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedJobId != null || _selectedStatus != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedJobId = null;
                  _selectedStatus = null;
                });
                _loadData();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.clear_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Clear filters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String hint,
    required T? value,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
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

  // ── Booking Card (mirrors bookings.php table row) ──────────────────────────
  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark) {
    final statusKey = (booking['booking_status'] ?? 'booked')
        .toString()
        .toLowerCase();
    final meta =
        _statusMap[statusKey] ??
        const _StatusMeta(Color(0xFF64748B), 'Unknown');

    // Determine past/upcoming
    bool isPast = false;
    bool isUpcoming = false;
    try {
      final slotDt = DateTime.parse(
        '${booking['slot_date'] ?? ''} ${booking['slot_time'] ?? '00:00:00'}',
      );
      isPast = slotDt.isBefore(DateTime.now());
      isUpcoming = slotDt.isAfter(DateTime.now());
    } catch (_) {}

    final hasReview =
        (booking['review_id'] != null &&
            booking['review_id'].toString().isNotEmpty) ||
        (booking['review_decision'] != null &&
            booking['review_decision'].toString().isNotEmpty);

    final rescheduleCount =
        int.tryParse(booking['reschedule_count']?.toString() ?? '0') ?? 0;

    final candidateName = booking['candidate_name'] ?? 'Candidate';
    final initials = candidateName.isNotEmpty
        ? candidateName[0].toUpperCase()
        : 'C';

    // Show reschedule button if upcoming & eligible
    final canReschedule =
        isUpcoming &&
        ['booked', 'confirmed', 'rescheduled'].contains(statusKey);

    // Show review button if past OR in certain statuses
    final canReview =
        isPast || ['completed', 'no_show', 'rescheduled'].contains(statusKey);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPast
              ? (isDark ? AppColors.borderDark : const Color(0xFFEEF2F7))
              : (isDark ? AppColors.borderDark : const Color(0xFFD9ECE5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.getPrimary(
                    isDark,
                  ).withOpacity(0.1),
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + job
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidateName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getText(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        booking['email']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.getTextMuted(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status badge
                _buildStatusBadge(meta),
              ],
            ),
          ),

          // ── Job title row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 12,
                  color: AppColors.getTextMuted(isDark),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    booking['job_title']?.toString() ?? 'Unknown Role',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Date & time strip ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColors.getPrimary(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSlotDate(booking['slot_date']),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.getTextMuted(isDark),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppColors.getPrimary(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatSlotTime(booking['slot_time']),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const Spacer(),
                  if (isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PAST',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Info grid (Booked On + Review / Reschedule count) ──────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildLabelValue(
                  'BOOKED ON',
                  _formatBookedDate(booking['booked_at']),
                  isDark,
                ),
                const SizedBox(width: 24),
                if (hasReview) ...[
                  _buildLabelValue(
                    'REVIEW',
                    'Reviewed',
                    isDark,
                    color: AppColors.success,
                  ),
                  if (booking['review_decision'] != null) ...[
                    const SizedBox(width: 24),
                    _buildLabelValue(
                      'DECISION',
                      _capitalizeWords(booking['review_decision'].toString()),
                      isDark,
                    ),
                  ],
                ] else
                  _buildLabelValue(
                    'REVIEW',
                    'Pending',
                    isDark,
                    color: AppColors.getTextMuted(isDark),
                  ),
                if (rescheduleCount > 0) ...[
                  const SizedBox(width: 24),
                  _buildLabelValue(
                    'RESCHEDULED',
                    '${rescheduleCount}x',
                    isDark,
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),

          // Review notes preview
          if (hasReview &&
              booking['review_notes'] != null &&
              booking['review_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _truncate(booking['review_notes'].toString(), 80),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.getTextMuted(isDark),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // ── Action buttons ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                // Review / Edit Review button (mirrors php: past or eligible)
                if (canReview)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(context, booking),
                      icon: Icon(
                        hasReview
                            ? Icons.edit_outlined
                            : Icons.rate_review_outlined,
                        size: 13,
                        color: AppColors.getPrimary(isDark),
                      ),
                      label: Text(
                        hasReview ? 'Edit Review' : 'Review Interview',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.getPrimary(isDark).withOpacity(0.3),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                // Reschedule button (mirrors php: upcoming & eligible)
                if (canReschedule) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRescheduleSheet(context, booking),
                      icon: const Icon(
                        Icons.sync_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
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
                        backgroundColor: AppColors.getPrimary(isDark),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],

                // If neither action is available
                if (!canReview && !canReschedule)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(
                        '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.getTextMuted(isDark),
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildStatusBadge(_StatusMeta meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        meta.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: meta.color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildLabelValue(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextMuted(isDark),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.getText(isDark),
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
              Icons.event_busy_rounded,
              size: 32,
              color: AppColors.getPrimary(isDark).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.getTextMuted(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adjust your filters or create interview slots.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.getTextMuted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Review Dialog ──────────────────────────────────────────────────────────
  void _showReviewDialog(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _ReviewFormDialog(booking: booking, onSuccess: _loadData),
    );
  }

  // ── Reschedule Sheet ───────────────────────────────────────────────────────
  void _showRescheduleSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _RescheduleFormSheet(booking: booking, onSuccess: _loadData),
    );
  }

  // ── Formatting helpers ─────────────────────────────────────────────────────
  String _formatSlotDate(dynamic raw) {
    try {
      if (raw == null || raw.toString().isEmpty) return 'N/A';
      final d = DateTime.parse(raw.toString());
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatSlotTime(dynamic raw) {
    try {
      if (raw == null || raw.toString().isEmpty) return 'N/A';
      final parts = raw.toString().split(':');
      if (parts.length < 2) return raw.toString();
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatBookedDate(dynamic raw) {
    try {
      if (raw == null || raw.toString().isEmpty) return 'N/A';
      final d = DateTime.parse(raw.toString().trim());
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      final parts = raw.toString().split(' ');
      return parts.isNotEmpty ? parts[0] : raw.toString();
    }
  }

  String _capitalizeWords(String s) {
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }
}

// ── Decision chip widget ───────────────────────────────────────────────────────
class _DecisionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _DecisionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : AppColors.getTextMuted(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.getTextMuted(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reschedule form sheet ──────────────────────────────────────────────────────
class _RescheduleFormSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const _RescheduleFormSheet({required this.booking, required this.onSuccess});

  @override
  State<_RescheduleFormSheet> createState() => _RescheduleFormSheetState();
}

class _RescheduleFormSheetState extends State<_RescheduleFormSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
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
          // Handle
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reschedule Booking',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.booking['candidate_name']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.getTextMuted(isDark),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Select New Date
          Text(
            'SELECT NEW DATE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextMuted(isDark),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    size: 16,
                    color: _selectedDate != null
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getTextMuted(isDark),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Choose Date'
                        : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedDate != null
                          ? AppColors.getText(isDark)
                          : AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Select New Time
          Text(
            'SELECT NEW TIME',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextMuted(isDark),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    Icons.access_time_rounded,
                    size: 16,
                    color: _selectedTime != null
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getTextMuted(isDark),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime == null
                        ? 'Choose Time'
                        : _selectedTime!.format(context),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTime != null
                          ? AppColors.getText(isDark)
                          : AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm button
          ElevatedButton(
            onPressed: _isSaving ? null : _handleReschedule,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.getPrimary(isDark),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                      fontSize: 14,
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
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select both date and time',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    final finalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final response = await _apiService.rescheduleInterview({
      'interview_id': widget.booking['id'],
      'recruiter_id': recruiterId,
      'interview_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime),
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (response['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Interview rescheduled successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to reschedule',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Review Form Dialog ───────────────────────────────────────────────────────
class _ReviewFormDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onSuccess;

  const _ReviewFormDialog({
    Key? key,
    required this.booking,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<_ReviewFormDialog> {
  final _strengthsController = TextEditingController();
  final _concernsController = TextEditingController();
  final _notesController = TextEditingController();
  String _attendance = 'attended';
  String _decision = 'shortlisted';
  bool _isSaving = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _attendance =
        widget.booking['review_attendance_status']?.toString() ?? 'attended';
    if (_attendance.isEmpty) _attendance = 'attended';

    _decision = widget.booking['review_decision']?.toString() ?? 'shortlisted';
    if (_decision.isEmpty) _decision = 'shortlisted';

    _notesController.text = widget.booking['review_notes']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Interview',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getText(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Candidate: ${widget.booking['candidate_name'] ?? 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.getTextMuted(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.getTextMuted(isDark),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('ATTENDANCE', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: _inputDecoration(isDark),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _attendance,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? AppColors.bgCardDark
                              : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.getTextMuted(isDark),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'attended',
                              child: Text(
                                'Attended',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'late',
                              child: Text(
                                'Late but attended',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'no_show',
                              child: Text(
                                'No Show',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _attendance = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle('RECRUITER DECISION', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: _inputDecoration(isDark),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _decision,
                          isExpanded: true,
                          dropdownColor: isDark
                              ? AppColors.bgCardDark
                              : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.getTextMuted(isDark),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'shortlisted',
                              child: Text(
                                'Shortlist for next step',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'hold',
                              child: Text(
                                'Hold / Revisit Later',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'selected',
                              child: Text(
                                'Select / Offer',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text(
                                'Reject',
                                style: _inputTextStyle(isDark),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _decision = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('STRENGTHS', isDark),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _strengthsController,
                                'What did they do well?',
                                isDark,
                                lines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('CONCERNS', isDark),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _concernsController,
                                'Any concerns?',
                                isDark,
                                lines: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle('RECRUITER NOTES', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _notesController,
                      'Write the interview summary and next steps...',
                      isDark,
                      lines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Footer / Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE2E8F0),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.getPrimary(isDark),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Review',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() => _isSaving = true);

    final response = await _apiService.submitInterviewReview({
      'booking_id': widget.booking['id'],
      'recruiter_id': recruiterId,
      'attendance_status': _attendance,
      'decision': _decision,
      'notes': _notesController.text,
      'strengths': _strengthsController.text,
      'concerns': _concernsController.text,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (response['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review submitted successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to submit review',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.getTextMuted(isDark),
        letterSpacing: 0.5,
      ),
    );
  }

  BoxDecoration _inputDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.bgCardDark : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
      ),
    );
  }

  TextStyle _inputTextStyle(bool isDark) {
    return GoogleFonts.inter(fontSize: 13, color: AppColors.getText(isDark));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      style: _inputTextStyle(isDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.getTextMuted(isDark),
        ),
        filled: true,
        fillColor: isDark ? AppColors.bgCardDark : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.getPrimary(isDark),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}

// ── Card item model ───────────────────────────────────────────────────────────
class _CardItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CardItem(this.label, this.value, this.icon, this.color);
}
