import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthRepository {
  static const String baseUrl = "https://www.cvlture.it/wp-json";
  static const storage = FlutterSecureStorage();

  /* ==========================================
     LOGIN
     Usa l'email come username (uguale al sito web):
     l'utente WP viene creato con email come username
     in cvlture_handle_user_registration()
  ========================================== */

  static Future<void> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/jwt-auth/v1/token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameOrEmail,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await storage.write(key: "jwt_token",         value: data["token"]);
        await storage.write(key: "user_email",        value: data["user_email"]        ?? "");
        await storage.write(key: "user_display_name", value: data["user_display_name"] ?? "");
        return;
      }

      if (response.statusCode == 403) throw Exception("Credenziali non valide");
      throw Exception("Errore del server");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception("Controlla la connessione internet");
      }
      rethrow;
    }
  }

  /* ==========================================
     REGISTER
     Endpoint: POST /wp-json/cvlture/v1/user/register
     Stessa logica di cvlture_handle_user_registration()
     in auth.php, adattata per REST API.
     Nomi campi identici al form web + meta WP esistenti.
  ========================================== */

  static Future<void> register({
    required String nome,
    required String cognome,
    required String email,
    required String password,
    required String dataNascita,
    String igName = "",          // meta key "ig_name" come in auth.php
  }) async {
    try {
      final body = {
        "nome":         nome,
        "cognome":      cognome,
        "email":        email,
        "password":     password,
        "data_nascita": dataNascita,
        "ig_name":      igName,  // ← stesso nome del meta WP esistente
      };

      final response = await http.post(
        Uri.parse("$baseUrl/cvlture/v1/user/register"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return;

      throw Exception(data["message"] ?? "Errore durante la registrazione");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception("Controlla la connessione internet");
      }
      rethrow;
    }
  }

  /* ==========================================
     LOGOUT
  ========================================== */

  static Future<void> logout() async {
    await storage.delete(key: "jwt_token");
    await storage.delete(key: "user_email");
    await storage.delete(key: "user_display_name");
    await storage.delete(key: "is_staff");
    await storage.delete(key: "can_manage_events");
    await storage.delete(key: "can_validate_checkin");
  }

  /* ==========================================
     RUOLO STAFF
     Salvato localmente dopo aver letto /user/profile,
     che ora restituisce anche is_staff / can_manage_events /
     can_validate_checkin (vedi cvlture_user_profile() in
     cvlture-api.php). Serve per decidere, dopo il login,
     se mostrare la UI cliente o la UI staff.
  ========================================== */

  static Future<void> saveRoleFlags({
    required bool isStaff,
    required bool canManageEvents,
    required bool canValidateCheckin,
  }) async {
    await storage.write(key: "is_staff", value: isStaff.toString());
    await storage.write(key: "can_manage_events", value: canManageEvents.toString());
    await storage.write(key: "can_validate_checkin", value: canValidateCheckin.toString());
  }

  static Future<bool> isStaff() async =>
      (await storage.read(key: "is_staff")) == "true";

  static Future<bool> canManageEvents() async =>
      (await storage.read(key: "can_manage_events")) == "true";

  static Future<bool> canValidateCheckin() async =>
      (await storage.read(key: "can_validate_checkin")) == "true";

  /* ==========================================
     HELPERS
  ========================================== */

  static Future<bool>    isLoggedIn()         async => await storage.read(key: "jwt_token") != null;
  static Future<String?> getToken()           async => await storage.read(key: "jwt_token");
  static Future<String>  getUserDisplayName() async => await storage.read(key: "user_display_name") ?? "";
  static Future<String>  getUserEmail()       async => await storage.read(key: "user_email") ?? "";

  /* ==========================================
     RESET PASSWORD
     POST /cvlture/v1/user/forgot-password
  ========================================== */

  static Future<void> sendPasswordReset({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/cvlture/v1/user/forgot-password"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return;
      throw Exception(data["message"] ?? "Errore durante il recupero password");
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw Exception("Controlla la connessione internet");
      }
      rethrow;
    }
  }
}
