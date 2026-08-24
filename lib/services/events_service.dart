import 'api_client.dart';

class EventsService {
  /* ==========================================
     LISTA EVENTI ATTIVI
     GET /cvlture/v1/user/events
     Response: { data: [ {id, title, date, time, location,
                          image, capacity, registered, sold_out} ] }
  ========================================== */

  static Future<List<dynamic>> getActiveEvents() async {
    final response = await ApiClient.get("/user/events");
    return response["data"] ?? [];
  }

  /* ==========================================
     DETTAGLIO EVENTO
     GET /cvlture/v1/user/events/{id}
     Response: { id, title, date, time, location, image,
                 description, capacity, registered, sold_out,
                 user_registered, user_token }
  ========================================== */

  static Future<Map<String, dynamic>> getEventDetail(
    int eventId,
  ) async {
    final response = await ApiClient.get("/user/events/$eventId");
    return Map<String, dynamic>.from(response);
  }

  /* ==========================================
     ISCRIZIONE A EVENTO
     POST /cvlture/v1/user/register-event
     Body: { event_id }
     Response: { success, message, token }
  ========================================== */

  static Future<Map<String, dynamic>> registerForEvent(
    int eventId,
  ) async {
    final response = await ApiClient.post(
      "/user/register-event",
      {"event_id": eventId},
    );
    return Map<String, dynamic>.from(response);
  }

  /* ==========================================
     CANCELLA ISCRIZIONE
     DELETE /cvlture/v1/user/unregister-event/{id}
  ========================================== */

  static Future<void> unregisterFromEvent(int eventId) async {
    await ApiClient.delete("/user/unregister-event/$eventId");
  }

  /* ==========================================
     I MIEI EVENTI (BIGLIETTI)
     GET /cvlture/v1/user/my-events
     Response: { data: [ {event_id, title, date, time,
                          location, image, token, checked_in} ] }
  ========================================== */

  static Future<List<dynamic>> getMyRegistrations() async {
    final response = await ApiClient.get("/user/my-events");
    return response["data"] ?? [];
  }

  /* ==========================================
     PROFILO UTENTE
     GET /cvlture/v1/user/profile
     Response: { name, email, first_name, last_name,
                 data_nascita, ig_name }
  ========================================== */

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get("/user/profile");
    return Map<String, dynamic>.from(response);
  }

  /* ==========================================
     AGGIORNA PROFILO
     POST /cvlture/v1/user/profile/update
     Body: { nome, cognome, data_nascita, ig_name }
  ========================================== */

  static Future<void> updateProfile({
    required String nome,
    required String cognome,
    required String dataNascita,
    String igName = "",
  }) async {
    await ApiClient.post("/user/profile/update", {
      "nome":         nome,
      "cognome":      cognome,
      "data_nascita": dataNascita,
      "ig_name":      igName,
    });
  }
  /* ==========================================
     EVENTI A CUI L'UTENTE HA PARTECIPATO
     GET /cvlture/v1/user/participated-events
     Solo quelli con check-in confermato (convalidato=1 nel DB).
     Query server-side: più affidabile del filtro client-side.
  ========================================== */

  static Future<List<dynamic>> getParticipatedEvents() async {
    final response = await ApiClient.get("/user/participated-events");
    return response["data"] ?? [];
  }
}