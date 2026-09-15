import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../dashboard/exception_repository.dart';

class AddManualClassSheet extends StatefulWidget {
  final String semesterCode;
  final List<Map<String, String>> enrolledCourses;
  final String? originalCancelCode;
  final String? originalCancelDateStr;
  final String? resolveExceptionId;
  final String? sessionType;
  final ExceptionRepository exceptionRepo;
  final Future<void> Function() onSaved;

  const AddManualClassSheet({
    super.key,
    required this.semesterCode,
    required this.enrolledCourses,
    this.originalCancelCode,
    this.originalCancelDateStr,
    this.resolveExceptionId,
    this.sessionType,
    required this.exceptionRepo,
    required this.onSaved,
  });

  @override
  State<AddManualClassSheet> createState() => _AddManualClassSheetState();
}

class _AddManualClassSheetState extends State<AddManualClassSheet> {
  late List<Map<String, String>> _courses;
  String? _selectedCourse;
  late TextEditingController _dateCtrl;
  late TextEditingController _roomCtrl;
  String _currentName = '';
  String _currentFaculty = '';
  TimeOfDay? _selectedStartTime;
  String _computedStartStr = '';
  String _computedEndStr = '';
  bool _isSaving = false;

  bool get _isMakeup => widget.originalCancelCode != null || widget.resolveExceptionId != null;

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.enrolledCourses);
    if (widget.originalCancelCode != null && !_courses.any((c) => c['code'] == widget.originalCancelCode)) {
      _courses.add({'code': widget.originalCancelCode!, 'name': 'Course', 'faculty': '', 'room': ''});
      _courses.sort((a, b) => (a['code'] ?? '').compareTo(b['code'] ?? ''));
    }

    _selectedCourse = widget.originalCancelCode;
    _dateCtrl = TextEditingController(text: widget.originalCancelDateStr ?? '');
    _roomCtrl = TextEditingController();

    if (widget.originalCancelCode != null) {
      final meta = _courses.firstWhere((c) => c['code'] == widget.originalCancelCode, orElse: () => {});
      _currentName = meta['name'] ?? '';
      _currentFaculty = meta['faculty'] ?? '';
      if (meta['room'] != null) _roomCtrl.text = meta['room']!;
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceNavyBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: colors.secondaryText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMakeup ? Icons.event_repeat_rounded : Icons.add_circle_outline_rounded,
                    color: colors.primaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMakeup ? 'Schedule Makeup Session' : 'Add Manual Class',
                      style: GoogleFonts.sora(
                        color: colors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _isMakeup ? 'Plan a replacement for a cancelled session' : 'Add an extra or temporary session',
                      style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Course selection
            Text('COURSE', style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourse,
              dropdownColor: colors.surfaceNavyBlue,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.primaryNavy.withValues(alpha: colors.isDark ? 0.6 : 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
              ),
              items: _courses.map((c) => DropdownMenuItem(
                value: c['code'],
                child: Text("${c['code']} - ${c['name']}", style: GoogleFonts.sora(color: colors.primaryText, fontSize: 13)),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCourse = val;
                  final meta = _courses.firstWhere((c) => c['code'] == val, orElse: () => {});
                  _currentName = meta['name'] ?? '';
                  _currentFaculty = meta['faculty'] ?? '';
                  if (meta['room'] != null) _roomCtrl.text = meta['room']!;
                });
              },
            ),
            const SizedBox(height: 14),

            // Date picker
            Text('DATE', style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              style: GoogleFonts.sora(color: colors.primaryText, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Select date',
                hintStyle: GoogleFonts.sora(color: colors.secondaryText),
                suffixIcon: Icon(Icons.calendar_today_rounded, color: colors.primaryCyan, size: 20),
                filled: true,
                fillColor: colors.primaryNavy.withValues(alpha: colors.isDark ? 0.6 : 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (d != null) {
                  _dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                }
              },
            ),
            const SizedBox(height: 14),

            // Time & Room Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TIME', style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _selectedStartTime ?? const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (t != null) {
                            setState(() {
                              _selectedStartTime = t;
                              final hr = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
                              final period = t.period == DayPeriod.am ? 'AM' : 'PM';
                              final min = t.minute.toString().padLeft(2, '0');
                              _computedStartStr = '$hr:$min $period';

                              // Default 1.5 hr duration
                              final endMinutes = t.hour * 60 + t.minute + 90;
                              final endHrRaw = (endMinutes ~/ 60) % 24;
                              final endMinRaw = endMinutes % 60;
                              final endPeriod = endHrRaw < 12 ? 'AM' : 'PM';
                              final endHr = (endHrRaw % 12) == 0 ? 12 : endHrRaw % 12;
                              _computedEndStr = '$endHr:${endMinRaw.toString().padLeft(2, '0')} $endPeriod';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.primaryNavy.withValues(alpha: colors.isDark ? 0.6 : 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: colors.primaryCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _computedStartStr.isNotEmpty ? _computedStartStr : 'Start Time',
                                style: GoogleFonts.sora(color: _computedStartStr.isNotEmpty ? colors.primaryText : colors.secondaryText, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROOM', style: GoogleFonts.sora(color: colors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _roomCtrl,
                        style: GoogleFonts.sora(color: colors.primaryText, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'e.g. 538',
                          hintStyle: GoogleFonts.sora(color: colors.secondaryText),
                          filled: true,
                          fillColor: colors.primaryNavy.withValues(alpha: colors.isDark ? 0.6 : 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryCyan,
                  foregroundColor: colors.isDark ? AppColors.primaryNavy : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_selectedCourse == null || _dateCtrl.text.isEmpty || _computedStartStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select course, date, and start time')),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);
                        Navigator.pop(context);

                        try {
                          if (_isMakeup) {
                            if (widget.originalCancelDateStr != null) {
                              await widget.exceptionRepo.addCancellation(
                                widget.originalCancelDateStr!,
                                _selectedCourse!,
                                pendingMakeup: false,
                              );
                            } else if (widget.resolveExceptionId != null) {
                              await widget.exceptionRepo.resolvePendingMakeup(widget.resolveExceptionId!);
                            }
                            await widget.exceptionRepo.addMakeupClass(
                              date: _dateCtrl.text,
                              courseCode: _selectedCourse!,
                              courseName: _currentName,
                              startTime: _computedStartStr,
                              endTime: _computedEndStr,
                              room: _roomCtrl.text,
                              faculty: _currentFaculty,
                            );
                          } else {
                            await widget.exceptionRepo.addManualClass(
                              date: _dateCtrl.text,
                              courseCode: _selectedCourse!,
                              courseName: _currentName,
                              startTime: _computedStartStr,
                              endTime: _computedEndStr,
                              room: _roomCtrl.text,
                              faculty: _currentFaculty,
                            );
                          }
                          await widget.onSaved();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AuthErrorUtils.getFriendlyMessage(e))),
                            );
                          }
                        }
                      },
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _isMakeup ? 'SAVE MAKEUP' : 'SAVE ENTRY',
                        style: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
