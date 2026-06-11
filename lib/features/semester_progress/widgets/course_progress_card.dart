import 'package:flutter/material.dart';
import 'package:ewumate/core/models/semester_course_marks.dart';

class CourseProgressCard extends StatelessWidget {
  final Map<String, dynamic> courseData;
  final String? courseName;
  final VoidCallback onTap;

  const CourseProgressCard({
    super.key,
    required this.courseData,
    this.courseName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final code = courseData['course_code'] ?? 'Course';
    final name = courseName ?? 'Course Full Name';
    
    // Parse into the model to use our single-source-of-truth totalObtained calculator
    // Inject required fields just in case legacy/broken cache data lacks them
    final safeData = Map<String, dynamic>.from(courseData);
    safeData['id'] ??= 'fallback_id_$code';
    safeData['user_id'] ??= 'fallback_user';
    safeData['semester_code'] ??= 'unknown_sem';
    safeData['course_code'] ??= code;
    
    final courseModel = SemesterCourseMarks.fromJson(safeData);
    final double totalObtained = courseModel.totalObtained;

    // Attendance calculation
    final extra = courseData['marks_data'] ?? {};
    final attendance = extra['attendance'] ?? {};
    final dates = attendance['dates'] as Map<dynamic, dynamic>? ?? {};
    final types = attendance['types'] as Map<dynamic, dynamic>? ?? {};
    
    // Filter out duplicate plain date keys if their suffix-based equivalents exist
    final Set<String> keysToIgnore = {};
    dates.forEach((keyStr, _) {
      final key = keyStr.toString();
      if (key.contains('_')) {
        final plainKey = key.split('_')[0];
        keysToIgnore.add(plainKey);
      }
    });
    
    int joinedTheory = 0;
    int conductedTheory = 0;
    int joinedLab = 0;
    int conductedLab = 0;
    
    dates.forEach((keyStr, status) {
      final key = keyStr.toString();
      if (keysToIgnore.contains(key)) return;
      
      final type = types[key]?.toString() ?? (key.endsWith('_Lab') ? 'Lab' : 'Theory');
      
      if (status == 'joined') {
        if (type == 'Lab') {
          joinedLab++;
          conductedLab++;
        } else {
          joinedTheory++;
          conductedTheory++;
        }
      } else if (status == 'missed') {
        if (type == 'Lab') {
          conductedLab++;
        } else {
          conductedTheory++;
        }
      }
    });
    
    final double theoryPct = conductedTheory > 0 ? (joinedTheory / conductedTheory) * 100 : 0;
    final double labPct = conductedLab > 0 ? (joinedLab / conductedLab) * 100 : 0;
    
    final bool hasTheory = conductedTheory > 0;
    final bool hasLab = conductedLab > 0;

    final String percentageText = '${totalObtained.toStringAsFixed(1)}%';
    
    // Logic for grade badge (placeholder logic based on percentage)
    String grade = 'F';
    Color gradeColor = const Color(0xFFF43F5E); // Red
    
    if (totalObtained >= 80) { grade = 'A+'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 75) { grade = 'A'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 70) { grade = 'A-'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 65) { grade = 'B+'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 60) { grade = 'B'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 55) { grade = 'B-'; gradeColor = Colors.cyanAccent; }
    else if (totalObtained >= 50) { grade = 'C+'; gradeColor = Colors.orangeAccent; }
    else if (totalObtained >= 45) { grade = 'C'; gradeColor = Colors.orangeAccent; }
    else if (totalObtained >= 40) { grade = 'D'; gradeColor = Colors.orangeAccent; }
    else { grade = 'F'; gradeColor = const Color(0xFFF43F5E); }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code and Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      percentageText,
                      style: TextStyle(
                        color: gradeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: gradeColor.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Course Name
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (hasTheory || hasLab) ...[
              const SizedBox(height: 8),
              if (hasTheory) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (theoryPct >= 80 
                        ? const Color(0xFF10B981) 
                        : theoryPct >= 60 
                            ? const Color(0xFFF59E0B) 
                            : const Color(0xFFEF4444)).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (theoryPct >= 80 
                          ? const Color(0xFF10B981) 
                          : theoryPct >= 60 
                              ? const Color(0xFFF59E0B) 
                              : const Color(0xFFEF4444)).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 11,
                        color: theoryPct >= 80 
                            ? const Color(0xFF10B981) 
                            : theoryPct >= 60 
                                ? const Color(0xFFF59E0B) 
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Theory: ${theoryPct.toStringAsFixed(0)}% ($joinedTheory/$conductedTheory)',
                        style: TextStyle(
                          color: theoryPct >= 80 
                              ? const Color(0xFF10B981) 
                              : theoryPct >= 60 
                                  ? const Color(0xFFF59E0B) 
                                  : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasLab) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (labPct >= 80 
                        ? const Color(0xFF10B981) 
                        : labPct >= 60 
                            ? const Color(0xFFF59E0B) 
                            : const Color(0xFFEF4444)).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (labPct >= 80 
                          ? const Color(0xFF10B981) 
                          : labPct >= 60 
                              ? const Color(0xFFF59E0B) 
                              : const Color(0xFFEF4444)).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science_rounded,
                        size: 11,
                        color: labPct >= 80 
                            ? const Color(0xFF10B981) 
                            : labPct >= 60 
                                ? const Color(0xFFF59E0B) 
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lab: ${labPct.toStringAsFixed(0)}% ($joinedLab/$conductedLab)',
                        style: TextStyle(
                          color: labPct >= 80 
                              ? const Color(0xFF10B981) 
                              : labPct >= 60 
                                  ? const Color(0xFFF59E0B) 
                                  : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            // Progress Bar
            const SizedBox(height: 20),
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (totalObtained / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: gradeColor.withOpacity(0.8),
                    minHeight: 6,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 0,
                  child: Text(
                    '100 Max',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            // Activity List
            const SizedBox(height: 24),
            Expanded(
              child: _buildMarksList(courseData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksList(Map<String, dynamic> data) {
    List<Widget> items = [];
    
    // Quizzes logic
    final List<dynamic>? qArr = data['obt_quizzes'];
    if (qArr != null && qArr.isNotEmpty) {
      for (int i = 0; i < qArr.length; i++) {
        items.add(_buildMarkRow('Quiz ${i + 1}', qArr[i].toString()));
      }
    }
    
    // Short Quizzes logic
    final List<dynamic>? sqArr = data['obt_short_quizzes'];
    if (sqArr != null && sqArr.isNotEmpty) {
      for (int i = 0; i < sqArr.length; i++) {
        items.add(_buildMarkRow('S. Quiz ${i + 1}', sqArr[i].toString()));
      }
    }

    // Common fields
    if (data['obt_mid'] != null) items.add(_buildMarkRow('Mid', data['obt_mid'].toString()));
    if (data['obt_project'] != null && data['obt_project'] > 0) items.add(_buildMarkRow('Project', data['obt_project'].toString()));
    if (data['obt_term_paper'] != null && data['obt_term_paper'] > 0) items.add(_buildMarkRow('Term Paper', data['obt_term_paper'].toString()));
    if (data['obt_class_performance'] != null && data['obt_class_performance'] > 0) items.add(_buildMarkRow('Class Perf.', data['obt_class_performance'].toString()));
    if (data['obt_final'] != null && data['obt_final'] > 0) items.add(_buildMarkRow('Final', data['obt_final'].toString()));
    if (data['obt_attendance'] != null) items.add(_buildMarkRow('Attendance', data['obt_attendance'].toString()));

    if (items.isEmpty) {
      return Text(
        'Tap to add marks',
        style: TextStyle(color: Colors.grey[600], fontSize: 10, fontStyle: FontStyle.italic),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: items,
    );
  }

  Widget _buildMarkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
