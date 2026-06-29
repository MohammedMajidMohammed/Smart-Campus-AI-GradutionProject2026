class AssignmentModel {
  final String id;
  final String subjectId;
  final String professorId;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? link; // New optional Link field
  final DateTime? startDate; // New Start Date field
  final DateTime dueDate;
  final DateTime createdAt;
  final bool isActive;
  
  // Joined fields for convenience
  final String? subjectName;
  final String? professorName;

  AssignmentModel({
    required this.id,
    required this.subjectId,
    required this.professorId,
    required this.title,
    this.description,
    this.fileUrl,
    this.link,
    this.startDate,
    required this.dueDate,
    required this.createdAt,
    this.isActive = true,
    this.subjectName,
    this.professorName,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      professorId: json['professor_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      link: json['link'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String).toLocal() : null,
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      isActive: json['is_active'] as bool? ?? true,
      
      // Handle nested joins
      subjectName: json['subjects'] != null ? json['subjects']['name'] : null,
      professorName: json['users'] != null ? json['users']['full_name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'professor_id': professorId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'link': link,
      'start_date': startDate?.toUtc().toIso8601String(),
      'due_date': dueDate.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
