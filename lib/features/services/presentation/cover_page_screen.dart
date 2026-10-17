import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
import 'package:ewumate/core/utils/course_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/config/supabase_config.dart';


class CoverPageScreen extends ConsumerStatefulWidget {
  const CoverPageScreen({super.key});

  @override
  ConsumerState<CoverPageScreen> createState() => _CoverPageScreenState();
}

class _CoverPageScreenState extends ConsumerState<CoverPageScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedTemplate = 'assignment';
  String _topic = '';
  String _headerDept = 'Department of CSE';
  String _groupNo = '';
  String _labNo = '';
  String _semester = ''; // New state for editable semester
  
  // Course Info
  String _courseTitle = '';
  String _courseCode = '';
  String _section = '';
  String _teacherName = '';
  String _teacherDept = '';
  String _designation = 'Lecturer'; // Default to Lecturer
  
  final List<String> _designations = [
    'Lecturer',
    'Senior Lecturer',
    'Assistant Professor',
    'Associate Professor',
    'Professor',
    'Adjunct Faculty',
  ];
  
  // Date overrides (optional)
  String _allocationDate = '';
  String _submissionDate = '';
  
  // Group Students
  String _primaryName = '';
  String _primaryId = '';
  String _primaryProgram = '';
  String _primaryDept = '';
  
  List<Map<String, dynamic>> _enrolledCoursesData = [];
  
  final List<Map<String, String>> _additionalStudents = [];
  
  List<Map<String, dynamic>> _programData = [];
  bool _isLoadingPrograms = true;
  bool _profileInitialized = false;
  bool _isGenerating = false;

  final List<Map<String, String>> _templates = [
    {'value': 'assignment', 'label': 'Assignment'},
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'physics_lab', 'label': 'Physics Lab'},
    {'value': 'group_project', 'label': 'Group Project'},
    {'value': 'term_paper', 'label': 'Term Paper'},
    {'value': 'mps_assignment', 'label': 'Group Assignment'},
  ];

  List<String> _departments = [];
  bool _isLoadingDepts = true;

  @override
  void initState() {
    super.initState();

    _loadDepartments();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final data = await supabase
          .from('programs')
          .select('program_code, name, department_name');
      
      final programs = List<Map<String, dynamic>>.from(data as List);
      
      final Set<String> uniqueDepts = programs
          .map((e) => e['department_name']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('Department of') ? e : 'Department of $e')
          .toSet();
      
      if (mounted) {
        setState(() {
          _programData = programs;
          _departments = uniqueDepts.toList()..sort();
          if (_departments.isNotEmpty && !_departments.contains(_headerDept)) {
             _headerDept = _departments.first;
          }
          _isLoadingDepts = false;
          _isLoadingPrograms = false;
        });
      }
      
      // Also load enrolled courses from enrollments table as it's more reliable
      final user = ref.read(currentUserProvider);
      final currentSem = ref.read(currentSemesterCodeProvider).value;
      if (user != null && currentSem != null) {
        final cleanSem = currentSem.replaceAll(' ', '');
        final enrollRes = await supabase
            .from('enrollments')
            .select('course_code, section, semester_code')
            .eq('user_id', user.id)
            .eq('semester_code', cleanSem);
        
        if (mounted) {
          setState(() {
            _enrolledCoursesData = List<Map<String, dynamic>>.from(enrollRes as List);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDepts = false;
          _isLoadingPrograms = false;
        });
      }
    }
  }

  void _onProgramChanged(String code, bool isPrimary, [int? index]) {
    final program = _programData.firstWhere(
      (p) => p['program_code']?.toString().toUpperCase() == code.toUpperCase(),
      orElse: () => {},
    );
    
    if (program.isNotEmpty) {
      final degree = program['name']?.toString() ?? code; // Fallback to code if name missing
      final dept = program['department_name']?.toString() ?? '';
      final formattedDept = (dept.isNotEmpty && !dept.startsWith('Department of')) 
          ? 'Department of $dept' 
          : dept;
      
      setState(() {
        if (isPrimary) {
          _primaryProgram = degree;
          _primaryDept = formattedDept;
          // Sync header dept with student's dept by default
          if (formattedDept.isNotEmpty) {
            _headerDept = formattedDept;
          }
        } else if (index != null) {
          _additionalStudents[index]['program'] = degree;
          _additionalStudents[index]['dept'] = formattedDept;
        }
      });
    }
  }

  void _addStudent() {
    if (_additionalStudents.length < 3) {
      setState(() {
        _additionalStudents.add({'name': '', 'id': '', 'program': '', 'dept': ''});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 students allowed in a group.')),
      );
    }
  }

  void _removeStudent(int index) {
    setState(() {
      _additionalStudents.removeAt(index);
    });
  }

  Future<void> _generatePDF(Map<String, dynamic> userProfile, String semester) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final primaryStudent = {
      'name': _primaryName,
      'id': _primaryId,
      'program': _primaryProgram,
      'dept': _primaryDept,
    };

    List<Map<String, String>> allStudents = [primaryStudent, ..._additionalStudents];

    final payload = {
      "template": _selectedTemplate,
      "semester": semester,
      "topic": _topic, // Send exactly what the user entered
      "group_no": _groupNo,
      "lab_no": _labNo,
      "header_dept": _headerDept,
      "course_title": _courseTitle,
      "course_code": _courseCode,
      "section": _section,
      "teacher_name": _teacherName,
      "designation": _designation,
      "teacher_dept": _headerDept, // Use the full header dept which includes "Department of"
      "allocation_date": _allocationDate,
      "submission_date": _submissionDate.isEmpty ? DateTime.now().toString().split(' ')[0] : _submissionDate,
      "students": allStudents,
    };

    final supabase = ref.read(supabaseClientProvider);
    final String? token = supabase.auth.currentSession?.accessToken;
    
    setState(() => _isGenerating = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
              ),
              const SizedBox(width: 12),
              Text('Generating secure PDF...', style: GoogleFonts.sora()),
            ],
          ),
          backgroundColor: AppColors.surfaceNavyBlue,
        ),
      );

      final baseUrl = AppConfig.getAzureFunctionUrl;
      http.Response? response;
      String? networkError;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          response = await http.post(
            Uri.parse('$baseUrl/api/generate_pdf'),
            headers: {
              "Content-Type": "application/json",
              if (token != null) "Authorization": "Bearer $token",
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 25));
          networkError = null;
          break;
        } on SocketException catch (_) {
          networkError = 'Unable to reach the PDF service. Please verify your internet connection or DNS and try again.';
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } on http.ClientException catch (_) {
          networkError = 'Network connection error while contacting PDF generator. Please try again.';
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (networkError != null) {
        throw networkError;
      }

      if (response != null && response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName = 'EWUmate_${_selectedTemplate}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        if (kIsWeb) {
          // Web / PWA browser environment: trigger native browser blob download
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..target = '_blank'
            ..download = fileName;
          anchor.click();
          html.Url.revokeObjectUrl(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cover page downloaded successfully!', style: GoogleFonts.sora()),
                backgroundColor: AppColors.surfaceNavyBlue,
              ),
            );
          }
        } else {
          // Native mobile (Android / iOS): Save to temp directory and open
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          await OpenFilex.open(filePath);
        }
      } else {
        throw 'Server returned error: ${response?.body ?? "Unknown error"}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.sora()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _fetchFacultyDetails(String courseCode, String section, String semesterCode) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tableName = 'courses_${semesterCode.toLowerCase()}';
      
      final res = await supabase
          .from(tableName)
          .select('course_name, faculty_full_name, faculty_designation, dedicated_department')
          .eq('course_code', courseCode)
          .eq('section_number', section)
          .limit(1)
          .maybeSingle();

        setState(() {
          _courseTitle = res?['course_name']?.toString() ?? '';
          _teacherName = res?['faculty_full_name']?.toString() ?? '';
          
          final dbDesignation = res?['faculty_designation']?.toString() ?? '';
          if (dbDesignation.isNotEmpty && !RegExp(r'^\d+$').hasMatch(dbDesignation)) {
            // Find closest match in our predefined list
            final match = _designations.firstWhere(
              (d) => d.toLowerCase() == dbDesignation.toLowerCase(),
              orElse: () => _designation,
            );
            _designation = match;
          } else {
            _designation = 'Lecturer'; // Fallback for numeric IDs like '148'
          }
        });

        // Prompt student to update faculty if marked as TBA or empty
        final currentTeacher = _teacherName.trim().toUpperCase();
        if (currentTeacher.isEmpty || currentTeacher == 'TBA' || currentTeacher == 'NONE') {
          _showTBAAssignDialog(courseCode, section);
        } else {
        // Fallback to metadata if semester-specific record isn't found
        final metaRes = await supabase
            .from('course_metadata')
            .select('name')
            .eq('code', courseCode)
            .maybeSingle();
        if (metaRes != null) {
          setState(() => _courseTitle = metaRes['name']?.toString() ?? '');
        }
      }
    } catch (e) {
      debugPrint('Error fetching semester course details: $e');
    }
  }

  void _showTBAAssignDialog(String courseCode, String section) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              'Faculty Marked TBA',
              style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Faculty for $courseCode Sec $section is currently TBA.\n\nWould you like to assign the faculty member now with screenshot proof to update EWUmate?',
          style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push(
                '/services/faculty-assignment',
                extra: {
                  'course_code': courseCode,
                  'section': section,
                },
              );
            },
            child: Text('Update Faculty', style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isSubmission) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.primaryNavy,
              surface: AppColors.surfaceNavyBlue,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final dateStr = picked.toString().split(' ')[0];
        if (isSubmission) {
          _submissionDate = dateStr;
        } else {
          _allocationDate = dateStr;
        }
      });
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
      hintStyle: GoogleFonts.sora(color: Colors.white30, fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const FullGradientScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);

    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Cover Page Generator',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
        error: (e, st) => Center(
          child: Text('Error: $e', style: GoogleFonts.sora(color: Colors.redAccent)),
        ),
        data: (profile) {
          if (!_profileInitialized && profile != null && _programData.isNotEmpty) {
            _primaryName = profile.fullName ?? '';
            _primaryId = profile.studentId ?? '';
            
            final pCode = profile.programCode ?? profile.programName ?? '';
            final program = _programData.firstWhere(
              (p) => p['program_code']?.toString().toUpperCase() == pCode.toUpperCase(),
              orElse: () => {},
            );
            
            if (program.isNotEmpty) {
              _primaryProgram = program['name']?.toString() ?? pCode;
              _primaryDept = program['department_name']?.toString() ?? '';
            } else {
              _primaryProgram = profile.programName ?? '';
              _primaryDept = profile.departmentName ?? '';
            }

            if (!_primaryDept.startsWith('Department of') && _primaryDept.isNotEmpty) {
              _primaryDept = 'Department of $_primaryDept';
            }
            
            if (_primaryDept.isNotEmpty) {
              _headerDept = _primaryDept;
            }
            
            _profileInitialized = true;
          }
          
          final allSemestersAsync = ref.watch(semestersProvider);
          final semesterCode = currentSemAsync.value ?? 'Summer2026';

          // Auto-select active semester based on student track if not set yet
          if (_semester.isEmpty) {
            // Check active semester repository cache or current semester state
            final activeSemAsync = ref.watch(academicStateProvider);
            final currentCode = activeSemAsync.valueOrNull?.currentSemesterCode ?? semesterCode;
            if (currentCode != 'Unknown Semester') {
              _semester = CourseUtils.prettifySemesterCode(currentCode);
            } else {
              _semester = 'Summer 2026';
            }
          }

          // Build semester dropdown options
          final List<String> semesterOptions = [];
          allSemestersAsync.whenData((list) {
            for (final item in list) {
              final title = (item is Map ? item['title'] : item.title)?.toString() ?? '';
              if (title.isNotEmpty && !semesterOptions.contains(title)) {
                semesterOptions.add(title);
              }
            }
          });
          if (semesterOptions.isEmpty) {
            semesterOptions.addAll(['Summer 2026', 'Spring 2026', 'Fall 2026', 'Summer 2025']);
          }
          if (_semester.isNotEmpty && !semesterOptions.contains(_semester)) {
            semesterOptions.insert(0, _semester);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // Section 1: Template & Semester
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.description_rounded,
                        title: 'Submission Details',
                        subtitle: 'Select template style and target semester',
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedTemplate,
                          decoration: _inputDecoration(
                            labelText: 'Template Format',
                            prefixIcon: const Icon(Icons.layers_rounded, color: AppColors.primaryCyan, size: 20),
                          ),
                          dropdownColor: AppColors.surfaceNavyBlue,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          items: _templates.map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!, style: GoogleFonts.sora(), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedTemplate = v!;
                              if (_selectedTemplate != 'group_project' && _selectedTemplate != 'term_paper') {
                                _additionalStudents.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('semester_dropdown_$_semester'),
                          initialValue: semesterOptions.contains(_semester) ? _semester : semesterOptions.first,
                          isExpanded: true,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          dropdownColor: AppColors.surfaceNavyBlue,
                          decoration: _inputDecoration(
                            labelText: 'Academic Semester',
                            prefixIcon: const Icon(Icons.event_note_rounded, color: AppColors.primaryCyan, size: 20),
                          ),
                          items: semesterOptions.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: GoogleFonts.sora(), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _semester = v);
                            }
                          },
                          onSaved: (v) => _semester = v ?? _semester,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      if (['assignment', 'mps_assignment', 'project_report', 'group_project', 'term_paper'].contains(_selectedTemplate)) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          decoration: _inputDecoration(
                            labelText: 'Topic / Project Title',
                            prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primaryCyan, size: 20),
                          ),
                          onSaved: (v) => _topic = v ?? '',
                        ),
                      ],
                      if (['lab_report', 'physics_lab'].contains(_selectedTemplate)) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                decoration: _inputDecoration(labelText: 'Exp. No'),
                                onSaved: (v) => _labNo = v ?? '',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                decoration: _inputDecoration(labelText: 'Experiment Name'),
                                onSaved: (v) => _topic = v ?? '',
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (['mps_assignment', 'physics_lab', 'group_project', 'term_paper'].contains(_selectedTemplate)) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                          decoration: _inputDecoration(
                            labelText: 'Group Number',
                            prefixIcon: const Icon(Icons.group_work_rounded, color: AppColors.primaryCyan, size: 20),
                          ),
                          onSaved: (v) => _groupNo = v ?? '',
                        ),
                      ],
                      if (_isLoadingDepts)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
                        )
                      else if (_departments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: _inputDecoration(
                              labelText: 'Faculty Department (Header)',
                              prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.primaryCyan, size: 20),
                            ),
                            initialValue: _departments.contains(_headerDept) ? _headerDept : null,
                            dropdownColor: AppColors.surfaceNavyBlue,
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                            items: _departments.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, style: GoogleFonts.sora(fontSize: 12), overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _headerDept = v;
                                  _teacherDept = v;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Primary Student
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.person_rounded,
                        title: 'Primary Student',
                        subtitle: 'Details for lead submitter',
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          if (isNarrow) {
                            return Column(
                              children: [
                                TextFormField(
                                  key: ValueKey('student_name_$_primaryName'),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                  decoration: _inputDecoration(labelText: 'Full Name'),
                                  initialValue: _primaryName,
                                  onChanged: (v) => _primaryName = v,
                                  onSaved: (v) => _primaryName = v ?? '',
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: ValueKey('student_id_$_primaryId'),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                  decoration: _inputDecoration(labelText: 'Student ID'),
                                  initialValue: _primaryId,
                                  onChanged: (v) => _primaryId = v,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('student_name_$_primaryName'),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                  decoration: _inputDecoration(labelText: 'Full Name'),
                                  initialValue: _primaryName,
                                  onChanged: (v) => _primaryName = v,
                                  onSaved: (v) => _primaryName = v ?? '',
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('student_id_$_primaryId'),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                  decoration: _inputDecoration(labelText: 'Student ID'),
                                  initialValue: _primaryId,
                                  onChanged: (v) => _primaryId = v,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          final programWidget = _isLoadingPrograms 
                            ? const Center(child: LinearProgressIndicator(color: AppColors.primaryCyan))
                            : Theme(
                                data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: _inputDecoration(labelText: 'Program'),
                                  dropdownColor: AppColors.surfaceNavyBlue,
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                  initialValue: _programData.any((p) => p['name'] == _primaryProgram) 
                                    ? _programData.firstWhere((p) => p['name'] == _primaryProgram)['program_code'] 
                                    : null,
                                  items: _programData.map((p) => DropdownMenuItem(
                                    value: p['program_code'].toString(),
                                    child: Text(p['program_code'].toString(), style: GoogleFonts.sora(), overflow: TextOverflow.ellipsis),
                                  )).toList(),
                                  onChanged: (v) => _onProgramChanged(v!, true),
                                ),
                              );

                          final nameWidget = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Text(
                              _primaryProgram.isEmpty ? 'Program Name' : _primaryProgram,
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                color: _primaryProgram.isEmpty ? Colors.white24 : Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                programWidget,
                                const SizedBox(height: 10),
                                nameWidget,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(flex: 1, child: programWidget),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: nameWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('primary_dept_$_primaryDept'),
                          isExpanded: true,
                          decoration: _inputDecoration(labelText: 'Department'),
                          dropdownColor: AppColors.surfaceNavyBlue,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                          initialValue: _departments.contains(_primaryDept) ? _primaryDept : null,
                          items: _departments.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, style: GoogleFonts.sora(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() => _primaryDept = v!),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section 3: Additional Group Members (if applicable)
                if (_selectedTemplate == 'group_project' || _selectedTemplate == 'term_paper') ...[
                  const SizedBox(height: 16),
                  GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.group_add_rounded,
                          title: 'Group Members',
                          subtitle: 'Add up to 3 additional students',
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_rounded, color: AppColors.primaryCyan, size: 20),
                              onPressed: _addStudent,
                              tooltip: 'Add Member',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_additionalStudents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                'No extra members added. Click + to add member.',
                                style: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                              ),
                            ),
                          ),
                        ...List.generate(_additionalStudents.length, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Member ${index + 2}',
                                      style: GoogleFonts.sora(
                                        color: AppColors.primaryCyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () => _removeStudent(index),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                        decoration: _inputDecoration(labelText: 'Name'),
                                        onChanged: (v) => _additionalStudents[index]['name'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                        decoration: _inputDecoration(labelText: 'ID'),
                                        onChanged: (v) => _additionalStudents[index]['id'] = v,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                                        child: DropdownButtonFormField<String>(
                                          decoration: _inputDecoration(labelText: 'Program'),
                                          dropdownColor: AppColors.surfaceNavyBlue,
                                          style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                                          items: _programData.map((p) => DropdownMenuItem(
                                            value: p['program_code'].toString(),
                                            child: Text(p['program_code'].toString(), style: GoogleFonts.sora()),
                                          )).toList(),
                                          onChanged: (v) => _onProgramChanged(v!, false, index),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey('member_${index}_degree_${_additionalStudents[index]['program']}'),
                                        style: GoogleFonts.sora(color: Colors.white70, fontSize: 12),
                                        decoration: _inputDecoration(labelText: 'Degree'),
                                        initialValue: _additionalStudents[index]['program'],
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Theme(
                                  data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('member_${index}_dept_${_additionalStudents[index]['dept']}'),
                                    decoration: _inputDecoration(labelText: 'Department'),
                                    dropdownColor: AppColors.surfaceNavyBlue,
                                    style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                                    initialValue: _departments.contains(_additionalStudents[index]['dept']) ? _additionalStudents[index]['dept'] : null,
                                    items: _departments.map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d, style: GoogleFonts.sora(fontSize: 12)),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _additionalStudents[index]['dept'] = v!),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Section 4: Course & Faculty Info
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.school_rounded,
                        title: 'Course & Faculty Info',
                        subtitle: 'Autofill available from current enrollments',
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextFormField(
                                  key: ValueKey('course_code_field_$_courseCode'),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                                  decoration: _inputDecoration(
                                    labelText: 'Course Code',
                                    prefixIcon: const Icon(Icons.book_rounded, color: AppColors.primaryCyan, size: 20),
                                  ),
                                  initialValue: _courseCode,
                                  onChanged: (v) => _courseCode = v,
                                  onSaved: (v) => _courseCode = v ?? '',
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                if (_enrolledCoursesData.isNotEmpty)
                                  Positioned(
                                    right: 6,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primaryCyan),
                                        color: AppColors.surfaceNavyBlue,
                                        onSelected: (code) {
                                          final course = _enrolledCoursesData.firstWhere((c) => c['course_code'] == code);
                                          setState(() {
                                            _courseCode = course['course_code'].toString();
                                            _section = course['section']?.toString() ?? '';
                                          });
                                          _fetchFacultyDetails(_courseCode, _section, semesterCode);
                                        },
                                        itemBuilder: (context) => _enrolledCoursesData
                                            .map((c) => PopupMenuItem(
                                                  value: c['course_code'].toString(),
                                                  child: Text(
                                                    '${c['course_code']} (Sec ${c['section'] ?? '-'})',
                                                    style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                              decoration: _inputDecoration(labelText: 'Section'),
                              key: ValueKey('section_$_section'),
                              initialValue: _section,
                              onChanged: (v) => _section = v,
                              onSaved: (v) => _section = v ?? '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: ValueKey('title_$_courseTitle'),
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                        decoration: _inputDecoration(
                          labelText: 'Course Title',
                          prefixIcon: const Icon(Icons.subject_rounded, color: AppColors.primaryCyan, size: 20),
                        ),
                        initialValue: _courseTitle,
                        onChanged: (v) => _courseTitle = v,
                        onSaved: (v) => _courseTitle = v ?? '',
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          final teacherField = TextFormField(
                            key: ValueKey('teacher_$_teacherName'),
                            style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              labelText: 'Instructor Name',
                              prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primaryCyan, size: 20),
                            ),
                            initialValue: _teacherName,
                            onChanged: (v) => _teacherName = v,
                            onSaved: (v) => _teacherName = v ?? '',
                          );

                          final designationDropdown = Theme(
                            data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: _inputDecoration(labelText: 'Designation'),
                              dropdownColor: AppColors.surfaceNavyBlue,
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                              initialValue: _designations.contains(_designation) ? _designation : _designations.first,
                              items: _designations.map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, style: GoogleFonts.sora(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _designation = v);
                              },
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                teacherField,
                                const SizedBox(height: 12),
                                designationDropdown,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(flex: 3, child: teacherField),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: designationDropdown),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: AppColors.surfaceNavyBlue),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('dept_$_teacherDept'),
                          isExpanded: true,
                          decoration: _inputDecoration(
                            labelText: 'Instructor Department',
                            prefixIcon: const Icon(Icons.corporate_fare_rounded, color: AppColors.primaryCyan, size: 20),
                          ),
                          dropdownColor: AppColors.surfaceNavyBlue,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 12),
                          initialValue: _departments.any((d) => d.toLowerCase().contains(_teacherDept.toLowerCase())) 
                            ? _departments.firstWhere((d) => d.toLowerCase().contains(_teacherDept.toLowerCase())) 
                            : null,
                          items: _departments.map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, style: GoogleFonts.sora(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                 _headerDept = v;
                                 _teacherDept = v;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 5: Dates
                GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.calendar_month_rounded,
                        title: 'Dates (Optional)',
                        subtitle: 'Assignment allocation and submission dates',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range_rounded, color: AppColors.primaryCyan, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Assigned',
                                            style: GoogleFonts.sora(fontSize: 10, color: AppColors.secondaryText),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _allocationDate.isEmpty ? 'Pick Date' : _allocationDate,
                                            style: GoogleFonts.sora(
                                              fontSize: 13,
                                              color: _allocationDate.isEmpty ? Colors.white38 : Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, color: AppColors.primaryCyan, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Submission',
                                            style: GoogleFonts.sora(fontSize: 10, color: AppColors.secondaryText),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _submissionDate.isEmpty ? 'Pick Date' : _submissionDate,
                                            style: GoogleFonts.sora(
                                              fontSize: 13,
                                              color: _submissionDate.isEmpty ? Colors.white38 : Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit CTA Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryCyan, AppColors.secondarySoftBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withValues(alpha: _isGenerating ? 0.1 : 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () async {
                      if (profile != null) {
                        await _generatePDF(profile.toJson(), _semester);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isGenerating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Compiling Document...',
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryNavy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryNavy, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Generate PDF Cover Page',
                                style: GoogleFonts.sora(
                                  color: AppColors.primaryNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
