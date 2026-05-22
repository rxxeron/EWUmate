import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/study_vault_providers.dart';
import '../data/repositories/study_vault_repository.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import 'widgets/paginated_search_bottom_sheet.dart';

class UploadStudyMaterialScreen extends ConsumerStatefulWidget {
  const UploadStudyMaterialScreen({super.key});

  @override
  ConsumerState<UploadStudyMaterialScreen> createState() => _UploadStudyMaterialScreenState();
}

class _UploadStudyMaterialScreenState extends ConsumerState<UploadStudyMaterialScreen> {
  final List<PlatformFile> _selectedFiles = [];
  
  // Maps a file's path (or name if web) to its selected type
  final Map<String, String> _fileTypesSelection = {};
  
  bool _isUploading = false;
  bool _isLoadingOptions = true;

  String? _courseCode;
  String? _courseName;
  String? _facultyInitial;
  String? _facultyName;
  String? _semester;

  List<Map<String, String>> _semesterOptions = [
    {'code': 'spring2024', 'title': 'Spring 2024'},
    {'code': 'summer2024', 'title': 'Summer 2024'},
    {'code': 'fall2024', 'title': 'Fall 2024'},
    {'code': 'spring2025', 'title': 'Spring 2025'},
    {'code': 'summer2025', 'title': 'Summer 2025'},
    {'code': 'fall2025', 'title': 'Fall 2025'},
    {'code': 'spring2026', 'title': 'Spring 2026'},
    {'code': 'summer2026', 'title': 'Summer 2026'},
    {'code': 'fall2026', 'title': 'Fall 2026'}
  ];

  final List<String> _fileTypes = [
    'Term Paper',
    'Mid Questions',
    'Final Question',
    'Final Questions',
    'Quiz Questions',
    'Course Outline',
    'Slide',
    'Sample Code',
    'Book',
    'Lab Manual',
    'Lab Report',
    'Project Report',
    'Lecture Notes',
    'Assignment Solution',
    'Syllabus',
    'Cheat Sheet',
    'Class Handout',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      // Fetch semesters dynamically from the database to ensure we support all current semesters
      final List<Map<String, String>> dbSemesters = [];
      final semesterRes = await Supabase.instance.client
          .from('semesters')
          .select('code, title')
          .order('code', ascending: false);
          
      final rows = semesterRes as List;
      for (var row in rows) {
        if (row['code'] != null) {
          dbSemesters.add({
            'code': row['code'].toString(),
            'title': row['title']?.toString() ?? row['code'].toString(),
          });
        }
      }

      if (mounted) {
        setState(() {
          if (dbSemesters.isNotEmpty) {
            _semesterOptions = dbSemesters;
          }
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching semesters: $e");
      if (mounted) {
        setState(() {
          _isLoadingOptions = false; // Graceful fallback to hardcoded list
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (var file in result.files) {
          final key = file.path ?? file.name;
          if (!_selectedFiles.any((f) => (f.path ?? f.name) == key)) {
            _selectedFiles.add(file);
            _fileTypesSelection[key] = 'Other'; // Default type from the expanded list
          }
        }
      });
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      final key = file.path ?? file.name;
      _selectedFiles.removeWhere((f) => (f.path ?? f.name) == key);
      _fileTypesSelection.remove(key);
    });
  }

  Future<void> _uploadAll() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one file')),
      );
      return;
    }
    
    if (_courseCode == null || _facultyInitial == null || _semester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Course, Faculty, and Semester')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repository = ref.read(studyVaultRepositoryProvider);
      
      for (var file in _selectedFiles) {
        final filePath = file.path;
        if (filePath == null) continue;
        
        final type = _fileTypesSelection[filePath] ?? 'Other';
        
        await repository.uploadMaterial(
          file: File(filePath),
          fileName: file.name,
          facultyInitial: _facultyInitial!,
          courseCode: _courseCode!,
          semester: _semester!, // Mapped database key (e.g. summer2025)
          fileType: type,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All files uploaded successfully!')),
        );
        ref.invalidate(studyMaterialsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData iconData;
    Color color;
    
    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      color = Colors.redAccent;
    } else if (ext == 'doc' || ext == 'docx') {
      iconData = Icons.description_rounded;
      color = Colors.blueAccent;
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      iconData = Icons.image_rounded;
      color = Colors.greenAccent;
    } else {
      iconData = Icons.insert_drive_file_rounded;
      color = Colors.white54;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  void _showCourseSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PaginatedSearchBottomSheet(
          title: 'Select Course Code',
          tableName: 'course_metadata',
          labelKey: 'code',
          subtitleKey: 'name',
          searchPlaceholder: 'Search course code or title...',
          customValueLabel: 'Add this custom course code to details',
          onSelected: (code, name) {
            setState(() {
              _courseCode = code;
              _courseName = name;
            });
          },
        );
      },
    );
  }

  void _showFacultySearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PaginatedSearchBottomSheet(
          title: 'Select Faculty Member',
          tableName: 'faculty_directory',
          labelKey: 'short_name',
          subtitleKey: 'full_name',
          searchPlaceholder: 'Search faculty initial or name...',
          customValueLabel: 'Add this custom faculty initial to details',
          onSelected: (code, name) {
            setState(() {
              _facultyInitial = code;
              _facultyName = name;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: const EWUmateAppBar(
        title: 'Upload to Vault',
        showBack: true,
      ),
      body: _isLoadingOptions 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Global Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Custom Searchable Selector for Course Code
                  GlassContainer(
                    onTap: _showCourseSearchBottomSheet,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    borderRadius: 16,
                    borderColor: _courseCode != null ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white10,
                    opacity: 0.03,
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: _courseCode != null ? Colors.cyanAccent : Colors.white38,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Course Code',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _courseCode != null
                                    ? '[$_courseCode] ${_courseName ?? ""}'
                                    : 'Search course code...',
                                style: TextStyle(
                                  color: _courseCode != null ? Colors.white : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: _courseCode != null ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom Searchable Selector for Faculty
                  GlassContainer(
                    onTap: _showFacultySearchBottomSheet,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    borderRadius: 16,
                    borderColor: _facultyInitial != null ? Colors.purpleAccent.withValues(alpha: 0.3) : Colors.white10,
                    opacity: 0.03,
                    child: Row(
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          color: _facultyInitial != null ? Colors.purpleAccent : Colors.white38,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Faculty Initial',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _facultyInitial != null
                                    ? '[$_facultyInitial] ${_facultyName ?? ""}'
                                    : 'Search faculty initial...',
                                style: TextStyle(
                                  color: _facultyInitial != null ? Colors.white : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: _facultyInitial != null ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: const Color(0xFF0F172A),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Colors.cyanAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.cyanAccent),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      initialValue: _semester,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      iconEnabledColor: Colors.white60,
                      items: _semesterOptions.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['code'],
                          child: Text(
                            s['title']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _semester = val),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    "Select Files",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.cyanAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add Files (Any file type)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Up to 10 files at a time',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_selectedFiles.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final key = file.path ?? file.name;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _getFileIcon(file.name),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        file.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                      onPressed: () => _removeFile(file),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: const Color(0xFF1E293B),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'File Type',
                                      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.white10),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    initialValue: _fileTypesSelection[key],
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    items: _fileTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _fileTypesSelection[key] = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: _isUploading ? 0.0 : 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadAll,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                            )
                          : const Text(
                              'Upload All to Vault', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

