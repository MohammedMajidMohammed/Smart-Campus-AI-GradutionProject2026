import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';

class SubjectScheduleModel {
  final String id;
  final String dayOfWeek; // اليوم الكامل مثل "Wednesday"
  final String timeSlot; // الـ slot المحفوظ مباشرة مثل "08:00 AM - 10:00 AM"
  final DateTime createdAt;
  final SubjectModel? subject; // nullable إذا مفيش subject
  final String adminId;
  final RoomModel? room; // Added Room field
  final int? yearLevel; // Added yearLevel field
  final String? collegeId; // Fallback helper
  final String? academicYearId; // Fallback helper

  SubjectScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.createdAt,
    required this.adminId,
    this.subject,
    this.room,
    this.yearLevel,
    this.collegeId,
    this.academicYearId,
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
    final trimmedDay = dayOfWeek.trim();
    return dayMap[trimmedDay] ?? (trimmedDay.length >= 3 ? trimmedDay.substring(0, 3) : trimmedDay);
  }

  // Getter لاسم المادة
  String get subjectName => subject?.name ?? '—';

  factory SubjectScheduleModel.fromJson(Map<String, dynamic> json) {
    return SubjectScheduleModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: (json['day_of_week'] as String? ?? '').trim(),
      timeSlot: json['time_slot']?.toString() ?? '', // مباشرة من الـ DB
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      adminId: json['admin_id']?.toString() ?? '',
      yearLevel: json['year_level'] as int?, // From DB
      subject: json['subject'] != null
          ? SubjectModel.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      collegeId: json['subject']?['college_id']?.toString(),
      academicYearId: json['subject']?['academic_year_id']?.toString(),
    );
  }

  factory SubjectScheduleModel.empty() {
    return SubjectScheduleModel(
      id: '',
      dayOfWeek: '',
      timeSlot: '', // Empty slot
      createdAt: DateTime.now(),
      adminId: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
      'created_at': createdAt.toIso8601String(),
      'admin_id': adminId,
      'year_level': yearLevel,
      'subject': subject?.toJson(),
      'room': room?.toJson(),
    };
  }
}