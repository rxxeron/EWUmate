import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../../core/services/azure_functions_service.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/repositories/progress_repository.dart';
import 'package:ewumate/core/repositories/auth_repository.dart';
import 'package:ewumate/core/repositories/profile_repository.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';

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
  bool _isLoadingEnrolledCourses = true;
  
  List<Map<String, String>> _additionalStudents = [];
  
  List<Map<String, dynamic>> _programData = [];
  bool _isLoadingPrograms = true;
  bool _profileInitialized = false;

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
            _isLoadingEnrolledCourses = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDepts = false;
          _isLoadingPrograms = false;
          _isLoadingEnrolledCourses = false;
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

    final azureService = ref.read(azureFunctionsServiceProvider);
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating secure PDF...')),
      );

      final response = await http.post(
        Uri.parse('https://ewumate-parser.azurewebsites.net/api/generate_pdf'),
        headers: {
          "Content-Type": "application/json",
          "x-functions-key": azureService.functionKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/academic_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Open the file
        await OpenFilex.open(filePath);
      } else {
        throw 'Server returned error: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

      if (res != null) {
        setState(() {
          _courseTitle = res['course_name']?.toString() ?? '';
          _teacherName = res['faculty_full_name']?.toString() ?? '';
          
          final dbDesignation = res['faculty_designation']?.toString() ?? '';
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

  Future<void> _selectDate(BuildContext context, bool isSubmission) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final profileAsync = ref.watch(userProfileProvider);
    final currentSemAsync = ref.watch(currentSemesterCodeProvider);
    final marksAsync = ref.watch(currentSemesterMarksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cover Page Generator')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (!_profileInitialized && profile != null && _programData.isNotEmpty) {
            _primaryName = profile.fullName ?? '';
            _primaryId = profile.studentId ?? '';
            
            // Try to resolve full degree name from program code
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
          
          final semesterCode = currentSemAsync.value ?? 'Summer2026';
          
          // Initialize _semester if empty
          if (_semester.isEmpty && semesterCode != 'Unknown Semester') {
             // Format 'Summer2026' -> 'Summer 2026'
             _semester = semesterCode.replaceAllMapped(RegExp(r'(\d+)'), (match) => ' ${match.group(0)}').trim();
          }
          
          final enrolledCourses = marksAsync.value ?? [];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Submission Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedTemplate,
                  decoration: const InputDecoration(labelText: 'Template Format', border: OutlineInputBorder()),
                  items: _templates.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTemplate = v!;
                      if (_selectedTemplate != 'group_project' && _selectedTemplate != 'term_paper') {
                        _additionalStudents.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  key: ValueKey('semester_field_$_semester'),
                  initialValue: _semester,
                  decoration: const InputDecoration(
                    labelText: 'Academic Semester',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Summer 2026',
                  ),
                  onChanged: (v) => _semester = v,
                  onSaved: (v) => _semester = v ?? '',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                if (['assignment', 'mps_assignment', 'project_report', 'group_project', 'term_paper'].contains(_selectedTemplate)) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Topic / Project Name', border: OutlineInputBorder()),
                    onSaved: (v) => _topic = v ?? '',
                  ),
                  const SizedBox(height: 16),
                ],

                if (['lab_report', 'physics_lab'].contains(_selectedTemplate)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Experiment No', border: OutlineInputBorder()),
                          onSaved: (v) => _labNo = v ?? '',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Experiment Name', border: OutlineInputBorder()),
                          onSaved: (v) => _topic = v ?? '', // maps to topic in backend
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (['mps_assignment', 'physics_lab', 'group_project', 'term_paper'].contains(_selectedTemplate)) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Group No', border: OutlineInputBorder()),
                    onSaved: (v) => _groupNo = v ?? '',
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (_isLoadingDepts)
                  const Center(child: CircularProgressIndicator())
                else if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Faculty Department (Header)', border: OutlineInputBorder()),
                  value: _departments.contains(_headerDept) ? _headerDept : null,
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _headerDept = v;
                        _teacherDept = v; // Keep the full name
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                const Text('Student Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Primary Student', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                key: ValueKey('student_name_$_primaryName'),
                                decoration: const InputDecoration(labelText: 'Full Name'),
                                initialValue: _primaryName,
                                onChanged: (v) => _primaryName = v,
                                onSaved: (v) => _primaryName = v ?? '',
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('student_id_$_primaryId'),
                                decoration: const InputDecoration(labelText: 'ID'),
                                initialValue: _primaryId,
                                onChanged: (v) => _primaryId = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _isLoadingPrograms 
                                ? const Center(child: LinearProgressIndicator())
                                : DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(labelText: 'Program'),
                                    value: _programData.any((p) => p['name'] == _primaryProgram) ? _programData.firstWhere((p) => p['name'] == _primaryProgram)['program_code'] : null,
                                    items: _programData.map((p) => DropdownMenuItem(value: p['program_code'].toString(), child: Text(p['program_code'].toString()))).toList(),
                                    onChanged: (v) => _onProgramChanged(v!, true),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _primaryProgram,
                                style: const TextStyle(fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey('primary_dept_$_primaryDept'),
                          decoration: const InputDecoration(labelText: 'Department'),
                          value: _departments.contains(_primaryDept) ? _primaryDept : null,
                          items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => _primaryDept = v!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_selectedTemplate == 'group_project' || _selectedTemplate == 'term_paper') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Additional Group Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addStudent,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Member'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ...List.generate(_additionalStudents.length, (index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Member ${index + 2}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeStudent(index)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Name'),
                                  onChanged: (v) => _additionalStudents[index]['name'] = v,
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'ID'),
                                  onChanged: (v) => _additionalStudents[index]['id'] = v,
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(labelText: 'Program'),
                                    items: _programData.map((p) => DropdownMenuItem(value: p['program_code'].toString(), child: Text(p['program_code'].toString()))).toList(),
                                    onChanged: (v) => _onProgramChanged(v!, false, index),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('member_${index}_degree_${_additionalStudents[index]['program']}'),
                                    decoration: const InputDecoration(labelText: 'Degree'),
                                    initialValue: _additionalStudents[index]['program'],
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey('member_${index}_dept_${_additionalStudents[index]['dept']}'),
                              decoration: const InputDecoration(labelText: 'Department'),
                              value: _departments.contains(_additionalStudents[index]['dept']) ? _additionalStudents[index]['dept'] : null,
                              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (v) => setState(() => _additionalStudents[index]['dept'] = v!),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                const Text('Course & Faculty Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextFormField(
                            key: ValueKey('course_code_field_$_courseCode'),
                            decoration: const InputDecoration(
                              labelText: 'Course Code',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _courseCode,
                            onChanged: (v) => _courseCode = v,
                            onSaved: (v) => _courseCode = v ?? '',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          if (_enrolledCoursesData.isNotEmpty)
                            Positioned(
                              right: 4,
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
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
                                          child: Text(c['course_code'].toString()),
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Section'),
                        key: ValueKey('section_$_section'),
                        initialValue: _section,
                        onChanged: (v) => _section = v,
                        onSaved: (v) => _section = v ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('title_$_courseTitle'),
                  decoration: const InputDecoration(labelText: 'Course Title'),
                  initialValue: _courseTitle,
                  onChanged: (v) => _courseTitle = v,
                  onSaved: (v) => _courseTitle = v ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: ValueKey('teacher_$_teacherName'),
                        decoration: const InputDecoration(labelText: 'Instructor Name'),
                        initialValue: _teacherName,
                        onChanged: (v) => _teacherName = v,
                        onSaved: (v) => _teacherName = v ?? '',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Designation'),
                        value: _designations.contains(_designation) ? _designation : _designations.first,
                        items: _designations.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _designation = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('dept_$_teacherDept'),
                  decoration: const InputDecoration(labelText: 'Instructor Dept'),
                  value: _departments.any((d) => d.toLowerCase().contains(_teacherDept.toLowerCase())) 
                    ? _departments.firstWhere((d) => d.toLowerCase().contains(_teacherDept.toLowerCase())) 
                    : null,
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                         _headerDept = v;
                         _teacherDept = v; // Keep the full name
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                const Text('Dates (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (['physics_lab', 'project_report', 'lab_report', 'mps_assignment'].contains(_selectedTemplate)) ...[
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('allocation_$_allocationDate'),
                          readOnly: true,
                          onTap: () => _selectDate(context, false),
                          decoration: InputDecoration(
                            labelText: 'Allocation Date',
                            suffixIcon: _allocationDate.isNotEmpty 
                              ? IconButton(icon: const Icon(IconData(0xe16a, fontFamily: 'MaterialIcons')), onPressed: () => setState(() => _allocationDate = '')) 
                              : const Icon(IconData(0xe111, fontFamily: 'MaterialIcons')),
                          ),
                          initialValue: _allocationDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('submission_$_submissionDate'),
                        readOnly: true,
                        onTap: () => _selectDate(context, true),
                        decoration: InputDecoration(
                          labelText: 'Submission Date',
                          hintText: 'Defaults to today',
                          suffixIcon: _submissionDate.isNotEmpty 
                            ? IconButton(icon: const Icon(IconData(0xe16a, fontFamily: 'MaterialIcons')), onPressed: () => setState(() => _submissionDate = '')) 
                            : const Icon(IconData(0xe111, fontFamily: 'MaterialIcons')),
                        ),
                        initialValue: _submissionDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => _generatePDF({}, _semester),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Generate PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
