import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/staff_service.dart';
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

  Color _statusColor(String status) {
    switch (status) {
      case "active": return CvltureColors.green;
      case "draft":  return const Color(0xFFFFB300);
      case "past":   return CvltureColors.grey;
      default:       return CvltureColors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case "active": return "ATTIVO";
      case "draft":  return "BOZZA";
      case "past":   return "PASSATO";
      default:       return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CvltureLogo(height: 15),
                  const SizedBox(height: 6),
                  const Text(
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
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: CvltureColors.green),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: CvltureColors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          color: CvltureColors.green,
                          backgroundColor: CvltureColors.surface,
                          onRefresh: loadEvents,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final status = (event["status"] ?? "").toString();
                              final registrations = event["registrations"] ?? 0;
                              final checkins = event["checkins"] ?? 0;
                              final capacity = event["max_capacity"] ?? 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StaffEventDetailPage(
                                        eventId: event["id"],
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: CvltureColors.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: CvltureColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event["title"] ?? "",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  color: _statusColor(status),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined,
                                                color: CvltureColors.grey, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              "${event["date"] ?? "-"}  ${event["time"] ?? ""}",
                                              style: const TextStyle(
                                                  color: CvltureColors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.people_outline,
                                                color: CvltureColors.grey, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              capacity > 0
                                                  ? "$registrations / $capacity iscritti"
                                                  : "$registrations iscritti",
                                              style: const TextStyle(
                                                  color: CvltureColors.grey, fontSize: 13),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.qr_code_scanner_outlined,
                                                color: CvltureColors.green, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              "$checkins check-in",
                                              style: const TextStyle(
                                                  color: CvltureColors.green, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
