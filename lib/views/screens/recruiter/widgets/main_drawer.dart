import 'package:flutter/material.dart';
import 'package:hirematrix/views/screens/landing_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/drawer/company_details_screen.dart';
import 'package:hirematrix/views/screens/recruiter/drawer/team_management_screen.dart';
import 'package:hirematrix/views/screens/recruiter/candidates/candidate_management_screen.dart';
import 'package:hirematrix/views/screens/recruiter/drawer/help_support_screen.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/views/screens/recruiter/auth/login_screen.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';

import 'package:hirematrix/views/screens/recruiter/auth/account_selection_screen.dart';
import 'package:hirematrix/views/screens/recruiter/dashboard/candidate_insights_screen.dart';

import 'package:hirematrix/views/screens/recruiter/jobs/interview_slots_screen.dart';
import 'package:hirematrix/views/screens/recruiter/jobs/interview_bookings_screen.dart';
import 'package:hirematrix/views/screens/recruiter/profile/settings_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final recruiter = authController.currentRecruiter;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final background = AppColors.getBackground(isDarkMode);
    final borderColor = AppColors.getBorder(isDarkMode);

    return Drawer(
      backgroundColor: background,
      width: MediaQuery.of(context).size.width * 0.82,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildDrawerHeader(
                    context,
                    recruiter,
                    isDarkMode,
                    borderColor,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionLabel('RECRUITER WORKSPACE'),
                      _buildDrawerItem(
                        context,
                        Icons.storage_rounded,
                        'Candidate Database',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CandidateManagementScreen(
                                    isStandalone: true,
                                  ),
                            ),
                          );
                        },
                        isDarkMode,
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.emoji_events_outlined,
                        'Candidate Insights',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CandidateInsightsScreen(),
                            ),
                          );
                        },
                        isDarkMode,
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.business_center_outlined,
                        'Company Profile',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CompanyDetailsScreen(),
                            ),
                          );
                        },
                        isDarkMode,
                      ),
                      _buildExpandableDrawerItem(
                        context: context,
                        icon: Icons.event_available_rounded,
                        title: 'Interviews',
                        isDark: isDarkMode,
                        children: [
                          _buildDrawerItem(
                            context,
                            Icons.event_note_rounded,
                            'Interview Slots',
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InterviewSlotsScreen(),
                                ),
                              );
                            },
                            isDarkMode,
                          ),
                          _buildDrawerItem(
                            context,
                            Icons.book_online_rounded,
                            'Interview Bookings',
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InterviewBookingsScreen(),
                                ),
                              );
                            },
                            isDarkMode,
                          ),
                        ],
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.group_outlined,
                        'Team Management',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TeamManagementScreen(),
                            ),
                          );
                        },
                        isDarkMode,
                      ),
                      _buildDrawerItem(
                        context,
                        Icons.settings_outlined,
                        'Settings',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        isDarkMode,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Divider(height: 1, thickness: 0.5),
                      ),

                      _buildSectionLabel('SUPPORT'),
                      _buildDrawerItem(
                        context,
                        Icons.help_outline_rounded,
                        'Help & Support',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                        isDarkMode,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomSection(context, authController, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    Recruiter? recruiter,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        border: Border(
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.getPrimary(
              isDark,
            ).withValues(alpha: 0.1),
            child: Text(
              (recruiter != null && recruiter.fullName.isNotEmpty)
                  ? recruiter.fullName.substring(0, 1).toUpperCase()
                  : 'R',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  recruiter?.fullName ?? 'Recruiter Name',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            recruiter?.email ?? 'recruiter@company.com',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  size: 12,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  recruiter?.companyName.toUpperCase() ?? 'ORGANIZATION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDark, {
    Color? color,
    bool isActive = false,
  }) {
    final textColor = isActive
        ? AppColors.getPrimary(isDark)
        : (color ?? AppColors.getText(isDark).withValues(alpha: 0.8));
    final iconColor = isActive
        ? AppColors.getPrimary(isDark)
        : (color ?? Colors.blueGrey[400]);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.getPrimary(isDark).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildExpandableDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.blueGrey[400], size: 20),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.getText(isDark).withValues(alpha: 0.8),
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          iconColor: AppColors.getPrimary(isDark),
          collapsedIconColor: Colors.blueGrey[400],
          dense: true,
          visualDensity: VisualDensity.compact,
          children: children,
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    AuthController authController,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              final savedCount = authController.savedAccounts.length;
              await authController.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => savedCount > 0
                        ? const LandingScreen()
                        : const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout Workspace',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise Security',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'v1.0.8 Aligned',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
