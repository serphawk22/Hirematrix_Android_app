import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String postedAt;
  final int matchScore;
  final bool isDark;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.postedAt,
    required this.matchScore,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.getCard(isDark), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFF7F9FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForTitle(title),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),

                // Company
                Text(
                  company,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),

                // Meta info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[500]
                              : const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      postedAt,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey[500]
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Full-time',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getSecondary(isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        title.split(' ').first,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getSecondary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: matchScore / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.getPrimary(isDark),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Match Score',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey[500]
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '$matchScore%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // View Details Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Data')) return Icons.analytics;
    if (title.contains('UI/UX')) return Icons.design_services;
    if (title.contains('Backend')) return Icons.code;
    if (title.contains('Frontend')) return Icons.web;
    if (title.contains('Product')) return Icons.business_center;
    return Icons.code_off;
  }
}
