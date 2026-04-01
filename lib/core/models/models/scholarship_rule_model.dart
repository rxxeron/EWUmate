class ScholarshipRule {
  final int id;
  final String programId;
  final String programName;
  final String? admittedFrom;
  final String? admittedUpto;
  final double annualCreditsRequired;
  final double degreeCreditsRequired;
  final double tierMedhaLalonMin;
  final double tierDeansListMin;
  final double tierMerit100Min;
  final double waiverMedhaLalon;
  final double waiverDeansList;
  final double waiverMerit100;
  final String? effectiveFrom;
  final String? effectiveUntil;
  final String level;

  ScholarshipRule({
    required this.id,
    required this.programId,
    required this.programName,
    this.admittedFrom,
    this.admittedUpto,
    this.effectiveFrom,
    this.effectiveUntil,
    required this.annualCreditsRequired,
    required this.degreeCreditsRequired,
    this.tierMedhaLalonMin = 3.50,
    this.tierDeansListMin = 3.75,
    this.tierMerit100Min = 3.90,
    this.waiverMedhaLalon = 25,
    this.waiverDeansList = 50,
    this.waiverMerit100 = 100,
    this.level = 'undergraduate',
  });

  factory ScholarshipRule.fromMap(Map<String, dynamic> map) {
    return ScholarshipRule(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      programId: (map['department_code'] ?? map['program_id'] ?? '').toString(),
      programName: (map['program_name'] ?? map['department_code'] ?? '').toString(),
      admittedFrom: map['admitted_from'] as String?,
      admittedUpto: map['admitted_upto'] as String?,
      effectiveFrom: map['effective_from_semester'] as String?,
      effectiveUntil: map['effective_until_semester'] as String?,
      annualCreditsRequired: double.tryParse(map['min_yearly_credits']?.toString() ?? '') ?? 30.0,
      degreeCreditsRequired: double.tryParse(map['degree_credits_required']?.toString() ?? '') ?? 130.0,
      tierMedhaLalonMin: double.tryParse(map['medha_cgpa_min']?.toString() ?? '') ?? 3.50,
      tierDeansListMin: double.tryParse(map['deans_cgpa_min']?.toString() ?? '') ?? 3.75,
      tierMerit100Min: double.tryParse(map['merit_cgpa_min']?.toString() ?? '') ?? 3.90,
      // Default waivers as they aren't explicit in the observed schema columns
      waiverMedhaLalon: double.tryParse(map['merit_waiver']?.toString() ?? '') ?? 25,
      waiverDeansList: double.tryParse(map['deans_waiver']?.toString() ?? '') ?? 50,
      waiverMerit100: double.tryParse(map['full_waiver']?.toString() ?? '') ?? 100,
      level: map['level'] as String? ?? 'undergraduate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_code': programId,
      'program_name': programName,
      'admitted_from': admittedFrom,
      'admitted_upto': admittedUpto,
      'effective_from_semester': effectiveFrom,
      'effective_until_semester': effectiveUntil,
      'min_yearly_credits': annualCreditsRequired,
      'degree_credits_required': degreeCreditsRequired,
      'medha_cgpa_min': tierMedhaLalonMin,
      'deans_cgpa_min': tierDeansListMin,
      'merit_cgpa_min': tierMerit100Min,
      'merit_waiver': waiverMedhaLalon,
      'deans_waiver': waiverDeansList,
      'full_waiver': waiverMerit100,
    };
  }

  @override
  String toString() =>
      'ScholarshipRule($programName, from: $admittedFrom, annualCredits: $annualCreditsRequired, degreeCredits: $degreeCreditsRequired)';
}
