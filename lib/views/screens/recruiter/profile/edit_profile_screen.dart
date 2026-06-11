import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';

class EditProfileScreen extends StatefulWidget {
  final Recruiter recruiter;
  const EditProfileScreen({super.key, required this.recruiter});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recruiter.fullName);
    _companyController = TextEditingController(text: widget.recruiter.companyName);
    _phoneController = TextEditingController(text: widget.recruiter.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final response = await auth.updateProfile(
        fullName: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Update failed'), backgroundColor: AppColors.error)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (!auth.isLoading)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _handleUpdate,
            ),
        ],
      ),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    _buildTextField(_nameController, 'Enter your name', Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildLabel('Company Name'),
                    _buildTextField(_companyController, 'Organization Name', Icons.business_rounded),
                    const SizedBox(height: 16),
                    _buildLabel('Contact Number'),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone_android_rounded, keyboard: TextInputType.phone),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _handleUpdate,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                      child: const Text('SAVE CHANGES'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.getText(Theme.of(context).brightness == Brightness.dark).withValues(alpha: 0.8))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}
