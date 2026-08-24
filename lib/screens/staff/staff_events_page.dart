import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/staff_service.dart';
import '../../widgets/cvlture_loader.dart';
import '../../widgets/cvlture_logo.dart';
import 'staff_event_detail_page.dart';

class StaffEventsPage extends StatefulWidget {
  const StaffEventsPage({super.key});

  @override
  State<StaffEventsPage> createState() => _StaffEventsPageState();
}

class _StaffEventsPageState extends State<StaffEventsPage> {
  bool loading = true;
  List events = [];
  String? errorMessage;

  static const _mesi = [
    'Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno',
    'Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'
  ];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final data = await StaffService.getEvents();
      if (!mounted) return;
      setState(() { events = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  /* ─── Raggruppa per mese ─────────────────────────────── */

  Map<String, List> _groupByMonth(List evts) {
    final Map<String, List> grouped = {};
    for (final e in evts) {
      final dateStr = (e["date"] ?? "").toString();
      String label = "Senza data";
      if (dateStr.length >= 7) {
        try {
          final d = DateTime.parse(dateStr);
          label = "${_mesi[d.month - 1]} ${d.year}";
        } catch (_) {}
      }
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  /* ─── Colore / label status ──────────────────────────── */

  Color _statusColor(String s) {
    switch (s) {
      case "active": return CvltureColors.green;
      case "draft":  return const Color(0xFFFFB300);
      default:       return CvltureColors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "active": return "ATTIVO";
      case "draft":  return "BOZZA";
      case "past":   return "PASSATO";
      default:       return s.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* ── HEADER ── */
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CvltureLogo(height: 20),
                  SizedBox(height: 6),
                  Text(
                    "Eventi",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            /* ── LISTA ── */
            Expanded(
              child: loading
                  ? const Center(child: CvltureLoader())
                  : errorMessage != null
                      ? Center(
                          child: Text(errorMessage!,
                              style: const TextStyle(color: CvltureColors.grey)),
                        )
                      : RefreshIndicator(
                          color: CvltureColors.green,
                          backgroundColor: CvltureColors.surface,
                          onRefresh: loadEvents,
                          child: _buildGroupedGrid(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedGrid() {
    final grouped = _groupByMonth(events);
    if (grouped.isEmpty) {
      return const Center(
        child: Text("Nessun evento", style: TextStyle(color: CvltureColors.grey)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* INTESTAZIONE MESE */
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 12),
              child: Row(
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      color: CvltureColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: CvltureColors.border),
                  ),
                ],
              ),
            ),

            /* GRIGLIA 2 PER RIGA */
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:    2,
                crossAxisSpacing:  12,
                mainAxisSpacing:   12,
                childAspectRatio:  0.82,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, i) =>
                  _EventCard(event: entry.value[i],
                    statusColor: _statusColor,
                    statusLabel: _statusLabel),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   CARD EVENTO
══════════════════════════════════════════════════════════ */

class _EventCard extends StatelessWidget {
  final Map event;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _EventCard({
    required this.event,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status        = (event["status"] ?? "").toString();
    final registrations = event["registrations"] ?? 0;
    final capacity      = event["max_capacity"]  ?? 0;
    final checkins      = event["checkins"]      ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StaffEventDetailPage(eventId: event["id"]),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CvltureColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CvltureColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /* IMMAGINE */
            if (event["image"] != null)
              Image.network(
                event["image"],
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),

            /* BADGE STATUS */
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      statusLabel(status),
                      style: TextStyle(
                        color: statusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /* TITOLO */
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              child: Text(
                event["title"] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),

            const Spacer(),

            /* STATS */
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 12, color: CvltureColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    capacity > 0
                        ? "$registrations/$capacity"
                        : "$registrations",
                    style: const TextStyle(
                        color: CvltureColors.grey, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.qr_code_scanner_outlined,
                      size: 12, color: CvltureColors.green),
                  const SizedBox(width: 4),
                  Text(
                    "$checkins",
                    style: const TextStyle(
                        color: CvltureColors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 90,
      width: double.infinity,
      color: const Color(0xFF111111),
      child: const Center(
        child: Text(
          "CVLTURE",
          style: TextStyle(
            color: CvltureColors.green,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
