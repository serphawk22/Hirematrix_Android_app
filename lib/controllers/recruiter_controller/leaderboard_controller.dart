import 'package:flutter/material.dart';
import 'services/api_service.dart';

class LeaderboardController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _candidates = [];
  List<String> _skills = [];
  List<dynamic> _jobs = [];
  Map<String, dynamic> _metrics = {
    'avg_technical_score': 0.0,
    'avg_communication_score': 0.0,
    'avg_overall_rating': 0.0,
    'avg_ats_score': 0.0
  };

  bool _isLoading = false;
  String? _errorMessage;

  // Filters State
  String? _selectedJobId;
  String? _selectedSkill;
  String _sortBy = 'technical_score';

  // Getters
  List<dynamic> get candidates => _candidates;
  List<String> get skills => _skills;
  List<dynamic> get jobs => _jobs;
  Map<String, dynamic> get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedJobId => _selectedJobId;
  String? get selectedSkill => _selectedSkill;
  String get sortBy => _sortBy;

  // Setters with notifyListeners
  void setJobId(String? jobId) {
    _selectedJobId = jobId;
    notifyListeners();
  }

  void setSkill(String? skill) {
    _selectedSkill = skill;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _selectedJobId = null;
    _selectedSkill = null;
    _sortBy = 'technical_score';
    notifyListeners();
  }

  Future<void> fetchLeaderboardData(String recruiterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchLeaderboard(
        recruiterId,
        jobId: _selectedJobId,
        skill: _selectedSkill,
        sortBy: _sortBy,
      );

      if (response['success'] == true) {
        _candidates = response['candidates'] ?? [];
        _skills = List<String>.from(response['skills'] ?? []);
        _jobs = response['jobs'] ?? [];
        if (response['metrics'] != null) {
          _metrics = Map<String, dynamic>.from(response['metrics']);
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to load candidate insights';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching leaderboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
