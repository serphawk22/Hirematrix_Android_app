import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hirematrix/core/constants/api_constants.dart';

class LocalCompaniesController extends GetxController {
  final isLoading = false.obs;
  final isSearching = false.obs;
  final hasSearched = false.obs;

  // Initial lists
  final featuredCompanies = <dynamic>[].obs;
  final popularRoles = <String>[].obs;
  final popularCities = <String>[].obs;

  // Stats
  final companyCount = 0.obs;
  final openJobsCount = 0.obs;

  // Search state
  final searchResults = <dynamic>[].obs;
  final lastSearchRole = ''.obs;
  final lastSearchCity = ''.obs;

  // Real-time suggestions
  final roleSuggestions = <String>[].obs;
  final citySuggestions = <String>[].obs;
  final showRoleSuggestions = false.obs;
  final showCitySuggestions = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitData();
  }

  Future<void> fetchInitData() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/local-companies/init'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        featuredCompanies.assignAll(data['featuredCompanies'] ?? []);
        popularRoles.assignAll(List<String>.from(data['popularRoles'] ?? []));
        popularCities.assignAll(List<String>.from(data['popularCities'] ?? []));

        // Calculate stats
        companyCount.value = featuredCompanies.length;
        int jobsSum = 0;
        for (var comp in featuredCompanies) {
          jobsSum += int.tryParse(comp['open_jobs']?.toString() ?? '0') ?? 0;
        }
        openJobsCount.value = jobsSum;
      } else {
        Get.snackbar(
          'Error',
          'Failed to load local companies',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not connect to server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCompanies(String role, String city) async {
    if (role.trim().isEmpty || city.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both a role and a city.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber[700],
        colorText: Colors.white,
      );
      return;
    }

    isSearching.value = true;
    hasSearched.value = true;
    lastSearchRole.value = role.trim();
    lastSearchCity.value = city.trim();

    try {
      final baseUrlClean = ApiConstants.baseUrl.replaceAll('/api', '');
      final response = await http.get(
        Uri.parse('$baseUrlClean/fetch-companies?role=${Uri.encodeComponent(role.trim())}&city=${Uri.encodeComponent(city.trim())}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          searchResults.assignAll(data);
        } else {
          searchResults.clear();
        }
      } else {
        searchResults.clear();
        Get.snackbar(
          'Error',
          'Search request failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      searchResults.clear();
      Get.snackbar(
        'Error',
        'Something went wrong while loading companies.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> getSuggestions(String term, String type) async {
    if (term.trim().length < 2) {
      if (type == 'role') {
        roleSuggestions.clear();
        showRoleSuggestions.value = false;
      } else {
        citySuggestions.clear();
        showCitySuggestions.value = false;
      }
      return;
    }

    try {
      final baseUrlClean = ApiConstants.baseUrl.replaceAll('/api', '');
      final response = await http.get(
        Uri.parse('$baseUrlClean/suggest?term=${Uri.encodeComponent(term.trim())}&type=$type'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final list = List<String>.from(data);
          if (type == 'role') {
            roleSuggestions.assignAll(list);
            showRoleSuggestions.value = list.isNotEmpty;
          } else {
            citySuggestions.assignAll(list);
            showCitySuggestions.value = list.isNotEmpty;
          }
        }
      }
    } catch (_) {
      // Ignore suggestions error
    }
  }

  void clearSearch() {
    searchResults.clear();
    hasSearched.value = false;
    lastSearchRole.value = '';
    lastSearchCity.value = '';
    roleSuggestions.clear();
    citySuggestions.clear();
    showRoleSuggestions.value = false;
    showCitySuggestions.value = false;
  }
}
