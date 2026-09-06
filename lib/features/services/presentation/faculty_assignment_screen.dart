import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import '../repositories/faculty_assignment_repository.dart';

class FacultyAssignmentScreen extends ConsumerStatefulWidget {
  final String? initialCourseCode;
  final String? initialSection;

  const FacultyAssignmentScreen({
    super.key,
    this.initialCourseCode,
    this.initialSection,
  });

  @override
  ConsumerState<FacultyAssignmentScreen> createState() => _FacultyAssignmentScreenState();
}

class _FacultyAssignmentScreenState extends ConsumerState<FacultyAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Semester Selection State
  String _selectedSemester = 'Summer2026';
  List<String> _availableSemesters = ['Spring2026', 'Summer2026', 'Fall2026'];

  // State for Enrolled Courses Tab
  List<Map<String, dynamic>> _enrolledCourses = [];
  final Map<String, TextEditingController> _enrolledInitialControllers = {};
  Uint8List? _enrolledScreenshotBytes;
  String? _enrolledScreenshotName;

  // State for Bulk Non-Enrolled Tab
  List<Map<String, dynamic>> _facultyMaster = [];
  Map<String, dynamic>? _selectedFaculty;
  String _facultySearchQuery = '';
  Uint8List? _bulkScreenshotBytes;
  String? _bulkScreenshotName;
  final List<Map<String, String>> _bulkSelections = [];

  final TextEditingController _bulkCourseCodeCtrl = TextEditingController();
  final TextEditingController _bulkSectionCtrl = TextEditingController();

  // Course Catalog Dropdown State for Bulk Update
  List<String> _availableCourseCodes = [];
  Map<String, List<String>> _courseSectionsMap = {};
  String? _selectedBulkCourseCode;
  String? _selectedBulkSection;
  bool _manualMode = false;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize default semester from provider if available
    final currentSem = ref.read(currentSemesterCodeProvider).value ?? 'Summer2026';
    _selectedSemester = currentSem.replaceAll(' ', '');
    
    _loadInitialData();

    if (widget.initialCourseCode != null && widget.initialSection != null) {
      _selectedBulkCourseCode = widget.initialCourseCode!.toUpperCase();
      _selectedBulkSection = widget.initialSection!;
      _bulkCourseCodeCtrl.text = widget.initialCourseCode!;
      _bulkSectionCtrl.text = widget.initialSection!;
      _tabController.animateTo(1); // Switch to bulk/other sections tab
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bulkCourseCodeCtrl.dispose();
    _bulkSectionCtrl.dispose();
    for (var ctrl in _enrolledInitialControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = ref.read(facultyAssignmentRepositoryProvider);
      final supabase = ref.read(supabaseClientProvider);

      // 1. Fetch Faculty Master List
      final facList = await repo.fetchFacultyMasterList();

      // 2. Fetch Available Semesters List from DB
      try {
        final semRes = await supabase
            .from('semesters')
            .select('title')
            .order('created_at', ascending: false)
            .limit(10);

        if ((semRes as List).isNotEmpty) {
          final fetchedSems = (semRes as List)
              .map((e) => e['title']?.toString().replaceAll(' ', '') ?? '')
              .where((s) => s.isNotEmpty)
              .toList();

          if (fetchedSems.isNotEmpty) {
            if (!fetchedSems.contains(_selectedSemester)) {
              fetchedSems.insert(0, _selectedSemester);
            }
            _availableSemesters = fetchedSems.toSet().toList();
          }
        }
      } catch (e) {
        debugPrint('[FacultyAssignment] Using default semester list: $e');
      }

      await _loadDataForSemester(_selectedSemester, facList: facList);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDataForSemester(String semesterCode, {List<Map<String, dynamic>>? facList}) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final cleanSem = semesterCode.replaceAll(' ', '');

    // Clear previous enrolled initial controllers
    for (var ctrl in _enrolledInitialControllers.values) {
      ctrl.dispose();
    }
    _enrolledInitialControllers.clear();

    // Fetch Enrolled Courses for User in selected semester
    List<Map<String, dynamic>> enrolled = [];
    if (user != null) {
      final safeSemLower = cleanSem.toLowerCase();
      final spaceSem = cleanSem.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
      final possibleCodes = [cleanSem, safeSemLower, spaceSem, semesterCode];

      // 1. Try fetching from enrollments table (matching multiple semester code variations)
      try {
        final enrollRes = await supabase
            .from('enrollments')
            .select('course_code, section, semester_code')
            .eq('user_id', user.id)
            .inFilter('semester_code', possibleCodes);

        if ((enrollRes as List).isNotEmpty) {
          for (var item in enrollRes) {
            final cCode = (item['course_code'] ?? '').toString().trim().toUpperCase();
            final secNum = (item['section'] ?? '').toString().trim();
            if (cCode.isNotEmpty) {
              enrolled.add({
                'course_code': cCode,
                'section': secNum.isEmpty ? '1' : secNum,
                'semester_code': item['semester_code'] ?? cleanSem,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[FacultyAssignment] Enrollments fetch error: $e');
      }

      // 2. Fallback to weekly_grid_cache from user_semester_states
      if (enrolled.isEmpty) {
        try {
          final stateRes = await supabase
              .from('user_semester_states')
              .select('weekly_grid_cache')
              .eq('user_id', user.id)
              .inFilter('semester_code', possibleCodes)
              .maybeSingle();

          final grid = stateRes?['weekly_grid_cache'] as Map<String, dynamic>? ?? {};
          final Set<String> seen = {};

          for (final dayClasses in grid.values) {
            if (dayClasses is List) {
              for (final c in dayClasses) {
                final cCode = (c['courseCode'] ?? c['course_code'] ?? '').toString().trim().toUpperCase();
                final sec = (c['section'] ?? c['section_number'] ?? c['sec'] ?? '').toString().trim();
                final key = '${cCode}_$sec';
                if (cCode.isNotEmpty && !seen.contains(key)) {
                  seen.add(key);
                  enrolled.add({
                    'course_code': cCode,
                    'section': sec.isEmpty ? '1' : sec,
                    'semester_code': cleanSem,
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[FacultyAssignment] Weekly grid fallback error: $e');
        }
      }

      // 3. Fallback to Profile enrolled_sections array
      if (enrolled.isEmpty) {
        try {
          final profile = ref.read(userProfileProvider).valueOrNull ??
              await ref.read(profileRepositoryProvider).getProfile(user.id);
          if (profile != null && profile.enrolledSections.isNotEmpty) {
            final isNextSemester = cleanSem.toLowerCase().contains('fall');
            final sectionIds = (isNextSemester && profile.enrolledSectionsNext.isNotEmpty)
                ? profile.enrolledSectionsNext
                : profile.enrolledSections;

            final isUuid = sectionIds.any((s) => s.length > 20 && s.contains('-'));
            if (isUuid) {
              // Resolve section UUIDs from semester courses table
              final targetCourseTable = 'courses_${safeSemLower}';
              try {
                final resolvedRows = await supabase
                    .from(targetCourseTable)
                    .select('course_code, section_number')
                    .inFilter('id', sectionIds);

                for (var r in (resolvedRows as List)) {
                  final cCode = (r['course_code'] ?? '').toString().trim().toUpperCase();
                  final secNum = (r['section_number'] ?? '1').toString().trim();
                  if (cCode.isNotEmpty) {
                    enrolled.add({
                      'course_code': cCode,
                      'section': secNum,
                      'semester_code': cleanSem,
                    });
                  }
                }
              } catch (e) {
                debugPrint('[FacultyAssignment] Resolving section UUIDs error: $e');
              }
            } else {
              // Standard format e.g. "CSE110-1" or "CSE110"
              for (final raw in sectionIds) {
                final parts = raw.split('-');
                final cCode = parts.first.trim().toUpperCase();
                final sec = parts.length > 1 ? parts[1].trim() : '1';
                if (cCode.isNotEmpty) {
                  enrolled.add({
                    'course_code': cCode,
                    'section': sec,
                    'semester_code': cleanSem,
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[FacultyAssignment] Profile enrolled_sections fallback error: $e');
        }
      }

      // Initialize text controllers for all detected enrolled courses
      for (var c in enrolled) {
        final key = '${c['course_code']}_${c['section']}';
        _enrolledInitialControllers[key] = TextEditingController();
      }
    }

    // Fetch Course Catalog for Dropdowns
    final String safeSem = cleanSem.toLowerCase();
    Map<String, List<String>> sectionsMap = {};

    // 1. Try querying semester-specific course table courses_<semester>
    try {
      final catalogRes = await supabase
          .from('courses_$safeSem')
          .select()
          .limit(3000);

      for (var row in catalogRes as List) {
        final code = (row['course_code'] ?? row['code'] ?? row['course_id'] ?? '').toString().trim().toUpperCase();
        final sec = (row['section_number'] ?? row['section'] ?? row['sec'] ?? '').toString().trim();

        // Filter out corrupted program short codes (real course codes must contain numbers, e.g., CSE101)
        if (code.isNotEmpty && RegExp(r'\d').hasMatch(code)) {
          if (sec.isNotEmpty) {
            sectionsMap.putIfAbsent(code, () => []);
            if (!sectionsMap[code]!.contains(sec)) {
              sectionsMap[code]!.add(sec);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FacultyAssignment] Catalog query error for courses_$safeSem: $e');
    }

    // 2. Fetch master course list from course_metadata to ensure clean course codes are always available even if semester table is corrupted
    try {
      final metaRes = await supabase
          .from('course_metadata')
          .select('code')
          .order('code', ascending: true)
          .limit(2000);

      for (var row in metaRes as List) {
        final code = (row['code'] ?? '').toString().trim().toUpperCase();
        if (code.isNotEmpty && RegExp(r'\d').hasMatch(code) && !sectionsMap.containsKey(code)) {
          sectionsMap[code] = List.generate(20, (i) => (i + 1).toString());
        }
      }
    } catch (e) {
      debugPrint('[FacultyAssignment] course_metadata fetch error: $e');
    }

    // Ensure all valid course codes have sections
    for (var code in sectionsMap.keys) {
      if (sectionsMap[code]!.isEmpty) {
        sectionsMap[code] = List.generate(20, (i) => (i + 1).toString());
      }
    }

    final courseCodes = sectionsMap.keys.toList()..sort();
    for (var code in sectionsMap.keys) {
      sectionsMap[code]!.sort((a, b) {
        final intA = int.tryParse(a);
        final intB = int.tryParse(b);
        if (intA != null && intB != null) {
          return intA.compareTo(intB);
        }
        return a.compareTo(b);
      });
    }

    if (mounted) {
      setState(() {
        if (facList != null) _facultyMaster = facList;
        _enrolledCourses = enrolled;
        _availableCourseCodes = courseCodes;
        _courseSectionsMap = sectionsMap;
        _selectedBulkCourseCode = null;
        _selectedBulkSection = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSemesterChanged(String newSemester) async {
    setState(() {
      _selectedSemester = newSemester;
      _isLoading = true;
    });
    await _loadDataForSemester(newSemester);
  }

  void _showFacultySearchDialog({Function(Map<String, dynamic> selectedFaculty)? onSelect}) {
    setState(() {
      _facultySearchQuery = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredFaculty = _facultyMaster.where((f) {
              if (_facultySearchQuery.isEmpty) return true;
              final initial = (f['short_name'] ?? '').toString().toLowerCase();
              final name = (f['full_name'] ?? '').toString().toLowerCase();
              final desig = (f['designation_name'] ?? '').toString().toLowerCase();
              return initial.contains(_facultySearchQuery) ||
                  name.contains(_facultySearchQuery) ||
                  desig.contains(_facultySearchQuery);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.person_search_rounded, color: Color(0xFF22D3EE), size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Select Faculty Member',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredFaculty.length} available',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search by initial (e.g. NHUDA) or full name...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF22D3EE)),
                          suffixIcon: _facultySearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    setModalState(() {
                                      _facultySearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            _facultySearchQuery = query.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredFaculty.isEmpty
                            ? Center(
                                child: Text(
                                  'No faculty member matching "$_facultySearchQuery"',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredFaculty.length,
                                itemBuilder: (context, index) {
                                  final f = filteredFaculty[index];
                                  final initial = f['short_name']?.toString() ?? '';
                                  final name = f['full_name']?.toString() ?? '';
                                  final desig = f['designation_name']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22D3EE).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Color(0xFF22D3EE),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        '$initial • ${desig.isNotEmpty ? desig : 'Faculty'}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                      ),
                                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                                      onTap: () {
                                        if (onSelect != null) {
                                          onSelect(f);
                                        } else {
                                          setState(() {
                                            _selectedFaculty = f;
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCourseSearchModal() {
    String courseSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCourses = _availableCourseCodes.where((code) {
              if (courseSearchQuery.isEmpty) return true;
              return code.toLowerCase().contains(courseSearchQuery);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.book_rounded, color: Color(0xFF22D3EE), size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Select Course Code',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredCourses.length} available',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search course code (e.g. CSE101, ACT101)...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF22D3EE)),
                          suffixIcon: courseSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                  onPressed: () {
                                    setModalState(() {
                                      courseSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            courseSearchQuery = query.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredCourses.isEmpty
                            ? Center(
                                child: Text(
                                  'No course matching "$courseSearchQuery"',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final code = filteredCourses[index];
                                  final sections = _courseSectionsMap[code] ?? [];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedBulkCourseCode == code
                                            ? const Color(0xFF22D3EE).withOpacity(0.5)
                                            : Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22D3EE).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          code.substring(0, code.length > 3 ? 3 : code.length),
                                          style: const TextStyle(
                                            color: Color(0xFF22D3EE),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        code,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      subtitle: Text(
                                        sections.isNotEmpty
                                            ? '${sections.length} sections available (Sec ${sections.join(', ')})'
                                            : 'Available course',
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                      ),
                                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                                      onTap: () {
                                        setState(() {
                                          _selectedBulkCourseCode = code;
                                          _selectedBulkSection = null;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(bool isEnrolledTab) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isEnrolledTab) {
          _enrolledScreenshotBytes = bytes;
          _enrolledScreenshotName = image.name;
        } else {
          _bulkScreenshotBytes = bytes;
          _bulkScreenshotName = image.name;
        }
      });
    }
  }

  Future<void> _submitEnrolledTab() async {
    if (_enrolledScreenshotBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a screenshot of your portal routine as proof.')),
      );
      return;
    }

    final List<FacultyAssignmentItem> items = [];

    for (var c in _enrolledCourses) {
      final code = c['course_code'].toString();
      final sec = c['section'].toString();
      final key = '${code}_${sec}';
      final initial = _enrolledInitialControllers[key]?.text.trim().toUpperCase();

      if (initial != null && initial.isNotEmpty) {
        items.add(FacultyAssignmentItem(
          courseCode: code,
          sectionNumber: sec,
          facultyInitial: initial,
        ));
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one faculty initial.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(facultyAssignmentRepositoryProvider);
      await repo.submitEnrolledAssignments(
        semester: _selectedSemester,
        items: items,
        screenshotBytes: _enrolledScreenshotBytes!,
        fileName: _enrolledScreenshotName ?? 'enrolled_proof.jpg',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission received! Admin will review & approve shortly.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addBulkItem() {
    final String code;
    final String sec;

    if (_manualMode || _availableCourseCodes.isEmpty) {
      code = _bulkCourseCodeCtrl.text.trim().toUpperCase();
      sec = _bulkSectionCtrl.text.trim();
    } else {
      code = _selectedBulkCourseCode?.trim().toUpperCase() ?? '';
      sec = _selectedBulkSection?.trim() ?? '';
    }

    if (code.isEmpty || sec.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter Course Code & Section')),
      );
      return;
    }

    final exists = _bulkSelections.any(
      (e) => e['course_code'] == code && e['section_number'] == sec,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$code Sec $sec is already added.')),
      );
      return;
    }

    setState(() {
      _bulkSelections.add({'course_code': code, 'section_number': sec});
      if (_manualMode) {
        _bulkCourseCodeCtrl.clear();
        _bulkSectionCtrl.clear();
      } else {
        _selectedBulkSection = null;
      }
    });
  }

  Future<void> _submitBulkTab() async {
    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty member.')),
      );
      return;
    }

    if (_bulkSelections.isEmpty) {
      if (!_manualMode && _selectedBulkCourseCode != null && _selectedBulkSection != null) {
        _addBulkItem();
      } else if (_manualMode && _bulkCourseCodeCtrl.text.trim().isNotEmpty && _bulkSectionCtrl.text.trim().isNotEmpty) {
        _addBulkItem();
      }
    }

    if (_bulkSelections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one course & section.')),
      );
      return;
    }

    if (_bulkScreenshotBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload schedule screenshot proof.')),
      );
      return;
    }

    final facultyInit = _selectedFaculty!['short_name'].toString().toUpperCase();
    final facultyName = _selectedFaculty!['full_name'].toString();

    final List<FacultyAssignmentItem> items = _bulkSelections
        .map((e) => FacultyAssignmentItem(
              courseCode: e['course_code']!,
              sectionNumber: e['section_number']!,
              facultyInitial: facultyInit,
            ))
        .toList();

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(facultyAssignmentRepositoryProvider);
      await repo.submitBulkAssignments(
        semester: _selectedSemester,
        facultyInitial: facultyInit,
        facultyFullName: facultyName,
        items: items,
        screenshotBytes: _bulkScreenshotBytes!,
        fileName: _bulkScreenshotName ?? 'bulk_proof.jpg',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk submission received! Admin will verify screenshot.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Faculty (Get Verified)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'My Enrolled Courses'),
            Tab(icon: Icon(Icons.group_add), text: 'Update Other Sections'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSemesterHeader(theme),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEnrolledTab(theme),
                      _buildBulkTab(theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSemesterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF22D3EE)),
          const SizedBox(width: 10),
          const Text(
            'Target Semester:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSemester,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: _availableSemesters.map((sem) {
                return DropdownMenuItem<String>(
                  value: sem,
                  child: Text(
                    CourseUtils.prettifySemesterCode(sem),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && val != _selectedSemester) {
                  _onSemesterChanged(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledTab(ThemeData theme) {
    if (_enrolledCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No enrolled courses found for ${CourseUtils.prettifySemesterCode(_selectedSemester)}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('Update Non-Enrolled Courses Instead'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: theme.primaryColor.withOpacity(0.08),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter faculty initials for your enrolled courses & upload your portal routine screenshot.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ..._enrolledCourses.map((c) {
            final code = c['course_code'].toString();
            final sec = c['section'].toString();
            final key = '${code}_${sec}';
            final ctrl = _enrolledInitialControllers[key]!;
            final currentInitial = ctrl.text.trim().toUpperCase();

            // Find faculty in master list if present
            final matchedFaculty = currentInitial.isNotEmpty
                ? _facultyMaster.cast<Map<String, dynamic>?>().firstWhere(
                    (f) => (f?['short_name'] ?? '').toString().toUpperCase() == currentInitial,
                    orElse: () => null,
                  )
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: currentInitial.isNotEmpty
                      ? const Color(0xFF22D3EE).withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Color(0xFF22D3EE),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Section $sec',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Status: TBA',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        _showFacultySearchDialog(
                          onSelect: (f) {
                            setState(() {
                              ctrl.text = (f['short_name'] ?? '').toString().toUpperCase();
                            });
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentInitial.isNotEmpty
                                ? const Color(0xFF22D3EE)
                                : Colors.white24,
                            width: currentInitial.isNotEmpty ? 1.2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentInitial.isNotEmpty
                                  ? Icons.person_rounded
                                  : Icons.search_rounded,
                              color: currentInitial.isNotEmpty
                                  ? const Color(0xFF22D3EE)
                                  : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentInitial.isNotEmpty
                                        ? (matchedFaculty != null
                                            ? '$currentInitial - ${matchedFaculty['full_name']}'
                                            : currentInitial)
                                        : 'Select Faculty Initial (Search DB)...',
                                    style: TextStyle(
                                      color: currentInitial.isNotEmpty
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight: currentInitial.isNotEmpty
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (matchedFaculty != null &&
                                      (matchedFaculty['designation_name'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      matchedFaculty['designation_name'].toString(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (currentInitial.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    ctrl.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22D3EE).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentInitial.isNotEmpty ? 'Change' : 'Pick',
                                style: const TextStyle(
                                  color: Color(0xFF22D3EE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickImage(true),
            icon: const Icon(Icons.upload_file),
            label: Text(_enrolledScreenshotBytes == null
                ? 'Attach Routine Screenshot Proof *'
                : 'Change Screenshot (${_enrolledScreenshotName})'),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitEnrolledTab,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit For Admin Approval', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('1. Select Faculty Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showFacultySearchDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFaculty != null ? const Color(0xFF22D3EE) : Colors.white24,
                  width: _selectedFaculty != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedFaculty != null ? Icons.person_rounded : Icons.search_rounded,
                    color: const Color(0xFF22D3EE),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFaculty != null
                              ? '${_selectedFaculty!['short_name']} - ${_selectedFaculty!['full_name']}'
                              : 'Tap to Search Faculty (by Name or Initial)...',
                          style: TextStyle(
                            color: _selectedFaculty != null ? Colors.white : Colors.white54,
                            fontWeight: _selectedFaculty != null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedFaculty != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _selectedFaculty!['designation_name']?.toString() ?? 'Faculty Member',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedFaculty != null ? 'Change' : 'Search',
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Add Course Sections for This Faculty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (_availableCourseCodes.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _manualMode = !_manualMode;
                    });
                  },
                  icon: Icon(_manualMode ? Icons.list_rounded : Icons.edit_note_rounded, size: 16),
                  label: Text(_manualMode ? 'Use Dropdowns' : 'Type Manually', style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_manualMode && _availableCourseCodes.isNotEmpty) ...[
            Row(
              children: [
                // Searchable Course Code Picker
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _showCourseSearchModal,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Course Code',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 16, color: Color(0xFF22D3EE)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedBulkCourseCode ?? 'Search Code...',
                              style: TextStyle(
                                fontWeight: _selectedBulkCourseCode != null ? FontWeight.bold : FontWeight.normal,
                                color: _selectedBulkCourseCode != null ? Colors.white : Colors.white54,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Section Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedBulkSection,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    hint: const Text('Sec'),
                    items: (_selectedBulkCourseCode != null && _courseSectionsMap.containsKey(_selectedBulkCourseCode))
                        ? _courseSectionsMap[_selectedBulkCourseCode]!.map((sec) {
                            return DropdownMenuItem<String>(
                              value: sec,
                              child: Text('Sec $sec'),
                            );
                          }).toList()
                        : [],
                    onChanged: (val) {
                      setState(() {
                        _selectedBulkSection = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Add button
                IconButton.filled(
                  onPressed: _addBulkItem,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Section',
                ),
              ],
            ),
          ] else ...[
            // Manual entry fallback
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _bulkCourseCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Course Code',
                      hintText: 'e.g. CSE101',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _bulkSectionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sec',
                      hintText: '1',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addBulkItem,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          if (_bulkSelections.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _bulkSelections.map((item) {
                return Chip(
                  label: Text('${item['course_code']} Sec ${item['section_number']}'),
                  onDeleted: () => setState(() => _bulkSelections.remove(item)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const Text('3. Upload Schedule Proof Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickImage(false),
            icon: const Icon(Icons.image),
            label: Text(_bulkScreenshotBytes == null
                ? 'Attach Schedule Screenshot *'
                : 'Screenshot Selected (${_bulkScreenshotName})'),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitBulkTab,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Sections for Approval', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
