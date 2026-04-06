with open(r'D:\EWUmate\EWUmate_Clean\ewumate_v2\lib\features\course_browser\presentation\widgets\course_card.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
'''  Widget _buildActionButton({
    required bool isThisEnrolled,
    required bool hasAnyInThisCourse,
    required String? enrolledSectionId,
    required String thisSectionId,
    required String academicSemCode,
  }) {''',
'''  Widget _buildActionButton({
    required bool isThisEnrolled,
    required bool hasAnyInThisCourse,
    required String? enrolledSectionId,
    required String thisSectionId,
    required String thisSectionNumber,
    required String academicSemCode,
  }) {'''
)

text = text.replace(
'''      return ElevatedButton(
        onPressed: _isUpdating ? null : () => _handleEnrollmentAction(
          action: action,
          sectionId: thisSectionId,
          oldSectionId: enrolledSectionId,
          academicSemCode: academicSemCode,
        ),''',
'''      return ElevatedButton(
        onPressed: _isUpdating ? null : () => _handleEnrollmentAction(
          action: action,
          sectionId: thisSectionId,
          sectionNumber: thisSectionNumber,
          oldSectionId: enrolledSectionId,
          academicSemCode: academicSemCode,
        ),'''
)

with open(r'D:\EWUmate\EWUmate_Clean\ewumate_v2\lib\features\course_browser\presentation\widgets\course_card.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("patched course_card.dart")
