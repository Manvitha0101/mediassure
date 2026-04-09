import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen())
                );
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Doctor View - Escalations Only'),
      ),
    );
  }
}
