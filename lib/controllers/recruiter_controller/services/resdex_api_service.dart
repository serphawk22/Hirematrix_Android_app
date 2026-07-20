import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';

class ResdexApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> search(
    String recruiterId,
    Map<String, String> filters,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/${ApiConstants.resdexSearch}',
      ).replace(queryParameters: {'recruiter_id': recruiterId, ...filters});

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCandidate(
    String recruiterId,
    int candidateId,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/${ApiConstants.resdexCandidate}/$candidateId',
      ).replace(queryParameters: {'recruiter_id': recruiterId});

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getFolders(String recruiterId) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/${ApiConstants.resdexFolders}',
      ).replace(queryParameters: {'recruiter_id': recruiterId});

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createFolder(
    String recruiterId,
    String folderName,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexCreateFolder}'),
        body: {'recruiter_id': recruiterId, 'folder_name': folderName},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteFolders(
    String recruiterId,
    List<int> folderIds,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexDeleteFolders}'),
        body: {'recruiter_id': recruiterId, 'folder_ids': folderIds.join(',')},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getFolderDetails(
    String recruiterId,
    int folderId,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/${ApiConstants.resdexFolders}/$folderId',
      ).replace(queryParameters: {'recruiter_id': recruiterId});

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addToFolder(
    String recruiterId,
    int candidateId,
    int folderId,
    String newFolderName,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexAddToFolder}'),
        body: {
          'recruiter_id': recruiterId,
          'candidate_id': candidateId.toString(),
          'folder_id': folderId.toString(),
          'new_folder_name': newFolderName,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> bulkAddToFolder(
    String recruiterId,
    List<int> candidateIds,
    int folderId,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexBulkAddToFolder}'),
        body: {
          'recruiter_id': recruiterId,
          'candidate_ids': candidateIds.join(','),
          'folder_id': folderId.toString(),
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> removeFromFolder(
    String recruiterId,
    int folderId,
    List<int> candidateIds,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexRemoveFromFolder}'),
        body: {
          'recruiter_id': recruiterId,
          'folder_id': folderId.toString(),
          'candidate_ids': candidateIds.join(','),
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSearches(
    String recruiterId,
    String tab,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final uri = Uri.parse(
        '$baseUrl/${ApiConstants.resdexSearches}',
      ).replace(queryParameters: {'recruiter_id': recruiterId, 'tab': tab});

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveSearch(
    String recruiterId,
    int candidateId,
    String candidateName,
    Map<String, String> filters,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexSaveSearch}'),
        body: {
          'recruiter_id': recruiterId,
          'candidate_id': candidateId.toString(),
          'candidate_name': candidateName,
          ...filters,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSearches(
    String recruiterId,
    List<int> searchIds,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexDeleteSearches}'),
        body: {'recruiter_id': recruiterId, 'ids': searchIds.join(',')},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> bulkInviteCandidates(
    String recruiterId,
    List<int> candidateIds,
    int jobId,
    String message,
  ) async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConstants.resdexBulkInvite}'),
        body: {
          'recruiter_id': recruiterId,
          'candidate_ids': candidateIds.join(','),
          'job_id': jobId.toString(),
          'message': message,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {'success': true, 'data': data};
      } catch (e) {
        return {'success': false, 'message': 'Invalid response format'};
      }
    }

    try {
      final data = json.decode(response.body);
      return {
        'success': false,
        'message':
            data['message'] ?? data['messages']?['error'] ?? 'Server error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Server error (${response.statusCode})',
      };
    }
  }
}
