import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';
import 'package:intl/intl.dart';

class PreviewJobScreen extends StatelessWidget {
  final Job job;

  const PreviewJobScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.getPrimary(isDark);
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.getCard(isDark) : Colors.white;
    final textColor = AppColors.getText(isDark);
    final mutedColor = AppColors.getTextMuted(isDark);

    final skills = (job.requiredSkills ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text(
                    'PREVIEW MODE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  backgroundColor: primary.withValues(alpha: 0.1),
                  side: BorderSide(color: primary.withValues(alpha: 0.3)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.15),
                      isDark ? AppColors.getCard(isDark) : const Color(0xFFEFF9F9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.business_center_rounded, color: primary, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildStatusPill(job.status, isDark, primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickInfoCard(job, isDark, cardColor, mutedColor, textColor, primary),
                  const SizedBox(height: 16),
                  if (job.description != null && job.description!.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Job Description',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                      primary: primary,
                      child: Text(
                        job.description!,
                        style: GoogleFonts.inter(fontSize: 14, color: mutedColor, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (skills.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Required Skills',
                      icon: Icons.code_rounded,
                      isDark: isDark,
                      cardColor: cardColor,
                      primary: primary,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) => _buildSkillChip(s, isDark, primary)).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionCard(
                    title: 'Job Details',
                    icon: Icons.info_outline_rounded,
                    isDark: isDark,
                    cardColor: cardColor,
                    primary: primary,
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.work_outline_rounded, 'Type', job.jobType, isDark, mutedColor, textColor),
                        _buildDetailRow(Icons.laptop_rounded, 'Work Mode', job.workMode, isDark, mutedColor, textColor),
                        _buildDetailRow(Icons.location_on_outlined, 'Location', job.location ?? 'Not specified', isDark, mutedColor, textColor),
                        _buildDetailRow(Icons.trending_up_rounded, 'Experience', job.experience, isDark, mutedColor, textColor),
                        if (job.salary != null && job.salary!.isNotEmpty)
                          _buildDetailRow(Icons.payments_outlined, 'Salary', job.salary!, isDark, mutedColor, textColor),
                        if (job.openings != null)
                          _buildDetailRow(Icons.people_outline_rounded, 'Openings', job.openings.toString(), isDark, mutedColor, textColor),
                        if (job.applicationDeadline != null && job.applicationDeadline!.isNotEmpty)
                          _buildDetailRow(Icons.event_rounded, 'Deadline', _formatDeadline(job.applicationDeadline!), isDark, mutedColor, textColor),
                        _buildDetailRow(
                          Icons.calendar_today_rounded,
                          'Posted',
                          DateFormat('MMM d, yyyy').format(job.createdAt),
                          isDark,
                          mutedColor,
                          textColor,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (job.aiInterviewPolicy != null && job.aiInterviewPolicy != 'none') ...[
                    _buildSectionCard(
                      title: 'AI Interview',
                      icon: Icons.psychology_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                      primary: primary,
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.smart_toy_outlined, 'Policy', job.aiInterviewPolicy ?? '', isDark, mutedColor, textColor),
                          if (job.minAiCutoffScore != null)
                            _buildDetailRow(Icons.score_rounded, 'Min Score', '${job.minAiCutoffScore}%', isDark, mutedColor, textColor, isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is how candidates see your job listing. Edit the job to make changes.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[700], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark, Color primary) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'active':  bg = Colors.green.withValues(alpha: 0.12); fg = Colors.green; break;
      case 'closed':  bg = Colors.red.withValues(alpha: 0.12); fg = Colors.red; break;
      case 'draft':   bg = Colors.orange.withValues(alpha: 0.12); fg = Colors.orange; break;
      default:        bg = primary.withValues(alpha: 0.1); fg = primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildQuickInfoCard(Job job, bool isDark, Color cardColor, Color mutedColor, Color textColor, Color primary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _buildQuickStat('Applied', job.applicationsCount?.toString() ?? '0', Icons.people_outline_rounded, Colors.blue, isDark),
          Container(width: 1, height: 36, color: isDark ? Colors.white10 : Colors.grey[200]),
          _buildQuickStat('Shortlisted', job.shortlistedCount?.toString() ?? '0', Icons.star_outline_rounded, Colors.orange, isDark),
          Container(width: 1, height: 36, color: isDark ? Colors.white10 : Colors.grey[200]),
          _buildQuickStat(job.workMode, '', Icons.laptop_rounded, primary, isDark),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          if (val.isNotEmpty) Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.getTextMuted(isDark)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title, required IconData icon, required bool isDark,
    required Color cardColor, required Color primary, required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]!),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, Color mutedColor, Color textColor, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: mutedColor),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: mutedColor))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Text(skill, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
    );
  }

  String _formatDeadline(String deadline) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(deadline));
    } catch (_) {
      return deadline;
    }
  }
}
