import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _designationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _designationController.dispose();
    _linkedinController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
        );
        return;
      }

      final auth = Provider.of<AuthController>(context, listen: false);
      final response = await auth.signup(
        fullName: _fullNameController.text.trim(),
        companyName: _companyController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        companyWebsite: _websiteController.text.trim(),
        companyLocation: _locationController.text.trim(),
        designation: _designationController.text.trim(),
        linkedinProfile: _linkedinController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Signup failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        title: const Text('Create Recruiter Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
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
                    'Workspace Setup',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register your company to begin hiring',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.getTextMuted(isDarkMode)),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildLabel('Personal Details'),
                  _buildTextField(_fullNameController, 'Full Name', Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_designationController, 'Designation / Role', Icons.badge_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Contact Number', Icons.phone_android_rounded, keyboard: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(_linkedinController, 'LinkedIn Profile (Optional)', Icons.link_rounded),
                  
                  const SizedBox(height: 24),
                  _buildLabel('Company Information'),
                  _buildTextField(_companyController, 'Organization Name', Icons.business_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Official Work Email', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_websiteController, 'Company Website', Icons.language_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_locationController, 'Company Location', Icons.location_on_outlined),
                  
                  const SizedBox(height: 24),
                  _buildLabel('Security'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePass,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Create Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Confirm password' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSignup,
                        child: auth.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('CREATE RECRUITER ACCOUNT'),
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          if (hint.contains('Optional')) return null;
          return 'Required';
        }
        return null;
      },
    );
  }
}
