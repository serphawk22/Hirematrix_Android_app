import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class RecruiterSupportController extends ChangeNotifier {
  bool isSending = false;

  Future<bool> sendSupportMessage({
    required String recruiterId,
    required String subject,
    required String message,
  }) async {
    isSending = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/mobile/support/chat');
      final resp = await http.post(uri, body: {
        'recruiter_id': recruiterId,
        'subject': subject,
        'message': message,
      });

      if (resp.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(resp.body);
        return (json['success'] ?? false) == true || (json['status'] ?? '') == 'success';
      }

      return false;
    } catch (_) {
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
