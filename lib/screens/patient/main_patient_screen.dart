import 'package:flutter/material.dart';
import '../../widgets/glass_components.dart';

import 'dashboard.dart';
import 'medications.dart';
import 'history.dart';
import 'notifications.dart';
import 'profile.dart';

class MainPatientScreen extends StatefulWidget {
  const MainPatientScreen({super.key});

  @override
  State<MainPatientScreen> createState() => _MainPatientScreenState();
}

class _MainPatientScreenState extends State<MainPatientScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PatientDashboardScreen(),
    PatientMedicationsScreen(),
    PatientHistoryScreen(),
    PatientNotificationsScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the bottom nav
      body: GlassBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 30,
          opacity: 0.1,
          blur: 10,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withOpacity(0.2),
            elevation: 0,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication_rounded, color: Colors.white),
                label: 'Meds',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history_rounded, color: Colors.white),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded, color: Colors.white),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
