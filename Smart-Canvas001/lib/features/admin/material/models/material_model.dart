import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class MaterialModel {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final SubjectModel subjectModel;
  final UserModel uploadedBy;
  final DateTime? createdAt;
  final String? folderName; 
  final bool isLink; 
  final String materialType; // "Lecture" or "Section"

  MaterialModel({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.subjectModel,
    required this.uploadedBy,
    this.createdAt,
    this.folderName,
    this.isLink = false,
    required this.materialType,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'],
      fileUrl: json['file_url'] as String? ?? json['url'] as String? ?? '',
      subjectModel: SubjectModel.fromJson(json['subject'] as Map<String, dynamic>),
      uploadedBy: UserModel.fromJson((json['uploaded_by'] ?? json['user'] ?? {}) as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      folderName: json['folder_name'] as String?,
      isLink: json['is_link'] as bool? ?? false,
      materialType: json['material_type'] as String? ?? json['type'] as String? ?? 'Lecture',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'subject': subjectModel.toJson(),
      'uploaded_by': uploadedBy.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'folder_name': folderName,
      'is_link': isLink,
      'material_type': materialType,
    };
  }
}
