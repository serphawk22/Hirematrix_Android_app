import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:hirematrix/routes/app_routes.dart';
import 'package:hirematrix/controllers/auth_controller.dart'; // Just to re-use baseUrl if possible, or duplicate for now
import 'package:hirematrix/core/constants/api_constants.dart';

class OnboardingController extends GetxController {
  final currentStep = 0.obs;
  final isLoading = false.obs;
  int userId = 0; // We need to store user_id during login

  // Personal Step
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final gender = ''.obs;
  final dateOfBirthController = TextEditingController();

  // Resume Step
  final selectedResumePath = ''.obs;
  final selectedResumeName = ''.obs;

  // Skills Step
  final skillsController = TextEditingController();

  // Education Step
  final educations = <Map<String, dynamic>>[].obs;

  // Experience Step
  final isFresher = false.obs;
  final experiences = <Map<String, dynamic>>[].obs;

  // Preferences Step
  final resumeHeadlineController = TextEditingController();
  final preferredJobTitlesController = TextEditingController();
  final preferredLocationsController = TextEditingController();
  final preferredEmploymentType = ''.obs;
  final noticePeriod = ''.obs;
  final expectedSalaryController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    int uId = 0;
    String uName = '';
    String uPhone = '';
    String uStep = 'personal';

    if (Get.arguments != null) {
      if (Get.arguments['user_id'] != null) uId = Get.arguments['user_id'];
      if (Get.arguments['name'] != null) uName = Get.arguments['name'];
      if (Get.arguments['phone'] != null) uPhone = Get.arguments['phone'];
      if (Get.arguments['onboarding_step'] != null) uStep = Get.arguments['onboarding_step'];
    } else {
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser.isNotEmpty) {
          final user = authController.currentUser;
          uId = int.tryParse(user['id']?.toString() ?? '') ?? 0;
          uName = user['name'] ?? '';
          uPhone = user['phone'] ?? '';
          uStep = user['onboarding_step'] ?? 'personal';
        }
      } catch (e) {
        // ignore
      }
    }

    userId = uId;
    nameController.text = uName;
    phoneController.text = uPhone;

    switch (uStep) {
      case 'resume': currentStep.value = 1; break;
      case 'skills': currentStep.value = 2; break;
      case 'education': currentStep.value = 3; break;
      case 'experience': currentStep.value = 4; break;
      case 'preferences': currentStep.value = 5; break;
      case 'review': currentStep.value = 6; break;
      default: currentStep.value = 0; break;
    }
    
    // Add one empty education and experience to start
    addEducation();
    addExperience();
  }

  void setUserId(int id) {
    userId = id;
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // Default 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      dateOfBirthController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void addEducation() {
    educations.add({
      'degree': TextEditingController(),
      'field_of_study': TextEditingController(),
      'institution': TextEditingController(),
      'start_year': TextEditingController(),
      'end_year': TextEditingController(),
      'grade': TextEditingController(),
    });
  }

  void removeEducation(int index) {
    educations.removeAt(index);
  }

  void addExperience() {
    experiences.add({
      'job_title': TextEditingController(),
      'company_name': TextEditingController(),
      'employment_type': 'Full-time',
      'location': TextEditingController(),
      'start_date': TextEditingController(),
      'end_date': TextEditingController(),
      'is_current': false,
      'description': TextEditingController(),
    });
  }

  void removeExperience(int index) {
    experiences.removeAt(index);
  }

  Future<void> pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        selectedResumePath.value = result.files.single.path!;
        selectedResumeName.value = result.files.single.name;
      }
    } catch (e) {
      debugPrint("FilePicker Error: $e");
      Get.snackbar('Error', 'Failed to pick file: $e', duration: const Duration(seconds: 5));
    }
  }

  // ─── Skip to Dashboard ────────────────────────────────────────────────────
  void skipToDashboard() async {
    // Call the review step API to mark onboarding_completed = 1
    // so it doesn't keep showing up on every login.
    isLoading.value = true;
    try {
      await saveStep('review', {'user_id': userId});
      try {
        final authController = Get.find<AuthController>();
        final updatedUser = Map<String, dynamic>.from(authController.currentUser);
        updatedUser['onboarding_completed'] = 1;
        authController.currentUser.value = updatedUser;
        await authController.saveUserSession(updatedUser);
      } catch (e) {
        // ignore
      }
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  // ─── Mandatory field validation for the Personal step ────────────────────
  bool validatePersonalStep() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Full Name is required to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Phone number is required to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  Future<void> nextStep() async {
    // Personal step is mandatory — block if invalid
    if (currentStep.value == 0 && !validatePersonalStep()) return;

    isLoading.value = true;
    bool success = false;

    // We do API call to save current step
    switch (currentStep.value) {
      case 0:
        success = await saveStep('personal', {
          'user_id': userId,
          'name': nameController.text,
          'phone': phoneController.text,
          'location': locationController.text,
          'bio': bioController.text,
          'gender': gender.value,
          'date_of_birth': dateOfBirthController.text,
        });
        break;
      case 1:
        // Resume is optional — skip saving if nothing selected
        if (selectedResumePath.value.isEmpty) {
          isLoading.value = false;
          currentStep.value++;
          return;
        }
        success = await uploadResume();
        break;
      case 2:
        // Skills optional — save if provided, always continue
        if (skillsController.text.trim().isNotEmpty) {
          await saveStep('skills', {
            'user_id': userId,
            'skills': skillsController.text,
          });
        }
        success = true;
        break;
      case 3:
        // Education optional
        List<Map<String, dynamic>> eduList = [];
        for (var e in educations) {
          if (e['degree'].text.isNotEmpty) {
            eduList.add({
              'degree': e['degree'].text,
              'field_of_study': e['field_of_study'].text,
              'institution': e['institution'].text,
              'start_year': e['start_year'].text,
              'end_year': e['end_year'].text,
              'grade': e['grade'].text,
            });
          }
        }
        if (eduList.isNotEmpty) {
          await saveStep('education', {'user_id': userId, 'educations': eduList});
        }
        success = true;
        break;
      case 4:
        // Experience optional
        List<Map<String, dynamic>> expList = [];
        for (var e in experiences) {
          if (e['job_title'].text.isNotEmpty) {
            expList.add({
              'job_title': e['job_title'].text,
              'company_name': e['company_name'].text,
              'employment_type': e['employment_type'],
              'location': e['location'].text,
              'start_date': e['start_date'].text,
              'end_date': e['end_date'].text,
              'is_current': e['is_current'],
              'description': e['description'].text,
            });
          }
        }
        if (isFresher.value || expList.isNotEmpty) {
          await saveStep('experience', {
            'user_id': userId,
            'is_fresher': isFresher.value,
            'experiences': expList,
          });
        }
        success = true;
        break;
      case 5:
        // Preferences optional
        await saveStep('preferences', {
          'user_id': userId,
          'resume_headline': resumeHeadlineController.text,
          'preferred_job_titles': preferredJobTitlesController.text,
          'preferred_locations': preferredLocationsController.text,
          'preferred_employment_type': preferredEmploymentType.value,
          'notice_period': noticePeriod.value,
          'expected_salary': expectedSalaryController.text,
        });
        success = true;
        break;
      case 6: // Review — complete onboarding
        success = await saveStep('review', {'user_id': userId});
        if (success) {
          try {
            final authController = Get.find<AuthController>();
            final updatedUser = Map<String, dynamic>.from(authController.currentUser);
            updatedUser['onboarding_completed'] = 1;
            authController.currentUser.value = updatedUser;
            await authController.saveUserSession(updatedUser);
          } catch (e) {
            // ignore
          }
          isLoading.value = false;
          Get.snackbar(
            'Success',
            'Onboarding Complete! Welcome to HireMatrix 🎉',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.offAllNamed(AppRoutes.dashboard);
          return;
        }
        // Even if server fails, let them in
        try {
          final authController = Get.find<AuthController>();
          final updatedUser = Map<String, dynamic>.from(authController.currentUser);
          updatedUser['onboarding_completed'] = 1;
          authController.currentUser.value = updatedUser;
          await authController.saveUserSession(updatedUser);
        } catch (e) {
          // ignore
        }
        isLoading.value = false;
        Get.offAllNamed(AppRoutes.dashboard);
        return;
    }

    isLoading.value = false;

    if (success && currentStep.value < 6) {
      currentStep.value++;
    } else if (!success && currentStep.value == 0) {
      // Only block on personal step failure
      Get.snackbar(
        'Error',
        'Failed to save personal details. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<bool> saveStep(String stepName, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/$stepName'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadResume() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/onboarding/resume'));
      request.fields['user_id'] = userId.toString();
      
      if (selectedResumePath.value.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('resume', selectedResumePath.value));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final res = jsonDecode(responseData);
        return res['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
