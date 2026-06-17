import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';

class EditSlotScreen extends StatefulWidget {
  final Job job;
  final Map<String, dynamic> slot;

  const EditSlotScreen({super.key, required this.job, required this.slot});

  @override
  State<EditSlotScreen> createState() => _EditSlotScreenState();
}

class _EditSlotScreenState extends State<EditSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  DateTime? _slotDate;
  TimeOfDay? _slotTime;
  int _capacity = 1;
  int _bookedCount = 0;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookedCount =
        int.tryParse(widget.slot['booked_count']?.toString() ?? '0') ?? 0;
    _capacity = int.tryParse(widget.slot['capacity']?.toString() ?? '1') ?? 1;

    final rawDate = widget.slot['slot_date']?.toString() ?? '';
    final rawTime = widget.slot['slot_time']?.toString() ?? '';

    if (rawDate.isNotEmpty) {
      try {
        _slotDate = DateTime.parse(rawDate);
      } catch (_) {}
    }
    if (rawTime.isNotEmpty) {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        _slotTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_bookedCount > 0) return; // Read-only if booked
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _slotDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _slotDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (_bookedCount > 0) return; // Read-only if booked
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _slotTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _slotTime = picked);
    }
  }

  Future<void> _updateSlot() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slotDate == null) {
      setState(() => _error = 'Date is required');
      return;
    }
    if (_slotTime == null) {
      setState(() => _error = 'Time is required');
      return;
    }

    final recruiterId = Provider.of<AuthController>(
      context,
      listen: false,
    ).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        _slotTime!.hour,
        _slotTime!.minute,
      );
      final formattedTime = DateFormat('HH:mm').format(dt);

      final payload = {
        'recruiter_id': recruiterId.toString(),
        'slot_id': widget.slot['id']?.toString() ?? '',
        'slot_date': DateFormat('yyyy-MM-dd').format(_slotDate!),
        'slot_time': formattedTime,
        'capacity': _capacity.toString(),
      };

      // Since updateInterviewSlot might not exist yet, we will mimic what add/delete does
      // We will assume the backend either has this route or it will need to be implemented.
      final res = await _apiService.updateInterviewSlot(
        payload,
      ); // Ensure this method is in your API service

      setState(() => _isSaving = false);

      if (res['success'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(
          () => _error = res['message']?.toString() ?? 'Failed to update slot',
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBooked = _bookedCount > 0;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.getBackground(isDark),
        centerTitle: true,
        title: Text(
          'Edit Interview Slot',
          style: GoogleFonts.inter(
            color: AppColors.getText(isDark),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update the timing and capacity of an interview slot while keeping bookings safe.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 24),

              if (isBooked)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Warning: This slot has $_bookedCount booking(s). Slots with bookings cannot be edited.',
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildSectionCard('Job Position', isDark, [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    widget.job.jobTitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Job position cannot be changed',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Timing', isDark, [
                Row(
                  children: [
                    Expanded(
                      child: _buildPicker(
                        'Date *',
                        _slotDate == null
                            ? 'Select Date'
                            : DateFormat('MMM dd, yyyy').format(_slotDate!),
                        Icons.calendar_today,
                        isDark,
                        isBooked ? null : () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPicker(
                        'Time *',
                        _slotTime == null
                            ? 'Select Time'
                            : _slotTime!.format(context),
                        Icons.access_time,
                        isDark,
                        isBooked ? null : () => _selectTime(context),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Settings', isDark, [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacity *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _capacity.toString(),
                      keyboardType: TextInputType.number,
                      readOnly: isBooked,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) =>
                          _capacity = int.tryParse(val) ?? _bookedCount,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final num = int.tryParse(val) ?? 0;
                        if (num < _bookedCount)
                          return 'Cannot be less than booked ($_bookedCount)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBooked
                          ? 'Cannot reduce capacity below current bookings ($_bookedCount)'
                          : 'Number of candidates that can book this slot',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Additional Information', isDark, [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booked:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_bookedCount / $_capacity',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slot ID:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '#${widget.slot['id']}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 32),
              if (!isBooked)
                ElevatedButton(
                  onPressed: _isSaving ? null : _updateSlot,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppColors.getPrimary(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'UPDATE SLOT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.getPrimary(isDark),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPicker(
    String label,
    String valueText,
    IconData icon,
    bool isDark,
    VoidCallback? onTap,
  ) {
    final isDisabled = onTap == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  valueText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDisabled ? Colors.grey : AppColors.getText(isDark),
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: isDisabled
                      ? Colors.grey
                      : AppColors.getPrimary(isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
