// 2. DoctorSchedulesCubit (الـ Cubit مع الفلترة والـ allSceduleSelectd)
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'schedules_state.dart'; // افترض إن عندك states.dart مع GetSchedulesLoading, Success, Failure, Initial

class DoctorSchedulesCubit extends Cubit<SchedulesState> {
  DoctorSchedulesCubit() : super(SchedulesInitial()) {
    getSchedules();
  }

  // -- variables -- //
  List<SubjectScheduleModel> subjectScheduleModels = [];
  List<SubjectScheduleModel> filteredSchedules = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();
  bool allSceduleSelectd = false;

  // -- functions -- //
  getSchedules() async {
    try {
      emit(GetSchedulesLoading());
      final res = await supabase.rpc(
        'get_subject_schedules_with_subject',
      ); // افترض أنها ترجع time_slot
      log(res.toString());
      log(supabase.auth.currentUser!.id);
      final List schedules = res as List;
      subjectScheduleModels = schedules
          .map((e) => SubjectScheduleModel.fromJson(e))
          .toList();
      _applyFilter();
      emit(GetSchedulesSuccess());
    } catch (e) {
      log(e.toString());
      emit(GetSchedulesFailure(message: e.toString()));
    }
  }

  void _applyFilter() {
    List<SubjectScheduleModel> baseList = subjectScheduleModels;
    if (!allSceduleSelectd) {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        baseList = subjectScheduleModels
            .where((e) => e.adminId == currentUserId)
            .toList();
      }
    }

    if (_currentQuery.trim().isEmpty) {
      filteredSchedules = baseList;
      return;
    }

    final q = _currentQuery.trim().toLowerCase();
    filteredSchedules = baseList.where((schedule) {
      final subjectMatch = schedule.subjectName.toLowerCase().contains(q);
      final codeMatch = (schedule.subject?.code ?? '').toLowerCase().contains(q);
      final roomMatch = (schedule.room?.name ?? '').toLowerCase().contains(q);
      final dayMatch = schedule.dayOfWeek.toLowerCase().contains(q) || schedule.formattedDay.toLowerCase().contains(q);
      final timeMatch = schedule.timeSlot.toLowerCase().contains(q);
      return subjectMatch || codeMatch || roomMatch || dayMatch || timeMatch;
    }).toList();
  }

  filterSchedules({required bool allCourses}) {
    allSceduleSelectd = allCourses;
    _applyFilter();
    emit(GetSchedulesSuccess());
  }

  void searchSchedules(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetSchedulesSuccess());
  }
}