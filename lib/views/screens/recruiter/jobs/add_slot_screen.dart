import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';

class AddSlotScreen extends StatefulWidget {
  final Job job;

  const AddSlotScreen({super.key, required this.job});

  @override
  State<AddSlotScreen> createState() => _AddSlotScreenState();
}

class _AddSlotScreenState extends State<AddSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  DateTime? _startDate;
  DateTime? _endDate;
  int _capacity = 1;
  bool _excludeWeekends = true;
  List<TimeOfDay> _times = [];
  
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default 1 time slot at current time rounded to nearest hour
    _times.add(TimeOfDay.now());
  }

  void _addTimeSlot() {
    setState(() {
      _times.add(TimeOfDay.now());
    });
  }

  void _removeTimeSlot(int index) {
    if (_times.length > 1) {
      setState(() {
        _times.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() {
        _times[index] = picked;
      });
    }
  }

  Future<void> _saveSlots() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _error = 'Start date is required');
      return;
    }
    if (_times.isEmpty) {
      setState(() => _error = 'At least one time slot is required');
      return;
    }

    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final List<String> formattedTimes = _times.map((t) {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        return DateFormat('HH:mm').format(dt);
      }).toList();

      final payload = {
        'recruiter_id': recruiterId.toString(),
        'job_id': widget.job.jobId.toString(),
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
        'times': formattedTimes,
        'capacity': _capacity.toString(),
        'exclude_weekends': _excludeWeekends ? '1' : '0',
      };

      // Ensure your backend supports this route, otherwise you will get a 404
      final res = await _apiService.addInterviewSlot(payload);
      
      setState(() => _isSaving = false);

      if (res['success'] == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _error = res['message']?.toString() ?? 'Failed to save slots');
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
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.getBackground(isDark),
        centerTitle: true,
        title: Text(
          'Create Interview Slots',
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
                'Generate one or more booking windows for a job while keeping scheduling clear and organized.',
                style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.blueGrey[600]),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_error!, style: GoogleFonts.inter(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),

              _buildSectionCard('Job Position', isDark, [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  child: Text(
                    widget.job.jobTitle,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.getText(isDark)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Select the job position for these interview slots', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Date Range', isDark, [
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        'Start Date *', 
                        _startDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_startDate!), 
                        isDark, 
                        () => _selectDate(context, true)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        'End Date (Optional)', 
                        _endDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_endDate!), 
                        isDark, 
                        () => _selectDate(context, false)
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Time Slots *', isDark, [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _times.length,
                  itemBuilder: (context, index) {
                    final timeStr = _times[index].format(context);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(timeStr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                                    Icon(Icons.access_time, size: 18, color: AppColors.getPrimary(isDark)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_times.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeTimeSlot(index),
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: _addTimeSlot,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Another Time'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.getPrimary(isDark),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                Text('Add multiple time slots for each day', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ]),

              const SizedBox(height: 16),
              _buildSectionCard('Settings', isDark, [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacity per Slot *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _capacity.toString(),
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) => _capacity = int.tryParse(val) ?? 1,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if ((int.tryParse(val) ?? 0) < 1) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Text('Number of candidates that can book each slot', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Exclude Weekends', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Do not create slots on Saturday & Sunday', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  value: _excludeWeekends,
                  activeColor: AppColors.getPrimary(isDark),
                  onChanged: (val) => setState(() => _excludeWeekends = val),
                ),
              ]),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSlots,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColors.getPrimary(isDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('CREATE SLOTS', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
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
          Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getPrimary(isDark), letterSpacing: 1)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, String valueText, bool isDark, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(valueText, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                Icon(Icons.calendar_today, size: 16, color: AppColors.getPrimary(isDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
