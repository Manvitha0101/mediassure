// screens/add_medicine_screen.dart
// Form to add a new medicine or edit an existing one.
// Supports: name, dosage, frequency, time schedule, optional image

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';
import '../services/image_picker_service.dart';

class AddMedicineScreen extends StatefulWidget {
  // Pass an existing medicine for edit mode; null = add mode
  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineService = MedicineService();
  final _notificationService = NotificationService();
  final _imagePicker = ImagePickerService();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _dosageController;

  // Dropdown values
  String _selectedFrequency = 'Once daily';
  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'As needed',
  ];

  // Time schedule checkboxes
  final Map<String, bool> _schedule = {
    'Morning': false,
    'Afternoon': false,
    'Night': false,
  };

  // Reminder time (for notification)
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  // Optional medicine image
  File? _selectedImage;

  bool _isLoading = false;
  bool get _isEditMode => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    _nameController =
        TextEditingController(text: widget.medicine?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');

    if (_isEditMode) {
      _selectedFrequency =
          widget.medicine!.frequency.isNotEmpty
              ? widget.medicine!.frequency
              : 'Once daily';
      for (final time in widget.medicine!.timeSchedule) {
        if (_schedule.containsKey(time)) _schedule[time] = true;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  // ── Image picker bottom sheet ───────────────────────────────────────────────
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1A73E8)),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _imagePicker.pickFromCamera();
                if (file != null) setState(() => _selectedImage = file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF34A853)),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await _imagePicker.pickFromGallery();
                if (file != null) setState(() => _selectedImage = file);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Save medicine ───────────────────────────────────────────────────────────
  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    // At least one time slot must be selected
    final selectedTimes = _schedule.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time slot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final medicine = Medicine(
        id: widget.medicine?.id ?? '',
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _selectedFrequency,
        timeSchedule: selectedTimes,
      );

      if (_isEditMode) {
        await _medicineService.updateMedicine(medicine);
      } else {
        await _medicineService.addMedicine(medicine);
      }

      // Schedule a daily notification for the reminder time
      await _notificationService.scheduleDailyReminder(
        id: medicine.name.hashCode,
        medicineName: medicine.name,
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Medicine updated!'
                : 'Medicine added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Medicine' : 'Add Medicine',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name field ─────────────────────────────────────────────────
              _SectionLabel('Medicine Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Paracetamol'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Dosage field ───────────────────────────────────────────────
              _SectionLabel('Dosage'),
              TextFormField(
                controller: _dosageController,
                decoration: _inputDecoration('e.g. 500mg'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Frequency dropdown ─────────────────────────────────────────
              _SectionLabel('Frequency'),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: _inputDecoration(''),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedFrequency = val!),
              ),
              const SizedBox(height: 16),

              // ── Time schedule checkboxes ───────────────────────────────────
              _SectionLabel('Time Schedule'),
              ..._schedule.keys.map(
                (time) => CheckboxListTile(
                  title: Text(time),
                  value: _schedule[time],
                  activeColor: const Color(0xFF1A73E8),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) =>
                      setState(() => _schedule[time] = val!),
                ),
              ),
              const SizedBox(height: 16),

              // ── Reminder time picker ───────────────────────────────────────
              _SectionLabel('Reminder Time'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm, color: Color(0xFF1A73E8)),
                title: Text(
                  _reminderTime.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Tap to change reminder time'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) setState(() => _reminderTime = picked);
                },
              ),
              const Divider(),
              const SizedBox(height: 8),

              // ── Optional medicine image ────────────────────────────────────
              _SectionLabel('Medicine Image (Optional)'),
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add image',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Save button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode ? 'Update Medicine' : 'Add Medicine',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: consistent input decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
      ),
    );
  }
}

// Small section label widget
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
    );
  }
}