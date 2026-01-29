import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OnboardingRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final doc = await _db.collection('metadata').doc('departments').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['list'] is List) {
          return List<Map<String, dynamic>>.from(data['list']);
        }
      }
    } catch (e) {
      // ignore
    }

    return [
      {
        "name": "Dept. of CSE",
        "programs": [
          {"id": "cse_eng", "name": "B.Sc. in Computer Science & Engineering"},
          {
            "id": "cse_ice",
            "name": "B.Sc. in Information & Communication Engineering"
          }
        ]
      },
      {
        "name": "Dept. of Business",
        "programs": [
          {"id": "bba", "name": "Bachelor of Business Administration"},
          {"id": "mba", "name": "Master of Business Administration"}
        ]
      },
      {
        "name": "Dept. of EEE",
        "programs": [
          {"id": "eee", "name": "B.Sc. in Electrical & Electronic Engineering"},
          {
            "id": "ete",
            "name": "B.Sc. in Electronics & Telecommunication Engineering"
          }
        ]
      },
      {
        "name": "Dept. of Pharmacy",
        "programs": [
          {"id": "pha_b", "name": "Bachelor of Pharmacy"},
          {"id": "pha_m", "name": "Master of Pharmacy"}
        ]
      },
      {
        "name": "Dept. of English",
        "programs": [
          {"id": "eng_ba", "name": "B.A. in English"}
        ]
      },
      {
        "name": "Dept. of Sociology",
        "programs": [
          {"id": "soc_bss", "name": "B.S.S. in Sociology"}
        ]
      },
      {
        "name": "Dept. of Economics",
        "programs": [
          {"id": "eco_bss", "name": "B.S.S. in Economics"}
        ]
      },
      {
        "name": "Dept. of GEB",
        "programs": [
          {"id": "geb", "name": "B.Sc. in Genetic Engineering & Biotechnology"}
        ]
      }
    ];
  }

  Future<void> saveProgram(
      String programId, String deptName, String admittedSemester) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    await _db.collection('users').doc(uid).set({
      'programId': programId,
      'department': deptName,
      'admittedSemester': admittedSemester, // New field for context awareness
      'onboardingStatus': 'program_selected',
    }, SetOptions(merge: true));
  }

  /// Saves course history, separating Live (Current) vs Archived (Past) semesters
  Future<void> saveCourseHistory(Map<String, Map<String, String>> history,
      List<String> enrolledIds, String currentSemester) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    // 1. Separate Current vs Past
    final pastHistory = Map<String, Map<String, String>>.from(history);
    final Map<String, String> currentCourses =
        pastHistory.remove(currentSemester) ?? {};

    // 2. Flatten Past for "completedCourses"
    final completed = <String>[];
    pastHistory.forEach((sem, courses) {
      courses.forEach((code, grade) {
        if (grade != "Ongoing") {
          completed.add(code);
        }
      });
    });

    // 3. Save User Doc (Clean History + Metadata)
    await _db.collection('users').doc(uid).set({
      'courseHistory': pastHistory,
      'completedCourses': completed,
      'enrolledSections': enrolledIds, // Used by Dashboard for context
      'onboardingStatus': 'onboarded',
    }, SetOptions(merge: true));

    // 4. Initialize Live Semester (Subcollections)
    if (currentCourses.isNotEmpty) {
      final safeSem =
          currentSemester.replaceAll(" ", ""); // "Spring 2026" -> "Spring2026"
      final batch = _db.batch();

      for (var code in currentCourses.keys) {
        final docRef = _db
            .collection('users')
            .doc(uid)
            .collection('semesterProgress')
            .doc(safeSem)
            .collection('courses')
            .doc(code);

        batch.set(
            docRef,
            {
              'courseCode': code,
              'courseName': code, // We might lack name here, fallback to code.
              'distribution': {},
              'obtained': {'quizzes': [], 'shortQuizzes': []},
              'quizStrategy': 'bestN',
            },
            SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint("Onboarding: Live courses initialized for $safeSem");

      // 5. Touch parent document to trigger Cloud schedule generation
      await _db
          .collection('users')
          .doc(uid)
          .collection('semesterProgress')
          .doc(safeSem)
          .set({
        'semesterCode': safeSem,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("Onboarding: Triggered schedule generation for $safeSem");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourseCatalog(
      {String? semester, bool isCurrent = false, String? searchQuery}) async {
    // 1. Try Specific Semester (Priority)
    if (semester != null) {
      final safeSem = semester.replaceAll(" ", "");
      final collection = "courses_$safeSem";

      try {
        final queryStr = searchQuery?.toUpperCase().replaceAll(' ', '').trim();
        List<QueryDocumentSnapshot> docs = [];

        if (queryStr != null && queryStr.isNotEmpty) {
          // Try 'courseCode' field first (Preferred format)
          var snapshot = await _db
              .collection(collection)
              .where('courseCode', isGreaterThanOrEqualTo: queryStr)
              .where('courseCode', isLessThanOrEqualTo: '$queryStr\uf8ff')
              .limit(100)
              .get();

          if (snapshot.docs.isEmpty) {
            // Try 'code' field (Legacy/Alternative format)
            snapshot = await _db
                .collection(collection)
                .where('code', isGreaterThanOrEqualTo: queryStr)
                .where('code', isLessThanOrEqualTo: '$queryStr\uf8ff')
                .limit(100)
                .get();
          }
          docs = snapshot.docs;
        } else {
          // Default initial load: Just 100 items to keep it snappy
          final snapshot = await _db.collection(collection).limit(100).get();
          docs = snapshot.docs;
        }

        if (docs.isNotEmpty) {
          if (isCurrent) {
            final groups = <String, Map<String, dynamic>>{};

            for (var d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final rawCode = data['courseCode'] ?? data['code'] ?? "???";
              final code = rawCode.toString().replaceAll(' ', '');
              final section = (data['section'] ?? 'N/A').toString();
              final key = "${code}_Sec$section";

              // Build schedule from sessions array
              String schedule = "TBA";
              if (data['sessions'] is List &&
                  (data['sessions'] as List).isNotEmpty) {
                final sessions = data['sessions'] as List;
                final scheduleList = sessions.map((s) {
                  final day = s['day'] ?? 'TBA';
                  final start = s['startTime'] ?? '??';
                  final end = s['endTime'] ?? '??';
                  return "$day $start-$end";
                }).toList();
                schedule = scheduleList.join(", ");
              } else {
                // Fallback to legacy format
                schedule =
                    "${data['day'] ?? 'TBA'} ${data['startTime'] ?? '??'}-${data['endTime'] ?? '??'}";
              }

              if (!groups.containsKey(key)) {
                groups[key] = {
                  'id': d.id, // Primary ID
                  'allIds': [d.id],
                  'code': code,
                  'name': (data['courseName'] ?? rawCode).toString(),
                  'section': section,
                  'schedules': [schedule],
                };
              } else {
                groups[key]!['allIds'].add(d.id);
                groups[key]!['schedules'].add(schedule);
              }
            }

            return groups.values.map((g) {
              return {
                ...g,
                'time': (g['schedules'] as List).join(", "),
                'day': "", // Combined into time
              };
            }).toList();
          } else {
            final unique = <String, Map<String, dynamic>>{};
            for (var d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final rawCode = data['courseCode'] ?? data['code'];
              if (rawCode != null) {
                final code = rawCode.toString().replaceAll(' ', '');
                if (!unique.containsKey(code)) {
                  unique[code] = {
                    'code': code,
                    'name': (data['courseName'] ?? rawCode).toString(),
                  };
                }
              }
            }
            if (unique.isNotEmpty) return unique.values.toList();
          }
        }
      } catch (e) {
        // // print("Catalog Search Error ($collection): $e");
      }
    }

    // 2. Try Global Metadata (Master Catalog)
    try {
      final doc = await _db.collection('metadata').doc('courses').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['list'] is List) {
          final list = List<dynamic>.from(data['list']);
          final queryStr =
              searchQuery?.toUpperCase().replaceAll(' ', '').trim();

          return list
              .where((item) {
                if (queryStr == null || queryStr.isEmpty) return true;
                final m = item as Map;
                final code = (m['code'] ?? "")
                    .toString()
                    .toUpperCase()
                    .replaceAll(' ', '');
                return code.contains(queryStr);
              })
              .map((item) {
                final m = Map<String, dynamic>.from(item as Map);
                final rawCode = (m['code'] ?? '???').toString();
                final code = rawCode.replaceAll(' ', '');
                return {
                  'code': code,
                  'name': (m['name'] ?? rawCode).toString(),
                };
              })
              .take(100)
              .toList();
        }
      }
    } catch (e) {
      // // print("Master Catalog Error: $e");
    }

    // 3. Hard Fallback
    return [];
  }
}
