import 'package:flutter/material.dart';
import '../services/medicine_service.dart';
import '../models/medicine_model.dart';

class AddMedicineScreen extends StatefulWidget {
  /// The Firestore `patients` document ID this medicine belongs to.
  final String patientId;
  final MedicineModel? medicine; // non-null when editing

  const AddMedicineScreen({
    super.key,
    required this.patientId,
    this.medicine,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController   = TextEditingController();
  final _dosageController = TextEditingController();

  String _selectedFrequency = 'Once daily';
  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Thrice daily',
    'Four times daily'
  ];

  bool _morning   = false;
  bool _afternoon = false;
  bool _night     = false;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;
    if (med != null) {
      _nameController.text   = med.name;
      _dosageController.text = med.dosage;
      _selectedFrequency     = med.frequency;
      _morning   = med.timings.contains('Morning');
      _afternoon = med.timings.contains('Afternoon');
      _night     = med.timings.contains('Night');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _saveMedicine() async {
    final name   = _nameController.text.trim();
    final dosage = _dosageController.text.trim();

    if (name.isEmpty || dosage.isEmpty) {
      _snack('Please fill Medicine Name and Dosage');
      return;
    }

    final timings = <String>[
      if (_morning) 'Morning',
      if (_afternoon) 'Afternoon',
      if (_night) 'Night',
    ];

    if (timings.isEmpty) {
      _snack('Select at least one time schedule');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now     = DateTime.now();
      final service = MedicineService();

      print("Saving medicine for patient: ${widget.patientId}");

      final med = MedicineModel(
        id:        widget.medicine?.id ?? '',
        name:      name,
        dosage:    dosage,
        frequency: _selectedFrequency,
        timings:   timings,
        startDate: widget.medicine?.startDate ?? now,
        endDate:   widget.medicine?.endDate ?? now.add(const Duration(days: 365)), // default to 1 year if new
        patientId: widget.patientId,
        isActive:  true,
        createdAt: widget.medicine?.createdAt ?? now,
      );

      String docId;
      if (widget.medicine == null) {
        docId = await service.addMedicine(med);
        print("Medicine added with ID: $docId");
      } else {
        await service.updateMedicine(med);
        print("Medicine updated: ${med.id}");
      }

      if (mounted) {
        _snack('Medicine saved successfully!');
        Navigator.pop(context, true); // return true to refresh list
      }
    } catch (e) {
      print("Error in _saveMedicine: $e");
      if (mounted) _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          widget.medicine == null ? 'Add Medicine' : 'Edit Medicine',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E6CDB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Medicine Name'),
                  _field(controller: _nameController, hint: 'e.g. Paracetamol'),
                  const SizedBox(height: 20),

                  _label('Dosage'),
                  _field(controller: _dosageController, hint: 'e.g. 500mg'),
                  const SizedBox(height: 20),

                  _label('Frequency'),
                  _frequencyDropdown(),
                  const SizedBox(height: 24),

                  _label('Time Schedule'),
                  const SizedBox(height: 8),
                  _checkbox('Morning',   _morning,   (v) => setState(() => _morning   = v ?? false)),
                  _checkbox('Afternoon', _afternoon, (v) => setState(() => _afternoon = v ?? false)),
                  _checkbox('Night',     _night,     (v) => setState(() => _night     = v ?? false)),
                  const SizedBox(height: 24),

                  _label('Reminder Time'),
                  const SizedBox(height: 8),
                  _reminderRow(),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveMedicine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6CDB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.medicine == null ? 'Save Medicine' : 'Update Medicine',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      );

  Widget _field({required TextEditingController controller, required String hint}) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1E6CDB), width: 1.5),
          ),
        ),
      );

  Widget _frequencyDropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFrequency,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            items: _frequencies
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedFrequency = v);
            },
          ),
        ),
      );

  Widget _checkbox(String title, bool value, ValueChanged<bool?> onChanged) =>
      CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E6CDB),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.trailing,
      );

  Widget _reminderRow() => InkWell(
        onTap: _pickTime,
        child: Row(
          children: [
            const Icon(Icons.alarm, color: Color(0xFF1E6CDB), size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reminderTime.format(context),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Tap to change reminder time',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      );
}