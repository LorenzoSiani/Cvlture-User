import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/main_navigation_page.dart';
import 'screens/login_page.dart';
import 'services/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CvltureUserApp());
}

// Colori globali del brand
class CvltureColors {
  static const background = Color(0xFF0D0D0D);
  static const surface    = Color(0xFF1A1A1A);
  static const border     = Color(0xFF2D2D2D);
  static const green      = Color(0xFF00FF49);
  static const white      = Colors.white;
  static const grey       = Color(0xFF888888);
}

class CvltureUserApp extends StatelessWidget {
  const CvltureUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CVLTURE',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CvltureColors.background,
        colorScheme: ColorScheme.dark(
          primary:    CvltureColors.green,
          surface:    CvltureColors.surface,
          onPrimary:  Colors.black,
          onSurface:  Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: CvltureColors.surface,
          indicatorColor: CvltureColors.green.withOpacity(0.15),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: CvltureColors.green);
            }
            return const IconThemeData(color: Color(0xFF666666));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: CvltureColors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return const TextStyle(color: Color(0xFF666666), fontSize: 12);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CvltureColors.surface,
          hintStyle: const TextStyle(color: Color(0xFF555555)),
          labelStyle: const TextStyle(color: Color(0xFF888888)),
          prefixIconColor: const Color(0xFF666666),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CvltureColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CvltureColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CvltureColors.green, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CvltureColors.green,
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF1F3A25),
            disabledForegroundColor: const Color(0xFF3D7A4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: CvltureColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        dividerColor: CvltureColors.border,
        appBarTheme: const AppBarTheme(
          backgroundColor: CvltureColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/* ==========================================
   AUTH GATE
========================================== */

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool logged  = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final isLogged = await AuthRepository.isLoggedIn();
    if (!mounted) return;
    setState(() {
      logged  = isLogged;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: CvltureColors.green),
        ),
      );
    }
    return logged ? const MainNavigationPage() : const LoginPage();
  }
}
