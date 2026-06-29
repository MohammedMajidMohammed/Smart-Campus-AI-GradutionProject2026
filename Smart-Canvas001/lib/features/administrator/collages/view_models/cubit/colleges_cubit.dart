import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'colleges_state.dart';

class CollegesCubit extends Cubit<CollegesState> {
  CollegesCubit() : super(CollegesInitial()) {
    getColleges();
  }
  //--> variables
  List<CollegeModel> colleges = [];
  List<CollegeModel> filteredColleges = [];
  String _currentQuery = '';
  final supabase = getIt<SupabaseClient>();
  //--> functions
  // get colleges
  // get colleges
  getColleges() async {
    try {
      emit(GetCollegesLoading());
      
      // 1. Fetch Colleges
      final response = await supabase.rpc('get_colleges_full');
      if (response == null) {
        emit(GetCollegesSuccess()); // Empty
        return;
      }
      
      final List data = response as List;
      final rawColleges = data.map((e) => CollegeModel.fromJson(e)).toList();

      // 2. Fetch Academic Years (Departments) manually to ensure robust join
      dynamic yearsResponse;
      try {
        yearsResponse = await supabase.from('academic_years').select();
      } catch (e) {
        log('Error fetching academic years in CollegesCubit: $e');
        yearsResponse = [];
      }
      
      final List<AcademicYearModel> allYears = (yearsResponse as List)
          .map((e) => AcademicYearModel.fromJson(e))
          .toList();

      // 3. Manual Join to fix missing departments
      colleges = rawColleges.map((college) {
        // Strategy: Match by college_id
        List<AcademicYearModel> collegeYears = allYears.where((year) => year.collegeId == college.id).toList();
        
        // Strategy B: Fallback
        if (collegeYears.isEmpty && college.rawAcademicYearIds != null) {
          collegeYears = allYears.where((year) => college.rawAcademicYearIds!.contains(year.id)).toList();
        }

        return college.copyWith(academicYears: collegeYears);
      }).toList();
      
      // Sort alphabetically
      colleges.sort((a, b) => a.name.compareTo(b.name));
      
      log('Loaded ${colleges.length} colleges with manual join.');
      
      _applyFilter();
      emit(GetCollegesSuccess());
    } catch (e) {
      log('Critical Error in getColleges: $e');
      emit(GetCollegesError(message: e.toString()));
    }
  }

  void _applyFilter() {
    if (_currentQuery.trim().isEmpty) {
      filteredColleges = colleges;
      return;
    }
    final q = _currentQuery.trim().toLowerCase();
    filteredColleges = colleges.where((college) {
      final nameMatch = college.name.toLowerCase().contains(q);
      final abbreviationMatch = college.abbreviation.toLowerCase().contains(q);
      return nameMatch || abbreviationMatch;
    }).toList();
  }

  void searchColleges(String query) {
    _currentQuery = query;
    _applyFilter();
    emit(GetCollegesSuccess());
  }
}
