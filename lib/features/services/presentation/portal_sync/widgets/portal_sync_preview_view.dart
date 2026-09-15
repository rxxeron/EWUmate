import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/services/portal_service.dart';

class PortalSyncPreviewView extends StatelessWidget {
  final PortalSyncResult result;
  final bool syncActiveSchedule;
  final ValueChanged<bool> onToggleSyncActiveSchedule;
  final bool syncAcademicHistory;
  final ValueChanged<bool> onToggleSyncAcademicHistory;
  final int azureParsedGradesCount;
  final VoidCallback onConfirmAndSync;
  final VoidCallback onBack;

  const PortalSyncPreviewView({
    super.key,
    required this.result,
    required this.syncActiveSchedule,
    required this.onToggleSyncActiveSchedule,
    required this.syncAcademicHistory,
    required this.onToggleSyncAcademicHistory,
    required this.azureParsedGradesCount,
    required this.onConfirmAndSync,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('data_preview'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // Semester & Student Info Header (Compact for screenshot)
              Row(
                children: [
                  Text(
                    result.activeSemesterName.isNotEmpty ? result.activeSemesterName : "Enrolled Routine",
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                    ),
                    child: Text(
                      "${result.enrolledCourses.length} Courses",
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (result.profile.studentId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.profile.studentId,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Course Cards List (Compact & Densified for Single-Screen Screenshot)
              ...result.enrolledCourses.map((c) {
                final isInactive = c.isInactive;
                final groupedSessions = _groupCourseSessions(c.sessions);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isInactive
                            ? [const Color(0xFF1E1418), const Color(0xFF191216)]
                            : [const Color(0xFF0A192F), const Color(0xFF0D2342)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isInactive
                            ? const Color(0x55EF4444)
                            : const Color(0x3319D9F5),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Course Code, Sec, Cr + Faculty Initials
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF19D9F5).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF19D9F5).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                c.courseCode,
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF19D9F5),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Sec ${c.section}",
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!isInactive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${c.credits.toStringAsFixed(1)} Cr",
                                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            const Spacer(),
                            if (isInactive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                                ),
                                child: Text(
                                  c.isWithdrawn ? "Withdrawn" : "Dropped",
                                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (c.facultyInitial.isNotEmpty && c.facultyInitial != "TBA")
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF19D9F5).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c.facultyInitial,
                                  style: const TextStyle(color: Color(0xFF19D9F5), fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Faculty Name & Clickable Email
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, color: Color(0xFF19D9F5), size: 14),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                c.facultyName.isNotEmpty
                                    ? c.facultyName
                                    : (c.facultyInitial.isNotEmpty ? c.facultyInitial : "Faculty: TBA"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.facultyEmail.isNotEmpty)
                              InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: c.facultyEmail));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Copied email: ${c.facultyEmail}"),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined, color: Color(0xFF38BDF8), size: 13),
                                      const SizedBox(width: 3),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 140),
                                        child: Text(
                                          c.facultyEmail.split('@')[0],
                                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 5),

                        // Row 3+: Grouped Sessions with crystal-clear non-truncating display
                        if (groupedSessions.isNotEmpty)
                          ...groupedSessions.map((sess) {
                            final isLab = sess.type.toLowerCase() == 'lab';
                            return Container(
                              margin: const EdgeInsets.only(top: 4.5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isLab
                                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                    : const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isLab
                                      ? const Color(0xFF10B981).withValues(alpha: 0.22)
                                      : const Color(0xFF0EA5E9).withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Session Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isLab
                                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                          : const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLab ? "LAB" : "THEORY",
                                      style: TextStyle(
                                        color: isLab ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  // Days (e.g., Sun, Tue)
                                  Text(
                                    sess.days,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Full Time - Guaranteed never truncated & crystal-clear
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: isLab ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            sess.time,
                                            style: const TextStyle(
                                              color: Color(0xFFF8FAFC),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Room
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.room_outlined, size: 11, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 2.5),
                                        Text(
                                          sess.room,
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                        else ...[
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Color(0xFF38BDF8), size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      c.timing.isNotEmpty ? c.timing : "Schedule: TBA",
                                      style: const TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.room_outlined, size: 11, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 2.5),
                                      Text(
                                        _cleanRoom(c.room),
                                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (isInactive) ...[
                          const SizedBox(height: 4),
                          const Text(
                            "⚠ Course was dropped/withdrawn.",
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // Collapsible / Compact Sync Options (Takes near 0 vertical space by default for screenshot clarity)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  title: Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        "Sync Options (All active)",
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                      const Spacer(),
                      Text(
                        "$azureParsedGradesCount grades included",
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071426),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: syncActiveSchedule,
                            activeThumbColor: const Color(0xFF19D9F5),
                            activeTrackColor: const Color(0xFF19D9F5).withValues(alpha: 0.4),
                            title: const Text("Weekly Routine & Faculty", style: TextStyle(color: Colors.white, fontSize: 12)),
                            subtitle: const Text("Save schedule, room numbers and sections", style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                            onChanged: onToggleSyncActiveSchedule,
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: syncAcademicHistory,
                            activeThumbColor: const Color(0xFF19D9F5),
                            activeTrackColor: const Color(0xFF19D9F5).withValues(alpha: 0.4),
                            title: const Text("Academic History & Grades", style: TextStyle(color: Colors.white, fontSize: 12)),
                            subtitle: Text("Import $azureParsedGradesCount completed courses", style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                            onChanged: onToggleSyncAcademicHistory,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Bottom CTA Buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onConfirmAndSync,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF19D9F5),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF19D9F5).withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Confirm & Sync",
                        style: TextStyle(
                          fontFamily: 'Sora',
                          color: Color(0xFF071426),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Color(0xFF071426), size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<_GroupedSession> _groupCourseSessions(List<PortalCourseSession> sessions) {
    if (sessions.isEmpty) return [];

    final Map<String, List<String>> groups = {};
    final Map<String, PortalCourseSession> sample = {};

    for (final s in sessions) {
      final key = '${s.type}_${s.startTime}_${s.endTime}_${s.room}';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(s.day);
      sample[key] = s;
    }

    final List<_GroupedSession> result = [];
    groups.forEach((key, daysList) {
      final s = sample[key]!;
      final shortDays = daysList.map((d) {
        if (d.length >= 3) return d.substring(0, 3);
        return d;
      }).join(', ');

      result.add(_GroupedSession(
        type: s.type,
        days: shortDays,
        time: '${_cleanTime(s.startTime)} – ${_cleanTime(s.endTime)}',
        room: _cleanRoom(s.room),
      ));
    });

    return result;
  }

  static String _cleanTime(String rawTime) {
    var t = rawTime.trim();
    if (t.isEmpty) return "TBA";
    // Clean "03:10 PM" -> "3:10 PM"
    if (t.startsWith('0') && t.length > 1 && RegExp(r'^0\d:').hasMatch(t)) {
      t = t.substring(1);
    }
    return t;
  }

  static String _cleanRoom(String rawRoom) {
    if (rawRoom.isEmpty || rawRoom.toUpperCase() == 'TBA') return 'TBA';
    var cleaned = rawRoom.replaceAll(RegExp(r'^Room\s*[:\-]?\s*', caseSensitive: false), '').trim();
    final m = RegExp(r'^([A-Za-z0-9\-_]+)\s*\((.*?)\)').firstMatch(cleaned);
    if (m != null) {
      final roomNum = m.group(1) ?? '';
      final label = m.group(2) ?? '';
      if (label.toLowerCase().contains('lab')) {
        final labNumMatch = RegExp(r'lab\s*(\d+)', caseSensitive: false).firstMatch(label);
        if (labNumMatch != null) {
          return '$roomNum (Lab ${labNumMatch.group(1)})';
        }
        return '$roomNum (Lab)';
      }
      return roomNum;
    }
    return cleaned;
  }
}

class _GroupedSession {
  final String type;
  final String days;
  final String time;
  final String room;

  _GroupedSession({
    required this.type,
    required this.days,
    required this.time,
    required this.room,
  });
}
