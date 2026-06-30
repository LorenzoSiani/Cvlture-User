import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_repository.dart';

class ApiClient {
  static const String baseUrl =
      "https://www.cvlture.it/wp-json/cvlture/v1";

  /* ==========================================
     GET
  ========================================== */

  static Future<dynamic> get(String endpoint) async {
    final token = await AuthRepository.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 401) {
      await AuthRepository.logout();
      throw Exception("Sessione scaduta");
    }

    return jsonDecode(response.body);
  }

  /* ==========================================
     POST
  ========================================== */

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthRepository.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await AuthRepository.logout();
      throw Exception("Sessione scaduta");
    }

    return jsonDecode(response.body);
  }

  /* ==========================================
     DELETE
  ========================================== */

  static Future<dynamic> delete(String endpoint) async {
    final token = await AuthRepository.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 401) {
      await AuthRepository.logout();
      throw Exception("Sessione scaduta");
    }

    return jsonDecode(response.body);
  }
}
