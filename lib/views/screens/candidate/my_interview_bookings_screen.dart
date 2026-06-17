import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/my_interview_bookings_controller.dart';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/views/screens/candidate/reschedule_interview_screen.dart';

class MyInterviewBookingsScreen extends StatefulWidget {
  const MyInterviewBookingsScreen({super.key});

  @override
  State<MyInterviewBookingsScreen> createState() =>
      _MyInterviewBookingsScreenState();
}

class _MyInterviewBookingsScreenState extends State<MyInterviewBookingsScreen> {
  late final MyInterviewBookingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MyInterviewBookingsController());
  }

  void _launchWebUrl(String path) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl.replaceAll('/api', '')}/$path',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar('Error', 'Could not open portal page.');
      }
    } catch (_) {
      Get.snackbar('Error', 'Invalid portal URL.');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String dateTimeStr) {
    try {
      final parsed = DateTime.parse(dateTimeStr);
      final hour = parsed.hour > 12
          ? parsed.hour - 12
          : (parsed.hour == 0 ? 12 : parsed.hour);
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _getCountdownText(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);

    if (diff.isNegative) {
      return 'This interview has already started.';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return 'You have ${days}d ${hours}h left to prepare.';
    } else if (hours > 0) {
      return 'You have ${hours}h ${minutes}m left to prepare.';
    } else {
      return 'You have $minutes minute(s) left. Starting soon!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode;
    final mainBg = AppColors.getBackground(isDark);
    final cardColor = AppColors.getCard(isDark);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'My Bookings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.fetchBookings,
          color: AppColors.getPrimary(isDark),
          child: Obx(() {
            return _controller.isLoading.value
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getPrimary(isDark),
                      ),
                    ),
                  )
                : _controller.errorMessage.value.isNotEmpty
                ? _buildErrorState(textColor, subtitleColor, isDark)
                : _controller.bookingsList.isEmpty
                ? _buildEmptyState(cardColor, textColor, subtitleColor, isDark)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.getPrimary(isDark),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'INTERVIEW CALENDAR',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'My Interview Bookings',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review upcoming interviews, track completed bookings, and reschedule when needed.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Metrics Summary Row
                        _buildMetricsRow(isDark),
                        const SizedBox(height: 24),

                        // Next Action Box (if upcoming exists)
                        if (_controller.nextBooking.value != null) ...[
                          _buildNextActionCard(isDark),
                          const SizedBox(height: 24),
                        ],

                        // Timeline list
                        Text(
                          'Booking Timeline',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Combined list of items
                        ..._controller.upcomingBookings.map(
                          (b) => _buildBookingCard(
                            b,
                            true,
                            isDark,
                            cardColor,
                            textColor,
                            subtitleColor,
                          ),
                        ),
                        ..._controller.pastBookings.map(
                          (b) => _buildBookingCard(
                            b,
                            false,
                            isDark,
                            cardColor,
                            textColor,
                            subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  );
          }),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetricChip('Total: ${_controller.bookingsList.length}', isDark),
        _buildMetricChip(
          'Upcoming: ${_controller.upcomingCount.value}',
          isDark,
        ),
        _buildMetricChip(
          'Completed: ${_controller.completedCount.value}',
          isDark,
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[300] : const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildNextActionCard(bool isDark) {
    final nextBooking = _controller.nextBooking.value;
    if (nextBooking == null) return const SizedBox.shrink();

    final jobTitle = nextBooking['job_title'] ?? 'Role';
    final slotDtStr = nextBooking['slot_datetime']?.toString() ?? '';
    final target = DateTime.tryParse(slotDtStr) ?? DateTime.now();

    final maxReschedules =
        int.tryParse(nextBooking['max_reschedules']?.toString() ?? '') ?? 2;
    final reschedulesCount =
        int.tryParse(nextBooking['reschedule_count']?.toString() ?? '') ?? 0;
    final canReschedule =
        reschedulesCount < maxReschedules &&
        target.difference(DateTime.now()).inSeconds > 86400;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NEXT ACTION',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            jobTitle,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(slotDtStr)} at ${_formatTime(slotDtStr)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getCountdownText(target),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (canReschedule)
                ElevatedButton.icon(
                  onPressed: () => _launchWebUrl(
                    'candidate/reschedule-slot/${nextBooking['application_id']}',
                  ),
                  icon: const Icon(Icons.sync, size: 14),
                  label: Text(
                    'Reschedule now',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.block, size: 14),
                  label: Text(
                    'Reschedule locked',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledForegroundColor: isDark
                        ? Colors.grey[600]!
                        : Colors.grey[400]!,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF1E3A8A),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFBFDBFE),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    dynamic booking,
    bool isUpcoming,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final jobTitle = booking['job_title'] ?? 'Role';
    final slotDtStr = booking['slot_datetime']?.toString() ?? '';
    final bookedAtStr = booking['booked_at']?.toString() ?? '';
    final lastReschedStr = booking['last_rescheduled_at']?.toString() ?? '';
    final bookingStatus = booking['booking_status'] ?? 'booked';

    final maxReschedules =
        int.tryParse(booking['max_reschedules']?.toString() ?? '') ?? 2;
    final reschedulesCount =
        int.tryParse(booking['reschedule_count']?.toString() ?? '') ?? 0;

    final target = DateTime.tryParse(slotDtStr) ?? DateTime.now();
    final canReschedule =
        isUpcoming &&
        reschedulesCount < maxReschedules &&
        target.difference(DateTime.now()).inSeconds > 86400;

    // Status colors & labels mapping
    Color statusBadgeColor = const Color(0xFF3B82F6);
    String statusLabel = 'Booked';

    switch (bookingStatus) {
      case 'rescheduled':
        statusBadgeColor = const Color(0xFFF59E0B);
        statusLabel = 'Rescheduled';
        break;
      case 'completed':
        statusBadgeColor = const Color(0xFF10B981);
        statusLabel = 'Completed';
        break;
      case 'no_show':
      case 'cancelled':
        statusBadgeColor = const Color(0xFFEF4444);
        statusLabel = bookingStatus == 'no_show' ? 'No Show' : 'Cancelled';
        break;
    }

    String statusSummary =
        'Your slot is confirmed. You can still reschedule if your plans change.';
    String statusNextStep = 'Reschedule only if you need a different time.';

    if (bookingStatus == 'completed') {
      statusSummary =
          'This interview has finished. Watch this card for the next update from the hiring team.';
      statusNextStep = 'Await the recruiter update in your booking history.';
    } else if (!canReschedule && isUpcoming) {
      statusSummary =
          'Your slot is locked, so the best next step is preparation.';
      statusNextStep = 'Review the role details and prepare for the call.';
    } else if (bookingStatus == 'no_show') {
      statusSummary =
          'The interview was missed. If needed, check whether the role still allows another slot.';
      statusNextStep =
          'If the role is still open, consider reaching out to the recruiter.';
    } else if (bookingStatus == 'cancelled') {
      statusSummary = 'This booking is no longer active.';
      statusNextStep =
          'Look for a new interview slot or apply again if the role reopens.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marker Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUpcoming
                      ? Icons.upcoming_outlined
                      : Icons.check_circle_outline,
                  size: 15,
                  color: isUpcoming
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  isUpcoming ? 'UPCOMING INTERVIEW' : 'COMPLETED INTERVIEW',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    color: isUpcoming
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                if (isUpcoming)
                  Text(
                    _getTimeLeftText(target),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        jobTitle,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBadgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusBadgeColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusBadgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatDate(slotDtStr)} at ${_formatTime(slotDtStr)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: subtitleColor,
                  ),
                ),
                const Divider(height: 24),

                // Details columns
                if (isUpcoming) ...[
                  Text(
                    'What to do:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildFactBullet(
                    canReschedule
                        ? 'Confirm this slot, or reschedule if you need more time.'
                        : 'Focus on preparation because rescheduling is no longer available.',
                    subtitleColor,
                  ),
                  _buildFactBullet(
                    'Review the job description and match your answers to it.',
                    subtitleColor,
                  ),
                  _buildFactBullet(
                    'Prepare a short introduction and 2 to 3 role examples.',
                    subtitleColor,
                  ),
                  const SizedBox(height: 16),
                ],

                // Booking details block
                Text(
                  'Booking details:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                if (bookedAtStr.isNotEmpty)
                  _buildFactItem(
                    'Booked on:',
                    _formatDate(bookedAtStr),
                    subtitleColor,
                  ),
                _buildFactItem(
                  'Reschedules:',
                  '$reschedulesCount / $maxReschedules',
                  subtitleColor,
                ),
                if (lastReschedStr.isNotEmpty)
                  _buildFactItem(
                    'Last rescheduled:',
                    _formatDate(lastReschedStr),
                    subtitleColor,
                  ),
                const SizedBox(height: 12),

                // Current status block inside card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusSummary,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: subtitleColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusNextStep,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.getPrimary(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                if (!isUpcoming)
                  Expanded(
                    child: Text(
                      'Interview completed',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else ...[
                  if (booking['calendar_add_link'] != null &&
                      booking['calendar_add_link'].toString().isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(
                          booking['calendar_add_link'].toString(),
                        );
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: AppColors.getPrimary(isDark),
                      ),
                      label: Text(
                        'Add to Calendar',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (canReschedule)
                    ElevatedButton(
                      onPressed: () => Get.to(
                        () => RescheduleInterviewScreen(
                          applicationId: booking['application_id'],
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Reschedule',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Locked',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactItem(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Text(
            '$label ',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFactBullet(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 6.0),
            child: Icon(Icons.circle, size: 4, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeLeftText(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }

  Widget _buildEmptyState(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              'No Interview Bookings',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have any scheduled interviews yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(isDark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Go to Dashboard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textColor, Color subtitleColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.fetchBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
