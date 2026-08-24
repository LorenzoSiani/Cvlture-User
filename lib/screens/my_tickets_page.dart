import '../widgets/cvlture_loader.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart';
import '../services/events_service.dart';
import '../widgets/cvlture_logo.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  bool loading = true;
  List tickets = [];

  @override
  void initState() {
    super.initState();
    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      final data = await EventsService.getMyRegistrations();
      if (!mounted) return;
      setState(() { tickets = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CvltureLogo(height: 20),
                  SizedBox(height: 6),
                  Text(
                    "I miei biglietti",
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
                      child: CvltureLoader(),
                    )
                  : RefreshIndicator(
                      color: CvltureColors.green,
                      onRefresh: loadTickets,
                      child: tickets.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: tickets.length,
                              itemBuilder: (context, index) =>
                                  _buildTicketCard(tickets[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CvltureColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CvltureColors.border),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              size: 38,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Nessun biglietto",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Iscriviti a un evento per\nvedere il biglietto qui",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF444444), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map ticket) {
    final checkedIn = ticket["checked_in"] == true;
    final token     = ticket["token"]?.toString() ?? "";

    return GestureDetector(
      onTap: () => _showTicketModal(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: CvltureColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: checkedIn ? CvltureColors.border : CvltureColors.green.withOpacity(0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [

            /* IMMAGINE */
            if (ticket["image"] != null)
              Image.network(
                ticket["image"],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _miniPlaceholder(),
              )
            else
              _miniPlaceholder(),

            /* TRATTEGGIO DIVISORE */
            Row(
              children: List.generate(
                40,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    color: i.isOdd ? Colors.transparent : CvltureColors.border,
                  ),
                ),
              ),
            ),

            /* INFO + QR */
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket["title"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _miniInfo(Icons.calendar_today,
                            "${ticket["date"]} • ${ticket["time"]}"),
                        const SizedBox(height: 3),
                        _miniInfo(Icons.location_on, ticket["location"] ?? ""),
                        const SizedBox(height: 10),

                        // BADGE STATUS
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: checkedIn
                                ? const Color(0xFF1A2A1A)
                                : CvltureColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: checkedIn
                                  ? const Color(0xFF2A4A2A)
                                  : CvltureColors.green.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            checkedIn ? "✓ Già utilizzato" : "● Biglietto valido",
                            style: TextStyle(
                              color: checkedIn
                                  ? const Color(0xFF4CAF50)
                                  : CvltureColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // QR PREVIEW
                  if (token.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: checkedIn
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0, 0, 0, 0.5, 0,
                              ]),
                              child: QrImageView(data: token, size: 72),
                            )
                          : QrImageView(data: token, size: 72),
                    ),
                ],
              ),
            ),

            // HINT
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CvltureColors.border)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 13, color: Color(0xFF444444)),
                  SizedBox(width: 6),
                  Text(
                    "Tocca per aprire il biglietto",
                    style: TextStyle(fontSize: 11, color: Color(0xFF444444)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      height: 70,
      color: const Color(0xFF111111),
      child: const Center(
        child: Text(
          "CVLTURE",
          style: TextStyle(
            color: CvltureColors.green,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: CvltureColors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: CvltureColors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /* ==========================================
     MODAL BIGLIETTO FULLSCREEN
  ========================================== */

  void _showTicketModal(Map ticket) {
    final token     = ticket["token"]?.toString() ?? "";
    final checkedIn = ticket["checked_in"] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: CvltureColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // HANDLE
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CvltureColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // TITOLO
            Text(
              ticket["title"] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${ticket["date"]} • ${ticket["time"]}",
              style: const TextStyle(color: CvltureColors.grey),
            ),
            Text(
              ticket["location"] ?? "",
              style: const TextStyle(color: CvltureColors.grey),
            ),

            const SizedBox(height: 28),

            // QR GRANDE
            if (token.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: checkedIn
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 0.4, 0,
                        ]),
                        child: QrImageView(data: token, size: 200),
                      )
                    : QrImageView(data: token, size: 200),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: checkedIn
                      ? const Color(0xFF1A2A1A)
                      : CvltureColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: checkedIn
                        ? const Color(0xFF2A4A2A)
                        : CvltureColors.green.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  checkedIn
                      ? "✓ Biglietto già utilizzato"
                      : "Mostra questo QR all'ingresso",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: checkedIn
                        ? const Color(0xFF4CAF50)
                        : CvltureColors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
