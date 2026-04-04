import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _DashboardHeader(
                  greeting: _greeting,
                  onProfileTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: 'Health Overview',
                  actionLabel: 'See all',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: const [
                    _HealthMetricCard(
                      icon: Icons.favorite_rounded,
                      label: 'Heart Rate',
                      value: '78',
                      unit: 'bpm',
                      accentColor: AppColors.heartRed,
                      bgColor: Color(0xFFFFF0F0),
                    ),
                    SizedBox(width: 14),
                    _HealthMetricCard(
                      icon: Icons.water_drop_rounded,
                      label: 'Blood Pressure',
                      value: '120/80',
                      unit: 'mmHg',
                      accentColor: AppColors.bpBlue,
                      bgColor: Color(0xFFF0F5FF),
                    ),
                    SizedBox(width: 14),
                    _HealthMetricCard(
                      icon: Icons.bedtime_rounded,
                      label: 'Sleep',
                      value: '7.4',
                      unit: 'hrs',
                      accentColor: AppColors.sleepPurple,
                      bgColor: Color(0xFFF3F0FF),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(title: 'Weekly Activity'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _ActivityChartPlaceholder(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SectionHeader(
                  title: 'Upcoming Appointments',
                  actionLabel: 'View all',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(const [
                  _AppointmentCard(
                    doctorName: 'Dr. Priya Sharma',
                    specialty: 'Cardiologist',
                    date: 'Mon, 7 Apr',
                    time: '10:30 AM',
                    avatarColor: Color(0xFF0ABFBC),
                    initials: 'PS',
                  ),
                  SizedBox(height: 12),
                  _AppointmentCard(
                    doctorName: 'Dr. Rahul Mehta',
                    specialty: 'General Physician',
                    date: 'Wed, 9 Apr',
                    time: '2:00 PM',
                    avatarColor: Color(0xFF3B82F6),
                    initials: 'RM',
                  ),
                  SizedBox(height: 12),
                  _AppointmentCard(
                    doctorName: 'Dr. Anjali Nair',
                    specialty: 'Neurologist',
                    date: 'Fri, 11 Apr',
                    time: '11:00 AM',
                    avatarColor: Color(0xFF8B7CF6),
                    initials: 'AN',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.greeting,
    required this.onProfileTap,
  });

  final String greeting;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 2),
              Text('Arjun Kapoor 👋', style: AppTextStyles.headingLarge),
            ],
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0ABFBC), Color(0xFF087F7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'AK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: accentColor,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(unit, style: AppTextStyles.labelSmall),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChartPlaceholder extends StatelessWidget {
  const _ActivityChartPlaceholder();

  static const List<_BarData> _bars = [
    _BarData('M', 0.4),
    _BarData('T', 0.65),
    _BarData('W', 0.5),
    _BarData('T', 0.8),
    _BarData('F', 0.55),
    _BarData('S', 0.9),
    _BarData('S', 0.35),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '7-Day Steps',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '↑ 12%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _bars
                .map((bar) =>
                    _Bar(label: bar.label, heightFactor: bar.heightFactor))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  const _BarData(this.label, this.heightFactor);
  final String label;
  final double heightFactor;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.heightFactor});

  final String label;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 72.0 * heightFactor,
          decoration: BoxDecoration(
            color: heightFactor >= 0.8
                ? AppColors.teal
                : AppColors.teal.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.avatarColor,
    required this.initials,
  });

  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final Color avatarColor;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: avatarColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorName, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(specialty, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(time, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}