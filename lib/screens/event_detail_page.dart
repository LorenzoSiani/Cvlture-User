import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/events_service.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool loading       = true;
  bool actionLoading = false;
  Map<String, dynamic>? event;

  @override
  void initState() {
    super.initState();
    loadEvent();
  }

  Future<void> loadEvent() async {
    try {
      final data = await EventsService.getEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() { event = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> register() async {
    setState(() => actionLoading = true);
    try {
      final result = await EventsService.registerForEvent(widget.eventId);
      if (!mounted) return;
      setState(() {
        event!["user_registered"] = true;
        event!["user_token"]      = result["token"];
        event!["registered"]      = (event!["registered"] ?? 0) + 1;
        actionLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iscrizione completata! 🎉"),
          backgroundColor: CvltureColors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> openExternalTicket(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: CvltureColors.green)),
      );
    }
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("Evento non trovato", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isRegistered = event!["user_registered"] == true;
    final isSoldOut    = event!["sold_out"]         == true;
    final closed       = event!["registrazioni_chiuse"] == true;

    // LINEUP
    final dj    = (event!["dj"]    ?? "").toString().trim();
    final host  = (event!["host"]  ?? "").toString().trim();
    final guest = (event!["guest"] ?? "").toString().trim();
    final hasLineup = dj.isNotEmpty || host.isNotEmpty || guest.isNotEmpty;

    // RELEASE / PREZZO
    final releaseLabel = (event!["release_label"]       ?? "").toString().trim();
    final releasePrice = (event!["release_prezzo"]       ?? "").toString().trim();
    final releaseDesc  = (event!["release_descrizione"]  ?? "").toString().trim();
    final hasRelease   = releaseLabel.isNotEmpty || releasePrice.isNotEmpty;

    // DRINK
    final drinkAttivo = event!["drink_attivo"] == true;
    final drinkLimit  = (event!["drink_limit"] ?? "").toString().trim();

    // BIGLIETTO ESTERNO
    final externalUrl = (event!["external_ticket_url"] ?? "").toString().trim();

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /* ---- HERO ---- */
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: CvltureColors.background,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event!["title"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (event!["image"] != null)
                    Image.network(event!["image"], fit: BoxFit.cover)
                  else
                    Container(
                      color: CvltureColors.surface,
                      child: const Center(
                        child: Text(
                          "CVLTURE",
                          style: TextStyle(
                            color: CvltureColors.green,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /* ---- CONTENUTO ---- */
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // DATA
                  _infoRow(Icons.calendar_today,
                      "${event!["date"]} • ${event!["time"]}"),
                  const SizedBox(height: 10),

                  // LOCATION
                  _infoRow(Icons.location_on, event!["location"] ?? ""),

                  // REGISTRAZIONI CHIUSE (avviso, se attivo)
                  if (closed && !isRegistered) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1F0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5C4A1A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFFFFB74D), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Le registrazioni per questo evento sono chiuse",
                              style: TextStyle(
                                  color: Color(0xFFFFB74D), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Container(height: 1, color: CvltureColors.border),

                  // DESCRIZIONE
                  if (event!["description"] != null &&
                      event!["description"].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Info sull'evento",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event!["description"].toString(),
                      style: const TextStyle(
                        color: CvltureColors.grey,
                        height: 1.7,
                        fontSize: 15,
                      ),
                    ),
                  ],

                  // LINE-UP
                  if (hasLineup) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Line-up",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        if (dj.isNotEmpty)
                          _lineupTile(Icons.headphones, "DJ", dj),
                        if (host.isNotEmpty)
                          _lineupTile(Icons.mic_external_on, "Host", host),
                        if (guest.isNotEmpty)
                          _lineupTile(Icons.star_outline, "Guest", guest),
                      ],
                    ),
                  ],

                  // PREZZO / RELEASE
                  if (hasRelease) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CvltureColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CvltureColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                releaseLabel.isNotEmpty
                                    ? releaseLabel
                                    : "Prezzo ingresso",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (releasePrice.isNotEmpty)
                                Text(
                                  "€$releasePrice",
                                  style: const TextStyle(
                                    color: CvltureColors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                            ],
                          ),
                          if (releaseDesc.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              releaseDesc,
                              style: const TextStyle(
                                color: CvltureColors.grey,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // DRINK OMAGGIO
                  if (drinkAttivo) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: CvltureColors.green.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: CvltureColors.green.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_bar_outlined,
                              color: CvltureColors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              drinkLimit.isNotEmpty
                                  ? "Drink omaggio incluso (entro le $drinkLimit)"
                                  : "Drink omaggio incluso",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // BIGLIETTO ESTERNO
                  if (externalUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => openExternalTicket(externalUrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: CvltureColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CvltureColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                color: CvltureColors.grey, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Biglietti esterni disponibili",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.open_in_new,
                                color: CvltureColors.grey, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  _buildActionButton(isRegistered, isSoldOut, closed),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: CvltureColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _lineupTile(IconData icon, String role, String name) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CvltureColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: CvltureColors.grey,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isRegistered, bool isSoldOut, bool closed) {
    if (isRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CvltureColors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CvltureColors.green.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: CvltureColors.green),
            SizedBox(width: 10),
            Text(
              "Sei iscritto a questo evento",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CvltureColors.green,
              ),
            ),
          ],
        ),
      );
    }

    if (isSoldOut || closed) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            isSoldOut ? "SOLD OUT" : "REGISTRAZIONI CHIUSE",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: actionLoading ? null : register,
        child: actionLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black))
            : const Text("Iscriviti all'evento",
                style: TextStyle(fontSize: 17)),
      ),
    );
  }
}
