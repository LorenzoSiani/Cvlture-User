import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/staff_service.dart';
import 'qr_scanner_page.dart';

class StaffEventDetailPage extends StatefulWidget {
  final int eventId;
  const StaffEventDetailPage({super.key, required this.eventId});

  @override
  State<StaffEventDetailPage> createState() => _StaffEventDetailPageState();
}

class _StaffEventDetailPageState extends State<StaffEventDetailPage> {
  bool loading = true;
  Map<String, dynamic> event = {};
  List registrations = [];
  String? errorMessage;
  String searchQuery = "";
  final searchController = TextEditingController();

  // id delle registrazioni per cui è in corso una validazione manuale,
  // per disabilitare il bottone ed evitare doppi tap.
  final Set validatingIds = {};

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
    });
    loadDetail();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDetail() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final data = await StaffService.getEventDetail(widget.eventId);
      if (!mounted) return;
      setState(() {
        event = Map<String, dynamic>.from(data["event"] ?? {});
        registrations = data["registrations"] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  List get filteredRegistrations {
    if (searchQuery.isEmpty) return registrations;
    return registrations.where((r) {
      final name  = (r["name"]  ?? "").toString().toLowerCase();
      final email = (r["email"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();
  }

  Future<void> validateManually(Map registration) async {
    final id = registration["id"];
    setState(() => validatingIds.add(id));

    try {
      await StaffService.validateCheckin(
        token: registration["qr_token"] ?? "",
        eventId: widget.eventId,
      );
      if (!mounted) return;
      await loadDetail(); // ricarica per aggiornare stato + contatori
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ingresso validato: ${registration["name"]}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => validatingIds.remove(id));
    }
  }

  Future<void> openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerPage(
          eventId: widget.eventId,
          eventTitle: event["title"] ?? "",
        ),
      ),
    );
    // Se lo scanner ha validato almeno un ingresso, ricarichiamo la lista
    if (result == true) loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event["title"] ?? "Dettaglio evento"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openScanner,
        backgroundColor: CvltureColors.green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Scanner", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: CvltureColors.green))
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!, style: const TextStyle(color: CvltureColors.grey)),
                  )
                : RefreshIndicator(
                    color: CvltureColors.green,
                    backgroundColor: CvltureColors.surface,
                    onRefresh: loadDetail,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        _EventSummary(event: event, total: registrations.length),
                        const SizedBox(height: 20),
                        TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Cerca per nome o email",
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...filteredRegistrations.map((r) => _RegistrationTile(
                              registration: r,
                              isValidating: validatingIds.contains(r["id"]),
                              onValidate: () => validateManually(r),
                            )),
                        if (filteredRegistrations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                "Nessuna prenotazione trovata",
                                style: TextStyle(color: CvltureColors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _EventSummary extends StatelessWidget {
  final Map event;
  final int total;
  const _EventSummary({required this.event, required this.total});

  @override
  Widget build(BuildContext context) {
    final capacity = event["capacity"] ?? 0;
    final checkins = event["checkins"] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: "Iscritti",
              value: capacity > 0 ? "$total / $capacity" : "$total",
            ),
          ),
          Container(width: 1, height: 32, color: CvltureColors.border),
          Expanded(
            child: _SummaryStat(label: "Check-in", value: "$checkins"),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: CvltureColors.green, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: CvltureColors.grey, fontSize: 12)),
      ],
    );
  }
}

class _RegistrationTile extends StatelessWidget {
  final Map registration;
  final bool isValidating;
  final VoidCallback onValidate;

  const _RegistrationTile({
    required this.registration,
    required this.isValidating,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final checkedIn = registration["checkin"] == true;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration["name"] ?? "",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  registration["email"] ?? "",
                  style: const TextStyle(color: CvltureColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (checkedIn)
            const Chip(
              label: Text("Entrato", style: TextStyle(color: Colors.black, fontSize: 12)),
              backgroundColor: CvltureColors.green,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: isValidating ? null : onValidate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: isValidating
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text("Valida", style: TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}
