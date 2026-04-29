import json

with open('lib/features/onboarding/course_history_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

start_idx = text.find('  Widget _buildCourseList() {')
end_idx = text.find('  Widget _buildSyncOverlay() {')

new_block = """  Widget _buildCourseList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    if (_catalog.isEmpty) return const Center(child: Text("No courses found.", style: TextStyle(color: Colors.white38)));

    if (!_isCurrentSemester) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _catalog.length,
        itemBuilder: (ctx, i) {
          final c = _catalog[i];
          final code = c['code'] as String;
          final isSelected = (_history[_currentSemester] ?? {}).containsKey(code);

          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(code, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              subtitle: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white70)),
              trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? Colors.greenAccent : Colors.white38),
              onTap: () => _addCourse(c),
            ),
          );
        },
      );
    } else {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var c in _catalog) {
        grouped.putIfAbsent(c['code'], () => []).add(c);
      }
      final sortedKeys = grouped.keys.toList()..sort();

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedKeys.length,
        itemBuilder: (ctx, i) {
          final code = sortedKeys[i];
          final sections = grouped[code]!;
          final name = sections.first['name'] ?? '';

          int selectedCount = 0;
          for (var c in sections) {
            final section = (c['section'] ?? '').toString();
            final selectionKey = code + "_Sec" + section;
            if ((_history[_currentSemester] ?? {}).containsKey(selectionKey)) {
              selectedCount++;
            }
          }

          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: selectedCount > 0 ? Colors.cyanAccent.withOpacity(0.5) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(code, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                subtitle: Text(name, style: const TextStyle(color: Colors.white70)),
                trailing: selectedCount > 0 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                      child: const Text("Enrolled", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  : const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
                children: sections.map((c) {
                  final section = (c['section'] ?? '').toString();
                  final selectionKey = code + "_Sec" + section;
                  final isSelected = (_history[_currentSemester] ?? {}).containsKey(selectionKey);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text("Section " + section, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? Colors.greenAccent : Colors.white38),
                      onTap: () => _addCourse(c),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }
  }

"""

text = text[:start_idx] + new_block + text[end_idx:]

with open('lib/features/onboarding/course_history_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done grouping!")
