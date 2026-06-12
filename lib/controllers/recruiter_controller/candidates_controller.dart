import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/candidate.dart';

class CandidatesController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Candidate> _candidates = [];
  List<Candidate> _aiSuggestions = [];
  List<dynamic> _recruiterJobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Candidate> get candidates => _candidates;
  List<Candidate> get aiSuggestions => _aiSuggestions;
  List<dynamic> get recruiterJobs => _recruiterJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCandidates(
    String recruiterId, {
    String? keyword,
    String? skills,
    String? location,
    String? expMin,
    String? expMax,
    String? resume,
    String? jobId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = await _apiService.fetchCandidates(
        recruiterId,
        keyword: keyword,
        skills: skills,
        location: location,
        expMin: expMin,
        expMax: expMax,
        resume: resume,
        jobId: jobId,
      );

      final List<dynamic> candJsonList = data['candidates'] ?? [];
      _candidates = candJsonList.map((json) => Candidate.fromJson(json)).toList();

      final List<dynamic> suggJsonList = data['ai_suggestions'] ?? [];
      _aiSuggestions = suggJsonList.map((json) => Candidate.fromJson(json)).toList();

      _recruiterJobs = data['recruiter_jobs'] ?? [];
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching candidate database: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> inviteCandidate({
    required String recruiterId,
    required String candidateId,
    required String jobId,
    String? message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.inviteCandidate(
        recruiterId,
        candidateId,
        jobId,
        message,
      );
      if (response['success'] == true) {
        return true;
      }
      _errorMessage = response['message']?.toString() ?? 'Failed to send invitation.';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
