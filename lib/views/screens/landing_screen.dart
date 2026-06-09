import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/views/widgets/animated_gradient_background.dart';
import 'package:hirematrix/views/widgets/features_card.dart';
import 'package:hirematrix/views/widgets/get_started_card.dart';
import 'package:hirematrix/views/widgets/job_card.dart';
import 'package:hirematrix/views/widgets/theme_toggle_button.dart';
import 'package:hirematrix/controllers/landing_controller.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode;

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.getBackground(isDark),
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
              SliverToBoxAdapter(child: GetStartedSection(isDark: isDark)),
              SliverToBoxAdapter(child: FeaturedJobsSection(isDark: isDark)),
              SliverToBoxAdapter(child: FeaturesSection(isDark: isDark)),
              // bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      );
    });
  }

  // ─── Sidebar Drawer ──────────────────────────────────────────────────────────

  Widget _buildSideDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getPrimary(isDark),
                    AppColors.getPrimary(isDark),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'H',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HireMatrix',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connecting talent with\nopportunities through AI.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Primary actions
                  _drawerAction(
                    icon: Icons.login_rounded,
                    label: 'Sign In',
                    color: AppColors.getPrimary(isDark),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.login);
                    },
                  ),
                  _drawerAction(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Register as Candidate',
                    color: const Color(0xFF0A80FF),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.register);
                    },
                  ),
                  _drawerAction(
                    icon: Icons.business_center_rounded,
                    label: 'Register as Recruiter',
                    color: AppColors.getSecondary(isDark),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.recruiterRegister);
                    },
                  ),
                ],
              ),
            ),

            // ── Footer: Social + Copyright ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialBtn(
                        FaIcon(
                          FontAwesomeIcons.linkedin,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _socialBtn(
                        FaIcon(
                          FontAwesomeIcons.xTwitter,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _socialBtn(
                        FaIcon(
                          FontAwesomeIcons.instagram,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _socialBtn(
                        FaIcon(
                          FontAwesomeIcons.facebook,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF374151),
                        ),
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '© ${DateTime.now().year} HireMatrix. All rights reserved.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerLink({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.grey[200] : Colors.grey[800],
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _drawerDivider(bool isDark, {required String label}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialBtn(Widget icon, bool isDark) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon,
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white.withOpacity(0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildLogo(isDark),
            const Spacer(),

            // Desktop Navigation
            if (MediaQuery.of(context).size.width > 991) ...[
              _buildNavLink('Register Candidate', AppRoutes.register, isDark),
              const SizedBox(width: 24),
              _buildNavLink(
                'Register Recruiter',
                AppRoutes.recruiterRegister,
                isDark,
              ),
              const SizedBox(width: 24),
            ],

            // Always show Sign In button
            _buildSignInButton(isDark),
            const SizedBox(width: 12),

            // Theme Toggle
            ThemeToggleButton(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Row(
      children: [
        Text(
          'HireMatrix',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildNavLink(String title, String route, bool isDark) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildSignInButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.getPrimary(isDark), AppColors.getPrimary(isDark)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.login),
        child: Text(
          'Sign In',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Hero Section Widget
class HeroSection extends StatefulWidget {
  final bool isDark;

  const HeroSection({super.key, required this.isDark});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

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
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 20),
      child: Column(
        children: [
          // Hero Title
          Text(
            'Find Your ',
            style: GoogleFonts.inter(
              fontSize: MediaQuery.of(context).size.width > 768 ? 48 : 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'Dream Job',
              style: GoogleFonts.inter(
                fontSize: MediaQuery.of(context).size.width > 768 ? 48 : 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Connect with top companies and discover opportunities that match your skills. AI-powered recommendations to fast-track your career.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Search Panel - FIXED
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: isDark ? AppColors.getCard(isDark) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MediaQuery.of(context).size.width > 700
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildSearchInput(
                            icon: Icons.search,
                            hint: 'Job title, skills, or company',
                            isDark: isDark,
                            controller: _searchController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildSearchInput(
                            icon: Icons.location_on,
                            hint: 'City or location',
                            isDark: isDark,
                            controller: _locationController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSearchButton()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSearchInput(
                          icon: Icons.search,
                          hint: 'Job title, skills, or company',
                          isDark: isDark,
                          controller: _searchController,
                        ),
                        const SizedBox(height: 12),
                        _buildSearchInput(
                          icon: Icons.location_on,
                          hint: 'City or location',
                          isDark: isDark,
                          controller: _locationController,
                        ),
                        const SizedBox(height: 12),
                        _buildSearchButton(),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Sign in to view complete listings, AI match score, and application status.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : const Color(0xFF6B7280),
            ),
          ),
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
      height: 48, // Fixed height
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
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
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Get.toNamed(AppRoutes.login);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.getPrimary(widget.isDark),
                AppColors.getPrimary(widget.isDark),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.getPrimary(widget.isDark).withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              'Search Jobs',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Featured Jobs Section
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(
                        widget.isDark,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.getPrimary(widget.isDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Open Roles',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPrimary(widget.isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      'Featured Jobs',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live openings pulled from the database.\nSign in to get personalized matching.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: widget.isDark
                          ? Colors.grey[400]
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: Row(
                  children: [
                    Text(
                      'View all jobs',
                      style: GoogleFonts.inter(
                        color: AppColors.getPrimary(widget.isDark),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.getPrimary(widget.isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Swipe',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: widget.isDark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Jobs Carousel
          SizedBox(
            height: 290,
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
                        if (_controller.featuredJobs.isEmpty) {
                          // Fallback to static mock data if DB is empty
                          return Container(
                            width: MediaQuery.of(context).size.width > 600
                                ? 350
                                : MediaQuery.of(context).size.width * 0.85,
                            margin: const EdgeInsets.only(right: 20),
                            child: JobCard(
                              title: _getJobTitle(index),
                              company: _getCompanyName(index),
                              location: _getLocation(index),
                              postedAt: _getPostedDate(index),
                              matchScore: _getMatchScore(index),
                              isDark: widget.isDark,
                              onTap: () => Get.toNamed(AppRoutes.login),
                            ),
                          );
                        }

                        final job = _controller.featuredJobs[index];
                        final title = job['title'] ?? 'Untitled Role';
                        final company = job['company'] ?? 'Company';
                        final location = job['location'] ?? 'N/A';
                        final postedAt =
                            job['posted_at_formatted'] ?? 'Recently';
                        final matchScore = job['match_score'] ?? 85;

                        return Container(
                          width: MediaQuery.of(context).size.width > 600
                              ? 350
                              : MediaQuery.of(context).size.width * 0.85,
                          margin: const EdgeInsets.only(right: 20),
                          child: JobCard(
                            title: title,
                            company: company,
                            location: location,
                            postedAt: postedAt,
                            matchScore: matchScore,
                            isDark: widget.isDark,
                            onTap: () => Get.toNamed(AppRoutes.login),
                          ),
                        );
                      },
                    );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to see personalized match scores, saved jobs, and application status.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: widget.isDark ? Colors.grey[500] : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _getJobTitle(int index) {
    const titles = [
      'Data Scientist',
      'UI/UX Designer',
      'Backend Engineer',
      'Frontend Developer',
      'Product Manager',
      'DevOps Engineer',
    ];
    return titles[index % titles.length];
  }

  String _getCompanyName(int index) {
    const companies = [
      'AI Dynamics',
      'Design Studio Pro',
      'Cloud Systems Inc',
      'TechStart',
      'Innovation Labs',
      'ScaleUp',
    ];
    return companies[index % companies.length];
  }

  String _getLocation(int index) {
    const locations = [
      'Boston, MA',
      'Los Angeles, CA',
      'Seattle, WA',
      'New York, NY',
      'Austin, TX',
      'San Francisco, CA',
    ];
    return locations[index % locations.length];
  }

  String _getPostedDate(int index) {
    const dates = [
      '2 days ago',
      '4 days ago',
      '1 day ago',
      '3 days ago',
      '5 days ago',
      '2 days ago',
    ];
    return dates[index % dates.length];
  }

  int _getMatchScore(int index) {
    const scores = [88, 91, 86, 92, 89, 90];
    return scores[index % scores.length];
  }
}

// Features Section
class FeaturesSection extends StatelessWidget {
  final bool isDark;

  const FeaturesSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: FeaturesCard(isDark: isDark),
    );
  }
}

// Get Started Section
class GetStartedSection extends StatelessWidget {
  final bool isDark;

  const GetStartedSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
      color: Colors.transparent,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'Get Started Today',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Whether you\'re looking for your next opportunity or searching for top talent, HireMatrix has you covered.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Swipe',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600
                      ? 400
                      : MediaQuery.of(context).size.width * 0.85,
                  child: GetStartedCard(type: 'candidate', isDark: isDark),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600
                      ? 400
                      : MediaQuery.of(context).size.width * 0.85,
                  child: GetStartedCard(type: 'recruiter', isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Footer Section
class FooterSection extends StatelessWidget {
  final bool isDark;

  const FooterSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: AppColors.getBackground(isDark),
      child: Column(
        children: [
          // Footer Columns - Responsive layout
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogoSection(isDark),
                    const SizedBox(height: 32),
                    _buildJobSeekerSection(isDark),
                    const SizedBox(height: 24),
                    _buildRecruiterSection(isDark),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildLogoSection(isDark)),
                    Expanded(child: _buildJobSeekerSection(isDark)),
                    Expanded(child: _buildRecruiterSection(isDark)),
                  ],
                ),

          Divider(color: Colors.white24, height: 48),

          // Bottom Bar - Responsive
          isMobile
              ? Column(
                  children: [
                    _buildSocialIcons(),
                    const SizedBox(height: 16),
                    _buildCopyright(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildCopyright(), _buildSocialIcons()],
                ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getPrimary(isDark),
                    AppColors.getPrimary(isDark),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'HireMatrix',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Connecting talent with opportunities through AI-powered recommendations.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildJobSeekerSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For Job Seekers',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooterLink('Browse Jobs', '/jobs'),
        _buildFooterLink('Get Started', '/#get-started'),
        _buildFooterLink('Create Candidate Account', '/register'),
      ],
    );
  }

  Widget _buildRecruiterSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For Recruiters',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _buildFooterLink('Join as Recruiter', '/recruiter/register'),
        _buildFooterLink('Sign In', '/login'),
      ],
    );
  }

  Widget _buildFooterLink(String text, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (route == '/#get-started') {
            // Scroll to get started section on landing page
            Get.toNamed('/');
            // You can add scroll to element logic here
          } else {
            Get.toNamed(route);
          }
        },
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSocialIcon(
          FaIcon(FontAwesomeIcons.linkedin, size: 20, color: Colors.white),
          'LinkedIn',
          'https://linkedin.com/company/hirematrix',
        ),
        const SizedBox(width: 16),
        _buildSocialIcon(
          FaIcon(FontAwesomeIcons.xTwitter, size: 20, color: Colors.white),
          'X (Twitter)',
          'https://twitter.com/hirematrix',
        ),
        const SizedBox(width: 16),
        _buildSocialIcon(
          FaIcon(FontAwesomeIcons.instagram, size: 20, color: Colors.white),
          'Instagram',
          'https://instagram.com/hirematrix',
        ),
        const SizedBox(width: 16),
        _buildSocialIcon(
          FaIcon(FontAwesomeIcons.facebook, size: 20, color: Colors.white),
          'Facebook',
          'https://facebook.com/hirematrix',
        ),
      ],
    );
  }

  Widget _buildSocialIcon(Widget icon, String label, String url) {
    return InkWell(
      onTap: () {
        // Add url_launcher to open URLs
        // launchUrl(Uri.parse(url));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon,
      ),
    );
  }

  Widget _buildSearchInput({
    required IconData icon,
    required String hint,
    required bool isDark,
  }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.getPrimary(isDark),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Text(
      '© ${DateTime.now().year} HireMatrix. All rights reserved.',
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
    );
  }
}
