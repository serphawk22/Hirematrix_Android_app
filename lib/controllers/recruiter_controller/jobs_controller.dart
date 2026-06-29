import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/job.dart';

class JobsController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Job> _jobs = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  Future<void> fetchJobs(String recruiterId, {String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.fetchJobs(recruiterId, query: query);
      _jobs = data.map((json) => Job.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateJob(Map<String, dynamic> jobData, String recruiterId) async {
    try {
      final response = await _apiService.updateJob(jobData);
      if (response['success'] == true) {
        fetchJobs(recruiterId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteJob(String jobId, String recruiterId) async {
    try {
      final response = await _apiService.deleteJob(jobId, recruiterId);
      if (response['success'] == true) {
        fetchJobs(recruiterId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateJobStatus(
      String jobId, String recruiterId, String status) async {
    try {
      final response =
          await _apiService.updateJobStatus(jobId, recruiterId, status);
      if (response['success'] == true) {
        await fetchJobs(recruiterId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void refreshJobs(String recruiterId) {
    fetchJobs(recruiterId);
  }
}
