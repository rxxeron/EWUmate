import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_logic.dart';
import 'schedule_card.dart';
import 'hero_card.dart';

class ScheduleWidgetRender extends StatelessWidget {
  final Map<String, dynamic> data;

  const ScheduleWidgetRender({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'];
    final reason = data['reason'] ?? "";
    final schedule = (data['schedule'] as List?)?.cast<ScheduleItem>() ?? [];
    final targetDateRaw = data['targetDate'] ?? data['date'];
    final DateTime? targetDate = targetDateRaw is String
        ? DateTime.tryParse(targetDateRaw)
        : targetDateRaw as DateTime?;

    final isToday = targetDate != null && isSameDay(targetDate, DateTime.now());
    final isTomorrow = targetDate != null && isSameDay(targetDate, DateTime.now().add(const Duration(days: 1)));
    
    String title = targetDate != null ? DateFormat('EEEE').format(targetDate) : "Schedule";
    if (isToday) title = "Today's Schedule";
    if (isTomorrow) title = "Tomorrow's Schedule";
    
    final displayDate = targetDate != null ? DateFormat('EEEE, MMM d').format(targetDate) : "";

    return SizedBox(
      width: 600,
      height: 300,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(600, 300)),
        child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          ),
          child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: 600,
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (status == 'holiday')
                Expanded(
                  child: Center(
                    child: HeroCard(
                      iconInfo: "🎉",
                      title: "Holiday",
                      subtitle: reason.isNotEmpty ? reason : "It's a holiday! Enjoy your day off.",
                      color: Colors.amberAccent,
                    ),
                  ),
                )
              else if (status == 'chill')
                Expanded(
                  child: Center(
                    child: HeroCard(
                      iconInfo: "☕",
                      title: "Chill Mode",
                      subtitle: reason.isNotEmpty ? reason : "No classes scheduled.",
                      color: Colors.purpleAccent,
                    ),
                  ),
                )
              else if (schedule.isEmpty)
                Expanded(
                  child: Center(
                    child: HeroCard(
                      iconInfo: "✨",
                      title: isToday ? "All Clear" : "Nothing Found",
                      subtitle: isToday ? "No more classes for today." : "No classes scheduled for this day.",
                      color: Colors.greenAccent,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedule.length,
                    itemBuilder: (context, index) {
                      return ScheduleCard(item: schedule[index]);
                    },
                  ),
                ),
            ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
