import 'dart:ui';

import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/staff/staff_dashboard_page.dart';
import '../screens/staff/staff_events_page.dart';
import '../screens/staff/staff_profile_page.dart';

class StaffNavigationPage extends StatefulWidget {
  const StaffNavigationPage({super.key});

  @override
  State<StaffNavigationPage> createState() => _StaffNavigationPageState();
}

class _StaffNavigationPageState extends State<StaffNavigationPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    StaffDashboardPage(),
    StaffEventsPage(),
    StaffProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: currentIndex,
        onSelected: (i) => setState(() => currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon:         Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: "Eventi",
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
   GLASS NAVIGATION BAR
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
            color: Color(0xBB0D0D0D),
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
