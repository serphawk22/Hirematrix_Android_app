import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/language_controller.dart';
import '../../services/api_service.dart';
import '../../models/recruiter.dart';
import '../drawer/company_details_screen.dart';
import '../drawer/team_management_screen.dart';
import '../auth/login_screen.dart';
import '../auth/account_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Workspace', 'Notifications', 'Security'];
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  Map<String, dynamic> _settings = {
    'workspace_status': 1,
    'application_alerts': 1,
    'interview_reminders': 1,
    'hiring_summary': 1,
    'two_factor_auth': 0,
    'language': 'English',
  };

  final List<Map<String, String>> _languagesList = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Hindi', 'native': 'हिन्दी'},
    {'name': 'Bengali', 'native': 'বাংলা'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'name': 'Malayalam', 'native': 'മലയാളം'},
    {'name': 'Marathi', 'native': 'मराठी'},
    {'name': 'Punjabi (Gurmukhi)', 'native': 'ਪੰਜਾਬੀ'},
    {'name': 'Tamil', 'native': 'தமிழ்'},
    {'name': 'Telugu', 'native': 'తెలుగు'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      final response = await _apiService.fetchSettings(recruiterId);
      if (response['success'] == true) {
        setState(() {
          _settings = response['settings'] ?? _settings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSetting(String key, dynamic value) async {
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId == null) return;

    // Optimistic update
    setState(() {
      _settings[key] = value;
    });

    final response = await _apiService.updateSettings({
      'recruiter_id': recruiterId,
      key: value,
    });

    if (response['success'] != true && mounted) {
      // Revert if failed
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Failed to update setting'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recruiter = Provider.of<AuthController>(context).currentRecruiter;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: _buildCompactAppBar(context, isDarkMode),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                _buildCompactProfileHeader(recruiter, isDarkMode),
                _buildCompactSegmentedTabs(isDarkMode),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWorkspaceSection(isDarkMode),
                      _buildNotificationsSection(isDarkMode),
                      _buildSecuritySection(isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
      elevation: 0,
      toolbarHeight: 52,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Workspace Settings',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }

  Widget _buildCompactProfileHeader(Recruiter? recruiter, bool isDark) {
    String initial = 'R';
    if (recruiter != null && recruiter.fullName.isNotEmpty) {
      initial = recruiter.fullName[0].toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
            child: Text(
              initial,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recruiter?.fullName ?? 'Recruiter',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Senior Hiring Manager',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.getPrimary(isDark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCompactVerifiedBadge(),
        ],
      ),
    );
  }

  Widget _buildCompactVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
    );
  }

  Widget _buildCompactSegmentedTabs(bool isDarkMode) {
    return Container(
      height: 52, // Increased height to prevent clipping
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDarkMode ? AppColors.getCard(isDarkMode) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: AppColors.getPrimary(isDarkMode),
        unselectedLabelColor: AppColors.getTextMuted(isDarkMode),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: _tabs.map((t) => Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWorkspaceSection(bool isDark) {
    final langController = Provider.of<LanguageController>(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompactSectionLabel('WORKSPACE'),
        _buildCompactAdminTile(
          Icons.work_outline_rounded, 
          'Workspace Status', 
          'Manage hiring mode', 
          isDark, 
          trailing: _buildCompactSwitch(_settings['workspace_status'] == 1, (v) => _toggleSetting('workspace_status', v ? 1 : 0))
        ),
        _buildCompactAdminTile(
          Icons.translate_rounded, 
          'App Language', 
          langController.currentLanguage, 
          isDark, 
          onTap: () => _showLanguageSelectionDialog(context, langController)
        ),
        _buildCompactAdminTile(
          Icons.business_rounded, 
          'Organization Profile', 
          'Control visibility', 
          isDark, 
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyDetailsScreen()))
        ),
        _buildCompactAdminTile(
          Icons.group_outlined, 
          'Team & Roles', 
          'Collaborator settings', 
          isDark,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen()))
        ),
        _buildCompactAdminTile(Icons.admin_panel_settings_outlined, 'Permissions', 'Data privacy', isDark),
      ],
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, LanguageController controller) {
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.getCard(isDark) : Colors.white,
        title: Text(
          controller.translate('app_language'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languagesList.length,
            itemBuilder: (context, index) {
              final lang = _languagesList[index];
              final isSelected = controller.currentLanguage == lang['name'];
              return ListTile(
                dense: true,
                title: Text(
                  lang['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.getPrimary(isDark) : null,
                  ),
                ),
                subtitle: Text(
                  lang['native']!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isSelected ? AppColors.getPrimary(isDark).withOpacity(0.7) : AppColors.getTextMuted(isDark),
                  ),
                ),
                trailing: isSelected 
                    ? Icon(Icons.check_circle_rounded, color: AppColors.getPrimary(isDark), size: 18) 
                    : null,
                onTap: () async {
                  await controller.setLanguage(lang['name']!, recruiterId);
                  if (mounted) {
                    setState(() {
                      _settings['language'] = lang['name'];
                    });
                    Navigator.pop(ctx);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompactSectionLabel('NOTIFICATIONS'),
        _buildCompactAdminTile(
          Icons.person_search_outlined, 
          'Application Alerts', 
          'Push notifications', 
          isDark, 
          trailing: _buildCompactSwitch(_settings['application_alerts'] == 1, (v) => _toggleSetting('application_alerts', v ? 1 : 0))
        ),
        _buildCompactAdminTile(
          Icons.calendar_today_outlined, 
          'Interview Reminders', 
          'Sync updates', 
          isDark, 
          trailing: _buildCompactSwitch(_settings['interview_reminders'] == 1, (v) => _toggleSetting('interview_reminders', v ? 1 : 0))
        ),
        _buildCompactAdminTile(
          Icons.analytics_outlined, 
          'Hiring Summary', 
          'Weekly reports', 
          isDark, 
          trailing: _buildCompactSwitch(_settings['hiring_summary'] == 1, (v) => _toggleSetting('hiring_summary', v ? 1 : 0))
        ),
      ],
    );
  }

  Widget _buildSecuritySection(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompactSectionLabel('SECURITY'),
        _buildCompactAdminTile(Icons.lock_outline_rounded, 'Change Password', 'Update credentials', isDark, onTap: _showChangePasswordDialog),
        _buildCompactAdminTile(
          Icons.security_outlined, 
          '2FA Authentication', 
          'Login protection', 
          isDark, 
          trailing: _buildCompactSwitch(_settings['two_factor_auth'] == 1, (v) => _toggleSetting('two_factor_auth', v ? 1 : 0))
        ),
        _buildCompactAdminTile(Icons.history_rounded, 'Login Activity', 'Session history', isDark),
        const SizedBox(height: 16),
        _buildCompactLogoutTile(isDark),
      ],
    );
  }

  Widget _buildCompactSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.getTextMuted(Theme.of(context).brightness == Brightness.dark))),
    );
  }

  Widget _buildCompactAdminTile(IconData icon, String title, String subtitle, bool isDark, {Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, size: 18, color: AppColors.getPrimary(isDark)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      ),
    );
  }

  Widget _buildCompactSwitch(bool val, Function(bool)? onChanged) {
    return SizedBox(
      height: 24, width: 40,
      child: Switch(
        value: val, 
        onChanged: onChanged, 
        activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.5), 
        activeThumbColor: AppColors.getPrimary(Theme.of(context).brightness == Brightness.dark),
        thumbColor: WidgetStateProperty.all(Colors.white)
      ),
    );
  }

  Widget _buildCompactLogoutTile(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
        title: Text('Logout Account', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.error)),
        onTap: () => _showLogoutConfirm(context),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your workspace?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final auth = Provider.of<AuthController>(context, listen: false);
              final hasSaved = auth.savedAccounts.length > 1;
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => hasSaved ? const AccountSelectionScreen() : const LoginScreen()),
                  (route) => false,
                );
              }
            }, 
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              TextField(controller: confirmPass, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isUpdating ? null : () async {
                if (newPass.text != confirmPass.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                setDialogState(() => isUpdating = true);
                
                final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
                final response = await _apiService.changePassword(
                  userId: recruiterId!,
                  oldPassword: oldPass.text,
                  newPassword: newPass.text,
                  confirmPassword: confirmPass.text,
                );

                if (context.mounted) {
                  setDialogState(() => isUpdating = false);
                  if (response['success'] == true || response['status'] == 'success') {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Update failed'), backgroundColor: AppColors.error));
                  }
                }
              }, 
              child: isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
