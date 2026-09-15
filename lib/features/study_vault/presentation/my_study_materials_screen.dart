import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../data/models/study_material.dart';
import '../data/repositories/study_vault_repository.dart';
import 'providers/study_vault_providers.dart';
import 'widgets/delete_material_sheet.dart';
import 'widgets/my_study_material_card.dart';

class MyStudyMaterialsScreen extends ConsumerStatefulWidget {
  const MyStudyMaterialsScreen({super.key});

  @override
  ConsumerState<MyStudyMaterialsScreen> createState() => _MyStudyMaterialsScreenState();
}

class _MyStudyMaterialsScreenState extends ConsumerState<MyStudyMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  bool _isSubmitting = false;

  final List<String> _departments = [
    'All',
    'CSE',
    'BUS',
    'ENG',
    'EEE',
    'MATH',
    'LAW',
    'PHR',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationBottomSheet(StudyMaterial item) async {
    final confirmed = await DeleteMaterialSheet.show(
      context,
      item: item,
      formattedSize: MyStudyMaterialCard.formatFileSize(item.fileSizeBytes),
      formattedDate: MyStudyMaterialCard.formatDate(item.createdAt),
      fileTypeBadge: MyStudyMaterialCard.buildFileTypeBadge(item.fileName, fileType: item.fileType),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(studyVaultRepositoryProvider);
      await repository.deleteOrRequestRemoval(item);

      // Refresh providers
      ref.invalidate(myStudyMaterialsProvider);
      ref.invalidate(studyMaterialsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.status == 'pending'
                  ? 'Material removed successfully.'
                  : 'Removal request submitted for administrator review.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openFile(StudyMaterial item) async {
    final url = Uri.parse('https://drive.google.com/file/d/${item.driveFileId}/view?usp=drivesdk');
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open document: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  List<StudyMaterial> _filterMaterials(List<StudyMaterial> materials) {
    return materials.where((item) {
      // Department filter
      if (_selectedDepartment != 'All') {
        final courseCode = (item.courseCode ?? '').toUpperCase();
        if (!courseCode.contains(_selectedDepartment)) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = item.fileName.toLowerCase().contains(q);
        final matchesCode = (item.courseCode ?? '').toLowerCase().contains(q);
        final matchesFaculty = (item.facultyInitial ?? '').toLowerCase().contains(q);
        final matchesType = (item.fileType ?? '').toLowerCase().contains(q);

        if (!matchesName && !matchesCode && !matchesFaculty && !matchesType) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myMaterialsAsync = ref.watch(myStudyMaterialsProvider);

    return FullGradientScaffold(
      appBar: const EWUmateAppBar(
        title: 'My Uploaded Materials',
        showBack: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Glowing Navy Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF071426),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x3319D9F5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search by course, title, or type...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF19D9F5),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
              ),

              // Department Filter Horizontal Pills
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _departments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    final isSelected = dept == _selectedDepartment;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDepartment = dept);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF19D9F5)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF19D9F5)
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF19D9F5).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dept,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF071426) : const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // List of Uploaded Materials
              Expanded(
                child: myMaterialsAsync.when(
                  data: (materials) {
                    final filtered = _filterMaterials(materials);

                    if (materials.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white24),
                            SizedBox(height: 16),
                            Text(
                              'You haven\'t uploaded any materials yet.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No materials matched your filter.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFF19D9F5),
                      backgroundColor: const Color(0xFF071426),
                      onRefresh: () async {
                        ref.invalidate(myStudyMaterialsProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: MyStudyMaterialCard(
                              item: item,
                              onOpen: () => _openFile(item),
                              onDelete: () => _showDeleteConfirmationBottomSheet(item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF19D9F5)),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Floating "+ Upload Material" Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: GestureDetector(
              onTap: () {
                context.push('/services/study-vault/upload');
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF19D9F5),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19D9F5).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Color(0xFF071426),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Upload Material',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Color(0xFF071426),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Submitting Overlay
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF19D9F5)),
              ),
            ),
        ],
      ),
    );
  }
}
