import 'package:smart_canvas/features/auth/sign_in/models/role_model.dart';

class UserModel {
  final String id;
  final RoleModel? roleModel;
  final String? collegeId;
  final String? academicYearId;
  final String collegeName;
  final String roleName;
  final String fullName;
  final String? image;
  final DateTime? createdAt;
  final int? yearLevel;

  UserModel({
    required this.id,
    this.roleModel,
    this.collegeId,
    this.collegeName = '',
    this.roleName = '',
    this.academicYearId,
    required this.fullName,
    this.image,
    this.createdAt,
    this.yearLevel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleModel = json['role'] == null
          ? null
          : RoleModel.fromJson(json['role'] as Map<String, dynamic>);
          
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      roleModel: roleModel,
      roleName: json['role_name'] as String? ?? json['roles']?['name'] as String? ?? roleModel?.name ?? '',
      collegeId: json['college_id'] as String?,
      collegeName: json['college_name'] as String? ?? 
                   json['colleges']?['name'] as String? ?? 
                   json['college']?['name'] as String? ?? 
                   '',
      academicYearId: json['academic_year_id'] as String?,
      image: json['image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      yearLevel: json['year_level'] as int?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'role_id': roleModel?.id, // Use role ID for insertion, not full role object
    'role_name': roleName,
    'college_id': collegeId,
    'college_name': collegeName,
    'academic_year_id': academicYearId,
    'full_name': fullName,
    'image': image,
    'created_at': createdAt?.toIso8601String(),
    'year_level': yearLevel,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
