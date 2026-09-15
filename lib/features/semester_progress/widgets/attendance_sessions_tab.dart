import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/primitives/ewu_surface_card.dart';

class AttendanceSession {
  final DateTime date;
  final String type; // 'Theory' or 'Lab'
  AttendanceSession(this.date, this.type);
}

class AttendanceSessionsTab extends StatelessWidget {
  final bool isLoading;
  final String errorMessage;
  final List<AttendanceSession> sessions;
  final Map<String, String> markedDates;
  final VoidCallback onRetry;
  final VoidCallback onAddMakeup;
  final void Function(String sessionKey, String? newStatus) onStatusChanged;

  const AttendanceSessionsTab({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.sessions,
    required this.markedDates,
    required this.onRetry,
    required this.onAddMakeup,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.primaryCyan),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load calendar: $errorMessage',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryCyan,
                  foregroundColor: colors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry,
                child: Text('Retry', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    int joined = 0;
    int missed = 0;
    int joinedTheory = 0;
    int conductedTheory = 0;
    int joinedLab = 0;
    int conductedLab = 0;

    for (final session in sessions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(session.date);
      final key = '${dateStr}_${session.type}';
      final status = markedDates[key] ?? markedDates[dateStr] ?? 'unmarked';

      if (status == 'joined') {
        joined++;
        if (session.type == 'Lab') {
          joinedLab++;
          conductedLab++;
        } else {
          joinedTheory++;
          conductedTheory++;
        }
      } else if (status == 'missed') {
        missed++;
        if (session.type == 'Lab') {
          conductedLab++;
        } else {
          conductedTheory++;
        }
      }
    }

    final conducted = joined + missed;
    final double percentage = conducted > 0 ? (joined / conducted) * 100 : 100.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildAttendanceGauge(
          context,
          percentage,
          joined,
          missed,
          joinedTheory: joinedTheory,
          conductedTheory: conductedTheory,
          joinedLab: joinedLab,
          conductedLab: conductedLab,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Class Sessions',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
              ),
            ),
            TextButton.icon(
              onPressed: onAddMakeup,
              icon: Icon(Icons.add_rounded, color: colors.primaryCyan, size: 16),
              label: Text(
                'Add Makeup',
                style: GoogleFonts.sora(
                  color: colors.primaryCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          EwuSurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Center(
              child: Text(
                'No scheduled classes generated for this course.\nTry adding a custom makeup class!',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  color: colors.secondaryText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final date = session.date;
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final key = '${dateStr}_${session.type}';

              final status = markedDates[key] ?? markedDates[dateStr] ?? 'unmarked';
              final sessionType = session.type;

              final isHoliday = status == 'holiday';
              final isCancelled = status == 'cancelled';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceNavyBlue.withValues(alpha: colors.isDark ? 0.75 : 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: colors.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('EEEE').format(date),
                                style: GoogleFonts.sora(
                                  color: colors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (sessionType == 'Lab' ? Colors.orange : colors.primaryCyan).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (sessionType == 'Lab' ? Colors.orange : colors.primaryCyan).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  sessionType.toUpperCase(),
                                  style: GoogleFonts.sora(
                                    color: sessionType == 'Lab' ? Colors.orangeAccent : colors.primaryCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM d, yyyy').format(date),
                            style: GoogleFonts.sora(
                              color: colors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHoliday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Holiday',
                          style: GoogleFonts.sora(
                            color: Colors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Cancelled',
                          style: GoogleFonts.sora(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      _buildActionButtons(context, key, status),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAttendanceGauge(
    BuildContext context,
    double percentage,
    int joined,
    int missed, {
    required int joinedTheory,
    required int conductedTheory,
    required int joinedLab,
    required int conductedLab,
  }) {
    final colors = context.ewuColors;
    final conducted = joined + missed;

    Color statusColor = percentage >= 80
        ? const Color(0xFF10B981)
        : percentage >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return EwuSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.sora(
                      color: colors.primaryText,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Attendance',
                    style: GoogleFonts.sora(
                      color: colors.secondaryText,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLASSES ATTENDED',
                  style: GoogleFonts.sora(
                    color: colors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$joined / $conducted classes',
                  style: GoogleFonts.sora(
                    color: colors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMiniCounterPill(context, 'Theory', '$joinedTheory/$conductedTheory', colors.primaryCyan),
                    if (conductedLab > 0)
                      _buildMiniCounterPill(context, 'Lab', '$joinedLab/$conductedLab', const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounterPill(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.sora(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String sessionKey, String currentStatus) {
    final bool isJoined = currentStatus == 'joined';
    final bool isMissed = currentStatus == 'missed';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onStatusChanged(sessionKey, isJoined ? null : 'joined');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isJoined ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isJoined ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: isJoined ? Colors.white : Colors.white38,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onStatusChanged(sessionKey, isMissed ? null : 'missed');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMissed ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMissed ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isMissed ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}
