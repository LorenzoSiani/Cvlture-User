import 'package:flutter/material.dart';

import '../screens/staff/staff_dashboard_page.dart';
import '../screens/staff/staff_events_page.dart';
import '../screens/staff/staff_profile_page.dart';

/// Bottom navigation per gli account staff.
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
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) =>
            setState(() => currentIndex = index),
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
