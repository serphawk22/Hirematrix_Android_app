import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/book_interview_slot_controller.dart';

class BookInterviewSlotScreen extends StatefulWidget {
  final dynamic applicationId;

  const BookInterviewSlotScreen({super.key, required this.applicationId});

  @override
  State<BookInterviewSlotScreen> createState() =>
      _BookInterviewSlotScreenState();
}

class _BookInterviewSlotScreenState extends State<BookInterviewSlotScreen> {
  late final BookInterviewSlotController _controller;
  bool _isBooked = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(BookInterviewSlotController());
    _controller.fetchSlots(widget.applicationId);
  }

  Future<void> _confirmBooking() async {
    final slotId = _controller.selectedSlotId.value;
    if (slotId == null) return;

    final success = await _controller.confirmBooking(
      applicationId: widget.applicationId,
      slotId: slotId,
    );
    if (success) {
      setState(() {
        _isBooked = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Get.back(); // Pop book slot screen
        }
      });
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
          'Book Slot',
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.getPrimary(isDark),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'INTERVIEW SCHEDULING',
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
                  'Book Interview Slot',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a convenient interview time after you\'ve been shortlisted for this role.',
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
                      '${_controller.availableSlots.length} Available slots',
                      Icons.date_range_outlined,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Already Booked / Info status
                if (_controller.bookingStatus.value == 'info') ...[
                  _buildInfoState(cardColor, textColor, subtitleColor, isDark),
                ]
                // Eligibility or Slot load Error status
                else if (_controller.bookingStatus.value == 'error' ||
                    _controller.availableSlots.isEmpty) ...[
                  _buildNoSlotsState(
                    cardColor,
                    textColor,
                    subtitleColor,
                    isDark,
                  ),
                ]
                // Regular Scheduling view
                else ...[
                  // Congratulate Alert
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Congratulations!',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You have been shortlisted for $jobTitle. Please select an available interview slot below.',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFF065F46),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // List slots grouped by date
                  ..._controller.groupedSlots.entries.map((entry) {
                    final dateStr = entry.key;
                    final daySlots = entry.value;

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
                              itemCount: daySlots.length,
                              itemBuilder: (context, idx) {
                                final slot = daySlots[idx];
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
                                          '$spotsLeft spot(s) left',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
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

                  // Important instructions block
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
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
                              Icons.info_outline,
                              size: 16,
                              color: isDark
                                  ? Colors.blueAccent[100]!
                                  : Colors.blue[700]!,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Important Instructions:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildBulletItem(
                          'You can reschedule your interview up to 2 times',
                          subtitleColor,
                        ),
                        _buildBulletItem(
                          'Cancellation is not allowed',
                          subtitleColor,
                        ),
                        _buildBulletItem(
                          'Rescheduling must be done at least 24 hours before the interview',
                          subtitleColor,
                        ),
                      ],
                    ),
                  ),

                  // Confirm Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          (_controller.selectedSlotId.value == null ||
                              _controller.isBooking.value ||
                              _isBooked)
                          ? null
                          : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBooked
                            ? Colors.grey
                            : AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _controller.isBooking.value
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
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _isBooked ? 'Booked' : 'Confirm Booking',
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
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.getPrimary(isDark)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 5, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoState(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 48),
          const SizedBox(height: 16),
          Text(
            'Already Booked',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.statusMessage.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtitleColor,
              height: 1.4,
            ),
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
                'Go Back',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsState(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFFF59E0B),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Slots Available',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.statusMessage.value.isNotEmpty
                ? _controller.statusMessage.value
                : 'There are currently no available interview slots. Please check back later or contact HR.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtitleColor,
              height: 1.4,
            ),
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
                'Go Back',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
