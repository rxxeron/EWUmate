import re

with open('lib/features/schedule/presentation/schedule_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _computeEndTime signature and body
content = re.sub(
    r'  String _computeEndTime\(TimeOfDay start, bool isLab\) \{\n    final durationMinutes = isLab \? 180 : 90;',
    r'''  String _computeEndTime(TimeOfDay start, String sessionType) {
    final durationMinutes = (sessionType == 'Lab' || sessionType == 'Theory (MBA)') ? 180 : 90;''',
    content
)

# 2. Inside _showAddClassModal, replace bool isLab
content = content.replace(
    'bool isLab = sessionType == \'Lab\';',
    'String currentSessionType = sessionType ?? \'Theory\';'
)

# 3. Replace the Row -> Expanded -> GestureDetector block with the new layout
old_row_block = """                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              isLab = false;
                              if (selectedStartTime != null) {
                                computedEndStr = _computeEndTime(selectedStartTime!, false);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLab ? Colors.cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: !isLab ? Colors.cyanAccent : Colors.white24),
                            ),
                            child: Center(child: Text('Theory (90 min)', style: TextStyle(
                              color: !isLab ? Colors.cyanAccent : Colors.white54,
                              fontWeight: FontWeight.bold, fontSize: 13,
                            ))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              isLab = true;
                              if (selectedStartTime != null) {
                                computedEndStr = _computeEndTime(selectedStartTime!, true);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLab ? Colors.orangeAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isLab ? Colors.orangeAccent : Colors.white24),
                            ),
                            child: Center(child: Text('Lab (3 hrs)', style: TextStyle(
                              color: isLab ? Colors.orangeAccent : Colors.white54,
                              fontWeight: FontWeight.bold, fontSize: 13,
                            ))),
                          ),
                        ),
                      ),
                    ],
                  ),"""

new_row_block = """                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSessionTypeBtn(
                          label: 'Theory (90 min)',
                          isSelected: currentSessionType == 'Theory',
                          activeColor: Colors.cyanAccent,
                          onTap: () {
                            setModalState(() {
                              currentSessionType = 'Theory';
                              if (selectedStartTime != null) computedEndStr = _computeEndTime(selectedStartTime!, currentSessionType);
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildSessionTypeBtn(
                          label: 'Lab (3 hrs)',
                          isSelected: currentSessionType == 'Lab',
                          activeColor: Colors.orangeAccent,
                          onTap: () {
                            setModalState(() {
                              currentSessionType = 'Lab';
                              if (selectedStartTime != null) computedEndStr = _computeEndTime(selectedStartTime!, currentSessionType);
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildSessionTypeBtn(
                          label: 'Theory (MBA) - 3 hr',
                          isSelected: currentSessionType == 'Theory (MBA)',
                          activeColor: Colors.purpleAccent,
                          onTap: () {
                            setModalState(() {
                              currentSessionType = 'Theory (MBA)';
                              if (selectedStartTime != null) computedEndStr = _computeEndTime(selectedStartTime!, currentSessionType);
                            });
                          },
                        ),
                      ],
                    ),
                  ),"""

content = content.replace(old_row_block, new_row_block)

# 4. Replace other isLab calls inside that modal
content = content.replace(
    'computedEndStr = _computeEndTime(picked, isLab);',
    'computedEndStr = _computeEndTime(picked, currentSessionType);'
)

# 5. Fix End Time view logic
old_end_time_block = """                      decoration: BoxDecoration(
                        color: (isLab ? Colors.orangeAccent : Colors.cyanAccent).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (isLab ? Colors.orangeAccent : Colors.cyanAccent).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: isLab ? Colors.orangeAccent : Colors.cyanAccent, size: 20),
                          const SizedBox(width: 10),
                          Text('End: $computedEndStr', style: TextStyle(color: isLab ? Colors.orangeAccent : Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(isLab ? '3 hrs' : '90 min', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),"""

new_end_time_block = """                      decoration: BoxDecoration(
                        color: (currentSessionType == 'Lab' ? Colors.orangeAccent : (currentSessionType == 'Theory (MBA)' ? Colors.purpleAccent : Colors.cyanAccent)).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (currentSessionType == 'Lab' ? Colors.orangeAccent : (currentSessionType == 'Theory (MBA)' ? Colors.purpleAccent : Colors.cyanAccent)).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: currentSessionType == 'Lab' ? Colors.orangeAccent : (currentSessionType == 'Theory (MBA)' ? Colors.purpleAccent : Colors.cyanAccent), size: 20),
                          const SizedBox(width: 10),
                          Text('End: $computedEndStr', style: TextStyle(color: currentSessionType == 'Lab' ? Colors.orangeAccent : (currentSessionType == 'Theory (MBA)' ? Colors.purpleAccent : Colors.cyanAccent), fontSize: 15, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text((currentSessionType == 'Lab' || currentSessionType == 'Theory (MBA)') ? '3 hrs' : '90 min', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),"""

content = content.replace(old_end_time_block, new_end_time_block)

# 6. Inject the _buildSessionTypeBtn helper above _showAddClassModal
helper_fn = """  Widget _buildSessionTypeBtn({required String label, required bool isSelected, required Color activeColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.white24),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: isSelected ? activeColor : Colors.white54,
          fontWeight: FontWeight.bold, fontSize: 13,
        ))),
      ),
    );
  }

"""

if helper_fn not in content:
    content = content.replace('  void _showAddClassModal(String semesterCode, {', helper_fn + '  void _showAddClassModal(String semesterCode, {')

with open('lib/features/schedule/presentation/schedule_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
