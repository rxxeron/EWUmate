import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/result_models.dart';
// Unused imports removed

class ResultsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for metadata
  static final Map<String, double> _courseCreditsCache = {};
  static bool _metadataLoaded = false;

  Future<AcademicProfile> fetchAcademicProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
    }

    await _ensureMetadataLoaded();

    try {
      // Cloud source of truth: user doc itself (users/{uid})
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final data = userDoc.data();
      if (userDoc.exists && data != null) {
        final semesters = _buildSemestersFromUserDoc(data);
        return _buildProfileFromCloudData(semesters, data);
      }
    } catch (e) {
      debugPrint("Error fetching user profile doc: $e");
    }

    return AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
  }

  Future<void> _ensureMetadataLoaded() async {
    if (_metadataLoaded) return;
    try {
      // 1. Fetch Course Credits
      final courseDoc =
          await _firestore.collection('metadata').doc('courses').get();
      if (courseDoc.exists && courseDoc.data() != null) {
        final data = courseDoc.data()!;
        if (data['list'] is List) {
          for (var item in data['list']) {
            if (item is Map) {
              final code = item['code']?.toString().toUpperCase() ?? '';
              // Use creditVal (number) or fallback to parsing credits (string)
              double val = 3.0;
              if (item['creditVal'] is num) {
                val = (item['creditVal'] as num).toDouble();
              } else if (item['credits'] != null) {
                val = double.tryParse(item['credits'].toString()) ?? 3.0;
              }

              if (code.isNotEmpty) _courseCreditsCache[code] = val;
            }
          }
        }
      }
      _metadataLoaded = true;
    } catch (e) {
      debugPrint("Error loading metadata: $e");
    }
  }

  Stream<AcademicProfile> streamAcademicProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(
          AcademicProfile(semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0));
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userSnapshot) async {
      // Ensure metadata is available for parsing
      await _ensureMetadataLoaded();

      final userData = userSnapshot.data();
      if (!userSnapshot.exists || userData == null) {
        return AcademicProfile(
            semesters: [], cgpa: 0.0, totalCreditsEarned: 0.0);
      }

      try {
        // Fetch the server-calculated profile
        final profileDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('academic_data')
            .doc('profile')
            .get();

        if (profileDoc.exists && profileDoc.data() != null) {
          final profileData = profileDoc.data()!;

          // Use Server Data for Logic/Stats
          // But keep User Info from User Doc
          return AcademicProfile(
            semesters: _parseCloudSemesters(profileData['semesters']),
            cgpa: _readDouble(profileData['cgpa']),
            totalCreditsEarned: _readDouble(profileData['totalCreditsEarned']),
            studentName: (userData['fullName'] ?? 'Student').toString(),
            studentId: (userData['studentId'] ?? 'N/A').toString(),
            program: (profileData['programName'] ??
                    userData['programName'] ??
                    userData['programId'] ??
                    'N/A')
                .toString(),
            department: (userData['department'] ?? 'N/A').toString(),
            totalCoursesCompleted:
                _readInt(profileData['totalCoursesCompleted']),
            remainedCredits: _readDouble(profileData['remainedCredits']),
            scholarshipStatus: (userData['scholarshipStatus'] ?? '').toString(),
          );
        }
      } catch (e) {
        debugPrint("Error fetching profile sub-doc: $e");
      }

      // Fallback: Local Parsing
      final semesters = _buildSemestersFromUserDoc(userData);
      return AcademicProfile(
        semesters: semesters.reversed.toList(),
        cgpa: _readCgpa(userData),
        totalCreditsEarned: _readTotalCredits(userData),
        studentName: (userData['fullName'] ?? 'Student').toString(),
        studentId: (userData['studentId'] ?? 'N/A').toString(),
        program: (userData['programName'] ?? userData['programId'] ?? 'N/A')
            .toString(),
        department: (userData['department'] ?? 'N/A').toString(),
        totalCoursesCompleted: _readCoursesCompleted(userData),
        remainedCredits: _readRemainedCredits(userData),
        scholarshipStatus: _calculateScholarship(
          userData['studentId']?.toString() ?? '',
          userData['programName']?.toString() ??
              userData['programId']?.toString() ??
              '',
          _readCgpa(userData),
          semesters.reversed
              .toList(), // calculate expects oldest->newest usually? let's check input
        ),
      );
    });
  }

  // Helper to parse the list from Cloud Profile
  List<SemesterResult> _parseCloudSemesters(dynamic list) {
    if (list is! List) return [];
    try {
      final sems = list
          .map((item) {
            if (item is! Map) return null;
            final data = Map<String, dynamic>.from(item);

            final courses = (data['courses'] as List? ?? []).map((c) {
              final cMap = Map<String, dynamic>.from(c as Map);
              return CourseResult(
                  courseCode: cMap['code'] ?? '',
                  courseTitle: cMap['title'] ?? cMap['code'] ?? '',
                  credits: _readDouble(cMap['credits']),
                  grade: cMap['grade'] ?? '',
                  gradePoint: _readDouble(cMap['point']));
            }).toList();

            final sem = SemesterResult(
                semesterName: data['semesterName'] ?? '', courses: courses);
            // termGPA is often already in cloud data, but we can recalc or read it
            if (data.containsKey('termGPA')) {
              // We might need to extend SemesterResult to hold termGPA or just calculate it
              // SemesterResult calculates it in getter usually?
              // Looking at model: SemesterResult has calculateTermGPA() method but no setter?
              // It calculates from courses.
              sem.calculateTermGPA();
            }
            return sem;
          })
          .whereType<SemesterResult>()
          .toList();

      // Sort? Cloud usually sends sorted, but safety check
      sems.sort((a, b) => _compareSemesterName(a.semesterName, b.semesterName));

      // Calculate Cumulative GPA locally to ensure it's always correct
      _calculateRunningCGPA(sems);

      return sems.reversed.toList(); // Newest first
    } catch (e) {
      debugPrint("Error parsing cloud semesters: $e");
      return [];
    }
  }

  void _calculateRunningCGPA(List<SemesterResult> sems) {
    double totalPoints = 0;
    double totalCredits = 0;

    // Sems are sorted Oldest -> Newest
    for (var sem in sems) {
      // Add this term's stats
      totalPoints += sem.totalPoints;
      totalCredits += sem.totalCredits;

      if (totalCredits > 0) {
        sem.cumulativeGPA = totalPoints / totalCredits;
      } else {
        sem.cumulativeGPA = 0.0;
      }
    }
  }

  double _readDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _readInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  /// Fetches course list for AutoComplete
  Future<List<String>> fetchCourseCodes() async {
    try {
      final doc = await _firestore.collection('metadata').doc('courses').get();
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      if (data['list'] is List) {
        final list = List.from(data['list']);
        return list
            .map((item) {
              if (item is Map) {
                return item['id']?.toString() ?? item['code']?.toString() ?? '';
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .map((s) => s.toUpperCase())
            .toSet()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching course codes: $e");
      return [];
    }
  }

  List<SemesterResult> _buildSemestersFromUserDoc(Map<String, dynamic> data) {
    final rawHistory = data['courseHistory'];
    if (rawHistory is! Map) return [];

    final courseHistory = Map<String, dynamic>.from(rawHistory);
    final semesters = <SemesterResult>[];

    courseHistory.forEach((semesterName, coursesMap) {
      if (coursesMap is! Map) return;
      final courseGrades = Map<String, dynamic>.from(coursesMap);

      final courses = <CourseResult>[];
      courseGrades.forEach((code, gradeVal) {
        final codeStr = code.toString();
        final gradeStr = gradeVal?.toString() ?? '';

        // Credits: Lookup from cache, default to 3.0 if missing
        double credits = 3.0;
        if (_courseCreditsCache.containsKey(codeStr.toUpperCase())) {
          credits = _courseCreditsCache[codeStr.toUpperCase()]!;
        }

        courses.add(CourseResult(
          courseCode: codeStr,
          courseTitle: codeStr,
          credits: credits,
          grade: gradeStr,
          gradePoint: _gradeToPoint(gradeStr),
        ));
      });

      final sem = SemesterResult(
          semesterName: semesterName.toString(), courses: courses);
      sem.calculateTermGPA();
      semesters.add(sem);
    });

    // Handle Enrolled Sections (Ongoing)
    if (data['enrolledSections'] is List) {
      final enrolled = List.from(data['enrolledSections']);

      // Find Existing Current Sem or Create New
      // We need to know "Current Semester".
      // Fallback: If not in history, use "Spring 2026" or parse from ID?
      // Ideal: Parse from ID if format allows: CODE_SECTION_SEM

      for (var sectionId in enrolled) {
        if (sectionId is! String) continue;

        String code = '';
        String semester = 'Ongoing Semester';

        // Format 1: course_CODE_SECTION (e.g. course_ICE107_12) -> No sem in ID, assume Current
        if (sectionId.startsWith('course_')) {
          final parts = sectionId.split('_');
          if (parts.length >= 2) code = parts[1];
        }
        // Format 2: CODE_SECTION_SEM (e.g. ICE107_12_Spring2026)
        else {
          final parts = sectionId.split('_');
          if (parts.length >= 3) {
            code = parts[0];
            semester = parts[2]; // Use this sem if explicit
          } else {
            code = parts[0];
          }
        }

        if (code.isNotEmpty) {
          // Check if already in history (don't duplicate)
          bool alreadyExists = false;
          for (var s in semesters) {
            if (s.courses.any((c) => c.courseCode == code)) {
              alreadyExists = true;
              break;
            }
          }

          if (!alreadyExists) {
            // Add to map for grouping
            // Note: Simpler to just add to a 'Current' semester list if we don't know sem name
            // But if we want to merge into specific sem, we need that sem name.
            // Let's use a placeholder "Current Enrolled" if unknown, or try to merge.

            // Simplification: We add to a temporary list and merge later?
            // Or just add to "Ongoing" semester.

            // Let's try to match existing semester if possible, else create new.
            // Logic: Find semester with "Spring 2026" (or equivalent) in semesters list?
            // Since we don't have global config here easily without async, let's use "Spring 2026" fallback for now or "Current"

            final course = CourseResult(
                courseCode: code,
                courseTitle: code,
                credits: 3.0, // Should use metadata logic ideally vs fixed 3.0
                grade: 'Ongoing',
                gradePoint: 0.0);

            // Find or create semester
            var targetSemName =
                (semester == 'Ongoing Semester') ? 'Spring 2026' : semester;
            // Normalize name spacing? "Spring2026" -> "Spring 2026"
            if (!targetSemName.contains(' ')) {
              // naive split
              targetSemName =
                  targetSemName.replaceFirst(RegExp(r'(\d+)'), ' \$1');
            }

            var semResult = semesters
                .firstWhere((s) => s.semesterName == targetSemName, orElse: () {
              final newSem =
                  SemesterResult(semesterName: targetSemName, courses: []);
              semesters.add(newSem);
              return newSem;
            });

            semResult.courses.add(course);
          }
        }
      }
    }

    semesters
        .sort((a, b) => _compareSemesterName(a.semesterName, b.semesterName));
    _calculateRunningCGPA(semesters);
    return semesters;
  }

  static int _compareSemesterName(String a, String b) {
    final pa = _parseSemesterName(a);
    final pb = _parseSemesterName(b);
    final yearCmp = pa.$2.compareTo(pb.$2);
    if (yearCmp != 0) return yearCmp;
    return pa.$1.compareTo(pb.$1);
  }

  /// Returns (termOrder, year). termOrder: Spring=1, Summer=2, Fall=3, else=99
  static (int, int) _parseSemesterName(String name) {
    final lower = name.toLowerCase().trim();
    int term = 99;
    if (lower.contains('spring')) term = 1;
    if (lower.contains('summer')) term = 2;
    if (lower.contains('fall')) term = 3;

    final yearMatch = RegExp(r'(20\d{2})').firstMatch(lower);
    final year = int.tryParse(yearMatch?.group(1) ?? '') ?? 0;
    return (term, year);
  }

  static double _gradeToPoint(String grade) {
    final g = grade.trim().toUpperCase();
    switch (g) {
      case 'A+':
        return 4.00;
      case 'A':
        return 3.75;
      case 'A-':
        return 3.50;
      case 'B+':
        return 3.25;
      case 'B':
        return 3.00;
      case 'B-':
        return 2.75;
      case 'C+':
        return 2.50;
      case 'C':
        return 2.25;
      case 'D':
        return 2.00;
      case 'F':
        return 0.00;
      case 'W':
      case 'I':
      case 'ONGOING':
      case '':
        return 0.00;
      default:
        return 0.00;
    }
  }

  static double _readCgpa(Map<String, dynamic> data) {
    final stats = data['statistics'];
    if (stats is Map) {
      return (stats['cgpa'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  static double _readTotalCredits(Map<String, dynamic> data) {
    final stats = data['statistics'];
    if (stats is Map) {
      return (stats['totalCredits'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  static int _readCoursesCompleted(Map<String, dynamic> data) {
    final stats = data['statistics'];
    if (stats is Map) {
      return (stats['coursesCompleted'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static double _readRemainedCredits(Map<String, dynamic> data) {
    final stats = data['statistics'];
    if (stats is Map) {
      return (stats['remainedCredits'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<AcademicProfile> _buildProfileFromCloudData(
      List<SemesterResult> semesters, Map<String, dynamic> data) async {
    // Metadata Extraction
    String studentName = "Student";
    String studentId = "N/A";
    String program = "N/A";
    String dept = "N/A";

    if (data['studentId'] != null) studentId = data['studentId'].toString();
    if (data['fullName'] != null) {
      studentName = data['fullName'].toString();
    }

    // Program Resolution
    if (data['programName'] != null) {
      program = data['programName'].toString();
      // If programName is just the ID (e.g. "ice"), try to resolve it again locally
      if (program.length <= 4 ||
          program.toLowerCase() == data['programId'].toString().toLowerCase()) {
        final resolved = await _resolveProgramName(program);
        // Only overwrite if resolution gives a longer/different name
        if (resolved.length > program.length) {
          program = resolved;
        }
      }
    } else if (data['programId'] != null) {
      // Fallback: Resolve client-side if missing in cloud doc
      program = await _resolveProgramName(data['programId'].toString());
    }

    if (data['department'] != null) dept = data['department'].toString();

    // Stats from User Doc (Cloud calculated)
    double finalCGPA = 0.0;
    double finalTotalCredits = 0.0;
    int finalCoursesCompleted = 0;
    double finalRemained = 0.0;

    if (data['statistics'] != null) {
      final stats = data['statistics'];
      finalCGPA = double.tryParse(stats['cgpa']?.toString() ?? "0.0") ?? 0.0;
      finalTotalCredits =
          double.tryParse(stats['totalCredits']?.toString() ?? "0.0") ?? 0.0;
      finalCoursesCompleted =
          int.tryParse(stats['coursesCompleted']?.toString() ?? "0") ?? 0;

      if (stats is Map && stats.containsKey('remainedCredits')) {
        finalRemained =
            double.tryParse(stats['remainedCredits']?.toString() ?? "0.0") ??
                0.0;
      }
    }

    // Scholarship extraction moved to dynamic calculation below

    // Sort valid semesters (if cloud didn't) - usually cloud sends list in order but let's trust cloud list order
    // Cloud list in 'profile' doc is usually sorted.
    // We reverse it for UI (Newest first)? The UI currently expects Newest first?
    // Let's check UI... UI iterates them. Usually we want Newest on top.
    // If cloud sends oldest->newest, and we want Newest->Oldest, we reverse.
    // Assuming cloud sends historical order.

    return AcademicProfile(
      semesters: semesters.reversed.toList(),
      cgpa: finalCGPA,
      totalCreditsEarned: finalTotalCredits,
      studentName: studentName,
      studentId: studentId,
      program: program,
      department: dept,
      totalCoursesCompleted: finalCoursesCompleted,
      remainedCredits: finalRemained,
      scholarshipStatus: _calculateScholarship(
          studentId, program, finalCGPA, semesters.reversed.toList()),
    );
  }

  // --- EDITING CAPABILITIES ---

  /// Fetches the raw 'courseHistory' map for editing
  Future<Map<String, dynamic>> fetchRawCourseHistory() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('courseHistory')) {
        return Map<String, dynamic>.from(doc.data()!['courseHistory']);
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
    return {};
  }

  /// Updates the 'courseHistory' map in Firestore
  /// This will trigger the cloud function to recalculate stats
  Future<void> updateCourseHistory(Map<String, dynamic> history) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Recalculate completed courses based on the new history
    final Set<String> completed = {};
    history.forEach((semester, courses) {
      if (courses is Map) {
        courses.forEach((code, grade) {
          final g = grade.toString().toUpperCase();
          if (g != 'W' && g != 'I' && g != 'F' && g != 'ONGOING') {
            completed.add(code.toString().toUpperCase());
          }
        });
      }
    });

    await _firestore.collection('users').doc(user.uid).set({
      'courseHistory': history,
      'completedCourses': completed.toList(),
      'lastTouch': FieldValue.serverTimestamp(), // Trigger function
    }, SetOptions(merge: true));
  }

  /// Parses raw user data (Map) into an AcademicProfile object.
  /// Kept as FALLBACK until cloud migration is complete.
  Future<AcademicProfile> parseAcademicProfile(
      Map<String, dynamic> data) async {
    // 1. Raw Data Sources
    final Map<String, dynamic> courseHistory =
        data['courseHistory'] ?? {}; // {"Spring 2026": {"CSE101": "A+"}}
    final List<dynamic> academicResults = data['academicResults'] ??
        []; // [{courseCode:..., grade:..., credits:...}]

    // 2. Merge Logic
    Map<String, List<CourseResult>> groupedCourses = {};

    // Helper to find detailed result
    Map<String, dynamic>? findDetail(String semester, String code) {
      try {
        return academicResults.firstWhere((r) =>
            (r['semesterId'] == semester) &&
            (r['courseCode'] == code || r['courseId'] == code));
      } catch (e) {
        return null;
      }
    }

    // Process Course History (Onboarding Data)
    courseHistory.forEach((semester, coursesMap) {
      if (coursesMap is Map) {
        coursesMap.forEach((code, grade) {
          final detail = findDetail(semester, code);

          double credits = 3.0; // Default fallback
          String courseTitle = code;

          if (detail != null) {
            credits = (detail['credits'] is num)
                ? (detail['credits'] as num).toDouble()
                : 3.0;
            courseTitle = detail['courseName'] ?? code;
          }

          final point = (grade == "A+")
              ? 4.0
              : 0.0; // Simplified fallback for now as helpers were removed

          if (!groupedCourses.containsKey(semester)) {
            groupedCourses[semester] = [];
          }

          groupedCourses[semester]!.add(CourseResult(
            courseCode: code,
            courseTitle: courseTitle,
            credits: credits,
            grade: grade,
            gradePoint: point,
          ));
        });
      }
    });

    List<SemesterResult> semesters = [];
    groupedCourses.forEach((key, value) {
      semesters.add(SemesterResult(semesterName: key, courses: value));
    });

    return AcademicProfile(
        semesters: semesters,
        cgpa: 0.0,
        totalCreditsEarned: 0.0,
        studentName: "Student",
        studentId: "",
        program: "",
        department: "",
        totalCoursesCompleted: 0,
        remainedCredits: 0,
        scholarshipStatus: "");
  }

  // Dynamic Program Name Resolution
  Future<String> _resolveProgramName(String programId) async {
    if (programId.isEmpty) return "N/A";

    final lowerId = programId.toLowerCase();

    // 1. Try fetching from metadata cache or DB
    try {
      final doc =
          await _firestore.collection('metadata').doc('departments').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Scenario 1: Root 'programs' list (Matches user screenshot)
        if (data['programs'] is List) {
          final programs = data['programs'] as List<dynamic>;
          for (var p in programs) {
            if (p['id'].toString().toLowerCase() == lowerId) {
              return p['name'].toString();
            }
          }
        }

        // Scenario 2: Legacy 'list' of departments
        if (data['list'] is List) {
          final list = List<Map<String, dynamic>>.from(data['list']);
          for (var dept in list) {
            final programs = dept['programs'] as List<dynamic>? ?? [];
            for (var p in programs) {
              if (p['id'].toString().toLowerCase() == lowerId) {
                return p['name'].toString(); // Found in Metadata!
              }
            }
          }
        }
      }
    } catch (e) {
      // Only debug print if needed, silent fallback
    }

    // 2. Fallback to Local List (Expanded to Full Names)
    final fallbackList = [
      {
        "programs": [
          {"id": "cse_eng", "name": "B.Sc. in Computer Science & Engineering"},
          {
            "id": "cse_ice",
            "name": "B.Sc. in Information & Communication Engineering"
          },
          {
            "id": "cse",
            "name": "B.Sc. in Computer Science & Engineering"
          }, // Legacy fallback
          {
            "id": "ice",
            "name": "B.Sc. in Information & Communication Engineering"
          } // Legacy fallback
        ]
      },
      {
        "programs": [
          {"id": "bba", "name": "Bachelor of Business Administration"},
          {"id": "mba", "name": "Master of Business Administration"}
        ]
      },
      {
        "programs": [
          {"id": "eee", "name": "B.Sc. in Electrical & Electronic Engineering"},
          {
            "id": "ete",
            "name": "B.Sc. in Electronics & Telecommunication Engineering"
          }
        ]
      },
      {
        "programs": [
          {"id": "pha_b", "name": "Bachelor of Pharmacy"},
          {"id": "pha_m", "name": "Master of Pharmacy"},
          {"id": "pha", "name": "Bachelor of Pharmacy"}
        ]
      },
      {
        "programs": [
          {"id": "eng_ba", "name": "B.A. in English"},
          {"id": "eng", "name": "B.A. in English"}
        ]
      },
      {
        "programs": [
          {"id": "soc_bss", "name": "B.S.S. in Sociology"},
          {"id": "soc", "name": "B.S.S. in Sociology"}
        ]
      },
      {
        "programs": [
          {"id": "eco_bss", "name": "B.S.S. in Economics"},
          {"id": "eco", "name": "B.S.S. in Economics"}
        ]
      },
      {
        "programs": [
          {"id": "geb", "name": "B.Sc. in Genetic Engineering & Biotechnology"}
        ]
      }
    ];

    for (var dept in fallbackList) {
      final programs = dept['programs'] as List<dynamic>;
      for (var p in programs) {
        if (p['id'].toString().toLowerCase() == lowerId) {
          return p['name'].toString();
        }
      }
    }

    // 3. Last Resort Formatting
    if (lowerId == 'cse' || lowerId.contains('computer')) {
      return "Computer Science & Engineering";
    }
    if (programId.length <= 4) return programId.toUpperCase();
    return programId;
  }

  // --- SCHOLARSHIP CALCULATION ENGINE ---

  String _calculateScholarship(
    String studentId,
    String programName,
    double cgpa,
    List<SemesterResult> semesters,
  ) {
    if (cgpa < 3.50) return "";

    // 1. Parse Admission Info
    final (admissionTerm, admissionYear) = _parseAdmissionFromId(studentId);
    if (admissionYear == 0) return ""; // Cannot determine rules

    // 2. Determine Rule Set (Credits & CGPA) based on Admission
    // Rule Breakpoints:
    // - Spring 2026 (New CGPA Rules)
    // - Fall 2024 / Spring 2025 (New Credit Rules for some programs)

    bool isNewCGPARules = false;
    if (admissionYear > 2025) {
      isNewCGPARules = true;
    } else if (admissionYear == 2026 && admissionTerm >= 1) {
      isNewCGPARules = true; // Spring 2026+
    }

    // 3. Check CGPA Requirements
    String potentialScholarship = "";
    if (isNewCGPARules) {
      // Spring 2026+ Rules
      if (cgpa >= 3.95) {
        potentialScholarship = "100% Merit Scholarship";
      } else if (cgpa >= 3.85) {
        potentialScholarship = "Dean’s List Scholarship";
      } else if (cgpa >= 3.75) {
        potentialScholarship = "Medha Lalon Scholarship";
      }
    } else {
      // Old Rules (up to Fall 2025)
      if (cgpa >= 3.90) {
        potentialScholarship = "100% Merit Scholarship";
      } else if (cgpa >= 3.75) {
        potentialScholarship = "Dean’s List Scholarship";
      } else if (cgpa >= 3.50) {
        potentialScholarship = "Medha Lalon Scholarship";
      }
    }

    if (potentialScholarship.isEmpty) return "";

    // 4. Calculate Credits in Last 1 Year (Last 3 Completed Semesters)
    // Filter out "Ongoing" or current semester if incomplete
    // Sort semesters Descending (Newest First) to grab top 3
    final completedSemesters = semesters.where((s) {
      // Heuristic: If it has GPA > 0.0 or explicitly not ongoing
      // But we often default 0.0 for first sem.
      // Better: check if any course has a grade other than 'Ongoing'/'I'/'W'
      return s.courses
          .any((c) => c.grade != 'Ongoing' && c.grade != 'I' && c.grade != 'W');
    }).toList();

    // Sort Newest -> Oldest
    completedSemesters
        .sort((a, b) => _compareSemesterName(b.semesterName, a.semesterName));

    double creditsLastYear = 0.0;
    int acceptedSems = 0;

    for (var sem in completedSemesters) {
      if (acceptedSems >= 3) break;
      creditsLastYear += sem.totalCredits; // Use totalCredits (earned)
      acceptedSems++;
    }

    // 5. Determine Required Credits for Program
    final requiredCredits = _getRequiredCredits(
      programName,
      admissionYear,
      admissionTerm,
    );

    if (creditsLastYear >= requiredCredits) {
      return potentialScholarship;
    }

    return "";
  }

  /// Parses EWU ID format: YYYY-T-XX-PPP (e.g. 2023-1-60-012)
  (int, int) _parseAdmissionFromId(String id) {
    if (id.isEmpty) return (0, 0);
    final parts = id.split('-');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? 0;
      final term = int.tryParse(parts[1]) ?? 0;
      return (term, year);
    }
    return (0, 0);
  }

  double _getRequiredCredits(String programName, int admYear, int admTerm) {
    final p = programName.toLowerCase();

    // Normalize Logic
    bool afterFall2024 = (admYear > 2024) || (admYear == 2024 && admTerm >= 3);
    bool afterSpring2025 =
        (admYear > 2025) || (admYear == 2025 && admTerm >= 1);
    bool afterSpring2026 =
        (admYear > 2026) || (admYear == 2026 && admTerm >= 1);

    // --- SCIENCE / ENG ---
    if (p.contains('cse') || p.contains('computer science')) return 35;
    if (p.contains('ice') || p.contains('information & comm')) return 35;
    if (p.contains('eee') || p.contains('electrical')) return 35;
    if (p.contains('civil') || p.contains('ce')) {
      return afterSpring2026
          ? 35
          : 37; // "Admitted from Spring 2026": 35, else 37
    }
    if (p.contains('pharm')) return 39;
    if (p.contains('math')) return 33;
    if (p.contains('dsa') || p.contains('data science')) return 33;
    if (p.contains('geb') || p.contains('genetic')) {
      // Admitted from Spring 2026: 35, else 33
      return afterSpring2026 ? 35 : 33;
    }

    // --- BUSINESS ---
    if (p.contains('bba') || p.contains('business admin')) {
      // Admitted from Spring 2025: 33, else 30
      return afterSpring2025 ? 33 : 30;
    }
    if (p.contains('economics')) {
      // Admitted from Fall 2024: 33, else 30
      return afterFall2024 ? 33 : 30;
    }

    // --- ARTS / SOCIAL ---
    if (p.contains('english')) {
      // Admitted from Fall 2024: 33, else 30
      return afterFall2024 ? 33 : 30;
    }
    if (p.contains('soc') || p.contains('sociology')) {
      // Admitted from Spring 2025: 33, else 30
      return afterSpring2025 ? 33 : 30;
    }
    if (p.contains('information studies') || p.contains('info studies')) {
      return 30;
    }
    if (p.contains('law') || p.contains('ll.b')) return 33;
    if (p.contains('pphs') || p.contains('population')) {
      // Admitted from Fall 2024: 33, else 30
      return afterFall2024 ? 33 : 30;
    }

    // Default Fallback
    return 30;
  }
}
