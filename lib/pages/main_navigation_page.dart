import 'dart:ui';

import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/events_page.dart';
import '../screens/my_tickets_page.dart';
import '../screens/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() =>
      _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    EventsPage(),
    MyTicketsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,   // body scorre sotto la navbar trasparente
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: currentIndex,
        onSelected: (i) => setState(() => currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: "Eventi",
          ),
          NavigationDestination(
            icon:         Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: "Biglietti",
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profilo",
          ),
        ],
      ),
    );
  }
}

/* ══════════════════════════════════════════════════════════
   GLASS NAVIGATION BAR — effetto vetro opaco stile iOS
══════════════════════════════════════════════════════════ */

class _GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  const _GlassNavBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xBB0D0D0D),          // nero 73% opacità
            border: Border(
              top: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            indicatorColor: CvltureColors.green.withOpacity(0.15),
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
