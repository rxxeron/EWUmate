with open(r'd:\EWUmate\EWUmate_Clean\ewumate_v2\lib\features\onboarding\onboarding_repository.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
'''        for (final detail in enrolledCourseDetails) {
          enrollmentRows.add({
            'user_id': user.id,
            'course_code': detail['code'],
            'section_id': detail['id'],
            'semester_code': runningSemester,
            'status': 'enrolled',
          });
        }''',
'''        for (final detail in enrolledCourseDetails) {
          enrollmentRows.add({
            'user_id': user.id,
            'course_code': detail['code'],
            'section_id': detail['id'],
            if (detail['section'] != null && detail['section'].toString().isNotEmpty)
              'section': detail['section'],
            'semester_code': runningSemester,
            'status': 'enrolled',
          });
        }'''
)

with open(r'd:\EWUmate\EWUmate_Clean\ewumate_v2\lib\features\onboarding\onboarding_repository.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("patched onboarding_repository.dart")
