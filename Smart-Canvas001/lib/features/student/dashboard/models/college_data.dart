import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class CollegeData {
  final College college;
  final AcademicYear academicYear;
  final List<SubjectModel> subjects;

  CollegeData({
    required this.college,
    required this.academicYear,
    required this.subjects,
  });

  factory CollegeData.fromJson(Map<String, dynamic> json) {
    final subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    return CollegeData(
      college: College.fromJson(json['college']),
      academicYear: AcademicYear.fromJson(json['academic_year']),
      subjects: subjectsJson.map((e) => SubjectModel.fromJson(e)).toList(),
    );
  }
}

class College {
  final String id;
  final String name;
  final String? abbreviation;
  final String? image;

  College({
    required this.id,
    required this.name,
    this.abbreviation,
    this.image,
  });

  factory College.fromJson(Map<String, dynamic> json) => College(
        id: json['id'],
        name: json['name'],
        abbreviation: json['abbreviation'],
        image: json['image'],
      );
}

class AcademicYear {
  final String id;
  final String name;

  AcademicYear({
    required this.id,
    required this.name,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
        id: json['id'],
        name: json['name'],
      );
}

