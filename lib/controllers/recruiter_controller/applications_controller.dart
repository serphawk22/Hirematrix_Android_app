import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/application.dart';

class ApplicationsController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Application> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchApplications(String recruiterId, {String? jobId, String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> data =
          await _apiService.fetchApplications(recruiterId, jobId: jobId, query: query);
      _applications = data.map((json) => Application.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching applications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> shortlist(String appId, String recruiterId) async {
    try {
      final response = await _apiService.shortlistCandidate(appId, recruiterId);
      if (response['success'] == true) {
        await fetchApplications(recruiterId);
        return true;
      }
    } catch (e) {
      debugPrint("Shortlist error: $e");
    }
    return false;
  }

  Future<bool> updateStatus(
      String appId, String status, String recruiterId) async {
    try {
      final response =
          await _apiService.updateApplicationStatus(appId, status, recruiterId);
      if (response['success'] == true) {
        await fetchApplications(recruiterId);
        return true;
      }
      _errorMessage = response['message']?.toString() ??
          'Failed to update application status';
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint("Update status error: $e");
    }
    return false;
  }
}
