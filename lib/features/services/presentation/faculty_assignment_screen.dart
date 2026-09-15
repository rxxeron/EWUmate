import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/academic_providers.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ewu_theme_extension.dart';
import '../../../../core/utils/course_utils.dart';
import '../../../../core/widgets/ewumate_app_bar.dart';
import '../../../../core/widgets/glass_kit.dart';
import '../repositories/faculty_assignment_repository.dart';
import 'faculty_assignment/widgets/faculty_assignment_stepper.dart';
import 'faculty_assignment/widgets/add_courses_step.dart';
import 'faculty_assignment/widgets/upload_proof_step.dart';
import 'faculty_assignment/widgets/faculty_submissions_sheet.dart';
import 'faculty_assignment/widgets/course_search_modal.dart';
import 'faculty_assignment/widgets/proof_preview_dialog.dart';

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

class _FacultyAssignmentScreenState extends ConsumerState<FacultyAssignmentScreen> {
  int _currentStep = 0; // 0: Assign Courses, 1: Upload Proof

  // Semester State
  String _selectedSemester = 'Summer2026';
  List<String> _availableSemesters = ['Spring2026', 'Summer2026', 'Fall2026'];

  // Master Data
  List<Map<String, dynamic>> _facultyMaster = [];
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<String> _availableCourseCodes = [];
  Map<String, List<String>> _courseSectionsMap = {};

  // Builder State
  String? _selectedCourseCode;
  String _selectedSectionNumber = '1';
  String _selectedSessionType = 'Theory'; // 'Theory' or 'Lab'
  Map<String, dynamic>? _selectedFaculty;

  // Staged Assignments List
  final List<FacultyAssignmentItem> _addedAssignments = [];

  // Step 2: Proof
  Uint8List? _proofBytes;
  String? _proofFileName;
  int _proofFileSize = 0;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentSem = ref.read(currentSemesterCodeProvider).value ?? 'Summer2026';
    _selectedSemester = currentSem.replaceAll(' ', '');

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = ref.read(facultyAssignmentRepositoryProvider);
      final supabase = ref.read(supabaseClientProvider);

      // 1. Fetch Faculty Master List
      final facList = await repo.fetchFacultyMasterList();

      // 2. Fetch Available Semesters
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

      // If initial arguments were passed, pre-fill them
      if (widget.initialCourseCode != null) {
        _selectedCourseCode = widget.initialCourseCode!.toUpperCase();
        if (widget.initialSection != null) {
          _selectedSectionNumber = widget.initialSection!;
        }
      }
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
    final safeSem = cleanSem.toLowerCase();

    // 1. Fetch Enrolled Courses for User in selected semester
    List<Map<String, dynamic>> enrolled = [];
    if (user != null) {
      final spaceSem = cleanSem.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
      final possibleCodes = [cleanSem, safeSem, spaceSem, semesterCode];

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
                'course_name': CourseUtils.getCourseTitle(cCode),
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[FacultyAssignment] Enrollments fetch error: $e');
      }

      // Fallback to weekly_grid_cache
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
                    'course_name': CourseUtils.getCourseTitle(cCode),
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[FacultyAssignment] Weekly grid fallback error: $e');
        }
      }
    }

    // 2. Fetch Course Catalog for selected semester
    final Map<String, List<String>> sectionsMap = {};
    try {
      final catalogRes = await supabase
          .from('courses_$safeSem')
          .select('course_code, section_number')
          .limit(3000);

      for (var row in catalogRes as List) {
        final code = (row['course_code'] ?? row['code'] ?? '').toString().trim().toUpperCase();
        final sec = (row['section_number'] ?? row['section'] ?? '').toString().trim();

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

    // Master list fallback from course_metadata
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
      debugPrint('[FacultyAssignment] course_metadata error: $e');
    }

    final courseCodes = sectionsMap.keys.toList()..sort();
    for (var code in sectionsMap.keys) {
      sectionsMap[code]!.sort((a, b) {
        final intA = int.tryParse(a);
        final intB = int.tryParse(b);
        if (intA != null && intB != null) return intA.compareTo(intB);
        return a.compareTo(b);
      });
    }

    if (mounted) {
      setState(() {
        if (facList != null) _facultyMaster = facList;
        _enrolledCourses = enrolled;
        _availableCourseCodes = courseCodes;
        _courseSectionsMap = sectionsMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSemesterChanged(String newSem) async {
    setState(() {
      _selectedSemester = newSem;
      _isLoading = true;
    });
    await _loadDataForSemester(newSem);
  }

  void _quickFillEnrolled(String code, String section) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCourseCode = code;
      _selectedSectionNumber = section;
    });
  }

  void _addAssignment() {
    HapticFeedback.lightImpact();

    if (_selectedCourseCode == null || _selectedCourseCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course code.')),
      );
      return;
    }

    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assigned faculty member.')),
      );
      return;
    }

    final cleanCode = _selectedCourseCode!.trim().toUpperCase();
    final cleanSec = _selectedSectionNumber.trim();
    final facInit = (_selectedFaculty!['short_name'] ?? '').toString().toUpperCase();
    final facName = _selectedFaculty!['full_name']?.toString();
    final facDesig = _selectedFaculty!['designation_name']?.toString();

    // Check duplicate
    final exists = _addedAssignments.any(
      (e) =>
          e.courseCode.toUpperCase() == cleanCode &&
          e.sectionNumber == cleanSec &&
          e.sessionType.toLowerCase() == _selectedSessionType.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$cleanCode Sec $cleanSec ($_selectedSessionType) is already added.'),
          backgroundColor: const Color(0xFF0D2342),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _addedAssignments.add(
        FacultyAssignmentItem(
          courseCode: cleanCode,
          sectionNumber: cleanSec,
          sessionType: _selectedSessionType,
          facultyInitial: facInit,
          facultyFullName: facName,
          facultyDesignation: facDesig,
        ),
      );

      // If user added Theory and it was successful, keep course code & section ready for adding Lab faculty if desired
      if (_selectedSessionType == 'Theory') {
        _selectedSessionType = 'Lab';
        _selectedFaculty = null;
      } else {
        _selectedSessionType = 'Theory';
        _selectedFaculty = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $cleanCode Sec $cleanSec → $facInit'),
        backgroundColor: const Color(0xFF0D2342),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickProofFile() async {
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _proofBytes = file.bytes;
            _proofFileName = file.name;
            _proofFileSize = file.size;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[FilePicker] error: $e, falling back to ImagePicker');
    }

    // Fallback to ImagePicker
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _proofBytes = bytes;
          _proofFileName = image.name;
          _proofFileSize = bytes.length;
        });
      }
    } catch (e) {
      debugPrint('[ImagePicker] error: $e');
    }
  }

  Future<void> _submitAssignment() async {
    if (_addedAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one course assignment.')),
      );
      return;
    }

    if (_proofBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload schedule screenshot proof.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(facultyAssignmentRepositoryProvider);
      await repo.submitMultiAssignments(
        semester: _selectedSemester,
        items: _addedAssignments,
        screenshotBytes: _proofBytes!,
        fileName: _proofFileName ?? 'routine_proof.jpg',
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0D2342),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.primaryCyan, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Submitted!',
                  style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'Your faculty assignment request for ${_addedAssignments.length} course sessions has been submitted. Admins will verify your routine proof and update the schedule database.',
              style: GoogleFonts.sora(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.sora(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return FullGradientScaffold(
      appBar: EWUmateAppBar(
        title: 'Assign Faculty (Get Verified)',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primaryCyan),
            tooltip: 'My Submissions',
            onPressed: () => showFacultySubmissionsSheet(context, ref),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : Column(
              children: [
                // Top 2-Step Wizard Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FacultyAssignmentStepper(
                    currentStep: _currentStep,
                    onStepTapped: (step) => setState(() => _currentStep = step),
                  ),
                ),

                // Active Step Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStepView(colors),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepView(EwuColors colors) {
    switch (_currentStep) {
      case 0:
        final availableSections = _selectedCourseCode != null
            ? (_courseSectionsMap[_selectedCourseCode] ?? ['1'])
            : ['1'];

        return AddCoursesStep(
          selectedSemester: _selectedSemester,
          availableSemesters: _availableSemesters,
          onSemesterChanged: _onSemesterChanged,
          enrolledCourses: _enrolledCourses,
          onQuickFillEnrolled: _quickFillEnrolled,
          selectedCourseCode: _selectedCourseCode,
          selectedSessionType: _selectedSessionType,
          onSessionTypeChanged: (type) => setState(() => _selectedSessionType = type),
          selectedSectionNumber: _selectedSectionNumber,
          availableSections: availableSections,
          onSectionChanged: (sec) => setState(() => _selectedSectionNumber = sec),
          selectedFaculty: _selectedFaculty,
          onFacultySelected: (fac) => setState(() => _selectedFaculty = fac),
          facultyMaster: _facultyMaster,
          onSearchCourse: () async {
            final res = await showCourseSearchModal(
              context: context,
              availableCourseCodes: _availableCourseCodes,
              courseSectionsMap: _courseSectionsMap,
            );
            if (res != null) {
              setState(() {
                _selectedCourseCode = res['code'];
                _selectedSectionNumber = res['section'] ?? '1';
              });
            }
          },
          onAddAssignment: _addAssignment,
          addedAssignments: _addedAssignments,
          onRemoveAssignment: (idx) {
            HapticFeedback.lightImpact();
            setState(() => _addedAssignments.removeAt(idx));
          },
          onNextStep: () {
            HapticFeedback.lightImpact();
            setState(() => _currentStep = 1);
          },
          colors: colors,
        );

      case 1:
      default:
        return UploadProofStep(
          assignments: _addedAssignments,
          proofBytes: _proofBytes,
          proofFileName: _proofFileName,
          proofFileSize: _proofFileSize,
          onPickFile: _pickProofFile,
          onClearFile: () {
            setState(() {
              _proofBytes = null;
              _proofFileName = null;
              _proofFileSize = 0;
            });
          },
          onPreviewFile: () => showProofPreviewDialog(
            context: context,
            proofBytes: _proofBytes,
            proofFileName: _proofFileName,
          ),
          isSubmitting: _isSubmitting,
          onBack: () => setState(() => _currentStep = 0),
          onSubmit: _submitAssignment,
          colors: colors,
        );
    }
  }
}
