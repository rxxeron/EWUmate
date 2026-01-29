class AcademicEvent {
  final String date;
  final String title;

  AcademicEvent({required this.date, required this.title});

  factory AcademicEvent.fromMap(Map<String, dynamic> map) {
    return AcademicEvent(
      date: map['date'] ?? '',
      title: map['event'] ??
          map['title'] ??
          'Event', // Legacy uses 'event', new might use 'title'
    );
  }

  // Helper to parse date string "14 January 2026" to DateTime
  DateTime? get dateTime {
    try {
      // Basic parsing logic. Improve with intl if needed.
      // Assuming "DD Month YYYY" format from legacy OCR
      // Flutter's Uri.parse doesn't do dates... using custom logic or intl
      // Let's rely on simple string compare or passing to DateFormat in UI for now
      // ideally we parse this in the model
      return null;
    } catch (e) {
      return null;
    }
  }
}
