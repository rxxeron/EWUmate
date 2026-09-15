import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/faculty_providers.dart';
import 'widgets/faculty_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/animations/skeleton_loader.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/primitives/ewu_empty_state.dart';

class FacultyDirectoryScreen extends ConsumerStatefulWidget {
  const FacultyDirectoryScreen({super.key});

  @override
  ConsumerState<FacultyDirectoryScreen> createState() => _FacultyDirectoryScreenState();
}

class _FacultyDirectoryScreenState extends ConsumerState<FacultyDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  final List<String> _departments = const [
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
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;
    final facultyAsync = ref.watch(facultyDirectoryProvider);
    final selectedDept = ref.watch(facultyDepartmentFilterProvider);
    final hasSearchText = _searchController.text.isNotEmpty;

    return FullGradientScaffold(
      appBar: const EWUmateAppBar(
        title: 'Faculty Directory',
        showBack: true,
      ),
      body: Column(
        children: [
          // 1. Search Bar with Cyan Focus Glow
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 10.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: colors.surfaceNavyBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_isSearchFocused || hasSearchText)
                      ? AppColors.primaryCyan.withValues(alpha: 0.8)
                      : colors.borderSubtle,
                  width: (_isSearchFocused || hasSearchText) ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (_isSearchFocused || hasSearchText)
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.16),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) {
                  ref.read(facultySearchQueryProvider.notifier).state = val;
                  setState(() {});
                },
                style: GoogleFonts.sora(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name, initials, or email...',
                  hintStyle: GoogleFonts.sora(
                    color: colors.textTertiary,
                    fontSize: 13,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(
                      Icons.search_rounded,
                      color: (_isSearchFocused || hasSearchText)
                          ? AppColors.primaryCyan
                          : colors.textTertiary,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 22),
                  suffixIcon: hasSearchText
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryCyan.withValues(alpha: 0.20),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.primaryCyan,
                              size: 14,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            ref.read(facultySearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // 2. Horizontal Department Filter Bar
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _departments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final isSelected = selectedDept == dept;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(facultyDepartmentFilterProvider.notifier).state = dept;
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryCyan
                          : colors.surfaceNavyBlue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryCyan
                            : colors.borderSubtle,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dept,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryNavy
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // 3. Faculty List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryCyan,
              backgroundColor: AppColors.surfaceNavyBlue,
              onRefresh: () async {
                ref.invalidate(facultyDirectoryProvider);
              },
              child: facultyAsync.when(
                data: (facultyList) {
                  if (facultyList.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80.0),
                        child: Center(
                          child: EwuEmptyState(
                            icon: Icons.person_search_rounded,
                            title: 'No Faculty Found',
                            subtitle: hasSearchText
                                ? 'No results matching "${_searchController.text}". Try another query or switch departments.'
                                : 'No faculty profiles currently found in department "$selectedDept".',
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: facultyList.length,
                    itemBuilder: (context, index) => FacultyCard(
                      faculty: facultyList[index],
                    ),
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: 6,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(
                      width: double.infinity,
                      height: 88,
                      borderRadius: 20,
                    ),
                  ),
                ),
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          AuthErrorUtils.getFriendlyMessage(err),
                          style: GoogleFonts.sora(color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(facultyDirectoryProvider),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryCyan),
                          label: Text(
                            'Retry',
                            style: GoogleFonts.sora(
                              color: AppColors.primaryCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
