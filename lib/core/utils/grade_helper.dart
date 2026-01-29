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

  static Map<String, dynamic> calculateCGPA(List<dynamic> results) {
    if (results.isEmpty) {
      return {'cgpa': "0.00", 'totalCredits': 0, 'processedResults': []};
    }

    // Sort by Semester (Oldest first)
    // Assuming semesterId format like 'Spring2025'
    int getSemOrder(String semId) {
      if (semId.length < 5) return 0;
      final year = int.tryParse(semId.substring(semId.length - 4)) ?? 0;
      final sem = semId.substring(0, semId.length - 4);
      int sVal = 0;
      if (sem == 'Spring') sVal = 1;
      if (sem == 'Summer') sVal = 2;
      if (sem == 'Fall') sVal = 3;
      return year * 10 + sVal;
    }

    // Sort: Oldest to Newest
    results.sort((a, b) => getSemOrder(a['semesterId'] ?? '').compareTo(getSemOrder(b['semesterId'] ?? '')));

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
      // If multiple attempts, all except LAST (or BEST?) are Retakes.
      // Legacy logic implied: "if someone took the same course ID then result should show R".
      // Usually the latest valid grade stands.
      
      for (int i = 0; i < attempts.length; i++) {
        var attempt = attempts[i];
        bool isLast = (i == attempts.length - 1); // The latest attempt logic

        String grade = attempt['grade'] ?? 'F';
        double credits = double.tryParse(attempt['credits'].toString()) ?? 0.0;

        if (!isLast) {
          // It's a retaken course (previous attempt)
          // Mark visually as R but keep original grade for display?
          // Legacy check: `calculated` returned struct with `isRetake`.
          attempt['displayGrade'] = grade; // keep original visible
          attempt['isRetake'] = true;
          // Do not add to CGPA
        } else {
          // Logic: If user passed, count it. If F, count it (unless retaken later and passed? logic above handles retake)
          if (isGPAGrade(grade)) {
            double gp = getGradePoint(grade);
            totalPoints += (gp * credits);
            totalCredits += credits;
          }
          attempt['isRetake'] = false;
        }
      }
    });

    double cgpa = totalCredits > 0 ? (totalPoints / totalCredits) : 0.00;
    
    return {
      'cgpa': cgpa.toStringAsFixed(2),
      'totalCredits': totalCredits,
      'processedResults': processed
    };
  }
}
