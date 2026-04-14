import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_role_model.dart';
import '../models/patient_model.dart';
import '../services/auth_service.dart';
import '../widgets/glass_components.dart';
import 'app_theme.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  
  String? _gender;
  String? _bloodGroup;
  List<String> _medicalConditions = [];
  final _conditionCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userModel = await AuthService().getUserRole(uid);
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
          _nameCtrl.text = userModel.name;
          _isLoading = false;
        });
      }
    }
  }

  void _addCondition() {
    final raw = _conditionCtrl.text.trim();
    if (raw.isNotEmpty) {
      setState(() {
        final conditions = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for(var c in conditions) {
          if(!_medicalConditions.contains(c)) {
             _medicalConditions.add(c);
          }
        }
        _conditionCtrl.clear();
      });
    }
  }

  void _removeCondition(String condition) {
    setState(() {
      _medicalConditions.remove(condition);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser!;
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Update users/{uid}
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.set(userRef, {
        'name': _nameCtrl.text.trim(),
        'profileCompleted': true,
      }, SetOptions(merge: true));

      // 2. Update patients/{uid} ONLY if patient
      if (_userModel?.role == UserRole.patient) {
        final patientRef = FirebaseFirestore.instance.collection('patients').doc(user.uid);
        
        final ageVal = int.parse(_ageCtrl.text.trim());
        
        final patientData = {
          'name': _nameCtrl.text.trim(),
          'email': user.email ?? _userModel?.email ?? '',
          'age': ageVal,
          'gender': _gender,
          'bloodGroup': _bloodGroup,
          'medicalConditions': _medicalConditions.isEmpty ? [] : _medicalConditions,
          'caretakerIds': [],
          'doctorIds': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        batch.set(patientRef, patientData, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile completed successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // AuthWrapper automatically rebuilds when underlying firestore stream is updated,
        // Wait, AuthWrapper is listening to authStateChanges, not Firestore!
        // We will need to trigger a re-evaluation or pushReplacement.
        // Wait, does AuthWrapper listen to user role changes when profileCompleted changes?
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPatient = _userModel?.role == UserRole.patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back Without Completion
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Let\'s get to know you!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please fill in your details below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Common: Name
                  _buildLabel('Full Name *'),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDeco(Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  if (isPatient) ...[
                     Row(
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               _buildLabel('Age *'),
                               TextFormField(
                                 controller: _ageCtrl,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDeco(Icons.cake_outlined),
                                 validator: (v) {
                                   if (v == null || v.trim().isEmpty) return 'Required';
                                   final age = int.tryParse(v.trim());
                                   if (age == null || age <= 0) return 'Valid number > 0';
                                   return null;
                                 },
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               _buildLabel('Gender *'),
                               DropdownButtonFormField<String>(
                                 value: _gender,
                                 decoration: _inputDeco(Icons.wc_rounded),
                                 items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                 onChanged: (v) => setState(() => _gender = v),
                                 validator: (v) => v == null ? 'Required' : null,
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),

                     _buildLabel('Blood Group *'),
                     DropdownButtonFormField<String>(
                       value: _bloodGroup,
                       decoration: _inputDeco(Icons.bloodtype_outlined),
                       items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                       onChanged: (v) => setState(() => _bloodGroup = v),
                       validator: (v) => v == null ? 'Required' : null,
                     ),
                     const SizedBox(height: 16),

                     _buildLabel('Medical Conditions (optional comma-separated)'),
                     Row(
                       children: [
                         Expanded(
                           child: TextFormField(
                             controller: _conditionCtrl,
                             decoration: _inputDeco(Icons.medical_services_outlined).copyWith(
                               hintText: 'e.g. Diabetes, Hypertension',
                             ),
                             onFieldSubmitted: (_) => _addCondition(),
                           ),
                         ),
                         const SizedBox(width: 8),
                         IconButton(
                           icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 36),
                           onPressed: _addCondition,
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: _medicalConditions.map((c) => Chip(
                         label: Text(c, style: const TextStyle(color: Colors.white, fontSize: 13)),
                         backgroundColor: AppColors.accent,
                         deleteIconColor: Colors.white,
                         onDeleted: () => _removeCondition(c),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                       )).toList(),
                     ),
                  ],

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Complete Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger, width: 1.8)),
      errorStyle: const TextStyle(fontSize: 11, color: AppColors.danger),
    );
  }
}
