import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/widgets/features_card.dart';
import 'package:hirematrix/views/widgets/theme_toggle_button.dart';
import 'package:hirematrix/controllers/landing_controller.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);

      return Scaffold(
        backgroundColor: mainBg,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, isDark)),
              SliverToBoxAdapter(child: HeroSection(isDark: isDark)),
              SliverToBoxAdapter(child: PlatformStatsSection(isDark: isDark)),
              SliverToBoxAdapter(
                child: ConnectedJourneysSection(isDark: isDark),
              ),
              SliverToBoxAdapter(child: FeaturedJobsSection(isDark: isDark)),
              SliverToBoxAdapter(child: FeaturesSection(isDark: isDark)),
              SliverToBoxAdapter(child: FooterSection(isDark: isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      );
    });
  }

  // ─── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white.withOpacity(0.98),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildLogo(isDark),
            const Spacer(),
            _buildSignInButton(isDark),
            const SizedBox(width: 12),
            ThemeToggleButton(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Row(
      children: [
        Image.asset(
          'assets/hirematrix_logo.png',
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.bolt,
              color: AppColors.getPrimary(isDark),
              size: 28,
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          'HireMatrix',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark),
                  AppColors.getPrimary(isDark).withOpacity(0.8),
                ],
              ),
        color: isDark ? const Color(0xFF1E293B) : null,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.login),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sign In',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Section ────────────────────────────────────────────────────────────
class HeroSection extends StatefulWidget {
  final bool isDark;

  const HeroSection({super.key, required this.isDark});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _mockupTab = 0; // 0: Match, 1: Progress, 2: Studio

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 20),
      child: Column(
        children: [
          // Kicker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.getPrimary(isDark).withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 13, color: AppColors.getPrimary(isDark)),
                const SizedBox(width: 5),
                Text(
                  'AI HIRING PLATFORM',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getPrimary(isDark),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'From search to shortlist,',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'move faster.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.getPrimary(isDark),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'HireMatrix helps candidates get ready and helps recruiters find the right fit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5D7083),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Search Card
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 35,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSearchInput(
                  icon: Icons.search,
                  hint: 'Job title, skills, or company',
                  isDark: isDark,
                  controller: _searchController,
                ),
                const SizedBox(height: 10),
                _buildSearchInput(
                  icon: Icons.location_on_outlined,
                  hint: 'Location or remote',
                  isDark: isDark,
                  controller: _locationController,
                ),
                const SizedBox(height: 12),
                _buildSearchButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Links
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickLink('Developer'),
              _buildQuickLink('Data roles'),
              _buildQuickLink('Remote'),
              _buildQuickLink('Company discovery'),
            ],
          ),
          const SizedBox(height: 28),

          // Hero Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.getPrimary(isDark),
                        AppColors.getPrimary(isDark).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getPrimary(isDark).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Start as candidate',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.recruiterRegister),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getPrimary(isDark),
                      side: BorderSide(
                        color: AppColors.getPrimary(isDark).withOpacity(0.48),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Hire talent',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Product Scene Mockup (Live match card & metrics)
          _buildMockupProductScene(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required IconData icon,
    required String hint,
    required bool isDark,
    required TextEditingController controller,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!
              : AppColors.getPrimary(isDark).withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey[500] : const Color(0xFF5D7083),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.getPrimary(widget.isDark),
              AppColors.getPrimary(widget.isDark).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: () {
            Get.toNamed(AppRoutes.login);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Search Jobs',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink(String text) {
    final isDark = widget.isDark;
    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.login);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : AppColors.getPrimary(isDark).withOpacity(0.2),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.getPrimary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupProductScene(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : const Color(0xFFDDECEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Topbar window simulation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FCFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : const Color(0xFFDDECEF),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB5D84E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Live match',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D8A90),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini Tab Selector inside the Mockup
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFA),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFDDECEF),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildMockTabButton(0, 'Match Score', isDark),
                _buildMockTabButton(1, 'Pipelines', isDark),
                _buildMockTabButton(2, 'Studio & Events', isDark),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildMockupBody(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTabButton(int index, String label, bool isDark) {
    final isSelected = _mockupTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mockupTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? AppColors.getPrimary(isDark)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : const Color(0xFF5D7083),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupBody(bool isDark) {
    if (_mockupTab == 0) {
      // Match score card
      return Container(
        key: const ValueKey(0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFDDECEF),
          ),
        ),
        child: Row(
          children: [
            // Avatar Stack
            SizedBox(
              width: 54,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.getPrimary(isDark),
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.getSecondary(isDark),
                      child: const Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frontend Developer',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Matched by skills and intent',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF5D7083),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.getPrimary(isDark).withOpacity(0.12),
                border: Border.all(
                  color: AppColors.getPrimary(isDark),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '88%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_mockupTab == 1) {
      // Pipeline & Career progress bars
      return Container(
        key: const ValueKey(1),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFDDECEF),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pipeline',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Applied to booked',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF5D7083),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMiniBar(0.74, isDark),
                      const SizedBox(height: 6),
                      _buildMiniBar(0.54, isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Career path',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'PHP to Data Analyst',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF5D7083),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMiniBar(0.82, isDark),
                      const SizedBox(height: 6),
                      _buildMiniBar(0.61, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Resume Studio & Interview booked Row
      return Column(
        key: const ValueKey(2),
        children: [
          _buildMockupRow(
            Icons.file_present_outlined,
            'Resume Studio',
            'Tailored and ready',
            'ATS',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildMockupRow(
            Icons.calendar_today_outlined,
            'Interview booked',
            'Slot confirmed',
            'Today',
            isDark,
          ),
        ],
      );
    }
  }

  Widget _buildMiniBar(double val, bool isDark) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : const Color(0xFFE8F1F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        widthFactor: val,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getPrimary(isDark),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupRow(
    IconData icon,
    String title,
    String subtitle,
    String pillText,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFDDECEF),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: AppColors.getPrimary(isDark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF5D7083),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pillText,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D8A90),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Section ───────────────────────────────────────────────────────────
class PlatformStatsSection extends StatelessWidget {
  final bool isDark;

  const PlatformStatsSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Divider(color: isDark ? Colors.white12 : const Color(0xFFDDECEF)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStat('500+', 'jobs matched'),
              _buildCompactStat('2k+', 'candidates'),
              _buildCompactStat('250+', 'interviews'),
              _buildCompactStat('120+', 'recruiters'),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white12 : const Color(0xFFDDECEF)),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String val, String desc) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF5D7083),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Connected Journeys Section ──────────────────────────────────────────────
class ConnectedJourneysSection extends StatefulWidget {
  final bool isDark;

  const ConnectedJourneysSection({super.key, required this.isDark});

  @override
  State<ConnectedJourneysSection> createState() =>
      _ConnectedJourneysSectionState();
}

class _ConnectedJourneysSectionState extends State<ConnectedJourneysSection> {
  int _activeJourney = 0; // 0 for Candidate, 1 for Recruiter, 2 for Interview

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Kicker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'THREE CONNECTED JOURNEYS',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'One platform, different moves.',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Candidate, recruiter, and interview flow each get a clear next step.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5D7083),
            ),
          ),
          const SizedBox(height: 16),

          // Sliding Selector Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1FAF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildJourneyTab(0, 'Candidate', Icons.person_outline),
                _buildJourneyTab(
                  1,
                  'Recruiter',
                  Icons.business_center_outlined,
                ),
                _buildJourneyTab(2, 'Interview', Icons.calendar_today_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildActiveJourneyCard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTab(int index, String label, IconData icon) {
    final isSelected = _activeJourney == index;
    final isDark = widget.isDark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeJourney = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.getCard(isDark) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.getPrimary(isDark)
                    : const Color(0xFF5D7083),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : const Color(0xFF5D7083),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveJourneyCard(bool isDark) {
    if (_activeJourney == 0) {
      return _buildCardContent(
        key: const ValueKey(0),
        icon: Icons.person_outline,
        label: 'Candidate',
        title: 'Get ready before the application.',
        desc: 'Build the profile, match the role, send the better resume.',
        pills: ['Profile', 'Resume Studio', 'Matched jobs'],
        isDark: isDark,
      );
    } else if (_activeJourney == 1) {
      return _buildCardContent(
        key: const ValueKey(1),
        icon: Icons.business_center_outlined,
        label: 'Recruiter',
        title: 'See the right candidates sooner.',
        desc: 'Post the role, compare applicants, keep hiring motion visible.',
        pills: ['Post role', 'Applicant fit', 'Notes'],
        isDark: isDark,
      );
    } else {
      return _buildCardContent(
        key: const ValueKey(2),
        icon: Icons.calendar_today_outlined,
        label: 'Interview',
        title: 'Turn interest into a booked slot.',
        desc: 'Move from discovery to interview without losing the thread.',
        pills: ['Company discovery', 'Slots', 'Status'],
        isDark: isDark,
      );
    }
  }

  Widget _buildCardContent({
    required Key key,
    required IconData icon,
    required String label,
    required String title,
    required String desc,
    required List<String> pills,
    required bool isDark,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : const Color(0xFFDDECEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDark).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.getPrimary(isDark),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF5D7083),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pills.map((pill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1FAF9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  pill,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Featured Jobs Section ───────────────────────────────────────────────────
class FeaturedJobsSection extends StatefulWidget {
  final bool isDark;

  const FeaturedJobsSection({super.key, required this.isDark});

  @override
  State<FeaturedJobsSection> createState() => _FeaturedJobsSectionState();
}

class _FeaturedJobsSectionState extends State<FeaturedJobsSection> {
  late final LandingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LandingController());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Kicker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: AppColors.getPrimary(isDark),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE ROLE SIGNALS',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getPrimary(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jobs with HireMatrix context built in.',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Live openings from database.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF5D7083),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.getPrimary(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Horizontal scroll of 6 roles
          SizedBox(
            height: 250,
            child: Obx(() {
              return _controller.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getPrimary(widget.isDark),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _controller.featuredJobs.isNotEmpty
                          ? _controller.featuredJobs.length
                          : 6,
                      itemBuilder: (context, index) {
                        final job = _controller.featuredJobs.isNotEmpty
                            ? _controller.featuredJobs[index]
                            : null;
                        final title = job != null
                            ? (job['title'] ?? 'Untitled Role')
                            : _getMockTitle(index);
                        final company = job != null
                            ? (job['company'] ?? 'Company')
                            : _getMockCompany(index);
                        final location = job != null
                            ? (job['location'] ?? 'N/A')
                            : _getMockLocation(index);
                        final postedAt = job != null
                            ? (job['posted_at_formatted'] ?? 'Recently')
                            : 'Recently';
                        final jobType = job != null
                            ? (job['job_type'] ?? 'Full-time')
                            : _getMockType(index);

                        final signalLabel = _getSignalLabel(index);
                        final contextSet = _getContextLabels(index);

                        return Container(
                          width: MediaQuery.of(context).size.width > 600
                              ? 320
                              : MediaQuery.of(context).size.width * 0.8,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.getCard(isDark)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[850]!
                                  : const Color(0xFFDDECEF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Signal badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimary(
                                    isDark,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: AppColors.getPrimary(isDark),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      signalLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getPrimary(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1FAF9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _pickJobIcon(title),
                                      size: 18,
                                      color: AppColors.getPrimary(isDark),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          company,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF5D7083),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Meta details
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: const Color(0xFF5D7083),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF5D7083),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: const Color(0xFF5D7083),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    postedAt,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF5D7083),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Context tags list
                              Wrap(
                                spacing: 4,
                                children: contextSet.map((contextPill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : const Color(0xFFF7FAFA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      contextPill,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : const Color(0xFF48616A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const Spacer(),

                              // Link text button
                              InkWell(
                                onTap: () => Get.toNamed(AppRoutes.login),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Open role signal',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.getPrimary(isDark),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: AppColors.getPrimary(isDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
            }),
          ),
        ],
      ),
    );
  }

  IconData _pickJobIcon(String title) {
    final needle = title.toLowerCase();
    if (needle.contains('developer')) return Icons.code;
    if (needle.contains('engineer')) return Icons.settings_outlined;
    if (needle.contains('designer')) return Icons.palette_outlined;
    if (needle.contains('manager')) return Icons.trending_up;
    if (needle.contains('data')) return Icons.analytics_outlined;
    if (needle.contains('marketing')) return Icons.campaign_outlined;
    if (needle.contains('product')) return Icons.business_center_outlined;
    return Icons.work_outline;
  }

  String _getMockTitle(int idx) {
    const titles = [
      'Data Scientist',
      'UI/UX Designer',
      'Backend Engineer',
      'Product Analyst',
      'Talent Partner',
      'Cloud Project Lead',
    ];
    return titles[idx % titles.length];
  }

  String _getMockCompany(int idx) {
    const companies = [
      'AI Dynamics',
      'Design Studio Pro',
      'Cloud Systems Inc',
      'GrowthWorks',
      'PeopleOps Lab',
      'OpsBridge',
    ];
    return companies[idx % companies.length];
  }

  String _getMockLocation(int idx) {
    const locs = [
      'Remote',
      'Bangalore',
      'Hyderabad',
      'Pune',
      'Remote',
      'Mumbai',
    ];
    return locs[idx % locs.length];
  }

  String _getMockType(int idx) {
    const types = [
      'Full-time',
      'Contract',
      'Full-time',
      'Hybrid',
      'Full-time',
      'Full-time',
    ];
    return types[idx % types.length];
  }

  String _getSignalLabel(int idx) {
    const labels = [
      'Role signal',
      'Company context',
      'Resume angle',
      'Interview path',
      'Career move',
      'Recruiter signal',
    ];
    return labels[idx % labels.length];
  }

  List<String> _getContextLabels(int idx) {
    const labels = [
      ['Role snapshot', 'Skill themes'],
      ['Company view', 'Role cluster'],
      ['Resume Studio', 'Keyword hints'],
      ['Slot-ready', 'Status tracking'],
      ['Transition plan', 'Learning path'],
      ['Fresh lead', 'Hiring motion'],
    ];
    return labels[idx % labels.length];
  }
}

// ─── Features Section ────────────────────────────────────────────────────────
class FeaturesSection extends StatelessWidget {
  final bool isDark;

  const FeaturesSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: FeaturesCard(isDark: isDark),
    );
  }
}

// ─── Footer Section ──────────────────────────────────────────────────────────
class FooterSection extends StatelessWidget {
  final bool isDark;

  const FooterSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          // Join CTA panel
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2F34),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your next move starts here.',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search smarter. Hire faster.',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Join as candidate',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.recruiterRegister),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Join as recruiter',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(dynamic icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF1FAF9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFDDECEF),
        ),
      ),
      child: Center(
        child: FaIcon(icon, size: 16, color: AppColors.getPrimary(isDark)),
      ),
    );
  }
}
