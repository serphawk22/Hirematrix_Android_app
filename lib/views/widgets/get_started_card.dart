import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class GetStartedCard extends StatelessWidget {
  final String type; // 'candidate' or 'recruiter'
  final bool isDark;

  const GetStartedCard({super.key, required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCandidate = type == 'candidate';
    final color = isCandidate
        ? const Color(0xFF0A80FF)
        : AppColors.getSecondary(isDark);

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.getCard(isDark), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFF5F7FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isCandidate ? Icons.people : Icons.business_center,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isCandidate ? 'For Job Seekers' : 'For Recruiters',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isCandidate
                ? 'Discover opportunities tailored to your skills and career goals.'
                : 'Find and connect with the best talent for your organization.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ..._buildFeatures(isCandidate, color),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => Get.toNamed(
                  isCandidate ? '/register' : '/recruiter/register',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCandidate
                          ? 'Create Candidate Account'
                          : 'Join as Recruiter',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(bool isCandidate, Color color) {
    final features = isCandidate
        ? [
            'AI-powered job recommendations',
            'Skill gap analysis',
            'Career transition tools',
          ]
        : [
            'Smart candidate matching',
            'ATS integration',
            'Team collaboration tools',
          ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              feature,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
