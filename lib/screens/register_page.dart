import '../widgets/cvlture_loader.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_repository.dart';
import '../pages/main_navigation_page.dart';
import '../widgets/cvlture_logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nomeController      = TextEditingController();
  final cognomeController   = TextEditingController();
  final emailController     = TextEditingController();
  final passwordController  = TextEditingController();
  final confirmController   = TextEditingController();
  final instagramController = TextEditingController();

  DateTime? dataNascita;
  bool loading        = false;
  bool obscurePass    = true;
  bool obscureConfirm = true;
  String? errorMessage;

  @override
  void dispose() {
    nomeController.dispose();
    cognomeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  bool get canRegister =>
      nomeController.text.isNotEmpty &&
      cognomeController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmController.text.isNotEmpty &&
      dataNascita != null;

  String get dataNascitaFormatted {
    if (dataNascita == null) return "";
    return "${dataNascita!.day.toString().padLeft(2, '0')}/"
        "${dataNascita!.month.toString().padLeft(2, '0')}/"
        "${dataNascita!.year}";
  }

  Future<void> pickDataNascita() async {
    final now  = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: "Data di nascita",
      cancelText: "Annulla",
      confirmText: "Conferma",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   CvltureColors.green,
            onPrimary: Colors.black,
            surface:   CvltureColors.surface,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: CvltureColors.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => dataNascita = picked);
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (passwordController.text != confirmController.text) {
      setState(() => errorMessage = "Le password non corrispondono");
      return;
    }
    if (passwordController.text.length < 6) {
      setState(() => errorMessage = "Password minima 6 caratteri");
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      setState(() => errorMessage = "Email non valida");
      return;
    }

    setState(() { loading = true; errorMessage = null; });

    try {
      await AuthRepository.register(
        nome:       nomeController.text.trim(),
        cognome:    cognomeController.text.trim(),
        email:      emailController.text.trim(),
        password:   passwordController.text.trim(),
        dataNascita: dataNascitaFormatted,
        igName:    instagramController.text.trim(),
      );

      await AuthRepository.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
        (_) => false,
      );
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
        child: Column(
          children: [

            /* ---- TOP BAR ---- */
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
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
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CvltureLogo(height: 28),
                      SizedBox(height: 3),
                      Text(
                        "Crea il tuo account",
                        style: TextStyle(
                            color: CvltureColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /* ---- FORM SCROLLABILE ---- */
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ERRORE
                    if (errorMessage != null) ...[
                      _ErrorBox(message: errorMessage!),
                      const SizedBox(height: 20),
                    ],

                    // NOME + COGNOME (affiancati)
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: nomeController,
                            label: "Nome *",
                            icon: Icons.person_outline,
                            capitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: cognomeController,
                            label: "Cognome *",
                            icon: Icons.person_outline,
                            capitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // EMAIL
                    _buildField(
                      controller: emailController,
                      label: "Email *",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    // DATA DI NASCITA
                    GestureDetector(
                      onTap: pickDataNascita,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: CvltureColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: dataNascita != null
                                ? CvltureColors.green
                                : CvltureColors.border,
                            width: dataNascita != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              color: dataNascita != null
                                  ? CvltureColors.green
                                  : const Color(0xFF666666),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              dataNascita != null
                                  ? dataNascitaFormatted
                                  : "Data di nascita *",
                              style: TextStyle(
                                color: dataNascita != null
                                    ? Colors.white
                                    : const Color(0xFF555555),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // PASSWORD
                    _buildPasswordField(
                      controller: passwordController,
                      label: "Password *",
                      obscure: obscurePass,
                      onToggle: () =>
                          setState(() => obscurePass = !obscurePass),
                    ),

                    const SizedBox(height: 14),

                    // CONFERMA PASSWORD
                    _buildPasswordField(
                      controller: confirmController,
                      label: "Conferma password *",
                      obscure: obscureConfirm,
                      onToggle: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),

                    const SizedBox(height: 14),

                    // INSTAGRAM (opzionale)
                    TextField(
                      controller: instagramController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Instagram (opzionale)",
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "@",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                        filled: true,
                        fillColor: CvltureColors.surface,
                      ),
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      "* Campi obbligatori",
                      style: TextStyle(
                          color: Color(0xFF555555), fontSize: 12),
                    ),

                    const SizedBox(height: 28),

                    // BOTTONE
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (!canRegister || loading) ? null : register,
                        child: loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CvltureLoader(size: 22),
                              )
                            : const Text("Crea account",
                                style: TextStyle(fontSize: 17)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LINK LOGIN
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: CvltureColors.grey, fontSize: 14),
                            children: [
                              TextSpan(text: "Hai già un account? "),
                              TextSpan(
                                text: "Accedi",
                                style: TextStyle(
                                  color: CvltureColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  /* ---- HELPERS ---- */

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: CvltureColors.grey,
          ),
        ),
      ),
    );
  }
}

/* ==========================================
   ERROR BOX
========================================== */

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF6666),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
