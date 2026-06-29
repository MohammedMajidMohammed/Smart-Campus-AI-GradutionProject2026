class ExamSubmissionModel {
  final String id;
  final String examId;
  final String studentId;
  final double score;
  final int totalPoints;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final bool isSubmitted;
  // Joined fields
  final String? studentName;
  final String? studentImage;
  final String? examTitle;

  ExamSubmissionModel({
    required this.id,
    required this.examId,
    required this.studentId,
    this.score = 0,
    this.totalPoints = 0,
    this.startedAt,
    this.submittedAt,
    this.isSubmitted = false,
    this.studentName,
    this.studentImage,
    this.examTitle,
  });

  double get percentage => totalPoints > 0 ? (score / totalPoints) * 100 : 0;
  bool get isPassed => percentage >= 50;

  String get gradeLabel {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'B+';
    if (percentage >= 75) return 'B';
    if (percentage >= 70) return 'C+';
    if (percentage >= 65) return 'C';
    if (percentage >= 60) return 'D+';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  factory ExamSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ExamSubmissionModel(
      id: json['id']?.toString() ?? '',
      examId: json['exam_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'].toString())
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'].toString())
          : null,
      isSubmitted: json['is_submitted'] as bool? ?? false,
      studentName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['full_name']?.toString()
          : json['student_name']?.toString(),
      studentImage: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['image']?.toString()
          : null,
      examTitle: json['exams'] != null
          ? (json['exams'] as Map<String, dynamic>)['title']?.toString()
          : json['exam_title']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamSubmissionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
