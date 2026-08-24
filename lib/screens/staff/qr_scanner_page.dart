import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../main.dart';
import '../../widgets/cvlture_loader.dart';
import '../../services/staff_service.dart';

/// Scanner QR per la validazione ingressi.
///
/// Il QR dell'app cliente contiene il "token grezzo" (qr_token),
/// non un URL — vedi cvlture_register_event() in cvlture-api.php,
/// che restituisce 'token' come stringa pura per il QR generato
/// lato app (qr_flutter), non il link di /checkin/?token=... usato
/// invece dal flusso email/browser in cvlture-events.
///
/// Ritorna `true` a Navigator.pop se durante la sessione è stato
/// validato almeno un ingresso, così la pagina precedente sa di
/// dover ricaricare la lista prenotazioni.
class QrScannerPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const QrScannerPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  bool processing = false;
  bool didValidateAny = false;

  // Ultimo esito mostrato nel pannello in basso (null = nessuno ancora)
  bool? lastSuccess;
  String? lastMessage;
  String? lastDetail;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> handleDetection(BarcodeCapture capture) async {
    if (processing) return; // ignora scansioni multiple mentre elaboriamo

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => processing = true);
    await controller.stop();

    try {
      final data = await StaffService.validateCheckin(
        token: rawValue,
        eventId: widget.eventId,
      );

      didValidateAny = true;

      final name  = data["name"]  ?? "";
      final drink = data["drink"] == true;

      if (!mounted) return;
      setState(() {
        lastSuccess = true;
        lastMessage = "Ingresso validato";
        lastDetail  = drink ? "$name  •  drink omaggio" : name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        lastSuccess = false;
        lastMessage = e.toString().replaceAll("Exception: ", "");
        lastDetail  = null;
      });
    }

    if (!mounted) return;
    setState(() => processing = false);

    // Piccola pausa prima di riattivare la fotocamera, per non
    // ri-leggere subito lo stesso QR ancora inquadrato.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.eventTitle.isEmpty ? "Scanner" : widget.eventTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, didValidateAny);
        },
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: handleDetection,
            ),

            // Mirino
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: lastSuccess == null
                        ? CvltureColors.green
                        : (lastSuccess! ? CvltureColors.green : Colors.red),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            if (processing)
              const Center(
                child: CvltureLoader(),
              ),

            // Pannello esito in basso
            if (lastMessage != null)
              Positioned(
                left: 20, right: 20, bottom: 30,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (lastSuccess == true)
                        ? const Color(0xFF0A2A12)
                        : const Color(0xFF2A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (lastSuccess == true)
                          ? CvltureColors.green
                          : const Color(0xFF5C1A1A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        lastSuccess == true
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: lastSuccess == true
                            ? CvltureColors.green
                            : const Color(0xFFFF4444),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastMessage!,
                              style: TextStyle(
                                color: lastSuccess == true
                                    ? CvltureColors.green
                                    : const Color(0xFFFF6666),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (lastDetail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                lastDetail!,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
