import 'package:flutter/material.dart';
import '../services/medicine_service.dart';
import '../models/medicine_model.dart';
import '../widgets/glass_components.dart';
import 'app_theme.dart';

class AddMedicineScreen extends StatefulWidget {
  final String patientId;
  final MedicineModel? medicine;

  const AddMedicineScreen({
    super.key,
    required this.patientId,
    this.medicine,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController(); // New field from mockup

  bool _morning = false;
  bool _afternoon = false;
  bool _night = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      final med = widget.medicine!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _durationController.text = med.duration?.toString() ?? '';
      _morning = med.timings.contains('Morning');
      _afternoon = med.timings.contains('Afternoon');
      _night = med.timings.contains('Night');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final durationStr = _durationController.text.trim();

    if (name.isEmpty || dosage.isEmpty) {
      _snack('Please fill required fields');
      return;
    }

    final timings = <String>[
      if (_morning) 'Morning',
      if (_afternoon) 'Afternoon',
      if (_night) 'Night',
    ];

    if (timings.isEmpty) {
      _snack('Select early schedule');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final med = MedicineModel(
        id: widget.medicine?.id ?? '',
        name: name,
        dosage: dosage,
        duration: int.tryParse(durationStr),
        frequency: 'Daily',
        timings: timings,
        startDate: widget.medicine?.startDate ?? now,
        endDate: widget.medicine?.endDate ?? now.add(const Duration(days: 365)),
        patientId: widget.patientId,
        isActive: true,
        createdAt: widget.medicine?.createdAt ?? now,
      );

      final service = MedicineService();
      if (widget.medicine == null) {
        await service.addMedicine(med);
      } else {
        await service.updateMedicine(med);
      }

      if (mounted) {
        _snack('Saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'New Medicine',
                        style: AppTextStyles.headingLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // spacer for symmetry
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _sectionLabel('Medicine Name'),
                    _glassField(
                      controller: _nameController,
                      hint: 'e.g. Vitamin D3',
                      icon: Icons.medication_rounded,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Dosage'),
                              _glassField(
                                controller: _dosageController,
                                hint: '1 Pill',
                                icon: Icons.straighten_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Duration'),
                              _glassField(
                                controller: _durationController,
                                hint: '10 Days',
                                icon: Icons.calendar_today_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _sectionLabel('Schedule'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _scheduleItem('Morning', Icons.wb_sunny_outlined, _morning, (v) => setState(() => _morning = v)),
                        _scheduleItem('Afternoon', Icons.wb_cloudy_outlined, _afternoon, (v) => setState(() => _afternoon = v)),
                        _scheduleItem('Night', Icons.dark_mode_outlined, _night, (v) => setState(() => _night = v)),
                      ],
                    ),

                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        text: widget.medicine == null ? 'Add Medicine' : 'Update',
                        onPressed: _isLoading ? () {} : _save,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) =>
      GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _scheduleItem(String title, IconData icon, bool isSelected, Function(bool) onTap) =>
      GestureDetector(
        onTap: () => onTap(!isSelected),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          borderRadius: 20,
          opacity: isSelected ? 0.35 : 0.08,
          child: SizedBox(
            width: 80,
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}