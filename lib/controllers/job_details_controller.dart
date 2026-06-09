import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:hirematrix/controllers/applications_controller.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/theme_controller.dart';

class JobDetailsController extends GetxController {
  final authController = Get.find<AuthController>();

  // Applied status
  final isCheckingApplied = false.obs;
  final hasApplied = false.obs;

  // ATS Analysis status
  final isRunningAts = false.obs;
  final atsScore = 0.obs;
  final atsKeywords = <String>[].obs;
  final atsSuggestions = <String>[].obs;
  final atsGap = ''.obs;
  final atsErrorMessage = RxnString();
  final atsResumeVersionTitle = RxnString();
  final atsMatchedSkills = <String>[].obs;
  final atsMissingSkills = <String>[].obs;
  final atsSummarySuggestion = ''.obs;

  // Company details
  final isLoadingCompany = false.obs;
  final companyInfo = Rxn<Map<String, dynamic>>();

  // Cover Letter details
  final isGeneratingCoverLetter = false.obs;
  final coverLetterContent = ''.obs;

  // Invitation details
  final isLoadingInvitation = false.obs;
  final invitationData = Rxn<Map<String, dynamic>>();

  // Questionnaire details
  final questionnaireList = <dynamic>[].obs;
  final questionControllers = <String, TextEditingController>{}.obs;

  @override
  void onClose() {
    for (var controller in questionControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  void decodeQuestionnaire(dynamic rawQ) {
    if (rawQ != null && rawQ.toString().trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawQ.toString());
        if (decoded is List) {
          questionnaireList.assignAll(decoded);
          questionControllers.clear();
          for (var question in questionnaireList) {
            final id = question['id']?.toString();
            if (id != null) {
              questionControllers[id] = TextEditingController();
            }
          }
        }
      } catch (e) {
        debugPrint('Error decoding questionnaire: $e');
      }
    }
  }

  Future<void> fetchJobInvitation(dynamic jobId) async {
    final userId = authController.currentUser['id'];
    final jobIdStr = jobId?.toString() ?? '';
    if (userId == null || jobIdStr.isEmpty) return;

    isLoadingInvitation.value = true;
    try {
      final url = '${ApiConstants.baseUrl}/jobs/invitation?candidate_id=$userId&job_id=$jobIdStr';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          invitationData.value = Map<String, dynamic>.from(data['data']);
        } else {
          invitationData.value = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching job invitation: $e');
    } finally {
      isLoadingInvitation.value = false;
    }
  }

  Future<void> checkAppliedStatus(dynamic jobId) async {
    final userId = authController.currentUser['id'];
    if (userId == null) return;

    isCheckingApplied.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/applications/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final apps = data['data'] as List;
          final jobIdStr = jobId?.toString() ?? '';

          final alreadyApplied = apps.any(
            (app) =>
                app['job_id']?.toString() == jobIdStr &&
                app['status']?.toString() != 'withdrawn',
          );

          hasApplied.value = alreadyApplied;
        }
      }
    } catch (e) {
      debugPrint('Error checking applied status: $e');
    } finally {
      isCheckingApplied.value = false;
    }
  }

  Future<void> runAtsAnalysisOnLoad(dynamic jobId) async {
    final userId = authController.currentUser['id'];
    if (userId == null || jobId == null) return;

    isRunningAts.value = true;
    atsErrorMessage.value = null;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/jobs/analyze-ats-match?candidate_id=$userId&job_id=$jobId',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          atsScore.value = (data['score'] as num?)?.toInt() ?? 0;
          atsKeywords.assignAll(List<String>.from(
            data['missing_skills'] ?? data['keywords'] ?? [],
          ));
          atsSuggestions.assignAll(List<String>.from(data['suggestions'] ?? []));
          atsGap.value = data['gap']?.toString() ?? '';
          atsResumeVersionTitle.value = data['resume_version_title']?.toString();
          atsMatchedSkills.assignAll(List<String>.from(data['matched_skills'] ?? []));
          atsMissingSkills.assignAll(List<String>.from(data['missing_skills'] ?? []));
          atsSummarySuggestion.value = data['summary_suggestion']?.toString() ?? '';
        }
      } else {
        final data = jsonDecode(response.body);
        atsErrorMessage.value = data['messages']?['error'] ??
            data['message'] ??
            'Unable to run ATS Match. Complete your profile first.';
      }
    } catch (e) {
      atsErrorMessage.value = 'Connection error. Check your internet connection.';
    } finally {
      isRunningAts.value = false;
    }
  }

  Future<void> fetchCompanyDetails(dynamic companyId) async {
    if (companyId == null) return;

    isLoadingCompany.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/company/$companyId'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          companyInfo.value = data['company'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching company details: $e');
    } finally {
      isLoadingCompany.value = false;
    }
  }

  Future<void> handleApply({
    required dynamic jobId,
    required GlobalKey<FormState> formKey,
    required BuildContext context,
  }) async {
    if (formKey.currentState != null && !formKey.currentState!.validate()) {
      return;
    }

    final userId = authController.currentUser['id'];
    if (userId == null || jobId == null) return;

    // Build questionnaire responses
    final Map<String, String> responses = {};
    questionControllers.forEach((key, controller) {
      responses[key] = controller.text;
    });

    final themeController = Get.find<ThemeController>();

    Get.showOverlay(
      asyncFunction: () async {
        try {
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}/jobs/apply/$jobId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'candidate_id': userId,
              'questionnaire_responses': responses,
            }),
          );

          final data = jsonDecode(response.body);
          if (response.statusCode == 200) {
            hasApplied.value = true;
            Get.snackbar(
              'Success',
              data['message'] ?? 'Application submitted successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF10B981),
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
            
            // Also refresh applications controller to show newly applied job
            try {
              final appsController = Get.find<ApplicationsController>();
              await appsController.fetchApplications();
            } catch (_) {}
          } else {
            Get.defaultDialog(
              title: 'Application Error',
              middleText: data['messages']?['error'] ??
                  data['message'] ??
                  'Failed to submit application.',
              textConfirm: 'OK',
              confirmTextColor: Colors.white,
              buttonColor: AppColors.getPrimary(themeController.isDarkMode),
              onConfirm: () => Get.back(),
            );
          }
        } catch (e) {
          Get.snackbar(
            'Connection Error',
            'Could not submit application. Please check your network.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      },
      loadingWidget: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeController.isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> generateCoverLetter({
    required dynamic jobId,
    required String jobTitle,
    required String companyName,
    required Function(String title, String company) showModal,
  }) async {
    final userId = authController.currentUser['id'];
    if (userId == null || jobId == null) return;

    isGeneratingCoverLetter.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/jobs/generate-ai-cover-letter?candidate_id=$userId&job_id=$jobId',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          coverLetterContent.value = data['cover_letter'] ?? '';
          showModal(jobTitle, companyName);
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'AI Error',
          data['message'] ?? 'Failed to generate cover letter. Ensure your profile has details.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Connection Error',
        'Could not contact AI generator. Check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isGeneratingCoverLetter.value = false;
    }
  }
}
