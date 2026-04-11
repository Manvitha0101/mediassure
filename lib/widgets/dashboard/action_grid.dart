import 'package:flutter/material.dart';
import '../../screens/app_theme.dart';
import '../../screens/add_medicine_screen.dart';
import '../../screens/medicine_list_screen.dart';
import '../../screens/prescription_screen.dart';
import '../../screens/caretaker_screen.dart';

// ─── Action Item definition ───────────────────────────────────────────────────

class _ActionItem {
  const _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.destination,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Widget destination;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key, required this.patientId});

  final String patientId;

  List<_ActionItem> _getActions() => [
    _ActionItem(
      title: 'Add Medicine',
      icon: Icons.add_circle_rounded,
      color: AppColors.primary,
      bgColor: AppColors.primaryLight,
      destination: AddMedicineScreen(patientId: patientId),
    ),
    _ActionItem(
      title: 'Medicine List',
      icon: Icons.format_list_bulleted_rounded,
      color: AppColors.accent,
      bgColor: AppColors.accentLight,
      destination: const MedicineListScreen(),
    ),
    _ActionItem(
      title: 'Prescriptions',
      icon: Icons.description_rounded,
      color: AppColors.warning,
      bgColor: AppColors.warningLight,
      destination: const PrescriptionScreen(),
    ),
    _ActionItem(
      title: 'Caretakers',
      icon: Icons.people_alt_rounded,
      color: AppColors.danger,
      bgColor: AppColors.dangerLight,
      destination: const CaretakerScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _getActions();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
        children: actions
            .map((item) => _ActionCard(item: item))
            .toList(),
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});
  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.destination),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconBadge(icon: item.icon, color: item.color, bgColor: item.bgColor),
            _CardLabel(title: item.title, color: item.color),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: AppDecorations.iconBadge(color: bgColor),
        child: Icon(icon, color: color, size: 22),
      );
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Open',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 12, color: color),
            ],
          ),
        ],
      );
}