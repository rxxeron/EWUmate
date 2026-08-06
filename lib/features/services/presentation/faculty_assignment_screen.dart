import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ewumate/core/providers/academic_providers.dart';
import 'package:ewumate/core/providers/supabase_provider.dart';
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

  // State for Enrolled Courses Tab
  List<Map<String, dynamic>> _enrolledCourses = [];
  final Map<String, TextEditingController> _enrolledInitialControllers = {};
  Uint8List? _enrolledScreenshotBytes;
  String? _enrolledScreenshotName;

  // State for Bulk Non-Enrolled Tab
  List<Map<String, dynamic>> _facultyMaster = [];
  Map<String, dynamic>? _selectedFaculty;
  Uint8List? _bulkScreenshotBytes;
  String? _bulkScreenshotName;
  final List<Map<String, String>> _bulkSelections = [];

  final TextEditingController _bulkCourseCodeCtrl = TextEditingController();
  final TextEditingController _bulkSectionCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();

    if (widget.initialCourseCode != null && widget.initialSection != null) {
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
      final currentSem = ref.read(currentSemesterCodeProvider).value ?? 'Summer2026';
      final cleanSem = currentSem.replaceAll(' ', '');

      final user = supabase.auth.currentUser;

      // 1. Fetch Faculty Master List
      final facList = await repo.fetchFacultyMasterList();

      // 2. Fetch Enrolled Courses for User
      List<Map<String, dynamic>> enrolled = [];
      if (user != null) {
        final enrollRes = await supabase
            .from('enrollments')
            .select('course_code, section, semester_code')
            .eq('user_id', user.id)
            .eq('semester_code', cleanSem);

        enrolled = List<Map<String, dynamic>>.from(enrollRes as List);
        for (var c in enrolled) {
          final key = '${c['course_code']}_${c['section']}';
          _enrolledInitialControllers[key] = TextEditingController();
        }
      }

      if (mounted) {
        setState(() {
          _facultyMaster = facList;
          _enrolledCourses = enrolled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    final currentSem = ref.read(currentSemesterCodeProvider).value ?? 'Summer2026';
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
        semester: currentSem,
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
    final code = _bulkCourseCodeCtrl.text.trim().toUpperCase();
    final sec = _bulkSectionCtrl.text.trim();

    if (code.isEmpty || sec.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Course Code & Section')),
      );
      return;
    }

    setState(() {
      _bulkSelections.add({'course_code': code, 'section_number': sec});
      _bulkCourseCodeCtrl.clear();
      _bulkSectionCtrl.clear();
    });
  }

  Future<void> _submitBulkTab() async {
    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty member.')),
      );
      return;
    }

    if (_bulkSelections.isEmpty &&
        (_bulkCourseCodeCtrl.text.trim().isEmpty || _bulkSectionCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one course & section.')),
      );
      return;
    }

    if (_bulkCourseCodeCtrl.text.trim().isNotEmpty && _bulkSectionCtrl.text.trim().isNotEmpty) {
      _addBulkItem();
    }

    if (_bulkScreenshotBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload schedule screenshot proof.')),
      );
      return;
    }

    final currentSem = ref.read(currentSemesterCodeProvider).value ?? 'Summer2026';
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
        semester: currentSem,
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEnrolledTab(theme),
                _buildBulkTab(theme),
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
              const Text(
                'No enrolled courses found for active semester.',
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

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$code - Sec $sec',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text('Status: TBA', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: ctrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'e.g. NHUDA',
                          labelText: 'Initial',
                          isDense: true,
                          border: OutlineInputBorder(),
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
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedFaculty,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: const Text('Choose Faculty (Search by Initial or Name)'),
            items: _facultyMaster.map((f) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: f,
                child: Text('${f['short_name']} - ${f['full_name']}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedFaculty = val),
          ),
          const SizedBox(height: 20),

          const Text('2. Add Course Sections for This Faculty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
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
