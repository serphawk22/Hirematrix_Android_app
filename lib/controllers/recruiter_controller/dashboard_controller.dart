import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/recruiter.dart';
import 'auth_controller.dart';

class DashboardController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _dashboardData = <String, dynamic>{};
  List<dynamic> _upcomingInterviews = [];
  List<dynamic> _recruiterActivity = [];
  List<dynamic> _notifications = [];
  List<dynamic> _applications = [];
  Map<String, dynamic> _conversionMetrics = {};
  bool _isLoading = true;
  int _notificationCount = 0;

  Map<String, dynamic> get dashboardData => _dashboardData;
  List<dynamic> get upcomingInterviews => _upcomingInterviews;
  List<dynamic> get recruiterActivity => _recruiterActivity;
  List<dynamic> get notifications => _notifications;
  List<dynamic> get applications => _applications;
  Map<String, dynamic> get conversionMetrics => _conversionMetrics;
  bool get isLoading => _isLoading;
  int get notificationCount => _notificationCount;

  Future<void> fetchDashboard(String recruiterId,
      {AuthController? auth}) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("--- DASHBOARD BACKEND SYNC INITIATED ---");
      debugPrint("current recruiter_id: $recruiterId");

      // 1. Parallel fetch from real SQL-backed endpoints
      final results = await Future.wait([
        _apiService.fetchDashboard(recruiterId).catchError((e) {
          debugPrint("fetchDashboard failed: $e");
          return <String, dynamic>{'success': false, 'error': e.toString()};
        }),
        _apiService.fetchInterviews(recruiterId).catchError((e) {
          debugPrint("fetchInterviews failed: $e");
          return <dynamic>[];
        }),
        _apiService.fetchActivity(recruiterId).catchError((e) {
          debugPrint("fetchActivity failed: $e");
          return <dynamic>[];
        }),
        _apiService.fetchApplications(recruiterId).catchError((e) {
          debugPrint("fetchApplications failed: $e");
          return <dynamic>[];
        }),
        _apiService.fetchJobs(recruiterId).catchError((e) {
          debugPrint("fetchJobs failed: $e");
          return <dynamic>[];
        }),
        _apiService.fetchNotifications(recruiterId).catchError((e) {
          debugPrint("fetchNotifications failed: $e");
          return <dynamic>[];
        }),
      ]);

      final dashboardResponse = results[0] as Map;
      _upcomingInterviews = results[1] as List<dynamic>;
      _recruiterActivity = results[2] as List<dynamic>;
      final applications = results[3] as List<dynamic>;
      final jobs = results[4] as List<dynamic>;
      _notifications = results[5] as List<dynamic>;

      // Check for invalid session (e.g. database reset)
      if (dashboardResponse['success'] == false &&
          dashboardResponse['invalid_session'] == true) {
        throw Exception("SESSION_INVALID");
      }

      _dashboardData = Map<String, dynamic>.from(dashboardResponse);

      // Deep cast specific sub-maps to avoid type errors in UI
      if (_dashboardData['stats'] != null) {
        _dashboardData['stats'] =
            Map<String, dynamic>.from(_dashboardData['stats'] as Map);
      }
      if (_dashboardData['pipeline_stats'] != null) {
        _dashboardData['pipeline_stats'] =
            Map<String, dynamic>.from(_dashboardData['pipeline_stats'] as Map);
      }

      // Check for invalid session (e.g. database reset)
      if (dashboardResponse['success'] == false &&
          dashboardResponse['invalid_session'] == true) {
        throw Exception("SESSION_INVALID");
      }

      // Refresh recruiter info if returned in dashboard response (for verified status)
      if (auth != null && _dashboardData['recruiter'] != null) {
        final freshRecruiter = Recruiter.fromJson(
            _dashboardData['recruiter'] as Map<String, dynamic>);
        auth.updateRecruiterInfo(freshRecruiter);
      }

      // 2. Initialize and Compute Pipeline Stats (Direct SQL Reflection)
      Map<String, int> pipelineStats = {
        'Applied': 0,
        'Screening': 0,
        'Shortlisted': 0,
        'Interview': 0,
        'Offer': 0,
        'Hired': 0,
        'Rejected': 0,
        'Withdrawn': 0,
      };

      for (var app in applications) {
        String status = (app['status'] ?? '').toString().trim();
        if (pipelineStats.containsKey(status)) {
          pipelineStats[status] = pipelineStats[status]! + 1;
        } else {
          // Flexible matching for different status naming if any
          bool matched = false;
          for (var key in pipelineStats.keys) {
            if (key.toLowerCase() == status.toLowerCase()) {
              pipelineStats[key] = pipelineStats[key]! + 1;
              matched = true;
              break;
            }
          }
          if (!matched) {
            debugPrint("Unmapped application status: $status");
          }
        }
      }

      // DEBUG REQUIREMENT: Console logs for verification
      debugPrint("--- DATABASE PIPELINE REFLECTION ---");
      debugPrint("Applied Count: ${pipelineStats['Applied']}");
      debugPrint("Screening Count: ${pipelineStats['Screening']}");
      debugPrint("Shortlisted Count: ${pipelineStats['Shortlisted']}");
      debugPrint("Interview Count: ${pipelineStats['Interview']}");
      debugPrint("Hired Count: ${pipelineStats['Hired']}");
      debugPrint("Rejected Count: ${pipelineStats['Rejected']}");
      debugPrint("-------------------------------------");

      _dashboardData['pipeline_stats'] = pipelineStats;
      _applications = applications;

      // Helper function to extract normalized status keys (matching normalizeApplicationStatus in PHP backend)
      String getStatusKey(dynamic app) {
        if (app is! Map) return 'applied';
        if (app.containsKey('status_key') && app['status_key'] != null) {
          final sk = app['status_key'].toString().toLowerCase().trim();
          if (sk.isNotEmpty) return sk;
        }
        final status = (app['status'] ?? '').toString().toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
        if (status.isEmpty) return 'applied';
        if (status == 'interview' || status == 'interview_scheduled' || status == 'interview_slot_booked') {
          return 'interview_slot_booked';
        }
        if (status == 'offer' || status == 'offered' || status == 'selected') {
          return 'selected';
        }
        if (status == 'on_hold') {
          return 'hold';
        }
        return status;
      }

      // Calculate Conversion Metrics exactly matching DashboardController.php (web)
      int total = applications.length;
      int screenedCount = applications.where((app) {
        final key = getStatusKey(app);
        return key == 'shortlisted' || key == 'rejected' || key == 'hold';
      }).length;

      int shortlistedCount = applications.where((app) {
        return getStatusKey(app) == 'shortlisted';
      }).length;

      int hrScheduledCount = applications.where((app) {
        return getStatusKey(app) == 'interview_slot_booked';
      }).length;

      int hrCompletedCount = applications.where((app) {
        return getStatusKey(app) == 'hr_interview_completed';
      }).length;

      int selectedCount = applications.where((app) {
        return getStatusKey(app) == 'selected';
      }).length;

      double safeRate(int numerator, int denominator) {
        if (denominator <= 0) return 0.0;
        return double.parse(((numerator / denominator) * 100).toStringAsFixed(1));
      }

      // If denominator is 0 for stages, rate should be null (matching PHP backend)
      _conversionMetrics = {
        'application_to_screening': total > 0 ? safeRate(screenedCount, total) : null,
        'screening_to_shortlist': screenedCount > 0 ? safeRate(shortlistedCount, screenedCount) : null,
        'shortlist_to_hr_interview': shortlistedCount > 0 ? safeRate(hrScheduledCount, shortlistedCount) : null,
        'hr_interview_to_selection': hrCompletedCount > 0 ? safeRate(selectedCount, hrCompletedCount) : null,
        'overall_conversion': safeRate(selectedCount, total),
      };

      // 3. Compute Operational Intelligence (Strict Prompt Logic)
      _dashboardData['stats'] ??= <String, dynamic>{};
      final stats = _dashboardData['stats'] as Map<String, dynamic>;

      // Align Conversion Rate quick stat with overall_conversion (website behavior)
      stats['conversion_rate'] = "${_conversionMetrics['overall_conversion'] ?? 0.0}%";

      // Active Roles → jobs.job_status='Active'
      stats['open_jobs'] ??= jobs.where((j) {
        final status = (j['job_status'] ?? '').toString().toLowerCase();
        return status == 'open' || status == 'active';
      }).length;

      // Need Review → applications.status='Screening'
      stats['need_review'] =
          (pipelineStats['Applied'] ?? 0) + (pipelineStats['Screening'] ?? 0);

      // Drop Rate → rejected/decisioned ratio
      int totalDecisioned = (pipelineStats['Interview'] ?? 0) +
          (pipelineStats['Hired'] ?? 0) +
          (pipelineStats['Rejected'] ?? 0);
      int rejectedCount = pipelineStats['Rejected'] ?? 0;
      double dropRate =
          totalDecisioned > 0 ? (rejectedCount / totalDecisioned) * 100 : 0.0;
      stats['drop_rate'] = "${dropRate.toStringAsFixed(1)}%";
      stats['drop_status'] =
          dropRate > 25 ? 'High Risk' : (dropRate > 15 ? 'Alert' : 'Low Risk');

      // Hiring Velocity → derive from apps + interviews + hires
      int hiredCount = (pipelineStats['Hired'] ?? 0);
      int totalCount = applications.length;
      double velocity = totalCount > 0 ? (hiredCount / totalCount) * 100 : 0.0;
      // Normalizing velocity for visualization if no hires yet but apps exist
      stats['hiring_velocity'] = "${velocity.toStringAsFixed(0)}%";
      stats['velocity_status'] = velocity > 70 ? 'Optimal' : 'Stable';

      // DEBUG: Analytics Values
      debugPrint("fetched jobs count: ${jobs.length}");
      debugPrint("fetched interviews count: ${_upcomingInterviews.length}");
      debugPrint("computed drop_rate: ${stats['drop_rate']}");
      debugPrint("computed hiring_velocity: ${stats['hiring_velocity']}");

      // 4. Notification Indicators
      _notificationCount = _notifications
          .where((n) => n['is_read'] == 0 || n['is_read'] == false)
          .length;
      debugPrint("unread notification count: $_notificationCount");

      // 5. Recent Hiring Insights (Dynamic Calculation)
      if (jobs.isNotEmpty) {
        var sortedJobs = List.from(jobs)
          ..sort((a, b) =>
              (int.tryParse(b['applications_count']?.toString() ?? '0') ?? 0)
                  .compareTo(int.tryParse(
                          a['applications_count']?.toString() ?? '0') ??
                      0));
        stats['top_role'] = sortedJobs.first['job_title'];
        stats['top_role_apps'] = sortedJobs.first['applications_count'];
      }

      debugPrint(
          "Recent Insights: Most active role is '${stats['top_role']}' with ${stats['top_role_apps']} applications.");

      debugPrint("--- DASHBOARD BACKEND SYNC SUCCESS ---");
    } catch (e, st) {
      debugPrint("--- DASHBOARD BACKEND SYNC FAILED ---");
      debugPrint("Error: $e");
      debugPrint(st.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String recruiterId) async {
    final response =
        await _apiService.markNotificationRead(notificationId, recruiterId);
    if (response['success'] == true) {
      // Optimistic update
      final index = _notifications
          .indexWhere((n) => n['id'].toString() == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _notificationCount = _notifications
            .where((n) => n['is_read'] == 0 || n['is_read'] == false)
            .length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead(String recruiterId) async {
    final response = await _apiService.markNotificationRead('all', recruiterId);
    if (response['success'] == true) {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      _notificationCount = 0;
      notifyListeners();
    }
  }

  Future<bool> rescheduleInterview(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.rescheduleInterview(data);
      if (response['success'] == true) {
        if (data['recruiter_id'] != null) {
          fetchDashboard(data['recruiter_id'].toString());
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  void refresh(String recruiterId) {
    fetchDashboard(recruiterId);
  }
}
