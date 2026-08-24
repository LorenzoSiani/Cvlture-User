import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/staff_service.dart';
import '../../widgets/cvlture_loader.dart';
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
  final Set validatingIds = {};

  // Paginazione
  int currentPage = 0;
  static const int pageSize = 30;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() { searchQuery = searchController.text.toLowerCase(); currentPage = 0; });
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
        event         = Map<String, dynamic>.from(data["event"] ?? {});
        registrations = data["registrations"] ?? [];
        loading       = false;
        currentPage   = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  /* ─── Lista filtrata + ordinata + paginata ─────────────── */

  List get _filtered {
    List list = registrations;
    if (searchQuery.isNotEmpty) {
      list = list.where((r) {
        final name  = (r["name"]  ?? "").toString().toLowerCase();
        final email = (r["email"] ?? "").toString().toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    }
    // Ordine alfabetico per nome
    list = List.from(list)
      ..sort((a, b) => (a["name"] ?? "").toString()
          .compareTo((b["name"] ?? "").toString()));
    return list;
  }

  List get _paged {
    final all   = _filtered;
    final start = currentPage * pageSize;
    final end   = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / pageSize).ceil().clamp(1, 999);

  /* ─── Validazione con dialog di conferma ──────────────── */

  Future<void> validateManually(Map registration) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CvltureColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Conferma ingresso",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "Vuoi validare l'ingresso di ${registration["name"]}?",
          style: const TextStyle(color: CvltureColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annulla",
                style: TextStyle(color: CvltureColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Conferma"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final id = registration["id"];
    setState(() => validatingIds.add(id));

    try {
      await StaffService.validateCheckin(
        token:   registration["qr_token"] ?? "",
        eventId: widget.eventId,
      );
      if (!mounted) return;
      await loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ingresso validato: ${registration["name"]}"),
          backgroundColor: CvltureColors.green,
        ),
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
          eventId:    widget.eventId,
          eventTitle: event["title"] ?? "",
        ),
      ),
    );
    if (result == true) loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event["title"] ?? "Dettaglio evento")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openScanner,
        backgroundColor: CvltureColors.green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Scanner",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CvltureLoader())
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style: const TextStyle(color: CvltureColors.grey)))
                : RefreshIndicator(
                    color: CvltureColors.green,
                    backgroundColor: CvltureColors.surface,
                    onRefresh: loadDetail,
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        /* SUMMARY */
                        _EventSummary(
                          event: event,
                          total: registrations.length,
                        ),
                        const SizedBox(height: 20),

                        /* SEARCH */
                        TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Cerca nome o email",
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 6),

                        /* CONTATORE */
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "${_filtered.length} RSVP"
                            "${_totalPages > 1 ? " — pagina ${currentPage + 1} di $_totalPages" : ""}",
                            style: const TextStyle(
                                color: CvltureColors.grey, fontSize: 12),
                          ),
                        ),

                        /* LISTA */
                        ..._paged.map((r) => _RegistrationTile(
                              registration: r,
                              isValidating:
                                  validatingIds.contains(r["id"]),
                              onValidate: () => validateManually(r),
                            )),

                        if (_filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text("Nessun risultato",
                                  style: TextStyle(
                                      color: CvltureColors.grey)),
                            ),
                          ),

                        /* PAGINAZIONE */
                        if (_totalPages > 1) ...[
                          const SizedBox(height: 16),
                          _PaginationBar(
                            currentPage: currentPage,
                            totalPages:  _totalPages,
                            onPrev: currentPage > 0
                                ? () => setState(() => currentPage--)
                                : null,
                            onNext: currentPage < _totalPages - 1
                                ? () => setState(() => currentPage++)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   EVENT SUMMARY
══════════════════════════════════════════════════════════ */

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
            child: _Stat(
              label: "RSVP",
              value: capacity > 0 ? "$total / $capacity" : "$total",
            ),
          ),
          Container(width: 1, height: 32, color: CvltureColors.border),
          Expanded(
            child: _Stat(label: "Check-in", value: "$checkins"),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: CvltureColors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: CvltureColors.grey, fontSize: 12)),
      ],
    );
  }
}

/* ══════════════════════════════════════════════════════════
   REGISTRATION TILE
══════════════════════════════════════════════════════════ */

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
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  registration["email"] ?? "",
                  style: const TextStyle(
                      color: CvltureColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (checkedIn)
            /* Badge "Entrato" — grigio scuro, non sembra cliccabile */
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Entrato",
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                        width: 14,
                        height: 14,
                        child: CvltureLoader(size: 14),
                      )
                    : const Text("Valida",
                        style: TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   PAGINAZIONE
══════════════════════════════════════════════════════════ */

class _PaginationBar extends StatelessWidget {
  final int currentPage, totalPages;
  final VoidCallback? onPrev, onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            color: onPrev != null ? Colors.white : CvltureColors.border,
          ),
          Text(
            "${currentPage + 1} / $totalPages",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            color: onNext != null ? Colors.white : CvltureColors.border,
          ),
        ],
      ),
    );
  }
}
