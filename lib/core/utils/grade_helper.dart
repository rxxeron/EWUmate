class GradeHelper {
  /// Default fallback scale (Modern EWU Policy post-2023)
  static const Map<String, double> defaultModernScale = {
    'A': 4.00, 'A-': 3.70, 'B+': 3.30, 'B': 3.00, 'B-': 2.70,
    'C+': 2.30, 'C': 2.00, 'C-': 1.70, 'D+': 1.30, 'D': 1.00, 'F': 0.00,
    'S': 0, 'U': 0, 'W': 0, 'P': 0, 'I': 0, 'R': 0
  };

  /// Default fallback scale (Legacy EWU Policy pre-2023)
  static const Map<String, double> defaultLegacyScale = {
    'A+': 4.00, 'A': 3.75, 'A-': 3.50, 'B+': 3.25, 'B': 3.00, 'B-': 2.75,
    'C+': 2.50, 'C': 2.25, 'D': 2.00, 'F': 0.00,
    'S': 0, 'U': 0, 'W': 0, 'P': 0, 'I': 0, 'R': 0
  };

  /// Determines which grading policy to use ('modern' or 'legacy') based on the semester code.
  static String getPolicyForSemester(String semesterCode) {
    if (semesterCode.isEmpty) return 'modern';
    
    // Extract year using digits
    final digitStr = semesterCode.replaceAll(RegExp(r'\D'), '');
    final year = int.tryParse(digitStr) ?? 0;
    
    if (year == 0) return 'modern';
    if (year < 2022) return 'legacy';
    
    if (year == 2022) {
      final season = semesterCode.toLowerCase();
      if (season.contains('spring') || season.contains('summer')) {
        return 'legacy';
      }
    }
    
    return 'modern';
  }

  /// Gets the grade point for a specific grade. If dynamicScale is provided, it uses that.
  static double getGradePoint(String grade, {String? semesterCode, Map<String, double>? dynamicScale}) {
    if (dynamicScale != null) {
      return dynamicScale[grade] ?? 0.00;
    }
    
    final policy = getPolicyForSemester(semesterCode ?? '');
    final scale = policy == 'legacy' ? defaultLegacyScale : defaultModernScale;
    return scale[grade] ?? 0.00;
  }

  static bool isGPAGrade(String grade, {String? semesterCode, List<String>? validGpaGrades}) {
    if (validGpaGrades != null) {
      return validGpaGrades.contains(grade);
    }
    final policy = getPolicyForSemester(semesterCode ?? '');
    if (policy == 'legacy') {
      return ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'].contains(grade);
    }
    return ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'].contains(grade);
  }

  /// Converts a semester ID like "Spring2026" into a comparable integer.
  static int getSemesterValue(String semId) {
    if (semId.isEmpty || semId.length < 5) return 0;
    // Normalize string: Remove spaces, underscores, and convert to PascalCase if needed
    final clean = semId.replaceAll(' ', '').replaceAll('_', '').toLowerCase();
    
    // Extract year (last 4 digits)
    final yearStr = clean.length >= 4 ? clean.substring(clean.length - 4) : "0";
    final year = int.tryParse(yearStr) ?? 0;
    
    // Extract season
    final season = clean.length > 4 ? clean.substring(0, clean.length - 4) : "";
    int sVal = 0;
    if (season == 'spring') sVal = 1;
    if (season == 'summer') sVal = 2;
    if (season == 'fall') sVal = 3;
    
    return year * 10 + sVal;
  }

  static Map<String, dynamic> calculateCGPA(List<dynamic> results) {
    if (results.isEmpty) {
      return {'cgpa': "0.00", 'totalCredits': 0, 'processedResults': []};
    }
    
    // Sort: Oldest to Newest
    results.sort((a, b) => getSemesterValue(a['semesterId'] ?? '').compareTo(getSemesterValue(b['semesterId'] ?? '')));

    // Process retakes
    Map<String, List<Map<String, dynamic>>> courseMap = {};
    
    // We need to work with a list of Maps we can modify
    List<Map<String, dynamic>> processed = [];

    for (var r in results) {
      // Create a mutable copy
      Map<String, dynamic> item = Map<String, dynamic>.from(r);
      String courseCode = item['courseCode'] ?? 'UNK';
      
      if (!courseMap.containsKey(courseCode)) {
        courseMap[courseCode] = [];
      }
      courseMap[courseCode]!.add(item);
      processed.add(item); // Keep reference to the same object in map
    }

    double totalPoints = 0;
    double totalCredits = 0;

    courseMap.forEach((code, attempts) {
      for (int i = 0; i < attempts.length; i++) {
        var attempt = attempts[i];
        bool isLast = (i == attempts.length - 1); // The latest attempt logic

        String grade = attempt['grade'] ?? 'F';
        double credits = double.tryParse(attempt['credits'].toString()) ?? 0.0;

        if (!isLast) {
          attempt['displayGrade'] = grade; // keep original visible
          attempt['isRetake'] = true;
        } else {
          if (isGPAGrade(grade)) {
            totalPoints += (getGradePoint(grade) * credits);
            totalCredits += credits;
          }
          attempt['displayGrade'] = grade;
          attempt['isRetake'] = false;
        }
      }
    });

    String cgpa = totalCredits > 0 ? (totalPoints / totalCredits).toStringAsFixed(2) : "0.00";
    return {
      'cgpa': cgpa,
      'totalCredits': totalCredits.toInt(),
      'processedResults': processed
    };
  }
}
