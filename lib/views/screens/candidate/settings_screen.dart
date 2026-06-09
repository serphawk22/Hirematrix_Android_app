import 'dart:async';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/controllers/settings_controller.dart';
import 'package:hirematrix/routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SettingsController _settingsController;
  Timer? _syncTimer;

  // Change Password Form State
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _showCurrentPassword = false.obs;
  final _showNewPassword = false.obs;
  final _showConfirmPassword = false.obs;

  late DashboardController _dashController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dashController = Get.find<DashboardController>();
    _settingsController = Get.put(SettingsController());

    // Fetch fresh settings state immediately when Settings index is selected
    _dashController.currentIndex.listen((index) {
      if (index == 5 && mounted) {
        _dashController.fetchDashboardData();
      }
    });

    // Initial fetch on mount
    _dashController.fetchDashboardData();

    // Poll server settings every 3 seconds to keep sync'd with web changes
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_dashController.currentIndex.value == 5 &&
          !_settingsController.isLoading.value &&
          mounted) {
        _dashController.fetchDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _tabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateSettingField(String field, bool value) async {
    await _settingsController.updateSettingField(field, value);
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _settingsController.handlePasswordChange(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final profile = _dashController.userProfile;

      final mainBg = isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark);
      final cardBg = isDark ? AppColors.getCard(isDark) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF111827);
      final subtitleColor = isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF475569);
      final borderColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;

      final isVisible =
          int.tryParse(
            profile['allow_public_recruiter_visibility']?.toString() ?? '1',
          ) ==
          1;

      return Scaffold(
        backgroundColor: mainBg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom settings header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: AppColors.getPrimary(isDark),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ACCOUNT SETTINGS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPrimary(isDark),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Settings',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _dashController.currentIndex.value =
                                    4; // Back to profile tab
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: isDark
                                    ? AppColors.getPrimary(
                                        isDark,
                                      ).withOpacity(0.1)
                                    : AppColors.getPrimary(
                                        isDark,
                                      ).withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppColors.getPrimary(isDark),
                              ),
                              label: Text(
                                'My Profile',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getPrimary(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Control profile visibility, notifications, and account security from one compact panel.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Snapshot Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Quick snapshot',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep your job search settings aligned with your profile',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update visibility and alerts here, then continue editing the rest of your profile in one place.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isVisible ? 1.0 : 0.35,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.getPrimary(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab bar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 1.5),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                      indicatorColor: AppColors.getPrimary(isDark),
                      labelColor: AppColors.getPrimary(isDark),
                      unselectedLabelColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                      tabs: const [
                        Tab(text: 'Appearance'),
                        Tab(text: 'Visibility'),
                        Tab(text: 'Notifications'),
                        Tab(text: 'Account'),
                      ],
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAppearanceTab(
                          isDark,
                          cardBg,
                          textColor,
                          subtitleColor,
                          borderColor,
                          themeController,
                        ),
                        _buildVisibilityTab(
                          isDark,
                          cardBg,
                          textColor,
                          subtitleColor,
                          borderColor,
                          isVisible,
                        ),
                        _buildNotificationsTab(
                          isDark,
                          cardBg,
                          textColor,
                          subtitleColor,
                          borderColor,
                          profile,
                        ),
                        _buildAccountTab(
                          isDark,
                          cardBg,
                          textColor,
                          subtitleColor,
                          borderColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_settingsController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.getPrimary(isDark),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildVisibilityTab(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
    bool isVisible,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profile Visibility',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Control whether recruiters can discover your profile outside the jobs you already applied for.',
          style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visible To Recruiters',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When off, recruiters can access your profile only after you apply to one of their jobs.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: isVisible,
                activeThumbColor: AppColors.getPrimary(isDark),
                onChanged: (val) {
                  // Optimistic update
                  _dashController
                      .userProfile['allow_public_recruiter_visibility'] = val
                      ? 1
                      : 0;
                  _dashController.userProfile.refresh();
                  _updateSettingField('allow_public_recruiter_visibility', val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
    Map<String, dynamic> profile,
  ) {
    final alertsEnabled =
        int.tryParse(profile['job_alerts_enabled']?.toString() ?? '1') == 1;
    final notifyInApp =
        int.tryParse(profile['job_alert_notify_in_app']?.toString() ?? '1') ==
        1;
    final notifyEmail =
        int.tryParse(profile['job_alert_notify_email']?.toString() ?? '1') == 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage job alert activation and choose where alert updates should reach you.',
          style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildNotificationSwitchRow(
                title: 'Job Alerts',
                description:
                    'Turn profile-based job alerts on or off without changing the preferences saved in your profile.',
                value: alertsEnabled,
                onChanged: (val) {
                  // Optimistic update
                  _dashController.userProfile['job_alerts_enabled'] = val
                      ? 1
                      : 0;
                  _dashController.userProfile.refresh();
                  _updateSettingField('job_alerts_enabled', val);
                },
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              Divider(color: borderColor),
              _buildNotificationSwitchRow(
                title: 'In-App Notifications',
                description: 'Show matching job updates inside the portal.',
                value: notifyInApp,
                onChanged: (val) {
                  // Optimistic update
                  _dashController.userProfile['job_alert_notify_in_app'] = val
                      ? 1
                      : 0;
                  _dashController.userProfile.refresh();
                  _updateSettingField('job_alert_notify_in_app', val);
                },
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              Divider(color: borderColor),
              _buildNotificationSwitchRow(
                title: 'Email Notifications',
                description:
                    'Send matching jobs to your registered email address.',
                value: notifyEmail,
                onChanged: (val) {
                  // Optimistic update
                  _dashController.userProfile['job_alert_notify_email'] = val
                      ? 1
                      : 0;
                  _dashController.userProfile.refresh();
                  _updateSettingField('job_alert_notify_email', val);
                },
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: subtitleColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Job alert criteria are now taken automatically from the Preferences section in your profile.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: subtitleColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSwitchRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.getPrimary(Get.isDarkMode),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Account Security',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use the secure password change form to update your account credentials.',
          style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure your new password is at least 6 characters long and matches the confirmation.',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
                const SizedBox(height: 20),

                // Current Password
                Obx(
                  () => TextFormField(
                    controller: _currentPasswordController,
                    obscureText: !_showCurrentPassword.value,
                    style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                      hintText: 'Enter your current password',
                      hintStyle: GoogleFonts.inter(
                        color: subtitleColor.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: subtitleColor,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: subtitleColor,
                          size: 18,
                        ),
                        onPressed: _showCurrentPassword.toggle,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                Obx(
                  () => TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword.value,
                    style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                      hintText: 'Enter new password',
                      hintStyle: GoogleFonts.inter(
                        color: subtitleColor.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_reset,
                        color: subtitleColor,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: subtitleColor,
                          size: 18,
                        ),
                        onPressed: _showNewPassword.toggle,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                Obx(
                  () => TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword.value,
                    style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                      hintText: 'Confirm new password',
                      hintStyle: GoogleFonts.inter(
                        color: subtitleColor.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_clock,
                        color: subtitleColor,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: subtitleColor,
                          size: 18,
                        ),
                        onPressed: _showConfirmPassword.toggle,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _handlePasswordChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getPrimary(isDark),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Update Password',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab(
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
    ThemeController themeController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'App Appearance',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your preferred theme style for the HireMatrix interface.',
          style: GoogleFonts.inter(fontSize: 12.5, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: Text(
                  'Light Theme',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Clean and bright interface, best for daytime use.',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
                value: false,
                groupValue: isDark,
                activeColor: AppColors.getPrimary(isDark),
                onChanged: (val) {
                  if (isDark) {
                    themeController.toggleTheme();
                  }
                },
              ),
              Divider(height: 1, color: borderColor),
              RadioListTile<bool>(
                title: Text(
                  'Dark Theme',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'High contrast dark interface, easier on the eyes.',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor),
                ),
                value: true,
                groupValue: isDark,
                activeColor: AppColors.getPrimary(isDark),
                onChanged: (val) {
                  if (!isDark) {
                    themeController.toggleTheme();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
