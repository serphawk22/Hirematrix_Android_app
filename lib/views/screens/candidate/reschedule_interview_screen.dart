import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/reschedule_interview_controller.dart';

class RescheduleInterviewScreen extends StatefulWidget {
  final dynamic applicationId;

  const RescheduleInterviewScreen({super.key, required this.applicationId});

  @override
  State<RescheduleInterviewScreen> createState() =>
      _RescheduleInterviewScreenState();
}

class _RescheduleInterviewScreenState extends State<RescheduleInterviewScreen> {
  late final RescheduleInterviewController _controller;
  bool _isRescheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(RescheduleInterviewController());
    _controller.fetchRescheduleInfo(widget.applicationId);
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

  String _formatDateTimeString(String dateTimeStr) {
    try {
      final parsed = DateTime.parse(dateTimeStr);
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
      final hour = parsed.hour > 12
          ? parsed.hour - 12
          : (parsed.hour == 0 ? 12 : parsed.hour);
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      return '${days[parsed.weekday - 1]}, ${months[parsed.month - 1]} ${parsed.day}, ${parsed.year} at $hour:$minute $period';
    } catch (_) {
      return dateTimeStr;
    }
  }

  Future<void> _processReschedule() async {
    final slotId = _controller.selectedSlotId.value;
    if (slotId == null) return;

    final success = await _controller.rescheduleBooking(
      applicationId: widget.applicationId,
      slotId: slotId,
      reason: _controller.reasonController.text,
    );
    if (success) {
      setState(() {
        _isRescheduled = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Get.back();
        }
      });
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
          'Reschedule Interview',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getPrimary(isDark),
                ),
              ),
            );
          }

          final jobTitle =
              _controller.application.value?['job_title'] ?? 'Position';
          final currentBooking = _controller.booking.value;
          final remaining =
              _controller.canRescheduleInfo.value?['remaining_reschedules'] ??
              0;
          final maxReschedules = currentBooking?['max_reschedules'] ?? 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header text
                Row(
                  children: [
                    Icon(
                      Icons.sync_alt,
                      color: AppColors.getPrimary(isDark),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'INTERVIEW RESCHEDULE',
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
                  'Move Your Interview',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a new slot if you need to move your upcoming interview within the allowed limit.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: subtitleColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Meta Chips
                Row(
                  children: [
                    _buildHeaderMetaChip(
                      '$jobTitle Position',
                      Icons.work_outline,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderMetaChip(
                      '$remaining remaining reschedules',
                      Icons.repeat_one,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Current Interview Details Card
                if (currentBooking != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.getPrimary(isDark),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Booking',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatDateTimeString(
                            currentBooking['slot_datetime'] ?? '',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Reschedules Remaining: $remaining out of $maxReschedules',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_controller.availableSlots.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 40,
                          color: Colors.orange[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Alternative Slots Available',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please contact HR for assistance.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: subtitleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Slots List Section
                  Text(
                    'Select New Slot',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._controller.groupedSlots.entries.map((entry) {
                    final dateStr = entry.key;
                    final daySlots = entry.value;

                    // Filter out current slot
                    final filteredSlots = daySlots.where((slot) {
                      final slotId =
                          int.tryParse(slot['id']?.toString() ?? '') ?? 0;
                      return slotId != currentBooking?['slot_id'];
                    }).toList();

                    if (filteredSlots.isEmpty) return const SizedBox.shrink();

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
                          // Date Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[900]
                                  : const Color(0xFFF9FAFB),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.grey[850]!
                                      : Colors.grey[200]!,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColors.getPrimary(isDark),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDate(dateStr),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Time slots grid
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 2.3,
                                  ),
                              itemCount: filteredSlots.length,
                              itemBuilder: (context, idx) {
                                final slot = filteredSlots[idx];
                                final int slotId =
                                    int.tryParse(
                                      slot['id']?.toString() ?? '',
                                    ) ??
                                    0;
                                final capacity =
                                    int.tryParse(
                                      slot['capacity']?.toString() ?? '',
                                    ) ??
                                    0;
                                final booked =
                                    int.tryParse(
                                      slot['booked_count']?.toString() ?? '',
                                    ) ??
                                    0;
                                final spotsLeft = capacity - booked;
                                final isSelected =
                                    _controller.selectedSlotId.value == slotId;

                                return InkWell(
                                  onTap: () {
                                    _controller.selectedSlotId.value = slotId;
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.getPrimary(
                                              isDark,
                                            ).withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.getPrimary(isDark)
                                            : (isDark
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[300]!),
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time_outlined,
                                              size: 13,
                                              color: isSelected
                                                  ? AppColors.getPrimary(isDark)
                                                  : subtitleColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTime(
                                                slot['slot_datetime'] ?? '',
                                              ),
                                              style: GoogleFonts.inter(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 12.5,
                                                color: isSelected
                                                    ? AppColors.getPrimary(
                                                        isDark,
                                                      )
                                                    : textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$spotsLeft spots left',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppColors.getPrimary(
                                                    isDark,
                                                  ).withOpacity(0.8)
                                                : subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Reason for Rescheduling field
                  Text(
                    'Reason for Rescheduling (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller.reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Please provide a brief reason...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: subtitleColor,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.getPrimary(isDark),
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 20),

                  // Warning alert box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Warning',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• You have $remaining reschedule(s) remaining.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red[850],
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• After reaching the limit, you won\'t be able to reschedule again.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red[850],
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• Cancellation is NOT allowed.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red[850],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions row
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          (_controller.selectedSlotId.value == null ||
                              _controller.isRescheduling.value ||
                              _isRescheduled)
                          ? null
                          : _processReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRescheduled
                            ? Colors.grey
                            : const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _controller.isRescheduling.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sync, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _isRescheduled
                                      ? 'Rescheduled'
                                      : 'Confirm Reschedule',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],

                // Reschedule History Timeline Section
                if (_controller.history.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Reschedule History',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.history.length,
                    itemBuilder: (context, index) {
                      final item = _controller.history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[850]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.history,
                                  color: subtitleColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: textColor,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'From: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: _formatDateTimeString(
                                                item['old_slot_datetime'] ?? '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: textColor,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'To: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: _formatDateTimeString(
                                                item['new_slot_datetime'] ?? '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item['reason'] != null &&
                                item['reason']
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Reason: "${item['reason']}"',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatDateTimeString(
                                  item['rescheduled_at'] ?? '',
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeaderMetaChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
