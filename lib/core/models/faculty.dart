class Faculty {
  final String id;
  final String shortName;
  final String fullName;
  final String? designation;
  final String? email;
  final String? photoUrl;
  final String? profileUrl;
  final String? officeRoom;

  Faculty({
    required this.id,
    required this.shortName,
    required this.fullName,
    this.designation,
    this.email,
    this.photoUrl,
    this.profileUrl,
    this.officeRoom,
  });

  factory Faculty.fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['id'] ?? '',
      shortName: map['short_name'] ?? '',
      fullName: map['full_name'] ?? '',
      designation: map['designation_name'],
      email: map['email'],
      photoUrl: map['photo_url'],
      profileUrl: map['profile_url'],
      officeRoom: map['office_room'],
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
    };
  }
}
