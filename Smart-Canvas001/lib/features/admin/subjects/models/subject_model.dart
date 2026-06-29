import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';

class SubjectModel {
  final String id;
  final String? code;
  final String name;
  final CollegeModel? college;
  final AcademicYearModel? academicYearModel;
  final DateTime? createdAt;

  SubjectModel({
    required this.id,
    this.college,
    this.academicYearModel,
    required this.name,
    this.code,
    this.createdAt,
  });

  /// from Supabase / API
  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Subject',
      code: json['code']?.toString() ?? json['subject_code']?.toString(),
      college: json['college'] != null
          ? CollegeModel.fromJson(json['college'] as Map<String, dynamic>)
          : (json['college_id'] != null 
              ? CollegeModel(
                  id: json['college_id']?.toString() ?? '',
                  name: json['college_name']?.toString() ?? '', // Use college_name from RPC
                  abbreviation: '',
                  image: '',
                  createdAt: DateTime.now(),
                )
              : null),
      academicYearModel: json['academic_year'] != null
          ? AcademicYearModel.fromJson(
              json['academic_year'] as Map<String, dynamic>,
            )
          : (json['academic_year_id'] != null 
              ? AcademicYearModel(
                  id: json['academic_year_id']?.toString() ?? '',
                  name: json['academic_year_name']?.toString() ?? 'Program', // Use academic_year_name from RPC
                  createdAt: DateTime.now(),
                )
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  /// to Supabase / API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'college': college?.toJson(),
      'academic_year': academicYearModel?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
