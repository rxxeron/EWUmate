import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import 'providers/study_vault_providers.dart';
import 'package:go_router/go_router.dart';
import 'widgets/paginated_search_bottom_sheet.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class StudyVaultScreen extends ConsumerStatefulWidget {
  const StudyVaultScreen({super.key});

  @override
  ConsumerState<StudyVaultScreen> createState() => _StudyVaultScreenState();
}

class _StudyVaultScreenState extends ConsumerState<StudyVaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.studyVaultKey,
          steps: OnboardingSteps.studyVault,
        );
      }
    });
  }

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

  Widget _buildFileTypeBadge(String fileName, {String? fileType}) {
    final ext = fileName.split('.').last.toLowerCase();
    Color bgColor;
    Color textColor;
    String badgeText;
    IconData icon;

    if (ext == 'pdf' || (fileType?.toLowerCase().contains('pdf') ?? false)) {
      bgColor = const Color(0xFFEF4444);
      textColor = Colors.white;
      badgeText = 'PDF';
      icon = Icons.picture_as_pdf_rounded;
    } else if (['xlsx', 'xls', 'csv'].contains(ext) || (fileType?.toLowerCase().contains('excel') ?? false)) {
      bgColor = const Color(0xFF10B981);
      textColor = Colors.white;
      badgeText = 'XLS';
      icon = Icons.table_chart_rounded;
    } else if (['doc', 'docx'].contains(ext) || (fileType?.toLowerCase().contains('doc') ?? false)) {
      bgColor = const Color(0xFF3B82F6);
      textColor = Colors.white;
      badgeText = 'DOC';
      icon = Icons.description_rounded;
    } else if (['ppt', 'pptx'].contains(ext) || (fileType?.toLowerCase().contains('slide') ?? false)) {
      bgColor = const Color(0xFFF97316);
      textColor = Colors.white;
      badgeText = 'PPT';
      icon = Icons.slideshow_rounded;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      bgColor = const Color(0xFF8B5CF6);
      textColor = Colors.white;
      badgeText = 'IMG';
      icon = Icons.image_rounded;
    } else {
      bgColor = const Color(0xFF06B6D4);
      textColor = Colors.white;
      badgeText = 'NOTE';
      icon = Icons.article_rounded;
    }

    return Container(
      width: 46,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: bgColor),
          const SizedBox(height: 2),
          Text(
            badgeText,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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
      activeColor = const Color(0xFFC084FC);
      icon = Icons.badge_rounded;
    } else if (filterKey == 'courseCode') {
      activeColor = const Color(0xFF19D9F5);
      icon = Icons.menu_book_rounded;
    } else if (filterKey == 'semester') {
      activeColor = const Color(0xFF2DD4BF);
      icon = Icons.calendar_today_rounded;
    } else {
      activeColor = const Color(0xFFFBBF24);
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Icon(
                Icons.close_rounded,
                size: 14,
                color: activeColor,
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isActive ? displayValue : label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: Color(0xFF64748B),
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
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF19D9F5).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0x3319D9F5),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF19D9F5), size: 18),
            ),
            tooltip: 'My Uploaded Materials',
            onPressed: () {
              context.push('/services/study-vault/my-uploads');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
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
                      hintText: 'Search course code, faculty, or title...',
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
                                _onSearchChanged('');
                                setState(() {});
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
                      _onSearchChanged(val);
                      setState(() {});
                    },
                  ),
                ),
              ),

              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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

              // List of Study Materials
              Expanded(
                child: materialsAsync.when(
                  data: (materials) {
                    if (materials.isEmpty) {
                      return const Center(
                        child: Text(
                          'No materials found. Be the first to upload!',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        final item = materials[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0A192F),
                                  Color(0xFF0D2342),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x2219D9F5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildFileTypeBadge(item.fileName, fileType: item.fileType),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.fileName,
                                          style: const TextStyle(
                                            fontFamily: 'Sora',
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontSize: 13.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (item.courseCode != null && item.courseCode!.isNotEmpty)
                                              _buildBadge(item.courseCode!, const Color(0xFF19D9F5)),
                                            if (item.facultyInitial != null && item.facultyInitial!.isNotEmpty)
                                              _buildBadge(item.facultyInitial!, const Color(0xFFC084FC)),
                                            _buildBadge(item.fileType ?? 'Other', const Color(0xFFFBBF24)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'By: ${item.uploaderName ?? 'Student'} • ${_formatDate(item.createdAt)}',
                                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Circular glowing glassmorphic download button
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF19D9F5).withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: const Color(0xFF19D9F5).withValues(alpha: 0.3),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF19D9F5).withValues(alpha: 0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.download_rounded, color: Color(0xFF19D9F5), size: 20),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final url = Uri.parse('https://drive.google.com/file/d/${item.driveFileId}/view?usp=drivesdk');
                                        try {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to open document: $e'),
                                                backgroundColor: const Color(0xFFEF4444),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                      Icons.cloud_upload_rounded,
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
        ],
      ),
    );
  }
}
