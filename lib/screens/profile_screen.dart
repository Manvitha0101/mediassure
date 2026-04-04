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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: SectionHeader(title: 'Health Details'),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: _HealthDetailsGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: SectionHeader(title: 'My Health'),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF1A3A5C)],
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
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
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
                  color: Colors.white.withOpacity(0.55),
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
              colors: [Color(0xFF0ABFBC), Color(0xFF087F7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 3,
            ),
          ),
          child: const Center(
            child: Text(
              'AK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.navy, width: 2),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 12,
          ),
        ),
      ],
    );
  }
}

class _HealthDetailsGrid extends StatelessWidget {
  const _HealthDetailsGrid();

  static const List<_DetailItem> _items = [
    _DetailItem(label: 'Age', value: '28 yrs', icon: Icons.cake_outlined),
    _DetailItem(
        label: 'Blood Group', value: 'O+', icon: Icons.opacity_rounded),
    _DetailItem(label: 'Height', value: '175 cm', icon: Icons.height_rounded),
    _DetailItem(
        label: 'Weight',
        value: '72 kg',
        icon: Icons.monitor_weight_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.8,
      children: _items.map((item) => _DetailTile(item: item)).toList(),
    );
  }
}

class _DetailItem {
  const _DetailItem(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.item});

  final _DetailItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuList extends StatelessWidget {
  _ProfileMenuList();

  final List<_MenuEntry> _entries = const [
    _MenuEntry(
      icon: Icons.description_outlined,
      label: 'Medical Records',
      subtitle: '12 documents',
      iconBg: Color(0xFFF0F5FF),
      iconColor: AppColors.bpBlue,
    ),
    _MenuEntry(
      icon: Icons.medication_outlined,
      label: 'Prescriptions',
      subtitle: '3 active',
      iconBg: Color(0xFFF3F0FF),
      iconColor: AppColors.sleepPurple,
    ),
    _MenuEntry(
      icon: Icons.notifications_outlined,
      label: 'Notifications',
      subtitle: '5 unread',
      iconBg: Color(0xFFFFF0F0),
      iconColor: AppColors.heartRed,
    ),
    _MenuEntry(
      icon: Icons.lock_outline_rounded,
      label: 'Privacy & Security',
      subtitle: 'Manage settings',
      iconBg: Color(0xFFE0F7F7),
      iconColor: AppColors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(_entries.length, (index) {
          final isLast = index == _entries.length - 1;
          return Column(
            children: [
              _MenuTile(entry: _entries[index]),
              if (!isLast)
                const Divider(
                    height: 1, indent: 72, color: AppColors.divider),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: entry.iconBg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(entry.icon, color: entry.iconColor, size: 22),
      ),
      title: Text(entry.label, style: AppTextStyles.bodyLarge),
      subtitle: Text(entry.subtitle, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
    );
  }
}