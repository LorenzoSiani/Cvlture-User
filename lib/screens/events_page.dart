import '../widgets/cvlture_loader.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/events_service.dart';
import '../widgets/cvlture_logo.dart';
import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool   loading    = true;
  List   events     = [];
  String searchQuery = "";

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadEvents();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadEvents() async {
    try {
      final data = await EventsService.getActiveEvents();
      if (!mounted) return;
      setState(() { events = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List get filteredEvents {
    if (searchQuery.isEmpty) return events;
    return events.where((e) {
      final title    = (e["title"]    ?? "").toString().toLowerCase();
      final location = (e["location"] ?? "").toString().toLowerCase();
      return title.contains(searchQuery) || location.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /* ---- HEADER ---- */
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CvltureLogo(height: 15),
                  const SizedBox(height: 6),
                  const Text(
                    "Eventi in corso",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SEARCH
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Cerca evento o location...",
                      hintStyle: const TextStyle(color: Color(0xFF555555)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CvltureColors.grey,
                      ),
                      filled: true,
                      fillColor: CvltureColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: CvltureColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: CvltureColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: CvltureColors.green, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /* ---- LISTA ---- */
            Expanded(
              child: loading
                  ? const Center(
                      child: CvltureLoader(),
                    )
                  : RefreshIndicator(
                      color: CvltureColors.green,
                      onRefresh: loadEvents,
                      child: filteredEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.event_busy,
                                      size: 64, color: Color(0xFF333333)),
                                  const SizedBox(height: 14),
                                  Text(
                                    searchQuery.isEmpty
                                        ? "Nessun evento attivo"
                                        : "Nessun risultato",
                                    style: const TextStyle(
                                        color: Color(0xFF555555), fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) =>
                                  _buildEventCard(filteredEvents[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map event) {
    final soldOut = event["sold_out"] == true;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(eventId: event["id"]),
          ),
        );
        if (result == true) loadEvents();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CvltureColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CvltureColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /* IMMAGINE */
            Stack(
              children: [
                if (event["image"] != null)
                  Image.network(
                    event["image"],
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                else
                  _imagePlaceholder(),

                if (soldOut)
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "SOLD OUT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /* INFO */
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  _infoRow(Icons.calendar_today,
                      "${event["date"]} • ${event["time"]}"),
                  const SizedBox(height: 5),
                  _infoRow(Icons.location_on, event["location"] ?? ""),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 140,
      color: const Color(0xFF111111),
      child: const Center(
        child: Text(
          "CVLTURE",
          style: TextStyle(
            color: CvltureColors.green,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CvltureColors.grey),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: CvltureColors.grey, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}
