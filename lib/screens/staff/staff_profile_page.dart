import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_repository.dart';
import '../../widgets/cvlture_logo.dart';
import '../login_page.dart';

/// Profilo per account staff: solo identità + logout.
/// Non riusa ProfilePage (cliente) perché quella mostra anche
/// "I miei biglietti", una sezione che non ha senso per lo staff.
class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key});

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  String name = "";
  String email = "";
  bool canManageEvents = false;
  bool canValidateCheckin = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final n = await AuthRepository.getUserDisplayName();
    final e = await AuthRepository.getUserEmail();
    final manage = await AuthRepository.canManageEvents();
    final checkin = await AuthRepository.canValidateCheckin();
    if (!mounted) return;
    setState(() {
      name = n;
      email = e;
      canManageEvents = manage;
      canValidateCheckin = checkin;
    });
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
            child: const Text("Annulla", style: TextStyle(color: CvltureColors.grey)),
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const CvltureLogo(height: 15),
            const SizedBox(height: 6),
            const Text(
              "Profilo",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CvltureColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CvltureColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                      color: CvltureColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_outlined, color: CvltureColors.green),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(color: CvltureColors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Permessi", style: TextStyle(color: CvltureColors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            _PermissionRow(label: "Gestione eventi", granted: canManageEvents),
            _PermissionRow(label: "Validazione ingressi", granted: canValidateCheckin),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4444),
                  side: const BorderSide(color: Color(0xFF5C1A1A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text("Esci"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool granted;
  const _PermissionRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel_outlined,
            color: granted ? CvltureColors.green : CvltureColors.grey,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
