import 'package:flutter/material.dart';
import 'package:mediassure/widgets/glass_components.dart';

import 'tabs/patients_tab.dart';
import 'tabs/medicines_tab.dart';
import 'tabs/alerts_tab.dart';
import 'tabs/profile_tab.dart';

class CaretakerMainScreen extends StatefulWidget {
  const CaretakerMainScreen({super.key});

  @override
  State<CaretakerMainScreen> createState() => _CaretakerMainScreenState();
}

class _CaretakerMainScreenState extends State<CaretakerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CaretakerPatientsTab(),
    CaretakerMedicinesTab(),
    CaretakerAlertsTab(),
    CaretakerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded, color: Colors.white),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication_rounded, color: Colors.white),
                label: 'Medicines',
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
