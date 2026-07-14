import 'package:flutter/material.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/resdex_api_service.dart';

class ResdexController extends ChangeNotifier {
  final ResdexApiService _apiService = ResdexApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _searchResults = [];
  List<dynamic> get searchResults => _searchResults;
  
  Map<String, dynamic> _searchFilters = {};
  Map<String, dynamic> get searchFilters => _searchFilters;
  
  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  List<dynamic> _folders = [];
  List<dynamic> get folders => _folders;

  List<dynamic> _savedSearches = [];
  List<dynamic> get savedSearches => _savedSearches;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> performSearch(String recruiterId, Map<String, String> filters) async {
    _setLoading(true);
    try {
      final response = await _apiService.search(recruiterId, filters);
      if (response['success'] == true) {
        _searchResults = response['results']?['results'] ?? [];
        _searchFilters = response['filters'] ?? {};
        _hasSearched = response['hasSearched'] ?? false;
        return true;
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> fetchFolders(String recruiterId) async {
    _setLoading(true);
    try {
      final response = await _apiService.getFolders(recruiterId);
      if (response['success'] == true) {
        _folders = response['folders'] ?? [];
      }
      return response;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> createFolder(String recruiterId, String name) async {
    final response = await _apiService.createFolder(recruiterId, name);
    if (response['success'] == true) {
      await fetchFolders(recruiterId);
    }
    return response;
  }

  Future<Map<String, dynamic>> deleteFolders(String recruiterId, List<int> folderIds) async {
    final response = await _apiService.deleteFolders(recruiterId, folderIds);
    if (response['success'] == true) {
      _folders.removeWhere((f) => folderIds.contains(int.parse(f['id'].toString())));
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> getFolderDetails(String recruiterId, int folderId) async {
    return await _apiService.getFolderDetails(recruiterId, folderId);
  }

  Future<Map<String, dynamic>> addToFolder(String recruiterId, int candidateId, int folderId, String newFolderName) async {
    final response = await _apiService.addToFolder(recruiterId, candidateId, folderId, newFolderName);
    if (response['success'] == true && newFolderName.isNotEmpty) {
      await fetchFolders(recruiterId);
    } else if (response['success'] == true) {
      final folderIndex = _folders.indexWhere((f) => f['id'].toString() == folderId.toString());
      if (folderIndex != -1) {
        _folders[folderIndex]['candidate_count'] = (_folders[folderIndex]['candidate_count'] ?? 0) + 1;
        notifyListeners();
      }
    }
    return response;
  }
  
  Future<Map<String, dynamic>> bulkAddToFolder(String recruiterId, List<int> candidateIds, int folderId) async {
    final response = await _apiService.bulkAddToFolder(recruiterId, candidateIds, folderId);
    if (response['success'] == true) {
      final folderIndex = _folders.indexWhere((f) => f['id'].toString() == folderId.toString());
      if (folderIndex != -1) {
        _folders[folderIndex]['candidate_count'] = (_folders[folderIndex]['candidate_count'] ?? 0) + candidateIds.length;
        notifyListeners();
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> removeFromFolder(String recruiterId, int folderId, List<int> candidateIds) async {
    final response = await _apiService.removeFromFolder(recruiterId, folderId, candidateIds);
    if (response['success'] == true) {
      final folderIndex = _folders.indexWhere((f) => f['id'].toString() == folderId.toString());
      if (folderIndex != -1) {
        int newCount = (_folders[folderIndex]['candidate_count'] ?? 0) - candidateIds.length;
        _folders[folderIndex]['candidate_count'] = newCount < 0 ? 0 : newCount;
        notifyListeners();
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> fetchSearches(String recruiterId, String tab) async {
    _setLoading(true);
    try {
      final response = await _apiService.getSearches(recruiterId, tab);
      if (response['success'] == true) {
        _savedSearches = response['searches'] ?? [];
      }
      return response;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> toggleSaveSearch(String recruiterId, int candidateId, String candidateName, Map<String, String> filters) async {
    final response = await _apiService.saveSearch(recruiterId, candidateId, candidateName, filters);
    if (response['success'] == true) {
      final candIndex = _searchResults.indexWhere((c) => c['user_id'].toString() == candidateId.toString());
      if (candIndex != -1) {
        _searchResults[candIndex]['is_search_saved'] = (response['is_saved'] == true) ? '1' : '0';
        notifyListeners();
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> deleteSearches(String recruiterId, List<int> searchIds) async {
    final response = await _apiService.deleteSearches(recruiterId, searchIds);
    if (response['success'] == true) {
      _savedSearches.removeWhere((s) => searchIds.contains(int.parse(s['id'].toString())));
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> getCandidate(String recruiterId, int candidateId) async {
    return await _apiService.getCandidate(recruiterId, candidateId);
  }
}
