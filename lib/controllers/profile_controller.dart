import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hirematrix/controllers/auth_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hirematrix/controllers/dashboard_controller.dart';

class ProfileController extends GetxController {
  final isLoading = false.obs;
  
  // Data
  final user = {}.obs;
  final github = {}.obs;
  final skills = {}.obs;
  final interests = [].obs;
  final workExperiences = [].obs;
  final educations = [].obs;
  final certifications = [].obs;
  final projects = [].obs;
  final stats = {}.obs;
  final completion = {}.obs;
  final totalExperienceMonths = 0.obs;

  int userId = 0;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments['user_id'] != null) {
      userId = Get.arguments['user_id'];
    } else {
      try {
        final authUser = Get.find<AuthController>().currentUser;
        if (authUser.isNotEmpty && authUser['id'] != null) {
          userId = int.tryParse(authUser['id'].toString()) ?? 0;
        }
      } catch (e) {
        // Fallback or ignore
      }
    }
    
    if (userId > 0) {
      fetchProfile();
    } else {
      Get.snackbar('Error', 'User ID not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final pData = data['data'];
          github.value = pData['github'] ?? {};
          skills.value = pData['skills'] ?? {};
          interests.assignAll(pData['interests'] ?? []);
          workExperiences.assignAll(pData['workExperiences'] ?? []);
          educations.assignAll(pData['education'] ?? []);
          certifications.assignAll(pData['certifications'] ?? []);
          projects.assignAll(pData['projects'] ?? []);
          stats.assignAll(pData['stats'] ?? {});
          completion.assignAll(pData['completion'] ?? {});
          totalExperienceMonths.value = pData['totalExperienceMonths'] ?? 0;
          user.assignAll(pData['user'] ?? {});

          // Sync updated user to AuthController and SharedPreferences
          try {
            final authController = Get.find<AuthController>();
            if (user.isNotEmpty) {
              final updatedUser = Map<String, dynamic>.from(authController.currentUser);
              user.forEach((key, val) {
                updatedUser[key] = val;
              });
              authController.currentUser.value = updatedUser;
              await authController.saveUserSession(updatedUser);
            }
          } catch (e) {
            // ignore
          }
          try {
            if (Get.isRegistered<DashboardController>()) {
              final dashController = Get.find<DashboardController>();
              final updatedDashUser = Map<String, dynamic>.from(dashController.userProfile);
              user.forEach((key, val) {
                updatedDashUser[key] = val;
              });
              dashController.userProfile.assignAll(updatedDashUser);
              dashController.profileStrength.value = int.tryParse(pData['profileStrength']?.toString() ?? '0') ?? 0;
            }
          } catch (e) {
            // ignore
          }
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch profile',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not connect to server',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSection(String endpoint, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      data['user_id'] = userId;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile/$endpoint'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          await fetchProfile();
          Get.snackbar('Success', resData['message'] ?? 'Updated successfully',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
          return true;
        } else {
          Get.snackbar('Error', resData['message'] ?? 'Update failed',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Server returned error ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e, s) {
      debugPrint('Update section error: $e');
      debugPrint(s.toString());
      Get.snackbar('Error', 'Could not connect to server: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<void> deleteItem(String endpoint, int id) async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile/$endpoint/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          await fetchProfile();
          Get.snackbar('Success', resData['message'] ?? 'Deleted successfully',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not connect to server',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadFile(String endpoint, String fileField, List<String> allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        isLoading.value = true;
        
        var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/profile/$endpoint'));
        request.fields['user_id'] = userId.toString();
        request.files.add(await http.MultipartFile.fromPath(fileField, result.files.single.path!));
        
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var resData = jsonDecode(responseData);
        
        if (response.statusCode == 200 && resData['status'] == 'success') {
          await fetchProfile();
          Get.snackbar('Success', resData['message'] ?? 'File uploaded successfully',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', resData['message'] ?? 'Upload failed',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Error uploading file: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePhoto() async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile/delete_photo'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          await fetchProfile();
          Get.snackbar('Success', resData['message'] ?? 'Photo deleted successfully',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', resData['message'] ?? 'Deletion failed',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Server returned error ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not connect to server',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void goToResumeStudio() {
    Get.toNamed('/candidate/resume-studio');
  }
}
