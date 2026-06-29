class AttendanceRecordModel {
  final String sessionId;
  final String subjectId;
  final String studentId;
  final DateTime scannedAt;
  final int weekNumber;

  AttendanceRecordModel({
    required this.sessionId,
    required this.subjectId,
    required this.studentId,
    required this.scannedAt,
    required this.weekNumber,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      sessionId: json['session_id'] as String,
      subjectId: json['subject_id'] as String,
      studentId: json['student_id'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      weekNumber: json['week_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'subject_id': subjectId,
      'student_id': studentId,
      'scanned_at': scannedAt.toIso8601String(),
      'week_number': weekNumber,
    };
  }
}
