import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_medicine_screen.dart';
import 'medicine_list_screen.dart';
import 'prescription_screen.dart';
import 'caretaker_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
const DashboardScreen({super.key});

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;


return Scaffold(
  appBar: AppBar(
    title: const Text('Mediassure'),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
      ),
    ],
  ),
  body: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          'Hello ${user?.email ?? 'User'}',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddMedicineScreen(),
              ),
            );
          },
          child: const Text("Add Medicine"),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MedicineListScreen(),
              ),
            );
          },
          child: const Text("Medicine List"),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrescriptionScreen(),
              ),
            );
          },
          child: const Text("Prescriptions"),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CaretakerScreen(),
              ),
            );
          },
          child: const Text("Caretakers"),
        ),
      ],
    ),
  ),
);

}
}
