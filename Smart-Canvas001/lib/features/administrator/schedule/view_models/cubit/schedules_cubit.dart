import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'schedules_state.dart';

class SchedulesCubit extends Cubit<SchedulesState> {
  SchedulesCubit() : super(SchedulesInitial()) {
    initSchedules();
  }

  //-- variables --//
  List<SubjectScheduleModel> subjectScheduleModels = [];
  List<SubjectScheduleModel> filteredSchedules = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();

  // Filtering State
  CollegeModel? selectedCollege;
  AcademicYearModel? selectedProgram;
  int? selectedYearLevel;

  List<CollegeModel> colleges = [];
  List<AcademicYearModel> programs = [];

  //-- functions --//

  Future<void> initSchedules() async {
    await getColleges();
    await getSchedules();
  }

  Future<void> getColleges() async {
    try {
      final response = await supabase.rpc('get_colleges_full');
      if (response != null) {
        final List list = response as List;
        colleges = list.map((e) => CollegeModel.fromJson(e)).toList();
      }
    } catch (e) {
      log("Error fetching colleges: $e");
    }
  }

  void selectCollege(CollegeModel? college) {
    selectedCollege = college;
    selectedProgram = null;
    programs = college?.academicYears ?? [];
    getSchedules();
  }

  void selectProgram(AcademicYearModel? program) {
    selectedProgram = program;
    getSchedules();
  }

  void selectYearLevel(int? year) {
    selectedYearLevel = year;
    getSchedules();
  }

  Future<void> getSchedules() async {
    try {
      emit(GetSchedulesLoading());
      
      // Building a dynamic query based on filters
      var query = supabase
          .from('subject_schedules')
          .select('*, subject:subjects!inner(*, college:colleges(*), academic_year:academic_years(*)), room:rooms(*)');

      if (selectedYearLevel != null) {
        query = query.eq('year_level', selectedYearLevel!);
      }
      
      if (selectedCollege != null) {
        query = query.eq('subject.college_id', selectedCollege!.id);
      }

      if (selectedProgram != null) {
        query = query.eq('subject.academic_year_id', selectedProgram!.id);
      }

      final res = await query;
      
      final List schedules = res as List;
      subjectScheduleModels = schedules
          .map((e) => SubjectScheduleModel.fromJson(e))
          .toList();
      _applyFilter();
      emit(GetSchedulesSuccess());
    } catch (e) {
      log("Error fetching schedules: $e");
      emit(GetSchedulesFailure(message: e.toString()));
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      emit(GetSchedulesLoading());
      await supabase.from('subject_schedules').delete().eq('id', id);
      await getSchedules(); // Refresh
    } catch (e) {
      log("Error deleting schedule: $e");
      emit(GetSchedulesFailure(message: "Failed to delete: $e"));
    }
  }

  void _applyFilter() {
    if (_currentQuery.trim().isEmpty) {
      filteredSchedules = subjectScheduleModels;
      return;
    }
    final q = _currentQuery.trim().toLowerCase();
    filteredSchedules = subjectScheduleModels.where((schedule) {
      final subjectMatch = schedule.subjectName.toLowerCase().contains(q);
      final codeMatch = (schedule.subject?.code ?? '').toLowerCase().contains(q);
      final roomMatch = (schedule.room?.name ?? '').toLowerCase().contains(q);
      final dayMatch = schedule.dayOfWeek.toLowerCase().contains(q) || schedule.formattedDay.toLowerCase().contains(q);
      final timeMatch = schedule.timeSlot.toLowerCase().contains(q);
      return subjectMatch || codeMatch || roomMatch || dayMatch || timeMatch;
    }).toList();
  }

  void searchSchedules(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetSchedulesSuccess());
  }
}
