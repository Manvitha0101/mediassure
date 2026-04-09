import 'package:flutter/material.dart';
import 'package:mediassure/screens/app_theme.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Progress", style: AppTextStyles.headingMedium),
            const SizedBox(height: 10),
            const LinearProgressIndicator(value: 0.6),
            const SizedBox(height: 8),
            Text("3 / 5 medicines taken"),
          ],
        ),
      ),
    );
  }
}