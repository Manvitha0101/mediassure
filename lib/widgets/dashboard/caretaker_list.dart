import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediassure/screens/app_theme.dart';
import '../../widgets/glass_components.dart';

class CaretakerList extends StatelessWidget {
  const CaretakerList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData || userSnap.data?.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = userSnap.data!.data() as Map<String, dynamic>;
        final caretakerIds = List<String>.from(data['caretakerIds'] ?? []);

        if (caretakerIds.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                "No caretakers connected yet.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // Fetch the details for these caretakers
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: caretakerIds.take(10).toList())
              .get(),
          builder: (context, caretakerSnap) {
            if (!caretakerSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final caretakers = caretakerSnap.data!.docs;

            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: caretakers.map((c) {
                  final cData = c.data() as Map<String, dynamic>;
                  final name = cData['name'] ?? 'Unknown';
                  final role = cData['role'] ?? 'Caretaker';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentLight,
                      child: Text(
                        initial,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: Text(role.toString().toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.check_circle, size: 20, color: Colors.teal),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}