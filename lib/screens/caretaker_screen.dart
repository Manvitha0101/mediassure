// screens/caretaker_screen.dart
// Add, view, edit, and delete caretaker info

import 'package:flutter/material.dart';
import '../models/caretaker_model.dart';
import '../services/caretaker_service.dart';

class CaretakerScreen extends StatelessWidget {
  const CaretakerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caretakerService = CaretakerService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Caretakers',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9334E6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF9334E6),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCaretakerDialog(context, caretakerService),
      ),
      body: StreamBuilder<List<Caretaker>>(
        stream: caretakerService.getCaretakersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final caretakers = snapshot.data ?? [];

          if (caretakers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No caretakers added',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap + to add a caretaker',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: caretakers.length,
            itemBuilder: (context, index) {
              final c = caretakers[index];
              return _CaretakerCard(
                caretaker: c,
                onEdit: () =>
                    _showCaretakerDialog(context, caretakerService,
                        caretaker: c),
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Remove Caretaker?'),
                      content: Text('Remove "${c.name}" from your list?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await caretakerService.deleteCaretaker(c.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Add/Edit Dialog ─────────────────────────────────────────────────────────
  void _showCaretakerDialog(
    BuildContext context,
    CaretakerService service, {
    Caretaker? caretaker,
  }) {
    final isEdit = caretaker != null;
    final nameCtrl = TextEditingController(text: caretaker?.name ?? '');
    final phoneCtrl = TextEditingController(text: caretaker?.phone ?? '');
    final relCtrl =
        TextEditingController(text: caretaker?.relationship ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Caretaker' : 'Add Caretaker'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: relCtrl,
                decoration:
                    const InputDecoration(labelText: 'Relationship'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Relationship is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9334E6),
                foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final newCaretaker = Caretaker(
                id: caretaker?.id ?? '',
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                relationship: relCtrl.text.trim(),
              );

              if (isEdit) {
                await service.updateCaretaker(newCaretaker);
              } else {
                await service.addCaretaker(newCaretaker);
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}

// ─── Caretaker Card ────────────────────────────────────────────────────────────

class _CaretakerCard extends StatelessWidget {
  final Caretaker caretaker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CaretakerCard({
    required this.caretaker,
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
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF9334E6).withOpacity(0.15),
          child: Text(
            caretaker.name.isNotEmpty ? caretaker.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Color(0xFF9334E6), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(caretaker.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📞 ${caretaker.phone}'),
            Text('👤 ${caretaker.relationship}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero)),
          ],
        ),
      ),
    );
  }
}