import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../models/saved_account.dart';
import 'login_screen.dart';
import '../main_screen.dart';

class AccountSelectionScreen extends StatelessWidget {
  const AccountSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Switch Account',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getText(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a recruiter workspace to continue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.getTextMuted(isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: auth.savedAccounts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final account = auth.savedAccounts[index];
                    return _buildAccountTile(context, account, isDark);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildAddAccountButton(context, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, SavedAccount account, bool isDark) {
    return InkWell(
      onTap: () async {
        final auth = Provider.of<AuthController>(context, listen: false);
        final success = await auth.switchAccount(account);
        if (success && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
              child: Text(
                account.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimary(isDark),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    account.company,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
              onPressed: () {
                Provider.of<AuthController>(context, listen: false).removeSavedAccount(account.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountButton(BuildContext context, bool isDark) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline_rounded, size: 20),
          const SizedBox(width: 12),
          Text(
            'Add Workspace Account',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
