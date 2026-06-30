import 'package:flutter/material.dart';

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
