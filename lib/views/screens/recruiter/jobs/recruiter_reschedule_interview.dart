import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecruiterRescheduleInterviewScreen extends StatefulWidget {
  final String bookingId;
  final String recruiterId;

  const RecruiterRescheduleInterviewScreen({
    super.key,
    required this.bookingId,
    required this.recruiterId,
  });

  @override
  State<RecruiterRescheduleInterviewScreen> createState() =>
      _RecruiterRescheduleInterviewScreenState();
}

class _RecruiterRescheduleInterviewScreenState
    extends State<RecruiterRescheduleInterviewScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _availableSlots; // Grouped by date

  final TextEditingController _reasonController = TextEditingController();
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _fetchRescheduleData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchRescheduleData() async {
    setState(() => _isLoading = true);
    try {
      final recruiterId = widget.recruiterId;

      final baseUrl = await ApiService().getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/interviews/reschedule/data?recruiter_id=$recruiterId&booking_id=${widget.bookingId}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _bookingData = data['booking'];
            _availableSlots = data['available_slots'];
          });
        } else {
          _showError(data['message'] ?? 'Failed to load booking data');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReschedule() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _showError("Please provide a reason for rescheduling.");
      return;
    }
    if (_selectedSlotId == null) {
      _showError("Please select a new time slot.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final recruiterId = widget.recruiterId;

      final baseUrl = await ApiService().getBaseUrl();
      final uri = Uri.parse('$baseUrl/interviews/reschedule/process');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'recruiter_id': recruiterId.toString(),
          'booking_id': widget.bookingId,
          'slot_id': _selectedSlotId!,
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Interview rescheduled successfully"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to refresh list
          }
        } else {
          _showError(data['message'] ?? 'Failed to reschedule');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF16212B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppColors.getPrimary(isDark);
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.getBackground(isDark)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Reschedule Interview',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF16212B),
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0.5,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF16212B),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _bookingData == null
          ? Center(
              child: Text(
                'Failed to load booking details',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Booking Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Booking Details',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoItem(
                          'Booking ID',
                          '#${widget.bookingId}',
                          isDark,
                        ),
                        _buildInfoItem(
                          'Candidate',
                          _bookingData!['candidate_name'] ?? 'N/A',
                          isDark,
                        ),
                        _buildInfoItem(
                          'Job Position',
                          _bookingData!['job_title'] ?? 'N/A',
                          isDark,
                        ),

                        // Format Schedule
                        Builder(
                          builder: (context) {
                            final dtStr = _bookingData!['slot_datetime'];
                            if (dtStr != null && dtStr.isNotEmpty) {
                              final dt = DateTime.tryParse(dtStr);
                              if (dt != null) {
                                final formattedDate = DateFormat(
                                  'MMM d, yyyy',
                                ).format(dt);
                                final formattedTime = DateFormat(
                                  'hh:mm a',
                                ).format(dt);
                                return _buildInfoItem(
                                  'Current Schedule',
                                  '$formattedDate at $formattedTime',
                                  isDark,
                                );
                              }
                            }
                            return _buildInfoItem(
                              'Current Schedule',
                              'N/A',
                              isDark,
                            );
                          },
                        ),

                        _buildInfoItem(
                          'Status',
                          (_bookingData!['booking_status'] ?? '')
                              .toString()
                              .toUpperCase(),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reschedule Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select New Slot',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Reason Field
                        Text(
                          'Reason for Rescheduling *',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF16212B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Please provide a reason for rescheduling...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey),
                            filled: true,
                            fillColor: isDark ? Colors.black : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Available Slots
                        Text(
                          'Available Slots *',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF16212B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_availableSlots == null || _availableSlots!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No available slots found for this job position.',
                                    style: GoogleFonts.inter(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._availableSlots!.entries.map((entry) {
                            final dateStr = entry.key;
                            final slots = entry.value as List;

                            DateTime? parsedDate = DateTime.tryParse(dateStr);
                            String displayDate = parsedDate != null
                                ? DateFormat(
                                    'EEEE, MMMM d, yyyy',
                                  ).format(parsedDate)
                                : dateStr;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12,
                                    top: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        displayDate,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1F3B73),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...slots.map((slot) {
                                  final slotId = slot['id'].toString();
                                  final isSelected = _selectedSlotId == slotId;

                                  String timeDisplay = slot['slot_time'];
                                  try {
                                    final timeParts = timeDisplay.split(':');
                                    if (timeParts.length >= 2) {
                                      final tod = TimeOfDay(
                                        hour: int.parse(timeParts[0]),
                                        minute: int.parse(timeParts[1]),
                                      );
                                      final now = DateTime.now();
                                      final dt = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        tod.hour,
                                        tod.minute,
                                      );
                                      timeDisplay = DateFormat(
                                        'hh:mm a',
                                      ).format(dt);
                                    }
                                  } catch (_) {}

                                  return InkWell(
                                    onTap: () {
                                      setState(() => _selectedSlotId = slotId);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark
                                                  ? Colors.black
                                                  : const Color(0xFFEFFAF8))
                                            : (isDark
                                                  ? const Color(0xFF161D21)
                                                  : Colors.white),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                    ? const Color(0xFF23343A)
                                                    : Colors.grey[300]!),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: slotId,
                                            groupValue: _selectedSlotId,
                                            onChanged: (val) {
                                              setState(
                                                () => _selectedSlotId = val,
                                              );
                                            },
                                            activeColor: primaryColor,
                                            fillColor:
                                                WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                      WidgetState.selected,
                                                    )) {
                                                      return primaryColor;
                                                    }
                                                    return isDark
                                                        ? Colors.grey[600]
                                                        : Colors.grey[400];
                                                  },
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              timeDisplay,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: primaryColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'Available',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Confirm Reschedule',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
