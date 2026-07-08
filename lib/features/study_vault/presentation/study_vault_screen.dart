import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import 'providers/study_vault_providers.dart';
import 'package:go_router/go_router.dart';
import 'widgets/paginated_search_bottom_sheet.dart';

class StudyVaultScreen extends ConsumerStatefulWidget {
  const StudyVaultScreen({super.key});

  @override
  ConsumerState<StudyVaultScreen> createState() => _StudyVaultScreenState();
}

class _StudyVaultScreenState extends ConsumerState<StudyVaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(vaultFiltersProvider.notifier).update((state) {
        final newState = Map<String, String?>.from(state);
        newState['searchQuery'] = query.trim().isEmpty ? null : query;
        return newState;
      });
    });
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 28),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Future<void> _showFilterPicker(BuildContext context, String filterKey, String label) async {
    if (filterKey == 'facultyInitial') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return PaginatedSearchBottomSheet(
            title: 'Select Faculty Filter',
            tableName: 'faculty_directory',
            labelKey: 'short_name',
            subtitleKey: 'full_name',
            searchPlaceholder: 'Search faculty initial or name...',
            customValueLabel: '',
            showCustomValue: false,
            onSelected: (code, name) {
              ref.read(vaultFiltersProvider.notifier).update((state) {
                final newState = Map<String, String?>.from(state);
                newState[filterKey] = code;
                return newState;
              });
            },
          );
        },
      );
    } else if (filterKey == 'courseCode') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return PaginatedSearchBottomSheet(
            title: 'Select Course Filter',
            tableName: 'course_metadata',
            labelKey: 'code',
            subtitleKey: 'name',
            searchPlaceholder: 'Search course code or title...',
            customValueLabel: '',
            showCustomValue: false,
            onSelected: (code, name) {
              ref.read(vaultFiltersProvider.notifier).update((state) {
                final newState = Map<String, String?>.from(state);
                newState[filterKey] = code;
                return newState;
              });
            },
          );
        },
      );
    } else if (filterKey == 'semester') {
      final semestersFuture = ref.read(semestersProvider.future);
      List<Map<String, String>> semestersList = [];
      try {
        semestersList = await semestersFuture;
      } catch (e) {
        semestersList = [
          {'value': 'spring2024', 'label': 'Spring 2024'},
          {'value': 'summer2024', 'label': 'Summer 2024'},
          {'value': 'fall2024', 'label': 'Fall 2024'},
          {'value': 'spring2025', 'label': 'Spring 2025'},
          {'value': 'summer2025', 'label': 'Summer 2025'},
          {'value': 'fall2025', 'label': 'Fall 2025'},
          {'value': 'spring2026', 'label': 'Spring 2026'},
          {'value': 'summer2026', 'label': 'Summer 2026'},
          {'value': 'fall2026', 'label': 'Fall 2026'}
        ];
      }
      
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StaticListBottomSheet(
            title: 'Select Semester Filter',
            items: semestersList,
            onSelected: (val) {
              ref.read(vaultFiltersProvider.notifier).update((state) {
                final newState = Map<String, String?>.from(state);
                newState[filterKey] = val;
                return newState;
              });
            },
          );
        },
      );
    } else if (filterKey == 'fileType') {
      final types = [
        {'value': 'Term Paper', 'label': 'Term Paper'},
        {'value': 'Mid Questions', 'label': 'Mid Questions'},
        {'value': 'Final Question', 'label': 'Final Question'},
        {'value': 'Quiz Questions', 'label': 'Quiz Questions'},
        {'value': 'Course Outline', 'label': 'Course Outline'},
        {'value': 'Slide', 'label': 'Slide'},
        {'value': 'Sample Code', 'label': 'Sample Code'},
        {'value': 'Book', 'label': 'Book'},
        {'value': 'Lab Manual', 'label': 'Lab Manual'},
        {'value': 'Lab Report', 'label': 'Lab Report'},
        {'value': 'Project Report', 'label': 'Project Report'},
        {'value': 'Lecture Notes', 'label': 'Lecture Notes'},
        {'value': 'Assignment Solution', 'label': 'Assignment Solution'},
        {'value': 'Syllabus', 'label': 'Syllabus'},
        {'value': 'Cheat Sheet', 'label': 'Cheat Sheet'},
        {'value': 'Other', 'label': 'Other'},
      ];

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StaticListBottomSheet(
            title: 'Select Document Type',
            items: types,
            onSelected: (val) {
              ref.read(vaultFiltersProvider.notifier).update((state) {
                final newState = Map<String, String?>.from(state);
                newState[filterKey] = val;
                return newState;
              });
            },
          );
        },
      );
    }
  }

  Widget _buildFilterChip(BuildContext context, String filterKey, String label) {
    final currentFilters = ref.watch(vaultFiltersProvider);
    final isActive = currentFilters[filterKey] != null;
    final value = currentFilters[filterKey];

    Color activeColor;
    IconData icon;
    if (filterKey == 'facultyInitial') {
      activeColor = Colors.purpleAccent;
      icon = Icons.badge_rounded;
    } else if (filterKey == 'courseCode') {
      activeColor = Colors.cyanAccent;
      icon = Icons.menu_book_rounded;
    } else if (filterKey == 'semester') {
      activeColor = Colors.tealAccent;
      icon = Icons.calendar_today_rounded;
    } else {
      activeColor = Colors.amberAccent;
      icon = Icons.category_rounded;
    }

    String displayValue = value ?? "";
    if (filterKey == 'semester' && value != null) {
      try {
        if (value.length > 4) {
          final season = value.substring(0, value.length - 4);
          final year = value.substring(value.length - 4);
          if (season.isNotEmpty) {
            displayValue = '${season[0].toUpperCase()}${season.substring(1)} $year';
          } else {
            displayValue = value;
          }
        } else {
          displayValue = value;
        }
      } catch (e) {
        displayValue = value;
      }
    }

    return GestureDetector(
      onTap: () {
        if (isActive) {
          ref.read(vaultFiltersProvider.notifier).update((state) {
            final newState = Map<String, String?>.from(state);
            newState[filterKey] = null;
            return newState;
          });
        } else {
          _showFilterPicker(context, filterKey, label);
        }
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 20,
        borderColor: isActive ? activeColor.withValues(alpha: 0.6) : Colors.white10,
        opacity: isActive ? 0.08 : 0.02,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                icon,
                size: 14,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isActive ? displayValue : label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: Colors.white38,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(studyMaterialsProvider);

    return FullGradientScaffold(
      appBar: EWUmateAppBar(
        title: 'Study Materials Vault',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared_rounded, color: Colors.purpleAccent),
            tooltip: 'My Uploads',
            onPressed: () {
              context.push('/services/study-vault/my-uploads');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/services/study-vault/upload');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.cyanAccent,
                Colors.purpleAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.cloud_upload_rounded, color: Colors.black87, size: 20),
              SizedBox(width: 8),
              Text(
                'Upload Material',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Elegant Sleek Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search course code, faculty, or title...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) {
                  _onSearchChanged(val);
                  setState(() {});
                },
              ),
            ),
          ),
          // Scrollable Horizontal Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'facultyInitial', 'Faculty'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'courseCode', 'Course'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'semester', 'Semester'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'fileType', 'Type'),
                ],
              ),
            ),
          ),
          Expanded(
            child: materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return const Center(
                    child: Text(
                      'No materials found. Be the first to upload!',
                      style: TextStyle(color: Colors.white38, fontSize: 15),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Added bottom padding to not hide under FAB
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final item = materials[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        width: double.infinity,
                        borderRadius: 16,
                        borderColor: Colors.white10,
                        opacity: 0.03,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            _getFileIcon(item.fileName),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Gorgeous Translucent Micro-Badges
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (item.courseCode != null && item.courseCode!.isNotEmpty)
                                        _buildBadge(item.courseCode!, Colors.cyanAccent),
                                      if (item.facultyInitial != null && item.facultyInitial!.isNotEmpty)
                                        _buildBadge(item.facultyInitial!, Colors.purpleAccent),
                                      _buildBadge(item.fileType ?? 'Other', Colors.amberAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 12, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Uploaded by: ${item.uploaderName ?? 'Anonymous'} • ${_formatDate(item.createdAt)}',
                                          style: const TextStyle(fontSize: 10, color: Colors.white38),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Circular glowing glassmorphic download button
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.download_rounded, color: Colors.cyanAccent, size: 20),
                                onPressed: () async {
                                  final url = Uri.parse('https://drive.google.com/file/d/${item.driveFileId}/view?usp=drivesdk');
                                  try {
                                    // Use platformDefault mode (which opens Chrome Custom Tabs/In-App overlay)
                                    // instead of externalApplication, as BlueStacks' proprietary advertising system
                                    // server crashes with an NPE on activity pauses during external app switches.
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.platformDefault,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to open document: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
