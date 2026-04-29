import json

with open('lib/features/onboarding/course_history_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('  void _addCourse(Map<String, dynamic> course) async {')
end = text.find('  Future<String?> _showGradeDialog(')

new_add_course = """  void _addCourse(Map<String, dynamic> course) async {
    if (_currentSemester == null) return;
    final code = course['code'] as String;
    final sectionRaw = (course['section'] ?? '').toString();
    final selectionKey = _isCurrentSemester ? "${code}_Sec$sectionRaw" : code;

    // Check if the course is already taken in another semester within onboarding
    for (final sem in _history.keys) {
      if (sem == _currentSemester) continue;
      final semCourses = _history[sem]!;
      for (final prevKey in semCourses.keys) {
        final baseCode = prevKey.contains('_Sec') ? prevKey.split('_Sec').first : prevKey;
        if (baseCode == code) {
          final existingGrade = semCourses[prevKey];
          // If already passed, warn/prevent taking it again in another semester
          if (existingGrade != 'F' && existingGrade != 'W' && existingGrade != 'I' && existingGrade != 'R') {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text("You already passed $code in $sem with grade: $existingGrade."),
                 backgroundColor: Colors.orangeAccent,
               ));
             }
             return;
          }
        }
      }
    }

    final currentMap = _history[_currentSemester!] ?? {};

    if (currentMap.containsKey(selectionKey)) {
      setState(() {
        currentMap.remove(selectionKey);
        _selectedSectionIds.remove(selectionKey);
      });
      return;
    }

    String grade = "Ongoing";
    if (!_isCurrentSemester) {
      final g = await _showGradeDialog(code);
      if (g == null) return;
      grade = g;
    }

    setState(() {
      currentMap[selectionKey] = grade;
      _history[_currentSemester!] = currentMap;

      final List<String> ids = [];
      if (course.containsKey('allIds')) {
        ids.addAll(List<String>.from(course['allIds']));
      } else if (course.containsKey('id')) {
        ids.add(course['id']);
      }
      _selectedSectionIds[selectionKey] = ids;
    });
  }

"""

text = text[:start] + new_add_course + text[end:]

with open('lib/features/onboarding/course_history_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done validation!")
