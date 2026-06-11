import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'services/api_service.dart';
// PushNotificationService removed
import 'models/recruiter.dart';
import 'models/saved_account.dart';

class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  Recruiter? _currentRecruiter;
  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  Recruiter? get currentRecruiter => _currentRecruiter;
  List<SavedAccount> get savedAccounts => _savedAccounts;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  AuthController() {
    _loadSession();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final data = await _storage.read(key: 'saved_accounts');
      if (data != null) {
        final List decoded = json.decode(data);
        _savedAccounts = decoded.map((e) => SavedAccount.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading saved accounts: $e");
    }
  }

  Future<void> _addSavedAccount(Recruiter recruiter, String token) async {
    final index = _savedAccounts.indexWhere((element) => element.id == recruiter.id);
    final account = SavedAccount(
      id: recruiter.id,
      name: recruiter.fullName,
      email: recruiter.email,
      company: recruiter.companyName,
      profileImage: recruiter.profileImage,
      token: token,
    );

    if (index != -1) {
      _savedAccounts[index] = account;
    } else {
      _savedAccounts.add(account);
    }

    await _storage.write(key: 'saved_accounts', value: json.encode(_savedAccounts.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> removeSavedAccount(String id) async {
    _savedAccounts.removeWhere((element) => element.id == id);
    await _storage.write(key: 'saved_accounts', value: json.encode(_savedAccounts.map((e) => e.toJson()).toList()));
    await _storage.delete(key: 'session_token_$id');
    notifyListeners();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check for 'isLoggedIn' OR check if recruiterId exists
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final savedId = prefs.getString('recruiterId');

      debugPrint("Auth Init: isLoggedIn=$isLoggedIn, recruiterId=$savedId");

      if (isLoggedIn && savedId != null) {
        final token = await _storage.read(key: 'session_token')
          ?? await _storage.read(key: 'session_token_$savedId');
        final cachedData = prefs.getString('recruiterData');
        
        if (token != null) {
          // Restore from cache first for immediate UI availability
          if (cachedData != null) {
            try {
              _currentRecruiter = Recruiter.fromJson(json.decode(cachedData));
              debugPrint("Restored recruiter from cache: ${_currentRecruiter?.fullName}");
              // No notifyListeners here, we do it in finally
            } catch (e) {
              debugPrint("Cache restoration failed: $e");
            }
          }

          // Validate token with backend in background
          try {
            final response = await _apiService.validateSession(token, savedId);
            if (response['success'] == true && response['recruiter'] != null) {
              _currentRecruiter = Recruiter.fromJson(response['recruiter']);
              debugPrint("Session validated successfully for: ${_currentRecruiter?.fullName}");
              // Refresh saved data
              await _saveSession(_currentRecruiter!, token);
              // FCM token sync bypassed
            } else if (response['message']?.toString().toLowerCase().contains('expired') == true || 
                       response['message']?.toString().toLowerCase().contains('invalid') == true) {
              debugPrint("Session invalid or expired: ${response['message']}");
              await logout();
            }
          } catch (e) {
            debugPrint("Validation error (likely network): $e");
          }
        } else {
          debugPrint("Session token missing in storage");
          await logout();
        }
      } else {
        debugPrint("No persistent session found");
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveSession(Recruiter recruiter, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('recruiterId', recruiter.id);
    await prefs.setString('recruiterData', json.encode(recruiter.toJson()));

    await _storage.write(key: 'session_token', value: token);
    await _storage.write(key: 'session_token_${recruiter.id}', value: token);
    await _addSavedAccount(recruiter, token);
  }

  Future<Map<String, dynamic>> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password, rememberMe: rememberMe);
      if (response['success'] == true) {
        _currentRecruiter = Recruiter.fromJson(response['recruiter']);
        final token = response['token'] ?? 'mock_token';
        await _saveSession(_currentRecruiter!, token);
        // FCM token sync bypassed
        
        _isLoading = false;
        notifyListeners();
        return {"success": true, "message": response['message']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          "success": false, 
          "message": response['message'] ?? "Login failed",
          "needs_verification": response['needs_verification'] == true
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "An error occurred during login"};
    }
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
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.signup(
        fullName: fullName,
        companyName: companyName,
        email: email,
        phone: phone,
        password: password,
        companyWebsite: companyWebsite,
        companyLocation: companyLocation,
        designation: designation,
        linkedinProfile: linkedinProfile,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "An error occurred during signup: $e"};
    }
  }

  Future<bool> switchAccount(SavedAccount account) async {
    _isLoading = true;
    notifyListeners();
    
    final recruiterId = account.id;
    final response = await _apiService.fetchDashboard(recruiterId);
    
    if (response['success'] == true) {
       _currentRecruiter = Recruiter.fromJson(response['recruiter']);
       await _saveSession(_currentRecruiter!, account.token);
       _isLoading = false;
       notifyListeners();
       return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> refreshProfile() async {
    if (_currentRecruiter == null) return;
    
    try {
      final response = await _apiService.fetchDashboard(_currentRecruiter!.id);
      if (response['success'] == true && response['recruiter'] != null) {
        _currentRecruiter = Recruiter.fromJson(response['recruiter']);
        final token = await _storage.read(key: 'session_token_${_currentRecruiter!.id}');
        await _saveSession(_currentRecruiter!, token ?? '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String companyName,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile({
        'recruiter_id': _currentRecruiter!.id,
        'full_name': fullName,
        'company_name': companyName,
        'phone': phone,
      });

      if (response['success'] == true) {
        _currentRecruiter = Recruiter.fromJson(response['recruiter']);
        final token = await _storage.read(key: 'session_token');
        await _saveSession(_currentRecruiter!, token ?? '');
        
        _isLoading = false;
        notifyListeners();
        return {"success": true, "message": response['message']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {"success": false, "message": response['message'] ?? "Update failed"};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "An error occurred during update: $e"};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {"success": false, "message": "An error occurred"};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = _currentRecruiter?.id;
    await prefs.remove('isLoggedIn');
    await prefs.remove('recruiterId');
    await prefs.remove('recruiterData');
    await _storage.delete(key: 'session_token');
    if (currentId != null) {
      await _storage.delete(key: 'session_token_$currentId');
    }
    _currentRecruiter = null;
    notifyListeners();
  }

  void updateRecruiterInfo(Recruiter recruiter) async {
    _currentRecruiter = recruiter;
    final token = await _storage.read(key: 'session_token_${recruiter.id}');
    await _saveSession(recruiter, token ?? '');
    notifyListeners();
  }
}
