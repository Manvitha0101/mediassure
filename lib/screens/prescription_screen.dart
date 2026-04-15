// screens/prescription_screen.dart
// Upload and view prescription images.
// Uploads to Firebase Storage, metadata stored in Firestore.

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../services/prescription_service.dart';
import '../services/image_picker_service.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _prescriptionService = PrescriptionService();
  final _imagePicker = ImagePickerService();
  // ignore: unused_field
  bool _isUploading = false;

  // Show camera/gallery picker, then upload
  void _addPrescription() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Prescription',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Color(0xFFFA7B17)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _imagePicker.pickFromCamera();
                if (file != null) _uploadFile(file);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFFA7B17)),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _imagePicker.pickFromGallery();
                if (file != null) _uploadFile(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _isUploading = true);
    try {
      await _prescriptionService.uploadPrescription(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Prescription record saved!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Capture failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Prescriptions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFA7B17),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFA7B17),
        child: const Icon(Icons.upload, color: Colors.white),
        onPressed: _addPrescription,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Prescription>>(
            stream: _prescriptionService.getPrescriptionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final prescriptions = snapshot.data ?? [];

              if (prescriptions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No prescriptions uploaded',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Tap + to upload a prescription',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              // Grid of prescription images
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: prescriptions.length,
                itemBuilder: (context, index) {
                  final p = prescriptions[index];
                  return _PrescriptionCard(
                    prescription: p,
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Prescription?'),
                          content: const Text(
                              'This will remove the prescription record.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _prescriptionService
                            .deletePrescription(p.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Prescription Card ─────────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onDelete;

  const _PrescriptionCard(
      {required this.prescription, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: prescription.imageUrl.isEmpty 
              ? Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, color: Colors.green, size: 40),
                        SizedBox(height: 8),
                        Text('Image Verified', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : Image.network(
                  prescription.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
        ),
        // Delete button overlay
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Date label
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
            ),
            child: Text(
              prescription.uploadedAt.substring(0, 10),
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}