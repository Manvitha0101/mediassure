import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/prescription_model.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;

  const AddPrescriptionScreen({super.key, required this.patientId});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _medicineController = TextEditingController();

  List<String> _medicines = [];
  String? _selectedDoctorId;
  List<Map<String, String>> _linkedDoctors = [];
  bool _isLoadingDoctors = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedDoctors();
  }

  Future<void> _loadLinkedDoctors() async {
    try {
      final pDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (!pDoc.exists) return;

      final doctorIds = List<String>.from(pDoc.data()?['doctorIds'] ?? []);
      final List<Map<String, String>> doctors = [];

      for (var id in doctorIds) {
        final docRef = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (docRef.exists) {
          final data = docRef.data();
          if (data != null) {
            doctors.add({
              'id': id,
              'name': data['name'] ?? 'Unknown Doctor',
            });
          }
        }
      }

      setState(() {
        _linkedDoctors = doctors;
        if (_linkedDoctors.isNotEmpty) {
          _selectedDoctorId = _linkedDoctors.first['id'];
        }
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
    }
  }

  void _addMedicine() {
    final med = _medicineController.text.trim();
    if (med.isNotEmpty && !_medicines.contains(med)) {
      setState(() {
        _medicines.add(med);
        _medicineController.clear();
      });
    }
  }

  void _removeMedicine(String med) {
    setState(() {
      _medicines.remove(med);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor.')),
      );
      return;
    }
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('prescriptions').doc();
      final prescription = Prescription(
        id: docRef.id,
        patientId: widget.patientId,
        doctorId: _selectedDoctorId!,
        imageUrl: '', // Text-only flow
        imageCaptured: false,
        uploadedAt: DateTime.now().toIso8601String(),
        note: _noteController.text.trim(),
        medicines: _medicines,
      );

      await docRef.set(prescription.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Prescription', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Doctor', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (_isLoadingDoctors)
                    const CircularProgressIndicator()
                  else if (_linkedDoctors.isEmpty)
                    const Text('No doctors linked to this patient. Please link a doctor first.', style: TextStyle(color: AppColors.danger))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      decoration: _inputDecoration(),
                      items: _linkedDoctors.map((doc) {
                        return DropdownMenuItem(
                          value: doc['id'],
                          child: Text(doc['name']!),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDoctorId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Note (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: _inputDecoration(hint: 'e.g. Take with food'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Medicines', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _medicineController,
                          decoration: _inputDecoration(hint: 'Medicine name & dosage'),
                          onFieldSubmitted: (_) => _addMedicine(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addMedicine,
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_medicines.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _medicines.map((m) {
                        return Chip(
                          label: Text(m, style: const TextStyle(fontSize: 13)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeMedicine(m),
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: GradientButton(
                      text: _isSaving ? 'Saving...' : 'Save Prescription',
                      onPressed: _isSaving ? () {} : _savePrescription,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
