import 'package:flutter/material.dart';
import 'package:mediassure/screens/app_theme.dart';

class WeekCalendar extends StatefulWidget {
  final Function(DateTime)? onDaySelected;

  const WeekCalendar({super.key, this.onDaySelected});

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  int selectedIndex = DateTime.now().weekday - 1;

  List<DateTime> getWeekDays() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = getWeekDays();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final date = days[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () {
              setState(() => selectedIndex = index);

              if (widget.onDaySelected != null) {
                widget.onDaySelected!(date);
              }
            },
            child: Column(
              children: [
                Text(
                  _getDayName(date.weekday),
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getDayName(int weekday) {
    const names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return names[weekday - 1];
  }
}