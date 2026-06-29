import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class CollegeModel {
  final String id;
  final String name;
  final String abbreviation;
  final String image;
  final List<AcademicYearModel>? academicYears;
  final List<SubjectModel>? subjects;
  final DateTime createdAt;
  final List<String>? rawAcademicYearIds; // Added to support Array-based join
  final int? durationYears;
  final int? internshipYears;

  CollegeModel({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.image,
    this.academicYears,
    required this.createdAt,
    this.subjects,
    this.rawAcademicYearIds,
    this.durationYears,
    this.internshipYears,
  });

  factory CollegeModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract IDs if the list is just strings
    List<String>? parseRawIds(dynamic data) {
      if (data == null) return null;
      if (data is List) {
        if (data.isEmpty) return [];
        if (data.first is String) {
          return List<String>.from(data);
        }
      }
      return null;
    }

    // Helper to safely parse List<AcademicYearModel>
    List<AcademicYearModel>? parseAcademicYears(dynamic data) {
      if (data == null) return null;
      if (data is List) {
        if (data.isEmpty) return [];
        // Only parse if the items are Maps (objects)
        if (data.first is Map) {
          return List.from(data.map((e) => AcademicYearModel.fromJson(e)));
        }
      }
      return null; 
    }

    // Helper to safely parse List<SubjectModel>
    List<SubjectModel>? parseSubjects(dynamic data) {
       if (data == null) return null;
      if (data is List) {
         if (data.isEmpty) return [];
        if (data.first is Map) {
          return List.from(data.map((e) => SubjectModel.fromJson(e)));
        }
      }
      return null;
    }

    return CollegeModel(
      id: json['id'],
      name: json['name'],
      abbreviation: json['abbreviation'],
      image: json['image'],
      academicYears: parseAcademicYears(json['academic_years']),
      rawAcademicYearIds: parseRawIds(json['academic_years_ids']), // Use specific IDs field from RPC if available, or fallback
      subjects: parseSubjects(json['subjects']),
      createdAt: DateTime.parse(json['created_at']),
      durationYears: json['duration_years'] != null ? json['duration_years'] as int : 0,
      internshipYears: json['internship_years'] != null ? json['internship_years'] as int : 0,
    );
  }
  
  // CopyWith for manual join updates
  CollegeModel copyWith({List<AcademicYearModel>? academicYears}) {
    return CollegeModel(
      id: id,
      name: name,
      abbreviation: abbreviation,
      image: image,
      academicYears: academicYears ?? this.academicYears,
      createdAt: createdAt,
      subjects: subjects,
      rawAcademicYearIds: rawAcademicYearIds,
      durationYears: durationYears,
      internshipYears: internshipYears,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'image': image,
      'subjects': subjects?.map((e) => e.toJson()).toList(),
      'academic_years': academicYears?.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'duration_years': durationYears,
      'internship_years': internshipYears,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollegeModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
