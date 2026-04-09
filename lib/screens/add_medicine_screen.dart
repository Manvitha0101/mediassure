import 'package:flutter/material.dart';
import '../services/medicine_service.dart';
import '../models/medicine_model.dart';
import '../services/auth_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  String _selectedFrequency = 'Once daily';
  final List<String> _frequencies = ['Once daily', 'Twice daily', 'Thrice daily', 'Four times daily'];

  bool _morning = false;
  bool _afternoon = false;
  bool _night = false;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _dosageController.text = widget.medicine!.dosage;
      
      _morning = widget.medicine!.timings.contains('Morning');
      _afternoon = widget.medicine!.timings.contains('Afternoon');
      _night = widget.medicine!.timings.contains('Night');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_morning && !_afternoon && !_night) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time schedule')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = AuthService().currentUserId;
      if (uid == null) throw Exception("User not logged in");

      List<String> timings = [];
      if (_morning) timings.add("Morning");
      if (_afternoon) timings.add("Afternoon");
      if (_night) timings.add("Night");

      // We add the exact picked time format as well
      String timeString = _reminderTime.format(context);
      if (!timings.contains(timeString)) {
         timings.add("($timeString)");
      }

      final med = Medicine(
        id: widget.medicine?.id ?? '', // Firestore generates this if empty
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        timings: timings,
        startDate: widget.medicine?.startDate ?? DateTime.now(),
        // Simple default of 30 days based on their requirements
        endDate: widget.medicine?.endDate ?? DateTime.now().add(const Duration(days: 30)),
      );

      if (widget.medicine == null) {
        await MedicineService().addMedicine(uid, med);
      } else {
        await MedicineService().updateMedicine(uid, med);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Add Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E6CDB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Medicine Name'),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Paracetamol',
            ),
            const SizedBox(height: 20),

            _buildLabel('Dosage'),
            _buildTextField(
              controller: _dosageController,
              hint: 'e.g. 500mg',
            ),
            const SizedBox(height: 20),

            _buildLabel('Frequency'),
            Container(
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
                  items: _frequencies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFrequency = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Time Schedule'),
            const SizedBox(height: 8),
            _buildCheckbox('Morning', _morning, (val) => setState(() => _morning = val ?? false)),
            _buildCheckbox('Afternoon', _afternoon, (val) => setState(() => _afternoon = val ?? false)),
            _buildCheckbox('Night', _night, (val) => setState(() => _night = val ?? false)),
            const SizedBox(height: 24),

            _buildLabel('Reminder Time'),
            const SizedBox(height: 8),
            InkWell(
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to change reminder time',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            _buildLabel('Medicine Image (Optional)'),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50), // Spacer
            
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
                child: const Text('Save Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E6CDB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.grey.shade400,
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E6CDB),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}