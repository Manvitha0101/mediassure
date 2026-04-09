import 'package:flutter/material.dart';
import 'package:mediassure/screens/app_theme.dart';

class CaretakerList extends StatelessWidget {
  const CaretakerList({super.key});

  @override
  Widget build(BuildContext context) {
    final caretakers = [
      {"name": "John Doe", "role": "Father"},
      {"name": "Anita Sharma", "role": "Nurse"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: AppDecorations.card(),
        child: Column(
          children: caretakers.map((c) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accentLight,
                child: Text(
                  c["name"]![0],
                  style: const TextStyle(color: AppColors.accent),
                ),
              ),
              title: Text(c["name"]!),
              subtitle: Text(c["role"]!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            );
          }).toList(),
        ),
      ),
    );
  }
}