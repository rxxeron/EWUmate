import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/azure_functions_service.dart';
import '../../../core/repositories/schedule_repository.dart';
import '../../../core/repositories/auth_repository.dart';

part 'advising_notifier.g.dart';

class AdvisingState {
  final Set<String> selectedCourses;
  final String? generationId;
  final bool isGenerating;
  final String? error;

  AdvisingState({
    required this.selectedCourses,
    this.generationId,
    this.isGenerating = false,
    this.error,
  });

  AdvisingState copyWith({
    Set<String>? selectedCourses,
    String? generationId,
    bool? isGenerating,
    String? error,
  }) {
    return AdvisingState(
      selectedCourses: selectedCourses ?? this.selectedCourses,
      generationId: generationId ?? this.generationId,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error ?? this.error,
    );
  }
}

@riverpod
class AdvisingNotifier extends _$AdvisingNotifier {
  @override
  AdvisingState build() {
    return AdvisingState(selectedCourses: {});
  }

  void toggleCourse(String code) {
    final current = state.selectedCourses;
    final updated = Set<String>.from(current);
    if (updated.contains(code)) {
      updated.remove(code);
    } else {
      updated.add(code);
    }
    state = state.copyWith(selectedCourses: updated, error: null);
  }

  Future<void> startGeneration({
    required String userId,
    required String semester,
  }) async {
    if (state.selectedCourses.isEmpty) return;

    state = state.copyWith(isGenerating: true, error: null, generationId: null);

    try {
      final apiService = ref.read(azureFunctionsServiceProvider);
      // Clean 'Spring 2026' into 'Spring2026'
      final semesterClean = semester.replaceAll(' ', '');
      
      final genId = await apiService.generateSchedules(
        userId: userId,
        semester: semesterClean,
        courses: state.selectedCourses.toList(),
      );

      state = state.copyWith(
        isGenerating: false,
        generationId: genId,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveSchedule({
    required String semesterCode,
    required Map<String, dynamic> combination,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(scheduleRepositoryProvider).saveSchedule(
        userId: user.id,
        semesterCode: semesterCode,
        combinationData: combination,
      );
      
      // Refresh the saved schedules list if any provider is watching it
      // ref.invalidate(savedSchedulesProvider); 
    } catch (e) {
      state = state.copyWith(error: "Failed to save schedule: $e");
    }
  }

  void reset() {
    state = AdvisingState(selectedCourses: {});
  }
}
