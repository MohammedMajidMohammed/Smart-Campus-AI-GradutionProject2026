import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit() : super(SubjectsInitial()) {
    getSubjects();
  }
  //-- variables --//
  List<SubjectModel> subjects = [];
  List<SubjectModel> filteredSubjects = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();

  //-- functions --//
  getSubjects() async {
    try {
      emit(GetSubjectsLoading());
      final response = await supabase.rpc('get_subjects_with_college_and_year');
      final List subjectsList = response as List;
      var mappedSubjects = subjectsList.map((e) => SubjectModel.fromJson(e)).toList();
      
      final user = getIt<CacheHelper>().getUserModel();
      if (user != null && user.collegeId != null && user.collegeId!.isNotEmpty) {
        mappedSubjects = mappedSubjects.where((s) => s.college?.id == user.collegeId).toList();
      }
      
      subjects = mappedSubjects;
      _applyFilter();
      emit(GetSubjectsSuccess());
    } catch (e) {
      emit(GetSubjectsFailure(message: e.toString()));
    }
  }

  void _applyFilter() {
    if (_currentQuery.trim().isEmpty) {
      filteredSubjects = subjects;
      return;
    }
    final q = _currentQuery.trim().toLowerCase();
    filteredSubjects = subjects.where((subject) {
      final nameMatch = subject.name.toLowerCase().contains(q);
      final codeMatch = (subject.code ?? '').toLowerCase().contains(q);
      final collegeMatch = (subject.college?.name ?? '').toLowerCase().contains(q);
      final yearMatch = (subject.academicYearModel?.name ?? '').toLowerCase().contains(q);
      return nameMatch || codeMatch || collegeMatch || yearMatch;
    }).toList();
  }

  void searchSubjects(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetSubjectsSuccess());
  }
}
