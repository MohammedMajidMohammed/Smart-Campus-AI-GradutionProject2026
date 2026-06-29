import 'package:equatable/equatable.dart';

class OnlineSessionModel extends Equatable {
  final String id;
  final String professorId;
  final String subjectId;
  final String title;
  final String meetingLink;
  final DateTime startTime;
  final int durationMinutes;
  final DateTime createdAt;
  
  // Optional joined data
  final String? subjectName;
  final String? professorName;

  const OnlineSessionModel({
    required this.id,
    required this.professorId,
    required this.subjectId,
    required this.title,
    required this.meetingLink,
    required this.startTime,
    required this.durationMinutes,
    required this.createdAt,
    this.subjectName,
    this.professorName,
  });

  factory OnlineSessionModel.fromJson(Map<String, dynamic> json) {
    return OnlineSessionModel(
      id: json['id'] as String,
      professorId: json['professor_id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      meetingLink: json['meeting_link'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      subjectName: json['subjects'] != null ? json['subjects']['name'] as String? : json['subject_name'] as String?,
      professorName: json['users'] != null ? json['users']['full_name'] as String? : json['professor_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professor_id': professorId,
      'subject_id': subjectId,
      'title': title,
      'meeting_link': meetingLink,
      'start_time': startTime.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  @override
  List<Object?> get props => [id, professorId, subjectId, title, meetingLink, startTime, durationMinutes, createdAt, subjectName, professorName];
}
