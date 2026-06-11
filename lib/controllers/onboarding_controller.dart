import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:file_picker/file_picker.dart';

class OnboardingController extends GetxController {
  final currentStep = 0.obs;
  final isLoading = false.obs;

  // Personal Step Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final gender = ''.obs;
  final dateOfBirthController = TextEditingController();
  final bioController = TextEditingController();

  // Resume Upload Fields
  final selectedResumeName = ''.obs;
  final selectedResumePath = ''.obs;

  // Skills
  final skillsController = TextEditingController();

  // Dynamic Lists
  final educations = <Map<String, dynamic>>[].obs;
  final experiences = <Map<String, dynamic>>[].obs;
  final isFresher = false.obs;

  int userId = 0;

  @override
  void onInit() {
    super.onInit();
    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser;
      if (currentUser.isNotEmpty && currentUser['id'] != null) {
        userId = int.tryParse(currentUser['id'].toString()) ?? 0;
        nameController.text = currentUser['name'] ?? '';
        phoneController.text = currentUser['phone'] ?? '';
      }
    } catch (e) {
      // Ignore if AuthController is not available
    }

    // Initialize with 1 default entry
    addEducation();
    addExperience();
  }

  // Dynamic Lists Helpers
  void addEducation() {
    final degree = TextEditingController();
    final fieldOfStudy = TextEditingController();
    final institution = TextEditingController();
    final startYear = TextEditingController();
    final endYear = TextEditingController();
    final grade = TextEditingController();

    final education = {
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'institution': institution,
      'start_year': startYear,
      'end_year': endYear,
      'grade': grade,
    };
    educations.add(education);
  }

  void removeEducation(int index) {
    educations.removeAt(index);
  }

  void addExperience() {
    final jobTitle = TextEditingController();
    final companyName = TextEditingController();
    final location = TextEditingController();
    final startDate = TextEditingController();
    final endDate = TextEditingController();
    final description = TextEditingController();

    final experience = {
      'job_title': jobTitle,
      'company_name': companyName,
      'employment_type': 'Full-time',
      'location': location,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': false,
      'description': description
    };
    experiences.add(experience);
  }

  void removeExperience(int index) {
    experiences.removeAt(index);
  }

  // Date Pickers
  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateOfBirthController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> selectExperienceDate(BuildContext context, TextEditingController controllerField) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controllerField.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // File Upload & AI Parse
  Future<void> uploadAndParseResume(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        isLoading.value = true;
        selectedResumeName.value = result.files.single.name;
        selectedResumePath.value = result.files.single.path!;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/onboarding/parse-resume'),
        );
        request.files.add(
          await http.MultipartFile.fromPath('resume', selectedResumePath.value),
        );

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var resData = jsonDecode(responseData);

        if (response.statusCode == 200 && resData['status'] == 'success') {
          final parsed = resData['data'];
          if (parsed != null) {
            // Fill Personal
            nameController.text = parsed['name'] ?? '';
            phoneController.text = parsed['phone'] ?? '';
            locationController.text = parsed['location'] ?? '';
            gender.value = parsed['gender'] ?? '';
            dateOfBirthController.text = parsed['date_of_birth'] ?? '';
            bioController.text = parsed['bio'] ?? '';

            // Fill Skills
            if (parsed['skills'] != null) {
              if (parsed['skills'] is List) {
                skillsController.text = (parsed['skills'] as List).join(', ');
              } else {
                skillsController.text = parsed['skills'].toString();
              }
            }

            // Fill Educations
            educations.clear();
            if (parsed['educations'] != null && parsed['educations'] is List) {
              for (var edu in parsed['educations']) {
                final degree = TextEditingController(text: edu['degree'] ?? '');
                final fieldOfStudy = TextEditingController(text: edu['field_of_study'] ?? '');
                final institution = TextEditingController(text: edu['institution'] ?? '');
                final startYear = TextEditingController(text: edu['start_year']?.toString() ?? '');
                final endYear = TextEditingController(text: edu['end_year']?.toString() ?? '');
                final grade = TextEditingController(text: edu['grade']?.toString() ?? '');

                educations.add({
                  'degree': degree,
                  'field_of_study': fieldOfStudy,
                  'institution': institution,
                  'start_year': startYear,
                  'end_year': endYear,
                  'grade': grade,
                });
              }
            }
            if (educations.isEmpty) {
              addEducation();
            }

            // Fill Experiences
            experiences.clear();
            if (parsed['experiences'] != null && parsed['experiences'] is List) {
              isFresher.value = false;
              for (var exp in parsed['experiences']) {
                final jobTitle = TextEditingController(text: exp['job_title'] ?? '');
                final companyName = TextEditingController(text: exp['company_name'] ?? '');
                final location = TextEditingController(text: exp['location'] ?? '');
                final startDate = TextEditingController(text: exp['start_date'] ?? '');
                final endDate = TextEditingController(text: exp['end_date'] ?? '');
                final description = TextEditingController(text: exp['description'] ?? '');
                final isCurrent = exp['is_current'] == true || exp['is_current'] == 1 || exp['is_current'] == '1';

                experiences.add({
                  'job_title': jobTitle,
                  'company_name': companyName,
                  'employment_type': exp['employment_type'] ?? 'Full-time',
                  'location': location,
                  'start_date': startDate,
                  'end_date': endDate,
                  'is_current': isCurrent,
                  'description': description,
                });
              }
            } else {
              isFresher.value = true;
            }
            if (experiences.isEmpty && !isFresher.value) {
              addExperience();
            }
          }
          Get.snackbar('Success', 'Resume parsed & populated successfully!',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', resData['message'] ?? 'Failed to parse resume',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Error uploading/parsing resume: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Stepper Logic
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> nextStep() async {
    if (isLoading.value) return;

    if (currentStep.value == 0) {
      // Validate Personal
      if (nameController.text.isEmpty ||
          phoneController.text.isEmpty ||
          locationController.text.isEmpty ||
          gender.value.isEmpty ||
          dateOfBirthController.text.isEmpty ||
          bioController.text.isEmpty) {
        Get.snackbar('Required Fields', 'Please complete all required fields.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      final success = await savePersonalDetails();
      if (success) currentStep.value++;
    } else if (currentStep.value == 1) {
      // Validate Skills
      if (skillsController.text.isEmpty) {
        Get.snackbar('Required Fields', 'Please enter at least one skill.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      final success = await saveSkills();
      if (success) currentStep.value++;
    } else if (currentStep.value == 2) {
      // Validate Education
      for (var edu in educations) {
        if (edu['degree']!.text.isEmpty ||
            edu['field_of_study']!.text.isEmpty ||
            edu['institution']!.text.isEmpty ||
            edu['start_year']!.text.isEmpty ||
            edu['end_year']!.text.isEmpty) {
          Get.snackbar('Required Fields', 'Please complete all education details.',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }
      }
      final success = await saveEducation();
      if (success) currentStep.value++;
    } else if (currentStep.value == 3) {
      // Validate Experience
      if (!isFresher.value) {
        for (var exp in experiences) {
          if (exp['job_title']!.text.isEmpty ||
              exp['company_name']!.text.isEmpty ||
              exp['start_date']!.text.isEmpty) {
            Get.snackbar('Required Fields', 'Please complete all work experience details.',
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
        }
      }
      final success = await saveExperience();
      if (success) currentStep.value++;
    } else if (currentStep.value == 4) {
      // Submit and Go to Dashboard
      final success = await completeOnboarding();
      if (success) {
        skipToDashboard();
      }
    }
  }

  // API Calls
  Future<bool> savePersonalDetails() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/save-step'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'step': 'personal',
          'name': nameController.text,
          'phone': phoneController.text,
          'location': locationController.text,
          'gender': gender.value,
          'date_of_birth': dateOfBirthController.text,
          'bio': bioController.text,
        }),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to save personal details',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> saveSkills() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/save-step'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'step': 'skills',
          'skills': skillsController.text,
        }),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to save skills',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> saveEducation() async {
    isLoading.value = true;
    try {
      final educationPayload = educations.map((edu) => {
        'degree': edu['degree']!.text,
        'field_of_study': edu['field_of_study']!.text,
        'institution': edu['institution']!.text,
        'start_year': edu['start_year']!.text,
        'end_year': edu['end_year']!.text,
        'grade': edu['grade']?.text ?? '',
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/save-step'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'step': 'education',
          'educations': educationPayload,
        }),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to save education',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> saveExperience() async {
    isLoading.value = true;
    try {
      final experiencePayload = isFresher.value ? [] : experiences.map((exp) => {
        'job_title': exp['job_title']!.text,
        'company_name': exp['company_name']!.text,
        'employment_type': exp['employment_type'],
        'location': exp['location']!.text,
        'start_date': exp['start_date']!.text,
        'end_date': exp['is_current'] == true ? '' : exp['end_date']!.text,
        'is_current': exp['is_current'] == true ? 1 : 0,
        'description': exp['description']!.text,
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/save-step'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'step': 'experience',
          'is_fresher': isFresher.value ? 1 : 0,
          'experiences': experiencePayload,
        }),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to save experience',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> completeOnboarding() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/onboarding/save-step'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'step': 'review',
        }),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        return true;
      } else {
        Get.snackbar('Error', res['message'] ?? 'Failed to complete onboarding',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection error: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  void skipToDashboard() {
    Get.offAllNamed('/candidate/dashboard');
  }
}
