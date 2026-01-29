/// Represents the mark distribution and obtained marks for a single course
class CourseMarks {
  final String courseCode;
  final String courseName;
  final MarkDistribution distribution;
  final ObtainedMarks obtained;
  final String quizStrategy; // 'bestN' or 'average' or 'sum'
  int quizN; // For 'bestN' strategy
  int shortQuizN; // For 'bestN' strategy

  CourseMarks({
    required this.courseCode,
    required this.courseName,
    required this.distribution,
    required this.obtained,
    this.quizStrategy = 'bestN',
    this.quizN = 2, // Default to best 2
    this.shortQuizN = 2,
  });

  /// Calculates total obtained marks based on quiz strategy
  double get totalObtained {
    double total = 0;
    total += obtained.mid ?? 0;
    total += obtained.assignment ?? 0;
    total += obtained.presentation ?? 0;
    total += obtained.viva ?? 0;
    total += obtained.finalExam ?? 0;
    total += obtained.attendance ?? 0;
    total += obtained.lab ?? 0;
    total += calculatedQuizMark;
    total += calculatedShortQuizMark;
    return total;
  }

  // ... (omitted sections)

  /// Calculates short quiz mark based on strategy
  double get calculatedShortQuizMark {
    if (obtained.shortQuizzes.isEmpty) return 0;

    final sorted = List<double>.from(obtained.shortQuizzes)
      ..sort((a, b) => b.compareTo(a)); // Descending

    if (quizStrategy == 'sum') {
      return sorted.reduce((a, b) => a + b);
    } else if (quizStrategy == 'average') {
      return sorted.reduce((a, b) => a + b) / sorted.length;
    } else {
      // 'bestN' strategy: Average of the best N
      int n = shortQuizN;
      if (n <= 0) n = 1;
      if (n > sorted.length) n = sorted.length;

      final bestN = sorted.take(n).toList();
      return bestN.reduce((a, b) => a + b) / n; // Divide by N (averaged)
    }
  }

  /// Calculates quiz mark based on strategy
  double get calculatedQuizMark {
    if (obtained.quizzes.isEmpty) return 0;

    final sorted = List<double>.from(obtained.quizzes)
      ..sort((a, b) => b.compareTo(a)); // Descending

    if (quizStrategy == 'sum') {
      return sorted.reduce((a, b) => a + b);
    } else if (quizStrategy == 'average') {
      return sorted.reduce((a, b) => a + b) / sorted.length;
    } else {
      // 'bestN' strategy: Average of the best N
      int n = quizN;
      if (n <= 0) n = 1;
      if (n > sorted.length) n = sorted.length;

      final bestN = sorted.take(n).toList();
      return bestN.reduce((a, b) => a + b) / n; // Divide by N (averaged)
    }
  }

  /// Total possible marks (sum of distribution)
  double get totalPossible {
    return (distribution.mid ?? 0) +
        (distribution.finalExam ?? 0) +
        (distribution.quiz ?? 0) +
        (distribution.shortQuiz ?? 0) +
        (distribution.assignment ?? 0) +
        (distribution.presentation ?? 0) +
        (distribution.viva ?? 0) +
        (distribution.lab ?? 0) +
        (distribution.attendance ?? 0);
  }

  /// Calculates marks needed in Final to reach each grade (A+ to F)
  Map<String, double> getRequiredFinalMarks() {
    // EWU grading scale (out of 100)
    final targets = {
      'A+': 80.0,
      'A': 75.0,
      'A-': 70.0,
      'B+': 65.0,
      'B': 60.0,
      'B-': 55.0,
      'C+': 50.0,
      'C': 45.0,
      'D': 40.0,
      'F': 0.0,
    };
    final results = <String, double>{};

    final obtainedExcludingFinal = totalObtained - (obtained.finalExam ?? 0);
    final finalMax = distribution.finalExam ?? 0;

    targets.forEach((grade, target) {
      if (grade == 'F') {
        results[grade] = 0; // F is always achievable (unfortunately)
        return;
      }
      final required = target - obtainedExcludingFinal;
      if (required > finalMax) {
        results[grade] = -1; // Impossible
      } else if (required <= 0) {
        results[grade] = 0; // Already achieved
      } else {
        results[grade] = required;
      }
    });

    return results;
  }

  /// Gets the current predicted grade based on total obtained
  String get predictedGrade {
    final total = totalObtained;
    if (total >= 80) return 'A+';
    if (total >= 75) return 'A';
    if (total >= 70) return 'A-';
    if (total >= 65) return 'B+';
    if (total >= 60) return 'B';
    if (total >= 55) return 'B-';
    if (total >= 50) return 'C+';
    if (total >= 45) return 'C';
    if (total >= 40) return 'D';
    return 'F';
  }

  factory CourseMarks.fromMap(Map<String, dynamic> map) {
    return CourseMarks(
      courseCode: map['courseCode'] ?? '',
      courseName: map['courseName'] ?? '',
      distribution: MarkDistribution.fromMap(map['distribution'] ?? {}),
      obtained: ObtainedMarks.fromMap(map['obtained'] ?? {}),
      quizStrategy: map['quizStrategy'] ?? 'bestN',
      quizN: map['quizN'] ?? 2,
      shortQuizN: map['shortQuizN'] ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'distribution': distribution.toMap(),
      'obtained': obtained.toMap(),
      'quizStrategy': quizStrategy,
      'quizN': quizN,
      'shortQuizN': shortQuizN,
    };
  }
}

/// Full marks for each category
class MarkDistribution {
  final double? mid;
  final double? finalExam;
  final double? quiz;
  final double? shortQuiz;
  final double? assignment;
  final double? presentation;
  final double? viva;
  final double? attendance;
  final double? lab;

  MarkDistribution({
    this.mid,
    this.finalExam,
    this.quiz,
    this.shortQuiz,
    this.assignment,
    this.presentation,
    this.viva,
    this.attendance,
    this.lab,
  });

  factory MarkDistribution.fromMap(Map<String, dynamic> map) {
    return MarkDistribution(
      mid: (map['mid'] as num?)?.toDouble(),
      finalExam: (map['finalExam'] as num?)?.toDouble(),
      quiz: (map['quiz'] as num?)?.toDouble(),
      shortQuiz: (map['shortQuiz'] as num?)?.toDouble(),
      assignment: (map['assignment'] as num?)?.toDouble(),
      presentation: (map['presentation'] as num?)?.toDouble(),
      viva: (map['viva'] as num?)?.toDouble(),
      attendance: (map['attendance'] as num?)?.toDouble(),
      lab: (map['lab'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mid': mid,
      'finalExam': finalExam,
      'quiz': quiz,
      'shortQuiz': shortQuiz,
      'assignment': assignment,
      'presentation': presentation,
      'viva': viva,
      'attendance': attendance,
      'lab': lab,
    };
  }
}

/// Marks obtained by the student
class ObtainedMarks {
  double? mid;
  double? finalExam;
  List<double> quizzes;
  List<double> shortQuizzes;
  double? assignment;
  double? presentation;
  double? viva;
  double? attendance;
  double? lab;

  ObtainedMarks({
    this.mid,
    this.finalExam,
    this.quizzes = const [],
    this.shortQuizzes = const [],
    this.assignment,
    this.presentation,
    this.viva,
    this.attendance,
    this.lab,
  });

  factory ObtainedMarks.fromMap(Map<String, dynamic> map) {
    return ObtainedMarks(
      mid: (map['mid'] as num?)?.toDouble(),
      finalExam: (map['finalExam'] as num?)?.toDouble(),
      quizzes: (map['quizzes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      shortQuizzes: (map['shortQuizzes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      assignment: (map['assignment'] as num?)?.toDouble(),
      presentation: (map['presentation'] as num?)?.toDouble(),
      viva: (map['viva'] as num?)?.toDouble(),
      attendance: (map['attendance'] as num?)?.toDouble(),
      lab: (map['lab'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mid': mid,
      'finalExam': finalExam,
      'quizzes': quizzes,
      'shortQuizzes': shortQuizzes,
      'assignment': assignment,
      'presentation': presentation,
      'viva': viva,
      'attendance': attendance,
      'lab': lab,
    };
  }
}

/// Represents basic course data for progress screen
class CourseProgressData {
  final String code;
  final String name;
  final String section;
  final String grade;
  final String docId;

  CourseProgressData({
    required this.code,
    required this.name,
    this.section = '',
    this.grade = 'Ongoing',
    this.docId = '',
  });

  factory CourseProgressData.fromMap(Map<String, dynamic> map) {
    return CourseProgressData(
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      section: map['section'] ?? '',
      grade: map['grade'] ?? 'Ongoing',
      docId: map['docId'] ?? '',
    );
  }
}
