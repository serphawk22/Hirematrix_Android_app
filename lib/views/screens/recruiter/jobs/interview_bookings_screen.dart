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
  State<InterviewBookingsScreen> createState() => _InterviewBookingsScreenState();
}

class _InterviewBookingsScreenState extends State<InterviewBookingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  Map<String, dynamic> _metrics = {
    'total': '0',
    'upcoming': '0',
    'completed': '0',
    'rescheduled': '0'
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
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      final response = await _apiService.fetchInterviewBookings(
        recruiterId, 
        jobId: _selectedJobId, 
        status: _selectedStatus
      );
      if (response['success'] == true) {
        final List<dynamic> bookingsList = response['bookings'] ?? [];
        
        // Calculate metrics locally
        int total = bookingsList.length;
        int upcoming = 0;
        int completed = 0;
        int rescheduled = 0;
        
        for (var booking in bookingsList) {
          final bStatus = (booking['booking_status'] ?? '').toString().toLowerCase();
          if (bStatus == 'booked' || bStatus == 'confirmed') {
            upcoming++;
          } else if (bStatus == 'completed') {
            completed++;
          } else if (bStatus == 'rescheduled') {
            rescheduled++;
          }
        }
        
        setState(() {
          _bookings = bookingsList;
          _metrics = {
            'total': total.toString(),
            'upcoming': upcoming.toString(),
            'completed': completed.toString(),
            'rescheduled': rescheduled.toString(),
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
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF6F8FA),
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
            icon: Icon(Icons.refresh_rounded, size: 20, color: AppColors.getPrimary(isDark))
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : Column(
            children: [
              _buildMetricsHeader(isDark),
              _buildFilterBar(isDark),
              Expanded(
                child: _bookings.isEmpty 
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildBookingCard(_bookings[index], isDark),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildMetricsHeader(bool isDark) {
    return Container(
      height: 94,
      margin: const EdgeInsets.only(top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricCard('Total Bookings', _metrics['total'], Icons.book_online_rounded, Colors.blue, isDark),
          _buildMetricCard('Upcoming', _metrics['upcoming'], Icons.schedule_rounded, Colors.green, isDark),
          _buildMetricCard('Completed', _metrics['completed'], Icons.check_circle_outline_rounded, Colors.teal, isDark),
          _buildMetricCard('Rescheduled', _metrics['rescheduled'], Icons.history_rounded, Colors.amber, isDark),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String val, IconData icon, Color color, bool isDark) {
    return Container(
      width: 136,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!,
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
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: color.withValues(alpha: 0.8),
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.getCard(isDark) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJobId,
                  hint: Text('Filter by Job', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.getPrimary(isDark)),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Jobs', style: GoogleFonts.inter(fontSize: 12))),
                    ...jobs.map((j) => DropdownMenuItem(value: j.jobId, child: Text(j.jobTitle, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis)))
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                hint: Text('Status', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.getPrimary(isDark)),
                items: [
                  DropdownMenuItem(value: null, child: Text('All', style: GoogleFonts.inter(fontSize: 12))),
                  DropdownMenuItem(value: 'booked', child: Text('Booked', style: GoogleFonts.inter(fontSize: 12))),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed', style: GoogleFonts.inter(fontSize: 12))),
                  DropdownMenuItem(value: 'rescheduled', child: Text('Rescheduled', style: GoogleFonts.inter(fontSize: 12))),
                  DropdownMenuItem(value: 'completed', child: Text('Completed', style: GoogleFonts.inter(fontSize: 12))),
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
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDark) {
    final status = (booking['booking_status'] ?? 'confirmed').toString().toUpperCase();
    final review = (booking['review_status'] ?? 'pending').toString().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.getPrimary(isDark).withOpacity(0.08),
                child: Text(
                  (booking['candidate_name'] ?? 'C')[0].toUpperCase(), 
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.getPrimary(isDark))
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['candidate_name'] ?? 'Candidate', 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking['job_title'] ?? 'Role', 
                      style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey[500], fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.getPrimary(isDark)),
                const SizedBox(width: 8),
                Text(
                  "${booking['slot_date']}  •  ${booking['slot_time']}", 
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLabelValue('BOOKED DATE', _formatBookedDate(booking['created_at'])),
              const SizedBox(width: 32),
              _buildLabelValue('REVIEW STATUS', review),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12), 
            child: Divider(height: 1, thickness: 0.5)
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showReviewDialog(context, booking),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                  ),
                  child: Text(
                    'Review', 
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.getPrimary(isDark))
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRescheduleSheet(context, booking),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.getPrimary(isDark),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Reschedule', 
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5)
        ),
        const SizedBox(height: 3),
        Text(
          value, 
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)
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
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : dateString;
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'CANCELLED') color = Colors.redAccent;
    if (status == 'COMPLETED') color = Colors.teal;
    if (status == 'RESCHEDULED') color = Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(6)
      ),
      child: Text(
        status, 
        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'No bookings found.', 
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  void _showRescheduleSheet(BuildContext context, Map<String, dynamic> booking) {
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
    final notesController = TextEditingController();
    String decision = 'shortlisted'; // default decision
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Interview Evaluation', 
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Candidate: ${booking['candidate_name']}',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)
                ),
                const SizedBox(height: 12),
                Text(
                  'Submit Decision',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Shortlist'),
                      selected: decision == 'shortlisted',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => decision = 'shortlisted');
                      },
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11, 
                        fontWeight: FontWeight.w600, 
                        color: decision == 'shortlisted' ? Colors.green : Colors.grey
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Reject'),
                      selected: decision == 'rejected',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => decision = 'rejected');
                      },
                      selectedColor: Colors.red.withOpacity(0.2),
                      checkmarkColor: Colors.red,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11, 
                        fontWeight: FontWeight.w600, 
                        color: decision == 'rejected' ? Colors.red : Colors.grey
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Evaluation Notes',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter evaluation feedback...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!)
                    ),
                    fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
                    filled: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  final appId = booking['application_id']?.toString();
                  final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
                  
                  if (appId == null || recruiterId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot evaluate: Missing App ID or Recruiter ID'), backgroundColor: AppColors.error)
                    );
                    return;
                  }

                  setDialogState(() => isSaving = true);
                  
                  // Update application status based on decision
                  final response = await _apiService.updateApplicationStatus(
                    appId, 
                    decision, 
                    recruiterId
                  );

                  if (context.mounted) {
                    setDialogState(() => isSaving = false);
                    Navigator.pop(ctx);
                    if (response['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Candidate $decision successfully'), backgroundColor: AppColors.success)
                      );
                      _loadData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response['message'] ?? 'Failed to update status'), backgroundColor: AppColors.error)
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: decision == 'shortlisted' ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          );
        }
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 24),
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
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)
              ),
              IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.close_rounded, size: 20)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select New Date',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)
          ),
          const SizedBox(height: 6),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.getPrimary(isDark)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null 
                      ? 'Choose Date' 
                      : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select New Time',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context, 
                initialTime: TimeOfDay.now()
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: AppColors.getPrimary(isDark)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime == null 
                      ? 'Choose Time' 
                      : _selectedTime!.format(context),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleReschedule,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.getPrimary(isDark),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Confirm Reschedule', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleReschedule() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time'), backgroundColor: AppColors.error)
      );
      return;
    }

    setState(() => _isSaving = true);
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    final finalDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
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
          const SnackBar(content: Text('Interview rescheduled successfully'), backgroundColor: AppColors.success)
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to reschedule'), backgroundColor: AppColors.error)
        );
      }
    }
  }
}
