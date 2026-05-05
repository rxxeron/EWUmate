import 'package:flutter/material.dart';

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
    
    // Calculate total percentage (assuming out of 100)
    double totalObtained = 0.0;
    totalObtained += (courseData['obt_mid'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_final'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_attendance'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_project'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_presentation'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_viva'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_assignment'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_term_paper'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_lab'] as num?)?.toDouble() ?? 0.0;
    totalObtained += (courseData['obt_class_performance'] as num?)?.toDouble() ?? 0.0;
    
    final List<dynamic>? qArr = courseData['obt_quizzes'];
    if (qArr != null) {
      totalObtained += qArr.fold(0.0, (sum, item) => sum + (item as num).toDouble());
    }
    final List<dynamic>? sqArr = courseData['obt_short_quizzes'];
    if (sqArr != null) {
      totalObtained += sqArr.fold(0.0, (sum, item) => sum + (item as num).toDouble());
    }

    final String percentageText = '${totalObtained.toStringAsFixed(1)}%';
    
    // Logic for grade badge (placeholder logic based on percentage)
    String grade = 'F';
    Color gradeColor = const Color(0xFFF43F5E); // Red
    if (totalObtained >= 80) { grade = 'A+'; gradeColor = Colors.greenAccent; }
    else if (totalObtained >= 40) { grade = 'D'; gradeColor = Colors.orangeAccent; }

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
