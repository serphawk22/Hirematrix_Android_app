import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hirematrix/controllers/recruiter_controller/utils/api_constants.dart';
import 'package:http/http.dart' as http;

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final baseUrl = ApiConstants.baseUrl;
      final uri = Uri.parse('$baseUrl/contact');
      final response = await http.post(
        uri,
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        Get.snackbar(
          'Success',
          'Thanks, your message has been received. Our team will review it shortly.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not send message. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final mainBg = AppColors.getBackground(isDark);
      final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5D7083);
      final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

      return Scaffold(
        backgroundColor: mainBg,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/hirematrix_logo.png', width: 24, height: 24, errorBuilder: (context, error, stackTrace) => Icon(Icons.bolt, color: AppColors.getPrimary(isDark))),
              const SizedBox(width: 8),
              Text('HireMatrix', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textColor, fontSize: 18)),
            ],
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.envelopeOpenText, size: 14, color: AppColors.getPrimary(isDark)),
                          const SizedBox(width: 8),
                          Text('Contact', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Get in touch with the HireMatrix team.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Use this page for product questions, support requests, partnership enquiries, recruiter onboarding, or anything else related to the portal.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, color: subtitleColor, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Contact Info
              Text('What to contact us about', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text('We can help with account questions, recruiter onboarding, candidate experience issues, AI interview workflow questions, subscription matters, and platform feedback.', style: GoogleFonts.inter(fontSize: 14.5, color: subtitleColor, height: 1.5)),
              const SizedBox(height: 24),
              _buildContactPoint('Support', 'Questions about access, profile issues, applications, or interview flow.\n\nMail ID : info.serphawk@gmail.com\nContact No : +91 97477 51235', cardColor, borderColor, textColor, subtitleColor),
              const SizedBox(height: 16),
              _buildContactPoint('Business enquiries', 'Recruiter onboarding, partnerships, or platform adoption discussions.', cardColor, borderColor, textColor, subtitleColor),
              const SizedBox(height: 16),
              _buildContactPoint('Feedback', 'Suggestions, bug reports, and ideas that can improve the hiring experience.', cardColor, borderColor, textColor, subtitleColor),
              const SizedBox(height: 48),

              // Contact Form
              Text('Send a message', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Full Name', 'Your name', isDark),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email Address', 'you@example.com', isDark, isEmail: true),
                    const SizedBox(height: 16),
                    _buildTextField(_subjectController, 'Subject', 'What do you need help with?', isDark),
                    const SizedBox(height: 16),
                    _buildTextField(_messageController, 'Message', 'Share the details and we will review your message.', isDark, maxLines: 5),
                    const SizedBox(height: 24),
                    Text(
                      'Messages submitted here are captured by the platform for follow-up. Add enough detail so the team can respond efficiently.',
                      style: GoogleFonts.inter(fontSize: 13, color: subtitleColor, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitContactForm,
                        icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                        label: Text('Send message', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This public contact form is intended for legitimate business and support communication. Please avoid sharing sensitive credentials, payment details, or confidential data in plain text.',
                  style: GoogleFonts.inter(fontSize: 12, color: subtitleColor, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildContactPoint(String title, String desc, Color cardColor, Color borderColor, Color textColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.inter(fontSize: 14, color: subtitleColor, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, bool isDark, {bool isEmail = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: isDark ? Colors.grey[600] : Colors.grey[400]),
            filled: true,
            fillColor: isDark ? const Color(0xFF1F2937) : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.getPrimary(isDark)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (isEmail && !GetUtils.isEmail(value)) return 'Invalid email';
            return null;
          },
        ),
      ],
    );
  }
}
