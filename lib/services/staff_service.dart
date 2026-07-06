import 'api_client.dart';

/// Chiamate REST verso le rotte /staff/* di cvlture-api.php.
/// Usa lo stesso ApiClient (stesso token JWT) dell'app cliente:
/// è lo stesso account, solo con capability diverse lato WordPress.
class StaffService {
  /* ==========================================
     DASHBOARD
     GET /cvlture/v1/staff/dashboard
     Response: { data: { active_events, today_events,
                 total_registrations, total_checkins, entry_rate } }
  ========================================== */

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiClient.get("/staff/dashboard");
    return Map<String, dynamic>.from(response["data"] ?? {});
  }

  /* ==========================================
     LISTA EVENTI (STAFF)
     GET /cvlture/v1/staff/events
     Response: { data: [ {id, title, status, date, time, location,
                 max_capacity, registrations, checkins, ...} ] }
  ========================================== */

  static Future<List<dynamic>> getEvents() async {
    final response = await ApiClient.get("/staff/events");
    return response["data"] ?? [];
  }

  /* ==========================================
     DETTAGLIO EVENTO + LISTA REGISTRAZIONI
     GET /cvlture/v1/staff/event/{id}
     Response: { data: { event: {...}, registrations: [...] } }
  ========================================== */

  static Future<Map<String, dynamic>> getEventDetail(int eventId) async {
    final response = await ApiClient.get("/staff/event/$eventId");
    return Map<String, dynamic>.from(response["data"] ?? {});
  }

  /* ==========================================
     VALIDAZIONE INGRESSO (CHECK-IN)
     POST /cvlture/v1/staff/checkin
     Body: { token, event_id }
     Response: { success, data: { name, email, drink, timestamp } }
     In caso di errore (QR non valido / già usato / evento sbagliato)
     l'eccezione contiene il messaggio pronto da mostrare a schermo.
  ========================================== */

  static Future<Map<String, dynamic>> validateCheckin({
    required String token,
    required int eventId,
  }) async {
    final response = await ApiClient.post("/staff/checkin", {
      "token": token,
      "event_id": eventId,
    });

    // Le rotte REST di WordPress, in caso di errore (WP_Error),
    // rispondono con { code, message, data: {status} } e non con
    // { success: false, message }. Bisogna controllare entrambi i casi.
    if (response is Map && response.containsKey("code")) {
      throw Exception(response["message"] ?? "QR non valido");
    }

    if (response["success"] != true) {
      throw Exception(response["message"] ?? "QR non valido");
    }

    return Map<String, dynamic>.from(response["data"] ?? {});
  }
}
