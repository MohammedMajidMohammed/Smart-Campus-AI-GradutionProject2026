part of 'attendance_cubit.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final double overallRate;
  final int attendedClasses;
  final int totalClasses; 
  final int missedClasses;
  final int currentWeek;
  final List<Map<String, dynamic>> subjectsAttendance; // List of {subject_name, rate, attended, total}

  AttendanceLoaded({
    required this.overallRate,
    required this.attendedClasses,
    required this.totalClasses,
    required this.missedClasses,
    required this.currentWeek,
    this.subjectsAttendance = const [],
  });

  // Keep old getter for backward compatibility with existing widgets
  double get attendanceRate => overallRate;
}

class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError(this.message);
}
