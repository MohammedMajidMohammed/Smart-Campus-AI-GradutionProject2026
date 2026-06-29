import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/admin/material/models/material_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'materials_state.dart';

class MaterialsCubit extends Cubit<MaterialsState> {
  MaterialsCubit() : super(MaterialsInitial());

  //-- variables --//
  List<MaterialModel> materials = [];
  List<MaterialModel> filteredMaterials = [];
  List<SubjectModel> professorSubjects = [];
  List<SubjectModel> filteredProfessorSubjects = [];
  List<SubjectModel> allSystemSubjects = [];
  String? currentSubjectId;
  String? selectedFolder;
  
  final supabase = getIt<SupabaseClient>();

  //-- functions --//
  
  /// Fetches unique subjects assigned to the professor from their schedule
  Future<void> getProfessorSubjects() async {
    try {
      emit(GetMaterialsLoading());
      currentSubjectId = null;
      
      final currentUserId = supabase.auth.currentUser!.id;
      
      // Admin Check: Fetch all subjects if user is Admin, otherwise fetch only scheduled ones
      final profileRes = await supabase.from('users').select('*, role:roles(*)').eq('id', currentUserId).single();
      
      String roleName = '';
      if (profileRes['role'] != null) {
        if (profileRes['role'] is Map) {
          roleName = profileRes['role']['name']?.toString() ?? '';
        }
      }

      log("MaterialsCubit: User Role is '$roleName'");

      // To solve the user's issue where subjects don't appear, we'll fetch ALL subjects 
      // if the role contains 'admin' OR if the professor schedule fetch returns nothing.
      final List<dynamic> allSubjectsRes = await supabase.from('subjects').select('*');
      final List<SubjectModel> allSubjects = allSubjectsRes.map((e) => SubjectModel.fromJson(e)).toList();

      if (roleName.toLowerCase().contains('admin') || roleName.isEmpty) {
        var filteredAdminSubjects = allSubjects;
        final adminCollegeId = profileRes['college_id']?.toString();
        if (adminCollegeId != null && adminCollegeId.isNotEmpty) {
          filteredAdminSubjects = allSubjects.where((s) => s.college?.id == adminCollegeId).toList();
        }
        professorSubjects = filteredAdminSubjects;
        log("MaterialsCubit: Admin Mode - Loaded ${professorSubjects.length} subjects");
      } else {
        // Doctor Mode: Try to fetch from schedule
        final res = await supabase.rpc('get_subject_schedules_with_subject');
        if (res == null) {
          professorSubjects = [];
        } else {
          final List schedulesList = res as List;
          final List<SubjectScheduleModel> allSchedules = schedulesList
              .map((e) => SubjectScheduleModel.fromJson(e as Map<String, dynamic>))
              .toList();
              
          final professorSchedule = allSchedules.where((e) => e.adminId == currentUserId).toList();
          final Map<String, SubjectModel> uniqueSubjects = {};
          for (var schedule in professorSchedule) {
            if (schedule.subject != null) {
              uniqueSubjects[schedule.subject!.id] = schedule.subject!;
            }
          }
          professorSubjects = uniqueSubjects.values.toList();
        }
        
        // If doctor has no scheduled subjects, show all as a fallback to prevent empty screen
        if (professorSubjects.isEmpty) {
          professorSubjects = allSubjects;
        }
        log("MaterialsCubit: Doctor Mode - Loaded ${professorSubjects.length} subjects");
      }
      
      filteredProfessorSubjects = professorSubjects;
      emit(GetMaterialsSuccess());
    } catch (e) {
      log("Error fetching professor subjects: $e");
      emit(GetMaterialsFailure(message: e.toString()));
    }
  }

  /// Fetches materials for a specific subject
  Future<void> getMaterialsForSubject(String subjectId) async {
    try {
      emit(GetMaterialsLoading());
      currentSubjectId = subjectId;
      
      final response = await supabase.rpc('get_materials_with_subject_and_user');
      
      if (response == null) {
        materials = [];
      } else {
        final List materialsList = response as List;
        materials = materialsList
            .map((e) => MaterialModel.fromJson(e))
            .where((m) => m.subjectModel.id == subjectId)
            .toList();
      }
      
      filteredMaterials = materials;
      emit(GetMaterialsSuccess());
    } catch (e) {
      log("Error fetching materials for subject: $e");
      emit(GetMaterialsFailure(message: e.toString()));
    }
  }

  Future<void> refresh() async {
    if (currentSubjectId != null) {
      await getMaterialsForSubject(currentSubjectId!);
    } else {
      await getProfessorSubjects();
    }
  }

  void searchMaterials(String query) {
    if (query.isEmpty) {
      filteredMaterials = materials;
    } else {
      filteredMaterials = materials
          .where((material) =>
              material.title.toLowerCase().contains(query.toLowerCase()) ||
              (material.folderName?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
    emit(GetMaterialsSuccess());
  }

  void selectFolder(String? folder) {
    selectedFolder = folder;
    if (folder == null) {
      filteredMaterials = materials;
    } else {
      filteredMaterials = materials.where((m) => m.folderName == folder).toList();
    }
    emit(GetMaterialsSuccess());
  }

  Future<void> getAllSystemSubjects() async {
    try {
      final List<dynamic> res = await supabase.from('subjects').select('*');
      var subjectsList = res.map((e) => SubjectModel.fromJson(e)).toList();
      
      final user = getIt<CacheHelper>().getUserModel();
      if (user != null && user.collegeId != null && user.collegeId!.isNotEmpty) {
        subjectsList = subjectsList.where((s) => s.college?.id == user.collegeId).toList();
      }
      
      allSystemSubjects = subjectsList;
      emit(GetMaterialsSuccess());
    } catch (e) {
      log("Error fetching all system subjects: $e");
    }
  }

  Future<void> addSubject(String name, String code) async {
    try {
      emit(GetMaterialsLoading());
      final currentUserId = supabase.auth.currentUser!.id;
      
      // Fetch user's college and academic year to satisfy database constraints
      final profileRes = await supabase.from('users').select('college_id, academic_year_id').eq('id', currentUserId).single();
      
      final collegeId = profileRes['college_id'];
      final academicYearId = profileRes['academic_year_id'];

      if (collegeId == null || academicYearId == null) {
        throw Exception("User profile is missing college_id or academic_year_id. Please complete your profile first.");
      }

      await supabase.from('subjects').insert({
        'name': name,
        'code': code,
        'college_id': collegeId,
        'academic_year_id': academicYearId,
      });
      
      log("MaterialsCubit: Subject added successfully");
      emit(AddSubjectSuccess());
      await getProfessorSubjects();
    } catch (e) {
      log("Error adding subject: $e");
      emit(GetMaterialsFailure(message: e.toString()));
    }
  }

  void searchSubjects(String query) {
    if (query.isEmpty) {
      filteredProfessorSubjects = professorSubjects;
    } else {
      filteredProfessorSubjects = professorSubjects.where((s) => 
        s.name.toLowerCase().contains(query.toLowerCase()) || 
        (s.code?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
    }
    emit(GetMaterialsSuccess());
  }

  List<String> getFolders() {
    final Set<String> folders = {};
    for (var material in materials) {
      if (material.folderName != null && material.folderName!.isNotEmpty) {
        folders.add(material.folderName!);
      }
    }
    return folders.toList();
  }
}
