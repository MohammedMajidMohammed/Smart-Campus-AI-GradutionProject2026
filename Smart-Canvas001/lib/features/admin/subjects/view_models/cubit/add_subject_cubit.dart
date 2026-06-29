import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'add_subject_state.dart';

class AddSubjectCubit extends Cubit<AddSubjectState> {
  AddSubjectCubit() : super(AddSubjectInitial()) {
    getColleges();
  }
  //-- variables --//
  final formKey = GlobalKey<FormState>();
  final subjectNameController = TextEditingController();
  final supabase = getIt<SupabaseClient>();
  String? collegeId, academicYearId;
  List<CollegeModel> colleges = [];
  List<AcademicYearModel> availableAcademicYears = [];
  List<AcademicYearModel> selectedAcademicYears = [];
  //-- functions --//
  // get building
  Future<void> getColleges() async {
    try {
      emit(GetCollegesLoading());
      final response = await supabase.rpc('get_colleges_full');
      final List list = response as List;
      var mappedColleges = list.map((e) => CollegeModel.fromJson(e)).toList();
      
      final user = getIt<CacheHelper>().getUserModel();
      if (user != null && user.collegeId != null && user.collegeId!.isNotEmpty) {
        mappedColleges = mappedColleges.where((c) => c.id == user.collegeId).toList();
      }
      
      colleges = mappedColleges;
      
      // Auto-preselect college if there is exactly 1 match
      if (colleges.length == 1) {
        selectCollege(college: colleges.first);
      }
      
      emit(GetCollegesSuccess());
    } catch (e) {
      emit(GetCollegesError(message: e.toString()));
    }
  }

  // select college
  selectCollege({required CollegeModel college}) {
    collegeId = college.id;
    availableAcademicYears = college.academicYears ?? [];
    emit(GetAcademicYearsSuccess());
  }

  // toggle academic year
  void toggleAcademicYear(AcademicYearModel year) {
    selectedAcademicYears.clear();
    selectedAcademicYears.add(year);
    academicYearId = year.id;
    emit(AcademicYearsUpdated());
  }

  // add subject
  addSubject() async {
    if (formKey.currentState!.validate()) {
      if (collegeId == null) {
        emit(SelectCollege());
        return;
      }
      if (academicYearId == null) {
        emit(SelectAcademicYear());
        return;
      }
      try {
        emit(AddSubjectLoading());
        await addData(
          tableName: "subjects",
          data: {
            "name": subjectNameController.text,
            "college_id": collegeId,
            "academic_year_id": academicYearId,
            "created_at": DateTime.now().toIso8601String(),
          },
        );
        emit(AddSubjectSuccess());
      } catch (e) {
        emit(AddSubjectError(message: e.toString()));
      }
    }
  }
}
