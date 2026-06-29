class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String roleId;
  final String? roleName;
  final String? image;
  final String? collegeId;
  final String? collegeName;
  final String? academicYearId;
  final String? academicYearName;
  final int? currentYear;
  final String? universityId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.roleId,
    this.roleName,
    this.image,
    this.collegeId,
    this.collegeName,
    this.academicYearId,
    this.academicYearName,
    this.currentYear,
    this.universityId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      roleId: json['role_id'] ?? '',
      roleName: json['roles']?['name'],
      image: json['image'],
      collegeId: json['college_id'],
      collegeName: json['colleges']?['name'],
      academicYearId: json['academic_year_id'],
      academicYearName: json['academic_years']?['name'],
      currentYear: json['current_year'],
      universityId: json['university_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role_id': roleId,
      'image': image,
      'college_id': collegeId,
      'academic_year_id': academicYearId,
      'current_year': currentYear,
      'university_id': universityId,
    };
  }
}
