class AdvisingCourseItem {
  final String code;
  final String name;
  final double credits;
  final String areaName;
  final bool isCompulsory;
  final String status; // 'ELIGIBLE', 'LOCKED', 'COMPLETED', 'CURRENTLY_ENROLLED'
  final String? grade;
  final String? semester;
  final String? section;
  final List<String> prerequisites;
  final List<String> fulfilledPrerequisites;
  final List<String> missingPrerequisites;
  final double? requiredCredits;
  final List<String> lockReasons;
  final bool isOffered;
  final int sectionCount;
  final bool isRetakeEligible;

  const AdvisingCourseItem({
    required this.code,
    required this.name,
    required this.credits,
    required this.areaName,
    required this.isCompulsory,
    required this.status,
    this.grade,
    this.semester,
    this.section,
    this.prerequisites = const [],
    this.fulfilledPrerequisites = const [],
    this.missingPrerequisites = const [],
    this.requiredCredits,
    this.lockReasons = const [],
    this.isOffered = false,
    this.sectionCount = 0,
    this.isRetakeEligible = false,
  });

  bool get isEligible => status == 'ELIGIBLE';
  bool get isLocked => status == 'LOCKED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isEnrolled => status == 'CURRENTLY_ENROLLED';

  factory AdvisingCourseItem.fromJson(Map<String, dynamic> json) {
    return AdvisingCourseItem(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? 3.0,
      areaName: json['area_name']?.toString() ?? 'General',
      isCompulsory: json['is_compulsory'] == true,
      status: json['status']?.toString().toUpperCase() ?? 'LOCKED',
      grade: json['grade']?.toString(),
      semester: json['semester']?.toString(),
      section: json['section']?.toString(),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fulfilledPrerequisites: (json['fulfilled_prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missingPrerequisites: (json['missing_prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      requiredCredits: (json['required_credits'] as num?)?.toDouble(),
      lockReasons: (json['lock_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isOffered: json['is_offered'] == true,
      sectionCount: (json['section_count'] as num?)?.toInt() ?? 0,
      isRetakeEligible: json['is_retake_eligible'] == true,
    );
  }
}

class AdvisingAreaSummary {
  final String areaName;
  final int eligibleCount;
  final int lockedCount;
  final int completedCount;
  final List<AdvisingCourseItem> courses;

  const AdvisingAreaSummary({
    required this.areaName,
    this.eligibleCount = 0,
    this.lockedCount = 0,
    this.completedCount = 0,
    this.courses = const [],
  });

  factory AdvisingAreaSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['courses'] as List<dynamic>?)
            ?.map((e) => AdvisingCourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return AdvisingAreaSummary(
      areaName: json['area_name']?.toString() ?? 'General',
      eligibleCount: (json['eligible_count'] as num?)?.toInt() ?? 0,
      lockedCount: (json['locked_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      courses: list,
    );
  }
}

class AdvisingGuideData {
  final String programCode;
  final String programName;
  final String? departmentName;
  final double totalDegreeCredits;
  final double completedCredits;
  final int totalCurriculumCourses;
  final int completedCount;
  final int enrolledCount;
  final int eligibleCount;
  final int lockedCount;
  final int retakeCount;
  final List<AdvisingAreaSummary> areas;
  final List<AdvisingCourseItem> eligibleCourses;
  final List<AdvisingCourseItem> lockedCourses;
  final List<AdvisingCourseItem> completedCourses;
  final List<AdvisingCourseItem> enrolledCourses;

  const AdvisingGuideData({
    required this.programCode,
    required this.programName,
    this.departmentName,
    this.totalDegreeCredits = 130.0,
    this.completedCredits = 0.0,
    this.totalCurriculumCourses = 0,
    this.completedCount = 0,
    this.enrolledCount = 0,
    this.eligibleCount = 0,
    this.lockedCount = 0,
    this.retakeCount = 0,
    this.areas = const [],
    this.eligibleCourses = const [],
    this.lockedCourses = const [],
    this.completedCourses = const [],
    this.enrolledCourses = const [],
  });

  factory AdvisingGuideData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    final areasList = (json['areas'] as List<dynamic>?)
            ?.map((e) => AdvisingAreaSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final eligibleList = (json['eligible_courses'] as List<dynamic>?)
            ?.map((e) => AdvisingCourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final lockedList = (json['locked_courses'] as List<dynamic>?)
            ?.map((e) => AdvisingCourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final completedList = (json['completed_courses'] as List<dynamic>?)
            ?.map((e) => AdvisingCourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final enrolledList = (json['enrolled_courses'] as List<dynamic>?)
            ?.map((e) => AdvisingCourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return AdvisingGuideData(
      programCode: json['program_code']?.toString() ?? '',
      programName: json['program_name']?.toString() ?? (json['program_code']?.toString() ?? ''),
      departmentName: json['department_name']?.toString(),
      totalDegreeCredits: (json['total_degree_credits'] as num?)?.toDouble() ?? 130.0,
      completedCredits: (json['completed_credits'] as num?)?.toDouble() ?? 0.0,
      totalCurriculumCourses: (summary['total_curriculum_courses'] as num?)?.toInt() ??
          (eligibleList.length + lockedList.length + completedList.length + enrolledList.length),
      completedCount: (summary['completed_count'] as num?)?.toInt() ?? completedList.length,
      enrolledCount: (summary['enrolled_count'] as num?)?.toInt() ?? enrolledList.length,
      eligibleCount: (summary['eligible_count'] as num?)?.toInt() ?? eligibleList.length,
      lockedCount: (summary['locked_count'] as num?)?.toInt() ?? lockedList.length,
      retakeCount: (summary['retake_eligible_count'] as num?)?.toInt() ?? 0,
      areas: areasList,
      eligibleCourses: eligibleList,
      lockedCourses: lockedList,
      completedCourses: completedList,
      enrolledCourses: enrolledList,
    );
  }
}
