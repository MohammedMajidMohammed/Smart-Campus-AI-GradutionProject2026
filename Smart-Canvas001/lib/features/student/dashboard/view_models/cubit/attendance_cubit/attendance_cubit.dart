import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/student/dashboard/repositories/attendance_repository.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;

  // Semester Start Date: Jan 25, 2026
  final DateTime _semesterStartDate = DateTime(2026, 1, 25);

  AttendanceCubit(this._repository) : super(AttendanceInitial()) {
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    emit(AttendanceLoading());
    await _fetchData();
  }

  Future<void> retryFetch() async {
    emit(AttendanceLoading());
    await Future.delayed(const Duration(seconds: 1));
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = getIt<CacheHelper>().getUserModel();
      if (user == null) {
        emit(AttendanceError("User not logged in"));
        return;
      }

      // 1. Get Overall Attendance Records
      final records = await _repository.getStudentAttendance(user.id);
      final attendedCount = records.length;

      // 2. Calculate Current Week
      final now = DateTime.now();
      if (now.isBefore(_semesterStartDate)) {
        emit(AttendanceLoaded(overallRate: 100, attendedClasses: 0, totalClasses: 0, missedClasses: 0, currentWeek: 0));
        return;
      }
      final difference = now.difference(_semesterStartDate);
      int currentWeek = (difference.inDays / 7).ceil();
      if (currentWeek < 1) currentWeek = 1;
      if (currentWeek > 16) currentWeek = 16;

      // 3. Get Detailed Subject Attendance
      final subjectDetails = await _repository.getStudentAttendanceWithSubjects(user.id);
      final subjectCount = await _repository.getEnrolledSubjectsCount(user.id);

      // 4. Transform data for UI
      final List<Map<String, dynamic>> processedSubjects = [];
      for (final detail in subjectDetails) {
        final attended = detail['total_attended'] as int;
        // Assume each subject has 1 session per week
        final rate = (attended / currentWeek * 100).clamp(0, 100);
        processedSubjects.add({
          'name': detail['subject_name'],
          'rate': rate.toDouble(),
          'attended': attended,
          'total': currentWeek,
        });
      }

      // 5. Total calculations
      final totalExpectedClasses = currentWeek * subjectCount;
      var missedCount = totalExpectedClasses - attendedCount;
      if (missedCount < 0) missedCount = 0;

      double overallRate = totalExpectedClasses > 0 ? (attendedCount / totalExpectedClasses) * 100 : 100;
      if (overallRate > 100) overallRate = 100;

      emit(AttendanceLoaded(
        overallRate: overallRate,
        attendedClasses: attendedCount,
        totalClasses: totalExpectedClasses,
        missedClasses: missedCount,
        currentWeek: currentWeek,
        subjectsAttendance: processedSubjects,
      ));

    } catch (e) {
      log("Attendance Cubit Error: $e");
      emit(AttendanceError(e.toString()));
    }
  }
}
