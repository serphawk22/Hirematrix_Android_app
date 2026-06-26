import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/theme_provider.dart';
import 'package:hirematrix/views/screens/recruiter/auth/recruiter_change_password_screen.dart';

class RecruiterSettingsScreen extends StatefulWidget {
  const RecruiterSettingsScreen({super.key});

  @override
  State<RecruiterSettingsScreen> createState() => _RecruiterSettingsScreenState();
}

class _RecruiterSettingsScreenState extends State<RecruiterSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Account Security', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                title: 'Change Password',
                description: 'Manage your login credentials and security.',
                icon: Icons.lock_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecruiterChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Appearance', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                title: 'Theme',
                description: 'Switch between light and dark mode.',
                icon: Icons.palette_outlined,
                trailing: _ThemeToggleWidget(initialIsDark: isDark),
                onTap: null, // Interactive trailing widget
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Language', isDark),
              const SizedBox(height: 12),
              _buildSettingsCard(
                isDark: isDark,
                title: 'Page Translation',
                description: 'Feature coming soon. Mobile app translations will be supported in a future update.',
                icon: Icons.language,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language translation feature coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey[300] : Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.getPrimary(isDark),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleWidget extends StatefulWidget {
  final bool initialIsDark;
  const _ThemeToggleWidget({required this.initialIsDark});

  @override
  State<_ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<_ThemeToggleWidget> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialIsDark;
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: _isDark ? const Text('🌞', style: TextStyle(fontSize: 14)) : const SizedBox.shrink(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: !_isDark ? const Text('🌙', style: TextStyle(fontSize: 14)) : const SizedBox.shrink(),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: _isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isDark ? const Color(0xFF334155) : Colors.white,
                    boxShadow: [
                      if (!_isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
