import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/medicine_service.dart';
import '../services/adherence_service.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine_model.dart';
import '../models/adherence_log_model.dart';
import 'add_medicine_screen.dart';
import 'login_screen.dart';
import 'prescription_screen.dart';

class DashColors {
  static const bg = Color(0xFF161517);
  static const surface = Color(0xFF282729);
  static const primaryText = Colors.white;
  static const secondaryText = Color(0xFFA09FA4);
  static const accent = Color(0xFFD97971);
  static const accentLight = Color(0xFF4A3432); 
  static const cardIconBg = Color(0xFF3B383A);
  static const fabBg = Color(0xFF7A4A43);
  static const taken = Color(0xFF81C784);
  static const missed = Color(0xFFE57373);
}

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String? _userName;
  String? _uid;
  bool _isUploadingAdherence = false;

  final MedicineService _medService = MedicineService();
  final AdherenceService _adhService = AdherenceService();

  @override
  void initState() {
    super.initState();
    _uid = AuthService().currentUserId;
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (_uid != null) {
      final user = await AuthService().getUserRole(_uid!);
      if (mounted && user != null) {
        setState(() {
          _userName = user.name;
        });
      }
    }
  }

  Future<void> _markAsTakenWithImage(MedicineModel med, String scheduledTime) async {
    if (_uid == null) return;
    
    // 1. Open camera
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image required to mark as taken'),
            backgroundColor: DashColors.missed,
          ),
        );
      }
      return; // Do NOT proceed
    }

    setState(() => _isUploadingAdherence = true);

    try {
      await _adhService.logAdherenceStrict(
        patientId: _uid!,
        medicineId: med.id,
        scheduledTime: scheduledTime,
        photoFile: File(pickedFile.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged as Taken successfully!'),
            backgroundColor: DashColors.taken,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save log: $e'),
            backgroundColor: DashColors.missed,
          ),
        );
      }
      debugPrint("Error logging adherence: $e");
    } finally {
      if (mounted) {
        setState(() => _isUploadingAdherence = false);
      }
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        backgroundColor: DashColors.bg,
        body: const Center(child: CircularProgressIndicator(color: DashColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: DashColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDateTimeline(),
                  const SizedBox(height: 24),
                  const Divider(color: DashColors.surface, thickness: 1, height: 1),
                  const SizedBox(height: 16),
                  _buildWelcomeMessage(),
                  const SizedBox(height: 16),
                  
                  // Streams for live data
                  StreamBuilder<List<MedicineModel>>(
                    stream: _medService.getMedicinesStream(_uid!),
                    builder: (context, medSnapshot) {
                      return StreamBuilder<List<AdherenceLogModel>>(
                        stream: _adhService.getRecentLogs(_uid!),
                        builder: (context, logSnapshot) {
                          
                          final meds = medSnapshot.data ?? [];
                          final logs = logSnapshot.data ?? [];

                          // Analyze data
                          final todayMeds = meds.where((m) {
                            final now = DateTime.now();
                            // simplistic check: if now is between start and end
                            // We reset time to midnight for accurate day comparison
                            final start = DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
                            final end = DateTime(m.endDate.year, m.endDate.month, m.endDate.day, 23, 59, 59);
                            return now.isAfter(start) && now.isBefore(end);
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTodaysMedicines(todayMeds, logs),
                              const SizedBox(height: 32),
                              _buildAdherenceGraph(logs),
                              const SizedBox(height: 32),
                              _buildAllMedicines(meds),
                              const SizedBox(height: 80), // Padding for FAB
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isUploadingAdherence)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: DashColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Uploading Proof...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildAddButton(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: DashColors.primaryText,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: DashColors.secondaryText),
            onPressed: () async {
              await AuthService().logOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            tooltip: 'Logout',
          )
        ],
      ),
    );
  }

  Widget _buildDateTimeline() {
    final now = DateTime.now();
    // Get last week starting from today = index 3 to roughly center it
    final days = List.generate(7, (i) => now.add(Duration(days: i - 3)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = days[index];
          final isActive = _isSameDay(date, now);
          final dayStr = DateFormat('E').format(date); // Sun, Mon...
          final dateStr = DateFormat('d').format(date); // 5, 12...

          return Column(
            children: [
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashColors.accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayStr,
                    style: const TextStyle(
                      color: DashColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    dayStr,
                    style: const TextStyle(
                      color: DashColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: const Color(0xFFF1D4D1), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      color: DashColors.primaryText,
                      fontSize: 20,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    String firstName = _userName?.split(' ').first ?? '...';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Welcome $firstName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: DashColors.primaryText,
            ),
          ),
          const SizedBox(width: 8),
          const Text('☀️', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildTodaysMedicines(List<MedicineModel> meds, List<AdherenceLogModel> logs) {
    if (meds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No medicines scheduled for today.", style: TextStyle(color: DashColors.secondaryText)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: meds.map((med) {
        // Find if any logs exist for this medicine today
        final todaysLogs = logs.where((l) => l.medicineId == med.id && _isSameDay(l.timestamp, DateTime.now())).toList();
        
        bool isTaken = todaysLogs.any((l) => l.taken == true);

        Color ringColor = DashColors.accent;
        IconData? activeIcon;
        if (isTaken) {
          ringColor = DashColors.taken;
          activeIcon = Icons.check;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: isTaken 
                  ? Border.all(color: ringColor.withOpacity(0.3), width: 1.5) 
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: DashColors.cardIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication_liquid_rounded,
                    color: isTaken ? ringColor : DashColors.primaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: TextStyle(
                          color: isTaken ? ringColor : DashColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isTaken ? TextDecoration.lineThrough : null,
                          decorationColor: DashColors.taken,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${med.dosage} • ${med.timings.join(', ')}",
                        style: const TextStyle(
                          color: DashColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isTaken)
                  ElevatedButton.icon(
                    onPressed: () => _markAsTakenWithImage(med, med.timings.isNotEmpty ? med.timings.first : 'Time'),
                    icon: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                    label: const Text('Capture & Mark', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashColors.taken,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringColor.withOpacity(0.2),
                    ),
                    child: Icon(activeIcon, color: ringColor, size: 18),
                  )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdherenceGraph(List<AdherenceLogModel> logs) {
    // Generate data for the last 7 days
    final now = DateTime.now();
    List<BarChartGroupData> barGroups = [];
    
    // Group logs by day
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      final dayLogs = logs.where((l) => _isSameDay(l.timestamp, date)).toList();
      final takenCount = dayLogs.where((l) => l.taken == true).length;
      final missedCount = dayLogs.where((l) => l.taken == false).length;
      final total = takenCount + missedCount;
      
      double percentage = 0;
      if (total > 0) percentage = (takenCount / total) * 100;
      // If no logs, percentage remains 0, but we could add artificial data for visual aesthetic if desired.

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: percentage > 0 ? percentage : 2.0, // Minimum height for visual
              color: percentage >= 80 ? DashColors.taken : (percentage > 0 ? DashColors.accent : DashColors.surface),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: DashColors.surface,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Adherence Flow",
            style: TextStyle(color: DashColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final tDate = now.subtract(Duration(days: 6 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(tDate)[0], // S, M, T, W...
                            style: const TextStyle(color: DashColors.secondaryText, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAllMedicines(List<MedicineModel> meds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Medications",
            style: TextStyle(color: DashColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (meds.isEmpty)
            const Text("No active medications found.", style: TextStyle(color: DashColors.secondaryText)),
          ...meds.map((med) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DashColors.bg,
                border: Border.all(color: DashColors.surface, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: DashColors.secondaryText),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(color: DashColors.primaryText, fontWeight: FontWeight.w600)),
                      Text(med.dosage, style: const TextStyle(color: DashColors.secondaryText, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, right: 4),
      child: ElevatedButton.icon(
        onPressed: () {
          if (_uid == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMedicineScreen(patientId: _uid!),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline, color: DashColors.primaryText, size: 20),
        label: const Text(
          'Add',
          style: TextStyle(
            color: DashColors.primaryText, 
            fontWeight: FontWeight.w600, 
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DashColors.fabBg,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: DashColors.bg,
        border: Border(top: BorderSide(color: DashColors.surface, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.check_circle_outline, 'Today', true, hasBadge: true, badgeCount: 1),
          _buildNavItem(Icons.bar_chart_rounded, 'Progress', false),
          _buildNavItem(Icons.medical_services_outlined, 'Support', false),
          _buildNavItem(Icons.medication_outlined, 'Treatments', false, hasBadge: true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {bool hasBadge = false, int? badgeCount}) {
    return GestureDetector(
      onTap: () {
        if (label == 'Treatments') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionScreen()));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isActive ? DashColors.accent : DashColors.secondaryText,
                size: 26,
              ),
              if (hasBadge)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: DashColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: DashColors.bg, width: 1.5),
                    ),
                    child: badgeCount != null
                        ? Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 9, 
                              fontWeight: FontWeight.bold
                            ),
                          )
                        : const SizedBox(width: 4, height: 4),
                  ),
                )
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? DashColors.accent : DashColors.secondaryText,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
