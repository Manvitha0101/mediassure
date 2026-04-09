// screens/medicine_list_screen.dart
// Displays all saved medicines in a live-updating list.
// Allows edit and delete per item.

import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/medicine_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_medicine_screen.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicineService = MedicineService();
    final patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Medicines',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // FAB to add new medicine
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
        ),
      ),
      body: StreamBuilder<List<Medicine>>(
        stream: medicineService.getMedicinesStream(patientId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final medicines = snapshot.data ?? [];

          // Empty state
          if (medicines.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No medicines added yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap + to add your first medicine',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Medicine cards
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final med = medicines[index];
              return _MedicineCard(
                medicine: med,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddMedicineScreen(medicine: med)),
                ),
                onDelete: () async {
                  // Confirm before delete
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Medicine?'),
                      content: Text('Remove "${med.name}" from your list?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await medicineService.deleteMedicine(patientId, med.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Medicine Card Widget ──────────────────────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.medication, color: Color(0xFF1A73E8)),
        ),
        title: Text(
          medicine.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Dosage: ${medicine.dosage}',
                style: const TextStyle(fontSize: 13)),
            Text('Schedule: ${medicine.timings.join(", ")}',
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF1A73E8))),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }
}