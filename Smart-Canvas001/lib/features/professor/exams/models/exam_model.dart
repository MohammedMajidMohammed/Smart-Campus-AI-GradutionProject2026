class ExamModel {
  final String id;
  final String subjectId;
  final String professorId;
  final String title;
  final String? description;
  final DateTime openAt;
  final DateTime closeAt;
  final int durationMinutes;
  final bool isActive;
  final DateTime? createdAt;
  // Joined fields
  final String? subjectName;
  final String? professorName;
  final int? questionCount;

  ExamModel({
    required this.id,
    required this.subjectId,
    required this.professorId,
    required this.title,
    this.description,
    required this.openAt,
    required this.closeAt,
    this.durationMinutes = 60,
    this.isActive = true,
    this.createdAt,
    this.subjectName,
    this.professorName,
    this.questionCount,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      professorId: json['professor_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      openAt: DateTime.parse(json['open_at'].toString()),
      closeAt: DateTime.parse(json['close_at'].toString()),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      subjectName: json['subjects'] != null
          ? (json['subjects'] as Map<String, dynamic>)['name']?.toString()
          : json['subject_name']?.toString(),
      professorName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['full_name']?.toString()
          : json['professor_name']?.toString(),
      questionCount: json['exam_questions'] is List
          ? (json['exam_questions'] as List).length
          : json['question_count'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'subject_id': subjectId,
        'professor_id': professorId,
        'title': title,
        'description': description,
        'open_at': openAt.toUtc().toIso8601String(),
        'close_at': closeAt.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'is_active': isActive,
      };

  bool get isOpen {
    final now = DateTime.now().toUtc();
    return isActive && now.isAfter(openAt.toUtc()) && now.isBefore(closeAt.toUtc());
  }

  bool get isUpcoming => DateTime.now().toUtc().isBefore(openAt.toUtc());

  bool get isClosed => DateTime.now().toUtc().isAfter(closeAt.toUtc()) || !isActive;

  String get statusLabel {
    if (isOpen) return 'Open';
    if (isUpcoming) return 'Upcoming';
    return 'Closed';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
