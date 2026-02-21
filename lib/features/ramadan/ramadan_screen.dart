import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_kit.dart';
import '../../core/widgets/ewumate_app_bar.dart';
import '../../core/services/ramadan_service.dart';

class RamadanScreen extends StatelessWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timetable = RamadanService.getFullTimetable();
    final today = RamadanService.getTodayTimings();

    return Column(
      children: [
        const EWUmateAppBar(
          title: "Ramadan 2026",
          showMenu: true,
        ),
        Expanded(
          child: FutureBuilder<List<RamadanDay>>(
            future: RamadanService.getFullTimetable(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Unable to load Ramadan schedule", style: TextStyle(color: Colors.white70)));
              }

              final timetable = snapshot.data!;
              final now = DateTime.now();
              RamadanDay? today;
              try {
                today = timetable.firstWhere(
                  (day) => day.date.year == now.year && day.date.month == now.month && day.date.day == now.day,
                );
              } catch (_) {}

              return Column(
                children: [
                  _buildInfoCard(today),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: timetable.length,
                      itemBuilder: (context, index) {
                        final day = timetable[index];
                        final isToday = today?.day == day.day;
                        return _buildDayTile(day, isToday);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(RamadanDay? today) {
    if (today == null) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      borderColor: Colors.amberAccent.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Text(
            "Today's Timing",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeColumn("Sehri ends", today.sehri, Icons.wb_twilight),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildTimeColumn("Iftar starts", today.iftar, Icons.wb_sunny_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 24),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDayTile(RamadanDay day, bool isToday) {
    final dateStr = DateFormat('EEE, d MMM').format(day.date);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      borderColor: isToday ? Colors.amberAccent.withValues(alpha: 0.5) : null,
      color: isToday ? Colors.amberAccent.withValues(alpha: 0.1) : null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isToday ? Colors.amberAccent : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  color: isToday ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isToday)
                  const Text(
                    "Today",
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "S: ${day.sehri}",
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                "I: ${day.iftar}",
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
