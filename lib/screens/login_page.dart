import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_repository.dart';
import '../pages/main_navigation_page.dart';
import '../widgets/cvlture_logo.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  bool loading         = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get canLogin =>
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty;

  Future<void> login() async {
    FocusScope.of(context).unfocus();
    setState(() { loading = true; errorMessage = null; });

    try {
      await AuthRepository.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }

    if (!mounted) return;
    setState(() => loading = false);
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

              /* ---- LOGO ---- */
              const SizedBox(height: 60),
              const CvltureLogo(height: 42),
              const SizedBox(height: 10),
              const Text(
                "Accedi al tuo account",
                style: TextStyle(
                  color: CvltureColors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 48),

              /* ---- ERRORE ---- */
              if (errorMessage != null) ...[
                _ErrorBox(message: errorMessage!),
                const SizedBox(height: 20),
              ],

              /* ---- CAMPI ---- */
              TextField(
                controller: emailController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email o username",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      obscurePassword = !obscurePassword;
                    }),
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: CvltureColors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /* ---- BOTTONE ---- */
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (!canLogin || loading) ? null : login,
                  child: loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Text("Accedi",
                          style: TextStyle(fontSize: 17)),
                ),
              ),

              const SizedBox(height: 28),

              /* ---- LINK REGISTRAZIONE ---- */
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: CvltureColors.grey,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: "Non hai un account? "),
                        TextSpan(
                          text: "Registrati",
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
    );
  }
}

/* ==========================================
   ERROR BOX WIDGET
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
