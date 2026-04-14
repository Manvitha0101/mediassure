import 'package:flutter/material.dart';
import 'package:mediassure/widgets/glass_components.dart';
import '../app_theme.dart';

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
  String? _selectedPatientId;
  final GlobalKey<CaretakerPatientsTabState> _patientsTabKey = GlobalKey();

  void _onPatientSelected(String id) {
    setState(() {
      _selectedPatientId = id;
      _currentIndex = 1; // Switch to Medicines tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      CaretakerPatientsTab(
        key: _patientsTabKey,
        onPatientSelected: _onPatientSelected,
      ),
      CaretakerMedicinesTab(patientId: _selectedPatientId),
      const CaretakerAlertsTab(),
      const CaretakerProfileTab(),
    ];

    final titles = [
      'My Patients',
      'Medicine Library',
      'Recent Alerts',
      'Caretaker Profile'
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _patientsTabKey.currentState?.showLinkPatientDialog(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Link Patient',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              elevation: 4,
            )
          : null,
      body: GlassBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
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
