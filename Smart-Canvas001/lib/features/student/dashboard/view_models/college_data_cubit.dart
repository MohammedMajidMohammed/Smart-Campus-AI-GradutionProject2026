import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/features/student/dashboard/models/college_data.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'college_data_state.dart';

class CollegeDataCubit extends Cubit<CollegeDataState> {
  CollegeDataCubit() : super(CollegeDataInitial());
  //-- variables
  final _supabase = getIt<SupabaseClient>();
  CollegeData? college;
  List<SubjectModel> filteredSubjects = [];
  // -- functions
  Future<void> getStudentSubjects() async {
    final user = getIt<CacheHelper>().getUserModel();
    if (user != null && user.collegeId != null && user.academicYearId != null) {
      await fetchCollegeData(
        collegeId: user.collegeId!,
        academicYearId: user.academicYearId!,
      );
    } else {
      emit(const CollegeDataFailure("User data not found or incomplete"));
    }
  }

  // get subjects
  Future<void> fetchCollegeData({
    required String collegeId,
    required String academicYearId,
  }) async {
    emit(CollegeDataLoading());

    try {
      final response = await _supabase.rpc(
        'get_user_academic_data',
        params: {
          'p_college_id': collegeId,
          'p_academic_year_id': academicYearId,
        },
      );

      if (response == null) {
        emit(const CollegeDataFailure("No data found"));
        return;
      }

      // 1. Parse initial data (All subjects in program)
      var collegeData = CollegeData.fromJson(response as Map<String, dynamic>);

      // 2. Fetch Active Subject IDs for Current User's Year Level
      final user = getIt<CacheHelper>().getUserModel();
      final yearLevel = user?.yearLevel ?? 1;

      final scheduleResponse = await _supabase
          .from('subject_schedules')
          .select('subject_id')
          .eq('year_level', yearLevel);
          // Removed incorrect admin_id filter. subject_id intersection with collegeData is sufficient.

      final List<dynamic> scheduleList = scheduleResponse as List<dynamic>;
      final Set<String> activeSubjectIds = scheduleList.map((e) => e['subject_id'] as String).toSet();

      // 3. Filter subjects
      final filteredList = collegeData.subjects.where((s) => activeSubjectIds.contains(s.id)).toList();

      // 4. Update State
      college = CollegeData(
        college: collegeData.college,
        academicYear: collegeData.academicYear,
        subjects: filteredList,
      );
      filteredSubjects = filteredList;
      
      emit(CollegeDataSuccess());
    } catch (e) {
      emit(CollegeDataFailure(e.toString()));
    }
  }

  void searchSubjects(String query) {
    if (query.isEmpty) {
      filteredSubjects = college?.subjects ?? [];
    } else {
      filteredSubjects = college?.subjects
              .where((subject) =>
                  subject.name.toLowerCase().contains(query.toLowerCase()))
              .toList() ??
          [];
    }
    emit(CollegeDataSuccess());
  }
}
