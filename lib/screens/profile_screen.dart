import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text("Health Details", style: AppTextStyles.headingMedium),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: _HealthDetailsGrid(),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Text("My Health", style: AppTextStyles.headingMedium),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              child: _ProfileMenuList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent], // ✅ FIXED
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: Colors.white),
                ],
              ),
              const SizedBox(height: 24),
              const _ProfileAvatar(),
              const SizedBox(height: 16),
              Text(
                'Arjun Kapoor',
                style: AppTextStyles.headingLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'arjun.kapoor@gmail.com',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.primary],
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'AK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
        ),
      ],
    );
  }
}

class _HealthDetailsGrid extends StatelessWidget {
  const _HealthDetailsGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      ("Age", "28 yrs", Icons.cake),
      ("Blood", "O+", Icons.water_drop),
      ("Height", "175 cm", Icons.height),
      ("Weight", "72 kg", Icons.monitor_weight),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (_, i) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card(),
          child: Row(
            children: [
              Icon(items[i].$3, color: AppColors.accent),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(items[i].$1, style: AppTextStyles.bodySmall),
                  Text(items[i].$2, style: AppTextStyles.bodyMedium),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ("Medical Records", Icons.description),
      ("Prescriptions", Icons.medication),
      ("Notifications", Icons.notifications),
      ("Privacy", Icons.lock),
    ];

    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: Icon(item.$2, color: AppColors.accent),
            title: Text(item.$1),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        }).toList(),
      ),
    );
  }
}