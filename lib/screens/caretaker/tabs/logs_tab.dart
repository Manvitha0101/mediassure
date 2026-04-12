import 'package:flutter/material.dart';

class CaretakerLogsTab extends StatelessWidget {
  const CaretakerLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Logs (Coming Soon)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
