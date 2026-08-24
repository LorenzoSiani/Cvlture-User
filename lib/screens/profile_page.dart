import '../widgets/cvlture_loader.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_repository.dart';
import '../services/events_service.dart';
import '../widgets/cvlture_logo.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading      = true;
  bool editing      = false;
  bool saving       = false;
  bool loadingEvents = true;

  Map<String, dynamic> profile = {};
  List myEvents = [];

  final nomeController      = TextEditingController();
  final cognomeController   = TextEditingController();
  final instagramController = TextEditingController();
  DateTime? dataNascita;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadMyEvents();
  }

  @override
  void dispose() {
    nomeController.dispose();
    cognomeController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final name  = await AuthRepository.getUserDisplayName();
    final email = await AuthRepository.getUserEmail();
    if (!mounted) return;
    setState(() { profile = {"name": name, "email": email}; loading = false; });

    try {
      final data = await EventsService.getProfile();
      if (!mounted) return;
      setState(() {
        profile = data;
        _populateControllers();
      });
    } catch (_) {}
  }

  Future<void> loadMyEvents() async {
    try {
      // Usa endpoint dedicato che filtra server-side (convalidato=1)
      // così recupera anche eventi storici associati alla stessa email
      final data = await EventsService.getParticipatedEvents();
      if (!mounted) return;
      setState(() { myEvents = data; loadingEvents = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingEvents = false);
    }
  }

  void _populateControllers() {
    nomeController.text      = profile["first_name"]?.toString() ?? "";
    cognomeController.text   = profile["last_name"]?.toString()  ?? "";
    instagramController.text = profile["ig_name"]?.toString()    ?? "";

    final raw = profile["data_nascita"]?.toString() ?? "";
    dataNascita = _parseDate(raw);
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      // Formato salvato: DD/MM/YYYY
      final parts = raw.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  String get dataNascitaFormatted {
    if (dataNascita == null) return "";
    return "${dataNascita!.day.toString().padLeft(2, '0')}/"
        "${dataNascita!.month.toString().padLeft(2, '0')}/"
        "${dataNascita!.year}";
  }

  Future<void> pickDataNascita() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dataNascita ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: "Data di nascita",
      cancelText: "Annulla",
      confirmText: "Conferma",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   CvltureColors.green,
            onPrimary: Colors.black,
            surface:   CvltureColors.surface,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: CvltureColors.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => dataNascita = picked);
  }

  Future<void> saveProfile() async {
    if (nomeController.text.trim().isEmpty ||
        cognomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nome e cognome sono obbligatori"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await EventsService.updateProfile(
        nome:        nomeController.text.trim(),
        cognome:     cognomeController.text.trim(),
        dataNascita: dataNascitaFormatted,
        igName:      instagramController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        profile["first_name"]   = nomeController.text.trim();
        profile["last_name"]    = cognomeController.text.trim();
        profile["name"]         = "${nomeController.text.trim()} ${cognomeController.text.trim()}";
        profile["data_nascita"] = dataNascitaFormatted;
        profile["ig_name"]      = instagramController.text.trim();
        editing = false;
        saving  = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profilo aggiornato"),
          backgroundColor: CvltureColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CvltureColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Vuoi uscire dal tuo account?",
            style: TextStyle(color: CvltureColors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annulla",
                style: TextStyle(color: CvltureColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A0A0A),
              foregroundColor: const Color(0xFFFF4444),
              side: const BorderSide(color: Color(0xFF5C1A1A)),
            ),
            child: const Text("Esci"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthRepository.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = profile["name"]?.toString()  ?? "";
    final email       = profile["email"]?.toString() ?? "";
    final initial     = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email.isNotEmpty ? email[0].toUpperCase() : "?";

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CvltureLoader())
            : RefreshIndicator(
                color: CvltureColors.green,
                onRefresh: () async {
                  await loadProfile();
                  await loadMyEvents();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /* ---- HEADER ---- */
                      const CvltureLogo(height: 28),
                      const SizedBox(height: 6),
                      const Text(
                        "Profilo",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      /* ---- AVATAR + NOME ---- */
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: CvltureColors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: CvltureColors.green.withOpacity(0.25),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              displayName.isNotEmpty ? displayName : "Utente",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: CvltureColors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      /* ---- SEZIONE ACCOUNT (view / edit) ---- */
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel("Dati personali"),
                          GestureDetector(
                            onTap: () {
                              if (editing) {
                                _populateControllers(); // reset modifiche
                              }
                              setState(() => editing = !editing);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  editing ? Icons.close : Icons.edit_outlined,
                                  size: 15,
                                  color: editing
                                      ? const Color(0xFFFF6666)
                                      : CvltureColors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  editing ? "Annulla" : "Modifica",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: editing
                                        ? const Color(0xFFFF6666)
                                        : CvltureColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      editing ? _buildEditForm() : _buildViewMode(email),

                      const SizedBox(height: 32),

                      /* ---- I MIEI EVENTI ---- */
                      _sectionLabel("I miei eventi"),
                      const SizedBox(height: 12),
                      _buildMyEventsList(),

                      const SizedBox(height: 32),

                      /* ---- LOGOUT ---- */
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text(
                            "Esci dall'account",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF4444),
                            side: const BorderSide(color: Color(0xFF5C1A1A)),
                            backgroundColor: const Color(0xFF1A0808),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /* ==========================================
     VISUALIZZAZIONE DATI (sola lettura)
  ========================================== */

  Widget _buildViewMode(String email) {
    return Column(
      children: [
        _infoTile(Icons.badge_outlined, "Nome",
            profile["first_name"]?.toString().isNotEmpty == true
                ? profile["first_name"] : "-"),
        _infoTile(Icons.badge_outlined, "Cognome",
            profile["last_name"]?.toString().isNotEmpty == true
                ? profile["last_name"] : "-"),
        _infoTile(Icons.email_outlined, "Email", email.isNotEmpty ? email : "-"),
        _infoTile(Icons.cake_outlined, "Data di nascita",
            profile["data_nascita"]?.toString().isNotEmpty == true
                ? profile["data_nascita"] : "-"),
        _infoTile(Icons.camera_alt_outlined, "Instagram",
            profile["ig_name"]?.toString().isNotEmpty == true
                ? "@${profile["ig_name"]}" : "-"),
      ],
    );
  }

  /* ==========================================
     FORM DI MODIFICA
  ========================================== */

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(nomeController, "Nome", Icons.person_outline),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(cognomeController, "Cognome", Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // EMAIL (sola lettura)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CvltureColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 18, color: Color(0xFF555555)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile["email"]?.toString() ?? "",
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
              ),
              const Icon(Icons.lock_outline, size: 14, color: Color(0xFF444444)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // DATA DI NASCITA
        GestureDetector(
          onTap: pickDataNascita,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: CvltureColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CvltureColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: Color(0xFF666666), size: 20),
                const SizedBox(width: 12),
                Text(
                  dataNascita != null ? dataNascitaFormatted : "Data di nascita",
                  style: TextStyle(
                    color: dataNascita != null ? Colors.white : const Color(0xFF555555),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // INSTAGRAM
        TextField(
          controller: instagramController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Instagram (opzionale)",
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Text("@",
                  style: TextStyle(color: Color(0xFF666666), fontSize: 18)),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: saving ? null : saveProfile,
            child: saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CvltureLoader(size: 22),
                  )
                : const Text("Salva modifiche"),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  /* ==========================================
     LISTA EVENTI A CUI HA PARTECIPATO
  ========================================== */

  Widget _buildMyEventsList() {
    if (loadingEvents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CvltureLoader(size: 22),
        ),
      );
    }

    if (myEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CvltureColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CvltureColors.border),
        ),
        child: const Center(
          child: Text(
            "Non hai ancora partecipato a nessun evento",
            style: TextStyle(color: Color(0xFF555555), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: myEvents.map((e) => _eventHistoryTile(e)).toList(),
    );
  }

  Widget _eventHistoryTile(Map event) {
    final checkedIn = event["checked_in"] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: event["image"] != null
                ? Image.network(
                    event["image"],
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _eventThumbPlaceholder(),
                  )
                : _eventThumbPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event["title"] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "${event["date"] ?? ""} • ${event["time"] ?? ""}",
                  style: const TextStyle(color: CvltureColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: checkedIn
                  ? const Color(0xFF1A2A1A)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: checkedIn
                    ? const Color(0xFF2A4A2A)
                    : CvltureColors.border,
              ),
            ),
            child: Text(
              checkedIn ? "✓ Presente" : "In attesa",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: checkedIn
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventThumbPlaceholder() {
    return Container(
      width: 50, height: 50,
      color: const Color(0xFF111111),
      child: const Center(
        child: Icon(Icons.event, size: 18, color: CvltureColors.green),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: CvltureColors.grey,
        letterSpacing: 2,
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CvltureColors.grey),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: CvltureColors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
