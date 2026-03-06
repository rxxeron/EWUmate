class ScholarshipRule {
  final int id;
  final String program;
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
  final String level;

  ScholarshipRule({
    required this.id,
    required this.program,
    this.admittedFrom,
    this.admittedUpto,
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
      id: map['id'] as int? ?? 0,
      program: map['program'] as String? ?? '',
      admittedFrom: map['admitted_from'] as String?,
      admittedUpto: map['admitted_upto'] as String?,
      annualCreditsRequired: (map['annual_credits_required'] as num?)?.toDouble() ?? 30.0,
      degreeCreditsRequired: (map['degree_credits_required'] as num?)?.toDouble() ?? 130.0,
      tierMedhaLalonMin: (map['tier_medha_lalon_min'] as num?)?.toDouble() ?? 3.50,
      tierDeansListMin: (map['tier_deans_list_min'] as num?)?.toDouble() ?? 3.75,
      tierMerit100Min: (map['tier_merit_100_min'] as num?)?.toDouble() ?? 3.90,
      waiverMedhaLalon: (map['waiver_medha_lalon'] as num?)?.toDouble() ?? 25,
      waiverDeansList: (map['waiver_deans_list'] as num?)?.toDouble() ?? 50,
      waiverMerit100: (map['waiver_merit_100'] as num?)?.toDouble() ?? 100,
      level: map['level'] as String? ?? 'undergraduate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program': program,
      'admitted_from': admittedFrom,
      'admitted_upto': admittedUpto,
      'annual_credits_required': annualCreditsRequired,
      'degree_credits_required': degreeCreditsRequired,
      'tier_medha_lalon_min': tierMedhaLalonMin,
      'tier_deans_list_min': tierDeansListMin,
      'tier_merit_100_min': tierMerit100Min,
      'waiver_medha_lalon': waiverMedhaLalon,
      'waiver_deans_list': waiverDeansList,
      'waiver_merit_100': waiverMerit100,
      'level': level,
    };
  }

  @override
  String toString() =>
      'ScholarshipRule($program, from: $admittedFrom, annualCredits: $annualCreditsRequired, degreeCredits: $degreeCreditsRequired)';
}
