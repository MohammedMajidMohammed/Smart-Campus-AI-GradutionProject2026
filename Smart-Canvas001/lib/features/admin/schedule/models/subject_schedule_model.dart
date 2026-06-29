import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class SubjectScheduleModel {
  final String id;
  final String dayOfWeek; // اليوم الكامل مثل "Wednesday"
  final String timeSlot; // الـ slot المحفوظ مباشرة مثل "08:00 AM - 10:00 AM"
  final DateTime createdAt;
  final SubjectModel? subject; // nullable إذا مفيش subject

  SubjectScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.createdAt,
    this.subject,
  });

  // Getter لاختصار اليوم (Sat, Sun, etc.)
  String get formattedDay {
    final Map<String, String> dayMap = {
      'Saturday': 'Sat',
      'Sunday': 'Sun',
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
    };
    return dayMap[dayOfWeek] ?? dayOfWeek.substring(0, 3);
  }

  // Getter لاسم المادة
  String get subjectName => subject?.name ?? '—';

  factory SubjectScheduleModel.fromJson(Map<String, dynamic> json) {
    return SubjectScheduleModel(
      id: json['id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      timeSlot: json['time_slot'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      subject: json['subject'] != null
          ? SubjectModel.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
      'created_at': createdAt.toIso8601String(),
      'subject': subject?.toJson(),
    };
  }
}