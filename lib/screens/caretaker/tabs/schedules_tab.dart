import 'package:flutter/material.dart';

class CaretakerSchedulesTab extends StatelessWidget {
  const CaretakerSchedulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Schedules (Coming Soon)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
