class Faculty {
  final String id;
  final String shortName;
  final String fullName;
  final String? designation;
  final String? email;
  final String? photoUrl;
  final String? profileUrl;
  final String? officeRoom;
  final String? departmentName;

  Faculty({
    required this.id,
    required this.shortName,
    required this.fullName,
    this.designation,
    this.email,
    this.photoUrl,
    this.profileUrl,
    this.officeRoom,
    this.departmentName,
  });

  factory Faculty.fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['id']?.toString() ?? '',
      shortName: map['short_name'] ?? '',
      fullName: map['full_name'] ?? '',
      designation: map['designation_name'] ?? map['designation'],
      email: map['email'],
      photoUrl: map['photo_url'],
      profileUrl: map['profile_url'],
      officeRoom: map['office_room'],
      departmentName: map['department'] ?? map['department_name'] ?? map['dept_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'short_name': shortName,
      'full_name': fullName,
      'designation_name': designation,
      'email': email,
      'photo_url': photoUrl,
      'profile_url': profileUrl,
      'office_room': officeRoom,
      'department': departmentName,
    };
  }

  /// Extracts clean 2-letter uppercase initials for visual avatar badge
  String get avatarInitials {
    // If shortName is 2 uppercase letters:
    if (shortName.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(shortName)) {
      return shortName;
    }
    // If shortName is 3 letters (e.g. UFS): take first and last -> US
    if (shortName.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(shortName)) {
      return '${shortName[0]}${shortName[2]}';
    }

    final allTokens = fullName
        .replaceAll(RegExp(r'\b(Dr\.|Prof\.|Professor|Mr\.|Ms\.|Mrs\.|Engr\.)\b', caseSensitive: false), '')
        .split(RegExp(r'[\s.]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (allTokens.length >= 2) {
      return '${allTokens.first[0]}${allTokens.last[0]}'.toUpperCase();
    } else if (allTokens.isNotEmpty) {
      final token = allTokens.first;
      return token.substring(0, token.length >= 2 ? 2 : 1).toUpperCase();
    }

    if (shortName.length >= 2) {
      return shortName.substring(0, 2).toUpperCase();
    }
    return shortName.isEmpty ? 'FA' : shortName.toUpperCase();
  }

  /// Determines department code (e.g. CSE, EEE, BUS, ENG, etc.)
  String get department {
    if (departmentName != null && departmentName!.isNotEmpty) {
      return departmentName!;
    }
    final des = (designation ?? '').toLowerCase();
    final em = (email ?? '').toLowerCase();

    if (des.contains('cse') || des.contains('computer science') || em.contains('cse') || em.contains('cs.')) return 'CSE';
    if (des.contains('eee') || des.contains('electrical') || des.contains('electronic') || em.contains('eee')) return 'EEE';
    if (des.contains('bba') || des.contains('business') || des.contains('management') || des.contains('marketing') || des.contains('accounting') || des.contains('finance') || des.contains('economics') || des.contains('eco') || em.contains('bus') || em.contains('bba') || em.contains('eco')) return 'BUS';
    if (des.contains('eng') || des.contains('english') || em.contains('eng') || em.contains('english')) return 'ENG';
    if (des.contains('phr') || des.contains('pharmacy') || em.contains('phr') || em.contains('pharm')) return 'PHR';
    if (des.contains('law') || em.contains('law')) return 'LAW';
    if (des.contains('math') || des.contains('physics') || des.contains('mps') || em.contains('math') || em.contains('mps')) return 'MATH';
    if (des.contains('sociology') || des.contains('soc') || em.contains('soc')) return 'SOC';

    return 'CSE';
  }
}
