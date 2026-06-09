import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';
import 'account_selection_screen.dart';
import '../main_screen.dart';

import '../../widgets/hirematrix_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final response = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        bool needsVerify = response['needs_verification'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text(response['message'] ?? 'Login failed')),
                if (needsVerify)
                  TextButton(
                    onPressed: () => _handleResendVerification(_emailController.text.trim()),
                    child: const Text('RESEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleResendVerification(String email) async {
    final api = ApiService();
    final response = await api.resendVerification(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['success'] == true ? 'Verification email sent' : 'Failed to resend'),
        backgroundColor: response['success'] == true ? AppColors.success : AppColors.error,
      ));
    }
  }

  void _handleForgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your registered email to receive a password reset link.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(hintText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
                return;
              }
              Navigator.pop(ctx);
              final auth = Provider.of<AuthController>(context, listen: false);
              final response = await auth.forgotPassword(emailCtrl.text.trim());
              
              if (!mounted) return;
              final token = response['token']?.toString();
              
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(response['message'] ?? 'Check your email'),
                backgroundColor: response['success'] == true ? AppColors.success : AppColors.error,
                duration: const Duration(seconds: 8),
                action: (token != null) ? SnackBarAction(
                  label: 'RESET NOW',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(token: token),
                    ));
                  },
                ) : null,
              ));
            }, 
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(isDarkMode),
                const SizedBox(height: 32),
                _buildLoginForm(isDarkMode),
                const SizedBox(height: 24),
                _buildSignupLink(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    final auth = Provider.of<AuthController>(context);
    return Column(
      children: [
        HireMatrixLogo(
          height: 48,
          imageUrl: auth.currentRecruiter?.companyLogo,
        ),
        const SizedBox(height: 16),
        Text(
          'Recruiter Workspace Access',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.getTextMuted(isDarkMode),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDarkMode) {
    final auth = Provider.of<AuthController>(context);
    
    return Column(
      children: [
        if (auth.savedAccounts.isNotEmpty) ...[
          _buildSavedAccountsQuickSelect(auth, isDarkMode),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR LOGIN WITH EMAIL', 
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.getCard(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(isDarkMode).withAlpha(40)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Log in to manage your hiring pipeline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.getTextMuted(isDarkMode)),
                ),
                const SizedBox(height: 32),
                
                _buildLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'name@company.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Invalid email' : null,
                ),
                const SizedBox(height: 16),
                
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Password too short' : null,
                ),
                
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 20, width: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v!),
                            activeColor: AppColors.getPrimary(isDarkMode),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Keep me logged in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text('Reset Password', style: TextStyle(fontSize: 12, color: AppColors.getPrimary(isDarkMode), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  child: auth.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('LOG IN TO DASHBOARD'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAccountsQuickSelect(AuthController auth, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Workspaces', 
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.getText(isDarkMode))),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSelectionScreen())),
              child: Text('See All', style: TextStyle(fontSize: 11, color: AppColors.getPrimary(isDarkMode), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: auth.savedAccounts.length > 3 ? 3 : auth.savedAccounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final account = auth.savedAccounts[index];
              return InkWell(
                onTap: () async {
                  final success = await auth.switchAccount(account);
                  if (!mounted) return;
                  if (success) {
                    if (context.mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.getCard(isDarkMode) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.getBorder(isDarkMode).withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.getPrimary(isDarkMode).withAlpha(20),
                        child: Text(account.name[0].toUpperCase(), 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDarkMode))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(account.name, 
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(account.company, 
                              style: GoogleFonts.inter(fontSize: 9, color: Colors.grey),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignupLink(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New to HireMatrix?", style: TextStyle(color: AppColors.getTextMuted(isDarkMode), fontSize: 13)),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
          },
          child: Text(
            'Create Recruiter Account',
            style: TextStyle(color: AppColors.getPrimary(isDarkMode), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
