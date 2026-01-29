import 'package:flutter/material.dart';
import 'results_repository.dart';
import '../../core/widgets/glass_kit.dart';

class CourseHistoryEditor extends StatefulWidget {
  const CourseHistoryEditor({super.key});

  @override
  State<CourseHistoryEditor> createState() => _CourseHistoryEditorState();
}

class _CourseHistoryEditorState extends State<CourseHistoryEditor> {
  final ResultsRepository _repo = ResultsRepository();
  bool _loading = true;
  Map<String, dynamic> _history = {};
  List<String> _availableCourses = [];

  // Grade Options
  final List<String> _grades = [
    "A+",
    "A",
    "A-",
    "B+",
    "B",
    "B-",
    "C+",
    "C",
    "C-",
    "D+",
    "D",
    "F",
    "W",
    "I",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repo.fetchRawCourseHistory();
    // Use the newly added method to fetch suggestions
    List<String> codes = [];
    try {
      codes = await _repo.fetchCourseCodes();
    } catch (e) {
      debugPrint("Failed to load course list: $e");
    }

    if (mounted) {
      setState(() {
        _history = Map<String, dynamic>.from(data);
        _availableCourses = codes;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _repo.updateCourseHistory(_history);
      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved! Calculating stats...")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _addSemester() {
    String selectedSeason = "Spring";
    int selectedYear = DateTime.now().year;
    final List<String> seasons = ["Spring", "Summer", "Fall"];
    final List<int> years = List.generate(
      10,
      (index) => DateTime.now().year - 5 + index,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Semester"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSeason,
                    items: seasons
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSeason = val);
                      }
                    },
                    decoration: const InputDecoration(labelText: "Season"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    items: years
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text("$y")),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedYear = val);
                      }
                    },
                    decoration: const InputDecoration(labelText: "Year"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = "$selectedSeason $selectedYear";
                    // Prevent duplicates or just jump to it?
                    if (!_history.containsKey(name)) {
                      setState(() {
                        _history[name] = <String, dynamic>{};
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Unified Add/Edit Dialog
  void _openCourseDialog(
    String semester, {
    String? existingCode,
    String? existingGrade,
  }) {
    String selectedGrade = existingGrade ?? "A+";
    String courseCode = existingCode ?? "";
    final isEdit = existingCode != null;
    final TextEditingController searchCtrl = TextEditingController(
      text: courseCode,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Course" : "Add Course to $semester"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdit)
                    Text(
                      courseCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  else
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue val) {
                        if (val.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _availableCourses.where(
                          (c) => c.contains(val.text.toUpperCase()),
                        );
                      },
                      onSelected: (val) {
                        courseCode = val;
                        searchCtrl.text = val; // Reflect selection
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        // Sync initial
                        if (controller.text.isEmpty && courseCode.isNotEmpty) {
                          controller.text = courseCode;
                        }

                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (val) => courseCode = val.toUpperCase(),
                          decoration: const InputDecoration(
                            labelText: "Course Code (e.g. CSE101)",
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGrade,
                    items: _grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedGrade = val);
                      }
                    },
                    decoration: const InputDecoration(labelText: "Grade"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (courseCode.isNotEmpty) {
                      setState(() {
                        // Ensure map exists
                        if (_history[semester] is! Map) {
                          _history[semester] = <String, dynamic>{};
                        }
                        // Update or Add
                        _history[semester][courseCode] = selectedGrade;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSemester(String semester) {
    setState(() {
      _history.remove(semester);
    });
  }

  void _removeCourse(String semester, String code) {
    setState(() {
      if (_history[semester] is Map) {
        _history[semester].remove(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullGradientScaffold(
      appBar: AppBar(
        title: const Text("Edit Course History"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Semesters
                ..._history.keys.map((sem) => _buildSemesterTile(sem)),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Semester"),
                  onPressed: _addSemester,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSemesterTile(String sem) {
    final coursesMap = _history[sem] as Map<dynamic, dynamic>? ?? {};

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(
          sem,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white54),
          onPressed: () => _deleteSemester(sem),
        ),
        children: [
          ...coursesMap.entries.map((e) {
            return ListTile(
              title: Text(
                e.key.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => _openCourseDialog(
                sem,
                existingCode: e.key.toString(),
                existingGrade: e.value.toString(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value.toString(),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white30,
                      size: 18,
                    ),
                    onPressed: () => _removeCourse(sem, e.key.toString()),
                  ),
                ],
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.white70),
            title: const Text(
              "Add Course",
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => _openCourseDialog(sem),
          ),
        ],
      ),
    );
  }
}
