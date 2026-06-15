import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// [ApiService] manages all network communication for the recruiter application.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _cachedBaseUrl;
  Future<String>? _baseUrlFuture;

  /// Retrieves the base URL, testing connectivity to dev endpoints if not cached.
  Future<String> getBaseUrl() {
    if (_cachedBaseUrl != null) {
      return Future.value(_cachedBaseUrl);
    }
    if (_baseUrlFuture != null) {
      return _baseUrlFuture!;
    }
    
    _baseUrlFuture = _determineBaseUrl();
    return _baseUrlFuture!;
  }

  Future<String> _determineBaseUrl() async {
    // 1. Try to read from SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBaseUrl = prefs.getString('cached_api_base_url');
      if (savedBaseUrl != null) {
        final uri = Uri.parse(savedBaseUrl);
        // Test if the saved base URL still works (fast probe)
        if (await _testConnection(uri.host)) {
          _cachedBaseUrl = savedBaseUrl;
          _baseUrlFuture = null;
          return _cachedBaseUrl!;
        }
      }
    } catch (e) {
      debugPrint("Error reading cached base URL: $e");
    }

    // List of possible IPs to try (Priority: Emulator > PC LAN)
    final List<String> ips = [
      ApiConstants.emulatorIp, // 10.0.2.2
      ApiConstants.pcIp, // 10.25.155.26
    ];

    for (String ip in ips) {
      debugPrint("Testing connection to $ip...");
      if (await _testConnection(ip)) {
        _cachedBaseUrl = "http://$ip/${ApiConstants.apiBaseFolder}";
        debugPrint("Successfully connected via: $_cachedBaseUrl");
        // Save to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_api_base_url', _cachedBaseUrl!);
        } catch (e) {
          debugPrint("Failed to save base URL cache: $e");
        }
        _baseUrlFuture = null;
        return _cachedBaseUrl!;
      }
    }

    // Default fallback to PC IP if all tests fail (Better for physical devices)
    _cachedBaseUrl =
        "http://${ApiConstants.pcIp}/${ApiConstants.apiBaseFolder}";
    debugPrint("All tests failed, using fallback PC IP: $_cachedBaseUrl");
    _baseUrlFuture = null;
    return _cachedBaseUrl!;
  }

  /// Returns absolute URL for assets/images
  Future<String> getImageUrl(String? path) async {
    if (path == null || path.isEmpty) return '';
    
    var resolvedPath = path.trim();
    final baseUrl = await getBaseUrl();
    
    // Extract authority from baseUrl to replace localhost/127.0.0.1
    String targetAuthority = 'localhost';
    try {
      final uri = Uri.parse(baseUrl);
      targetAuthority = uri.authority;
    } catch (_) {}

    if (resolvedPath.contains('localhost')) {
      resolvedPath = resolvedPath.replaceAll('localhost', targetAuthority);
    } else if (resolvedPath.contains('127.0.0.1')) {
      resolvedPath = resolvedPath.replaceAll('127.0.0.1', targetAuthority);
    }

    if (resolvedPath.startsWith('http://') || resolvedPath.startsWith('https://')) {
      return resolvedPath;
    }

    // CI4 public folder pathing
    final publicUrl = baseUrl.split('api/mobile').first;
    return '$publicUrl$resolvedPath';
  }

  /// Internal health check for the API server.
  Future<bool> _testConnection(String ip) async {
    try {
      debugPrint("Probing http://$ip...");
      // Just hit the public folder. If Apache responds, it's alive.
      final response = await http
          .get(Uri.parse("http://$ip/ai-job-portal/public/index.php"))
          .timeout(const Duration(seconds: 4));

      return response.statusCode < 500;
    } catch (e) {
      debugPrint("Probe to $ip failed: $e");
      return false;
    }
  }

  // --- Auth Methods ---

  Future<Map<String, dynamic>> login(String email, String password,
      {bool rememberMe = true}) async {
    return _performPost(ApiConstants.login, {
      'email': email,
      'password': password,
      'remember_me': rememberMe.toString()
    });
  }

  Future<Map<String, dynamic>> validateSession(
      String token, String recruiterId) async {
    return _performPost(ApiConstants.session, {
      'token': token,
      'recruiter_id': recruiterId,
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _performPost(ApiConstants.forgotPassword, {'email': email});
  }

  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    return _performPost(
        ApiConstants.resetPassword, {'token': token, 'password': newPassword});
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    return _performPost(ApiConstants.resendVerification, {'email': email});
  }

  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _performPost("change-password", {
      'user_id': userId,
      'current_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  Future<Map<String, dynamic>> sendSupportMessage(
      String recruiterId, String message,
      {String? sessionId}) async {
    final body = {
      'recruiter_id': recruiterId,
      'message': message,
    };
    if (sessionId != null && sessionId.isNotEmpty) {
      body['session_id'] = sessionId;
    }
    return _performPost(ApiConstants.supportChat, body);
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String companyName,
    required String email,
    required String phone,
    required String password,
    String? companyWebsite,
    String? companyLocation,
    String? designation,
    String? linkedinProfile,
    String? inviteToken,
  }) async {
    return _performPost(ApiConstants.signup, {
      'full_name': fullName,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'password': password,
      'company_website': companyWebsite ?? '',
      'company_location': companyLocation ?? '',
      'designation': designation ?? '',
      'linkedin_profile': linkedinProfile ?? '',
      'invite_token': inviteToken ?? '',
    });
  }

  // --- Recruiter Features ---

  Future<Map<String, dynamic>> fetchDashboard(String recruiterId) async {
    return _performGet(ApiConstants.dashboard, {'recruiter_id': recruiterId});
  }

  Future<List<dynamic>> fetchInterviews(String recruiterId) async {
    final data = await _performGet(
        ApiConstants.interviews, {'recruiter_id': recruiterId});
    if (data['success'] == true && data['interviews'] != null) {
      return data['interviews'];
    }
    throw ApiException(
        data['message']?.toString() ?? 'Unable to load interviews');
  }

  Future<List<dynamic>> fetchApplications(String recruiterId,
      {String? jobId, String? query}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null) params['job_id'] = jobId;
    if (query != null) params['q'] = query;

    final data = await _performGet(ApiConstants.applications, params);
    if (data['success'] == true && data['applications'] != null) {
      return data['applications'];
    }
    throw ApiException(
        data['message']?.toString() ?? 'Unable to load applications');
  }

  Future<Map<String, dynamic>> fetchCandidates(String recruiterId, {
    String? keyword,
    String? skills,
    String? location,
    String? expMin,
    String? expMax,
    String? resume,
    String? jobId,
  }) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (skills != null && skills.isNotEmpty) params['skills'] = skills;
    if (location != null && location.isNotEmpty) params['location'] = location;
    if (expMin != null && expMin.isNotEmpty) params['exp_min'] = expMin;
    if (expMax != null && expMax.isNotEmpty) params['exp_max'] = expMax;
    if (resume != null && resume.isNotEmpty) params['resume'] = resume;
    if (jobId != null && jobId.isNotEmpty) params['job_id'] = jobId;

    final data = await _performGet(ApiConstants.candidates, params);
    if (data['success'] == true) {
      return data;
    }
    throw ApiException(
        data['message']?.toString() ?? 'Unable to load candidates');
  }

  Future<List<dynamic>> fetchJobs(String recruiterId, {String? query}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (query != null) params['q'] = query;
    
    final data = await _performGet(ApiConstants.jobs, params);
    if (data['success'] == true && data['jobs'] != null) {
      return data['jobs'];
    }
    throw ApiException(data['message']?.toString() ?? 'Unable to load jobs');
  }

  Future<Map<String, dynamic>> addJob(Map<String, dynamic> jobData) async {
    return _performPost("${ApiConstants.jobs}/add", jobData);
  }

  Future<Map<String, dynamic>> inviteCandidate(String recruiterId, String candidateId, String jobId, String? message) async {
    return _performPost(ApiConstants.inviteCandidate, {
      'recruiter_id': recruiterId,
      'candidate_id': candidateId,
      'job_id': jobId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<Map<String, dynamic>> fetchCandidateProfile(
      String recruiterId, String candidateId, {String? applicationId, String? jobId}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (applicationId != null && applicationId.isNotEmpty) params['application_id'] = applicationId;
    if (jobId != null && jobId.isNotEmpty) params['job_id'] = jobId;
    
    return _performGet("candidates/$candidateId", params);
  }

  Future<Map<String, dynamic>> logCandidateAction(
      String recruiterId, String candidateId, String action, {String? applicationId, String? jobId}) async {
    return _performPost("candidates/$candidateId/action", {
      'recruiter_id': recruiterId,
      'action': action,
      if (applicationId != null && applicationId.isNotEmpty) 'application_id': applicationId,
      if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
    });
  }

  Future<Map<String, dynamic>> sendCandidateMessage(
      String recruiterId, String candidateId, String message, {String? applicationId, String? jobId}) async {
    return _performPost("candidates/$candidateId/message", {
      'recruiter_id': recruiterId,
      'message': message,
      if (applicationId != null && applicationId.isNotEmpty) 'application_id': applicationId,
      if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
    });
  }

  Future<Map<String, dynamic>> saveCandidateNotes(
      String recruiterId, String candidateId, String tags, String notes) async {
    return _performPost("candidates/$candidateId/notes", {
      'recruiter_id': recruiterId,
      'tags': tags,
      'notes': notes,
    });
  }

  Future<List<dynamic>> fetchNotifications(String recruiterId) async {
    final data = await _performGet(
        ApiConstants.notifications, {'recruiter_id': recruiterId});
    if (data['success'] == true && data['notifications'] != null) {
      return data['notifications'];
    }
    throw ApiException(
        data['message']?.toString() ?? 'Unable to load notifications');
  }

  Future<Map<String, dynamic>> updateFcmToken(String recruiterId, String fcmToken) async {
    return _performPost("update_fcm_token", {
      'recruiter_id': recruiterId,
      'fcm_token': fcmToken,
    });
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return _performPost("${ApiConstants.profile}/update", data);
  }



  Future<Map<String, dynamic>> fetchCompanyProfile(String recruiterId) async {
    return _performGet(ApiConstants.company, {'recruiter_id': recruiterId});
  }

  Future<Map<String, dynamic>> updateCompanyProfile(
      Map<String, dynamic> data) async {
    return _performPost("${ApiConstants.company}/update", data);
  }

  Future<Map<String, dynamic>> fetchApplicationsWithStage(String recruiterId, {String? jobId, String? stage, String? query, Map<String, String>? filters}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null && jobId.isNotEmpty) params['job_id'] = jobId;
    if (stage != null && stage.isNotEmpty) params['stage'] = stage;
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (filters != null) {
      params.addAll(filters);
    }

    final data = await _performGet(ApiConstants.applications, params);
    if (data['success'] == true) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Unable to load applications');
  }

  Future<Map<String, dynamic>> fetchInterviewsForJob(String recruiterId, {String? jobId}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null && jobId.isNotEmpty) params['job_id'] = jobId;

    final data = await _performGet(ApiConstants.interviews, params);
    if (data['success'] == true) {
      return {
        'interviews': data['interviews'] ?? [],
        'slots': data['slots'] ?? [],
      };
    }
    throw ApiException(data['message']?.toString() ?? 'Unable to load interviews');
  }

  Future<Map<String, dynamic>> bulkUpdateStatus(String recruiterId, List<String> applicationIds, String status) async {
    return _performPost("applications/bulk_update_status", {
      'recruiter_id': recruiterId,
      'application_ids': applicationIds.join(','),
      'status': status,
    });
  }

  Future<Map<String, dynamic>> bulkSendEmail(String recruiterId, List<String> candidateIds, String subject, String body) async {
    return _performPost("applications/bulk_email", {
      'recruiter_id': recruiterId,
      'candidate_ids': candidateIds.join(','),
      'subject': subject,
      'body': body,
    });
  }

  Future<Map<String, dynamic>> bulkSendMessage(String recruiterId, List<String> candidateIds, String message, {String? applicationId, String? jobId}) async {
    return _performPost("applications/bulk_message", {
      'recruiter_id': recruiterId,
      'candidate_ids': candidateIds.join(','),
      'message': message,
      if (applicationId != null && applicationId.isNotEmpty) 'application_id': applicationId,
      if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
    });
  }

  // --- Network Helpers ---

  Future<Map<String, dynamic>> _performPost(
      String endpoint, Map<String, dynamic> body) async {
    String? url;
    try {
      url = await getBaseUrl();
      final fullUrl = '$url/$endpoint';
      debugPrint("POST Request to: $fullUrl");

      final response = await http
          .post(
            Uri.parse(fullUrl),
            body: body.map((k, v) => MapEntry(k, v.toString())),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on TimeoutException {
      return {
        "success": false,
        "message":
            "Connection timeout ($url). Ensure your PC and device are on the same WiFi and Port 80 is open."
      };
    } on http.ClientException catch (e) {
      return {
        "success": false,
        "message": "Network error: ${e.message}. Is the server running?"
      };
    } catch (e) {
      return {"success": false, "message": "Request failed: $e"};
    }
  }

  Future<Map<String, dynamic>> _performGet(
      String endpoint, Map<String, String> params) async {
    String? baseUrl;
    try {
      baseUrl = await getBaseUrl();
      final uri =
          Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params);
      debugPrint("GET Request to: $uri");

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on TimeoutException {
      return {"success": false, "message": "Connection timeout ($baseUrl)"};
    } catch (e) {
      return {"success": false, "message": "GET request failed: $e"};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final isSuccess =
            decoded['success'] == true || decoded['status'] == 'success';
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (decoded['success'] == null) decoded['success'] = isSuccess;
          return decoded;
        }

        final message = decoded['message'] ??
            decoded['error'] ??
            decoded['messages'] ??
            'Server error (${response.statusCode})';
        return {
          'success': false,
          'message': message.toString(),
          'status_code': response.statusCode,
        };
      }
      return {"success": false, "message": "Malformed response body"};
    } catch (e) {
      return {
        "success": false,
        "message": "Malformed response body (${response.statusCode})"
      };
    }
  }

  // Placeholder methods for missing legacy endpoints to prevent compilation errors
  Future<Map<String, dynamic>> updateJob(Map<String, dynamic> jobData) async =>
      {'success': false};
  Future<Map<String, dynamic>> deleteJob(
          String jobId, String recruiterId) async =>
      {'success': false};
  Future<Map<String, dynamic>> shortlistCandidate(
      String appId, String recruiterId) async {
    return updateApplicationStatus(appId, 'Shortlisted', recruiterId);
  }

  Future<Map<String, dynamic>> updateApplicationStatus(
      String appId, String status, String recruiterId) async {
    return _performPost("applications/update_status", {
      'application_id': appId,
      'status': status,
      'recruiter_id': recruiterId,
    });
  }

  Future<Map<String, dynamic>> scheduleInterview(
          Map<String, dynamic> interviewData) async =>
      {'success': false};

  Future<Map<String, dynamic>> rescheduleInterview(
      Map<String, dynamic> data) async {
    return _performPost("interviews/reschedule", data);
  }

  Future<Map<String, dynamic>> markNotificationRead(
      String notificationId, String recruiterId) async {
    return _performPost("notifications/mark_read", {
      'notification_id': notificationId,
      'recruiter_id': recruiterId,
    });
  }

  Future<Map<String, dynamic>> deleteNotification(
      String notificationId, String recruiterId) async {
    return _performPost("notifications/delete", {
      'notification_id': notificationId,
      'recruiter_id': recruiterId,
    });
  }


  Future<Map<String, dynamic>> fetchVerificationStatus(
          String recruiterId) async =>
      {'success': false};
  Future<Map<String, dynamic>> fetchVerificationDetails(
          String recruiterId) async =>
      {'success': false};
  Future<Map<String, dynamic>> submitVerification(
          Map<String, dynamic> data) async =>
      {'success': false};

  Future<Map<String, dynamic>> uploadCompanyImage(
      String filePath, String recruiterId,
      {String type = 'logo'}) async {
    try {
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl/company/upload_photo');
      final request = http.MultipartRequest('POST', uri);
      request.fields['recruiter_id'] = recruiterId;
      request.fields['type'] = type;
      final ext = filePath.split('.').last.toLowerCase();
      String mimeSubtype = 'jpeg';
      if (ext == 'png') mimeSubtype = 'png';
      if (ext == 'gif') mimeSubtype = 'gif';
      if (ext == 'webp') mimeSubtype = 'webp';
      
      request.files.add(await http.MultipartFile.fromPath(
        'photo', 
        filePath,
        contentType: MediaType('image', mimeSubtype),
      ));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Photo upload failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteCompanyImage(
      String recruiterId, String photoUrl) async {
    return _performPost('company/delete_photo', {
      'recruiter_id': recruiterId,
      'photo_url': photoUrl,
    });
  }

  Future<Map<String, dynamic>> uploadVerificationDocument(
          String filePath, String recruiterId) async =>
      {'success': false};
  Future<Map<String, dynamic>> fetchInterviewSlots(String recruiterId,
      {String? jobId, String? status}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null) params['job_id'] = jobId;
    if (status != null) params['status'] = status;
    return _performGet(ApiConstants.interviewSlots, params);
  }

  Future<Map<String, dynamic>> addInterviewSlot(
      Map<String, dynamic> slotData) async {
    return _performPost("${ApiConstants.interviewSlots}/add", slotData);
  }

  Future<Map<String, dynamic>> updateInterviewSlot(
      Map<String, dynamic> slotData) async {
    return _performPost("${ApiConstants.interviewSlots}/update", slotData);
  }

  Future<Map<String, dynamic>> deleteInterviewSlot(
      String slotId, String recruiterId) async {
    return _performPost("${ApiConstants.interviewSlots}/delete", {
      'slot_id': slotId,
      'recruiter_id': recruiterId,
    });
  }

  Future<Map<String, dynamic>> fetchInterviewBookings(String recruiterId,
      {String? jobId, String? status}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null) params['job_id'] = jobId;
    if (status != null) params['status'] = status;
    return _performGet(ApiConstants.interviewBookings, params);
  }

  Future<List<dynamic>> fetchActivity(String recruiterId) async {
    try {
      final data = await _performGet("activity", {'recruiter_id': recruiterId});
      if (data['success'] == true && data['activity'] != null) {
        return data['activity'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchJobsOverview(String recruiterId) async =>
      {'success': false};

  Future<Map<String, dynamic>> fetchLeaderboard(String recruiterId,
      {String? jobId, String? skill, String? sortBy}) async {
    final Map<String, String> params = {'recruiter_id': recruiterId};
    if (jobId != null && jobId.isNotEmpty) params['job_id'] = jobId;
    if (skill != null && skill.isNotEmpty) params['skill'] = skill;
    if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;

    final data = await _performGet(ApiConstants.leaderboard, params);
    if (data['success'] == true) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Unable to load candidate insights');
  }
}
