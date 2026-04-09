import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CaretakerDashboard extends StatelessWidget {
  const CaretakerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretaker Dashboard'),
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
        child: Text('Caretaker View - Monitor Patients'),
      ),
    );
  }
}
