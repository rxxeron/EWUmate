import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/study_vault_providers.dart';
import '../data/repositories/study_vault_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result.isNotEmpty) {
      setState(() {
        for (var file in result) {
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
          showCustomValue: false,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Global Details",
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Target course, faculty initial, and semester",
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Custom Searchable Selector for Course Code
                  GlassContainer(
                    onTap: _showCourseSearchBottomSheet,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: _courseCode != null ? AppColors.primaryCyan : Colors.white38,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course Code',
                                style: GoogleFonts.sora(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _courseCode != null
                                    ? '[$_courseCode] ${_courseName ?? ""}'
                                    : 'Search course code...',
                                style: GoogleFonts.sora(
                                  color: _courseCode != null ? Colors.white : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: _courseCode != null ? FontWeight.w600 : FontWeight.w400,
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
                  const SizedBox(height: 14),

                  // Custom Searchable Selector for Faculty
                  GlassContainer(
                    onTap: _showFacultySearchBottomSheet,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoftBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.badge_rounded,
                            color: _facultyInitial != null ? AppColors.secondarySoftBlue : Colors.white38,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Faculty Initial',
                                style: GoogleFonts.sora(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _facultyInitial != null
                                    ? '[$_facultyInitial] ${_facultyName ?? ""}'
                                    : 'Search faculty initial...',
                                style: GoogleFonts.sora(
                                  color: _facultyInitial != null ? Colors.white : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: _facultyInitial != null ? FontWeight.w600 : FontWeight.w400,
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
                  const SizedBox(height: 14),

                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: AppColors.surfaceNavyBlue,
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryCyan, size: 20),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      initialValue: _semester,
                      dropdownColor: AppColors.surfaceNavyBlue,
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 14),
                      iconEnabledColor: Colors.white60,
                      items: _semesterOptions.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['code'],
                          child: Text(
                            s['title']!,
                            style: GoogleFonts.sora(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _semester = val),
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primaryCyan, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Files",
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "PDFs, images, slides, notes, or code",
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppColors.primaryCyan,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add Files (Any file type)',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to 10 files at a time',
                            style: GoogleFonts.sora(
                              color: AppColors.secondaryText,
                              fontSize: 12,
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
                          color: AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                                        style: GoogleFonts.sora(
                                          fontWeight: FontWeight.w600,
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
                                const SizedBox(height: 14),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: AppColors.surfaceNavyBlue,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'File Type',
                                      labelStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.02),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primaryCyan),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    dropdownColor: AppColors.surfaceNavyBlue,
                                    initialValue: _fileTypesSelection[key],
                                    style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                    items: _fileTypes.map((t) => DropdownMenuItem(
                                      value: t, 
                                      child: Text(t, style: GoogleFonts.sora()),
                                    )).toList(),
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

                  const SizedBox(height: 28),
                  
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
                          color: AppColors.primaryCyan.withValues(alpha: _isUploading ? 0.0 : 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Uploading Files...',
                                  style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.file_upload_outlined, color: AppColors.primaryNavy, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Upload All to Vault', 
                                  style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 15, 
                                    color: AppColors.primaryNavy,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
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

