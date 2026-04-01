class GradeHelper {
  static const Map<String, double> gradeScale = {
    'A+': 4.00,
    'A': 3.75,
    'A-': 3.50,
    'B+': 3.25,
    'B': 3.00,
    'B-': 2.75,
    'C+': 2.50,
    'C': 2.25,
    'D': 2.00,
    'F': 0.00,
    // Non-GPA grades
    'S': 0, 'U': 0, 'W': 0, 'P': 0, 'I': 0, 'R': 0
  };

  static double getGradePoint(String grade) {
    return gradeScale[grade] ?? 0.00;
  }

  static bool isGPAGrade(String grade) {
    return ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'].contains(grade);
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
