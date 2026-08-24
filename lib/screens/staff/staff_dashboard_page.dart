import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/staff_service.dart';
import '../../widgets/cvlture_loader.dart';
import '../../widgets/cvlture_logo.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  bool loading = true;
  Map<String, dynamic> stats = {};
  String? errorMessage;

  static const _mesi = [
    'Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno',
    'Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'
  ];

  static String _currentMonthLabel() {
    final now = DateTime.now();
    return 'Eventi ${_mesi[now.month - 1]}';
  }

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final data = await StaffService.getDashboard();
      if (!mounted) return;
      setState(() { stats = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: CvltureColors.green,
          backgroundColor: CvltureColors.surface,
          onRefresh: loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const CvltureLogo(height: 20),
              const SizedBox(height: 6),
              const Text(
                "Dashboard Staff",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CvltureLoader()),
                )
              else if (errorMessage != null)
                _ErrorBox(message: errorMessage!, onRetry: loadDashboard)
              else ...[
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      label: _currentMonthLabel(),
                      value: "${stats['month_events'] ?? 0}",
                      icon: Icons.calendar_month_outlined,
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: _StatCard(
                      label: "Eventi attivi",
                      value: "${stats['active_events'] ?? 0}",
                      icon: Icons.event_outlined,
                    )),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      label: "RSVP totali",
                      value: "${stats['total_registrations'] ?? 0}",
                      icon: Icons.people_outline,
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: _StatCard(
                      label: "Check-in fatti",
                      value: "${stats['total_checkins'] ?? 0}",
                      icon: Icons.qr_code_scanner_outlined,
                    )),
                  ],
                ),
                const SizedBox(height: 14),
                _StatCard(
                  label: "Tasso di ingresso",
                  value: "${stats['entry_rate'] ?? 0}%",
                  icon: Icons.percent_outlined,
                  fullWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   STAT CARD
══════════════════════════════════════════════════════════════ */

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CvltureColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CvltureColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CvltureColors.green, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: CvltureColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════════
   ERROR BOX
══════════════════════════════════════════════════════════════ */

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5C1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Color(0xFFFF6666), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text("Riprova",
                style: TextStyle(color: CvltureColors.green)),
          ),
        ],
      ),
    );
  }
}
