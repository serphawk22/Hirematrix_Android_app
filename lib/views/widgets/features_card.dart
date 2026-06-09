import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class FeaturesCard extends StatelessWidget {
  final bool isDark;

  const FeaturesCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Account for margin (20*2), padding (20*2) and parent margin (24*2).
    // Total reduction is 128. We clamp the card width to keep it looking clean on desktop.
    double cardWidth = screenWidth - 128;
    if (cardWidth > 340) cardWidth = 340;
    if (cardWidth < 260) cardWidth = 260;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1B4B).withOpacity(0.8),
                  const Color(0xFF311042).withOpacity(0.8),
                  const Color(0xFF111827).withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF2FF), Color(0xFFF7EDFF), Color(0xFFFFF5EA)],
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(isDark).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dashboard_customize,
                          size: 14,
                          color: AppColors.getPrimary(isDark),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Portal Showcase',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      'Explore Portal Features',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      'A structured candidate-recruiter ecosystem with preparation, interview, and hiring workflows connected in one platform.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Swipe',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 12, color: isDark ? Colors.grey[300] : const Color(0xFF4B5563)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Mini Features Carousel
                  SizedBox(
                    height: 215,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFeatureItem(
                          Icons.psychology,
                          'AI Coaching Suite',
                          'Get role-targeted resume improvement guidance and prep for interviews with intelligent mock questions.',
                          'AI Tool',
                          'Boosts candidate readiness',
                          cardWidth,
                        ),
                        const SizedBox(width: 16),
                        _buildFeatureItem(
                          Icons.sync_alt,
                          'Two-Sided Workflows',
                          'Applications, review actions, and status updates are perfectly aligned between candidates and recruiters.',
                          'Workflow',
                          'Reduces communication gaps',
                          cardWidth,
                        ),
                        const SizedBox(width: 16),
                        _buildFeatureItem(
                          Icons.auto_graph,
                          'Smart Matching',
                          'Utilize contextual fit cues to discover the strongest candidate-to-job matches effortlessly.',
                          'Analytics',
                          'Prioritizes high-value connections',
                          cardWidth,
                        ),
                        const SizedBox(width: 16),
                        _buildFeatureItem(
                          Icons.calendar_month,
                          'Interview Booking',
                          'Direct slot scheduling, rescheduling, and stage visibility tied directly to interview progress.',
                          'Execution',
                          'Maintains hiring momentum',
                          cardWidth,
                        ),
                        const SizedBox(width: 16),
                        _buildFeatureItem(
                          Icons.rocket_launch,
                          'Job Strategy Coach',
                          'End-to-end application strategy support before and after applying to improve your traction.',
                          'AI Tool',
                          'Maximizes application success',
                          cardWidth,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.getCard(isDark) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => Get.toNamed('/features'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Feature Details',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String subtitle,
    String category,
    String highlight,
    double cardWidth,
  ) {
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.getPrimary(isDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.getText(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highlight,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
