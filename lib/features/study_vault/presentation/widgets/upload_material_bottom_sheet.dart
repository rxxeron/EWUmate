import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/study_vault_providers.dart';
import '../../data/repositories/study_vault_repository.dart';

class UploadMaterialBottomSheet extends ConsumerStatefulWidget {
  const UploadMaterialBottomSheet({super.key});

  @override
  ConsumerState<UploadMaterialBottomSheet> createState() => _UploadMaterialBottomSheetState();
}

class _UploadMaterialBottomSheetState extends ConsumerState<UploadMaterialBottomSheet> {
  File? _selectedFile;
  String? _fileName;
  String? _fileType;
  bool _isUploading = false;

  final _courseController = TextEditingController();
  final _facultyController = TextEditingController();
  final _semesterController = TextEditingController();

  final List<String> _fileTypes = ['Note', 'Slide', 'Question', 'Book', 'Other'];

  @override
  void dispose() {
    _courseController.dispose();
    _facultyController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }
    
    // Using controllers for quick manual entry, ideally these would be searchable dropdowns connected to DB
    final course = _courseController.text.trim();
    final faculty = _facultyController.text.trim();
    final semester = _semesterController.text.trim();

    if (course.isEmpty || faculty.isEmpty || semester.isEmpty || _fileType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repository = ref.read(studyVaultRepositoryProvider);
      await repository.uploadMaterial(
        file: _selectedFile!,
        fileName: _fileName ?? 'Unknown',
        facultyInitial: faculty.toUpperCase(),
        courseCode: course.toUpperCase(),
        semester: semester,
        fileType: _fileType,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
        // Refresh the list
        ref.invalidate(studyMaterialsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Study Material',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course Code (e.g., CSE101)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _facultyController,
              decoration: const InputDecoration(labelText: 'Faculty Initial (e.g., RH)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _semesterController,
              decoration: const InputDecoration(labelText: 'Semester (e.g., Spring 2024)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'File Type'),
              initialValue: _fileType,
              items: _fileTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                setState(() {
                  _fileType = val;
                });
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName ?? 'Select File (Any file type)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUploading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload to Vault'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
