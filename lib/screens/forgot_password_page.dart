import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_repository.dart';
import '../widgets/cvlture_loader.dart';
import '../widgets/cvlture_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;
  bool sent    = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendReset() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => errorMessage = "Inserisci il tuo indirizzo email");
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => errorMessage = "Email non valida");
      return;
    }

    setState(() { loading = true; errorMessage = null; });

    try {
      await AuthRepository.sendPasswordReset(email: email);
      if (!mounted) return;
      setState(() { sent = true; loading = false; });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /* BACK */
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CvltureColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CvltureColors.border),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),

              const SizedBox(height: 32),
              const CvltureLogo(height: 52),
              const SizedBox(height: 10),
              const Text(
                "Recupera password",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Inserisci la tua email e ti manderemo un link per reimpostare la password.",
                style: TextStyle(color: CvltureColors.grey, height: 1.5),
              ),

              const SizedBox(height: 32),

              if (sent) ...[
                /* SUCCESSO */
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CvltureColors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: CvltureColors.green.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          color: CvltureColors.green, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        "Email inviata",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Se l'indirizzo ${emailController.text.trim()} è registrato, "
                        "riceverai le istruzioni per reimpostare la password.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: CvltureColors.grey, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CvltureColors.green,
                      side: const BorderSide(color: CvltureColors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Torna al login"),
                  ),
                ),
              ] else ...[
                /* FORM */
                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A0A0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5C1A1A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFFF4444), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(errorMessage!,
                              style: const TextStyle(
                                  color: Color(0xFFFF6666),
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendReset,
                    child: loading
                        ? const CvltureLoader(size: 22)
                        : const Text("Invia link di recupero",
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
