import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/features/administrator/schedule/models/subject_schedule_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'add_subject_schedule_state.dart';

class AddSubjectScheduleCubit extends Cubit<AddSubjectScheduleState> {
  final SubjectScheduleModel? editModel;
  
  AddSubjectScheduleCubit({this.editModel}) : super(AddSubjectScheduleInitial()) {
    init();
  }

  //-- variables --//
  final formKey = GlobalKey<FormState>();
  final supabase = getIt<SupabaseClient>();
  
  // Selection State
  CollegeModel? selectedCollege;
  AcademicYearModel? selectedProgram;
  int? selectedYearLevel;
  
  // Data Lists
  List<CollegeModel> colleges = [];
  List<AcademicYearModel> programs = []; // aka Sections
  List<int> yearLevels = [1, 2, 3, 4, 5, 6, 7]; // Generic max range
  
  SubjectModel? subject;
  List<SubjectModel> subjects = [];
  
  List<UserModel> doctors = [];
  UserModel? doctor;
  
  String? dayOfWeek;
  String? timeSlot;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // Added for Edit
  String? _parseTime(String timeSlot, bool isStart) {
     final parts = timeSlot.split(" - ");
     if (parts.length != 2) return null;
     return isStart ? parts[0] : parts[1];
  }

  TimeOfDay? _timeFromString(String? timeStr) {
    if (timeStr == null) return null;
    final format = timeStr.contains("AM") ? "AM" : "PM";
    final time = timeStr.replaceAll(" AM", "").replaceAll(" PM", "");
    final parts = time.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (format == "PM" && hour != 12) hour += 12;
    if (format == "AM" && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  //-- functions --//

  // 1. Get Colleges
  Future<void> getColleges() async {
    try {
      emit(GetCollegesLoading());
      // Assuming get_colleges_full is the best way to get colleges with programs attached if needed,
      // but here we might just need simple list. Let's use generic getData for now.
      // Wait, CollegeModel.fromJson expects JSON struture from get_colleges_full possibly?
      // Let's us rpc 'get_colleges_full' to be safe as it's used elsewhere.
      final response = await supabase.rpc('get_colleges_full');
      if (response == null) {
        colleges = [];
      } else {
        final List list = response as List;
        colleges = list.map((e) => CollegeModel.fromJson(e)).toList();
      }
      emit(GetCollegesSuccess());
    } catch (e) {
      emit(GetCollegesError(message: e.toString()));
    }
  }

  // 2. Select College -> Get Programs
  selectCollege(CollegeModel college) async {
    selectedCollege = college;
    selectedProgram = null;
    subject = null;
    subjects = [];
    selectedYearLevel = null;
    doctor = null; // Clear selected doctor
    doctors = []; // Temporarily clear list until fetch completes
    
    // Programs are inside CollegeModel or fetched?
    // CollegeModel has `academicYears` list.
    if (college.academicYears != null && college.academicYears!.isNotEmpty) {
      programs = college.academicYears!;
    } else {
      // Fallback: Fetch from DB if missing in model
      try {
        emit(GetCollegesLoading()); // Or a specific loading state
        final response = await supabase
            .from('academic_years')
            .select()
            .or('college_id.eq.${college.id},collage_id.eq.${college.id}');
        
        programs = (response as List)
            .map((e) => AcademicYearModel.fromJson(e))
            .toList();
            } catch (e) {
        programs = [];
      }
    }
    
    // Adjust year levels based on duration
    int duration = college.durationYears ?? 5;
    yearLevels = List.generate(duration, (index) => index + 1);

    // Filter Doctors by this College
    await getDoctors(collegeId: college.id);

    emit(UpdateCollegeSelection()); 
  }

  // 3. Select Program -> Get Subjects
  selectProgram(AcademicYearModel program) async {
    selectedProgram = program;
    subject = null;
    subjects = [];
    
    await getSubjects(programId: program.id);
    emit(UpdateProgramSelection());
  }

  // 4. Select Year
  selectYear(int year) {
    selectedYearLevel = year;
    emit(UpdateYearSelection());
  }

  // Get Subjects (Filtered by Program)
  Future<void> getSubjects({required String programId}) async {
    try {
      emit(GetSubjectsLoading());
      // We need to fetch subjects linked to this academic_year_id (Program)
      // Generic getData doesn't filter. using supabase.from...
      final response = await supabase
          .from('subjects')
          .select('*, college:colleges(*), academic_year:academic_years(*)')
          .eq('academic_year_id', programId);
          
      subjects = (response as List).map((e) => SubjectModel.fromJson(e)).toList();
      emit(GetSubjectsSuccess());
    } catch (e) {
      emit(GetSubjectsError(message: e.toString()));
    }
  }

  // get Doctors (Admins/Doctors)
  // get Doctors (Admins/Doctors) filtered by College
  Future<void> getDoctors({String? collegeId}) async {
    try {
      emit(GetDoctorsLoading());
      
      final targetCollegeId = collegeId ?? selectedCollege?.id;

      // Build query: Get Users with role 'admin/doctor' (fixed UUID)
      var query = supabase.from('users').select().eq('role_id', '6b8200f5-ba01-4613-b8df-736943d61a50');
      
      if (targetCollegeId != null) {
        query = query.eq('college_id', targetCollegeId);
      }
      
      final response = await query;
      doctors = (response as List).map((e) => UserModel.fromJson(e)).toList();
      emit(GetDoctorsSuccess());
    } catch (e) {
      emit(GeDoctorsError(message: e.toString()));
    }
  }

  //-- functions --//

  // select day of week
  selectDay({required String day}) {
    dayOfWeek = day;
    emit(UpdateDayOfWeek());
  }

  // ... (existing functions) ...

  // ... (existing functions) ...

  // select start time
  setStartTime(TimeOfDay time) {
    startTime = time;
    emit(UpdateTimeSlot());
  }

  // select end time
  setEndTime(TimeOfDay time) {
    endTime = time;
    emit(UpdateTimeSlot());
  }
  
  // Format TimeOfDay to String (hh:mm a)
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // Custom formatting or generic. 
    // Manual simplified formatting to match "08:00 AM" pattern
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return "${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  // Room & Type State
  List<RoomModel> rooms = [];
  RoomModel? selectedRoom;
  String scheduleType = 'Lecture'; // Default
  
  // ... (existing variables) ...

  // 1. Get Colleges & Rooms
  Future<void> init() async {
    emit(GetCollegesLoading());
    await Future.wait([getColleges(), getDoctors(), getRooms()]);
    
    if (editModel != null) {
      await _initForEdit();
    }
    emit(GetCollegesSuccess());
  }

  Future<void> _initForEdit() async {
    final model = editModel!;
    dayOfWeek = model.dayOfWeek;
    selectedYearLevel = model.yearLevel;
    
    // Match Doctor from the freshly fetched list
    if (doctors.isNotEmpty) {
      doctor = doctors.any((d) => d.id == model.adminId) 
          ? doctors.firstWhere((d) => d.id == model.adminId) 
          : null;
    }

    // Match Room from the freshly fetched list
    if (model.room != null && rooms.isNotEmpty) {
      selectedRoom = rooms.any((r) => r.id == model.room!.id)
          ? rooms.firstWhere((r) => r.id == model.room!.id)
          : model.room;
    } else {
      selectedRoom = model.room;
    }

    final startStr = _parseTime(model.timeSlot, true);
    final endStr = _parseTime(model.timeSlot, false);
    startTime = _timeFromString(startStr);
    endTime = _timeFromString(endStr);

    final String? collegeIdToMatch = model.collegeId ?? model.subject?.college?.id;
    final String? programIdToMatch = model.academicYearId ?? model.subject?.academicYearModel?.id;

    if (collegeIdToMatch != null && colleges.isNotEmpty) {
      selectedCollege = colleges.any((c) => c.id == collegeIdToMatch)
          ? colleges.firstWhere((c) => c.id == collegeIdToMatch)
          : model.subject?.college;
      
      if (selectedCollege != null) {
        // Sync programs from selected college
        programs = selectedCollege!.academicYears ?? [];
        
        // Match Program
        if (programIdToMatch != null && programs.isNotEmpty) {
          selectedProgram = programs.any((p) => p.id == programIdToMatch)
              ? programs.firstWhere((p) => p.id == programIdToMatch)
              : model.subject?.academicYearModel;
          
          if (selectedProgram != null) {
            // AWAIT fetching subjects for this program
            await getSubjects(programId: selectedProgram!.id);
            
            // Now match subject from the fetched list
            if (model.subject != null && subjects.isNotEmpty) {
              subject = subjects.any((s) => s.id == model.subject!.id)
                  ? subjects.firstWhere((s) => s.id == model.subject!.id)
                  : model.subject;
            } else {
              subject = model.subject;
            }
          }
        }
      }
    }
    
    emit(UpdateCollegeSelection()); // Ensure UI reflects all pre-filled data
  }

  // Get Rooms
  Future<void> getRooms() async {
    try {
      final response = await supabase.from('rooms').select('*, building:buildings(*)');
      rooms = (response as List).map((e) => RoomModel.fromJson(e)).toList();
      emit(UpdateCollegeSelection()); // Trigger rebuild
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
  }

  void selectRoom(RoomModel room) {
    selectedRoom = room;
    emit(UpdateCollegeSelection());
  }

  void selectScheduleType(String type) {
    scheduleType = type;
    emit(UpdateCollegeSelection());
  }

  // add subjectSchedule
  addSubjectSchedule() async {
    if (formKey.currentState!.validate()) {
      if (selectedCollege == null) {
        emit(SelectCollege());
        return;
      }
      if (selectedProgram == null) {
        emit(SelectProgram());
        return;
      }
      if (selectedYearLevel == null) {
        emit(SelectYear());
        return;
      }
      if (subject == null) {
        emit(SelectSubject());
        return;
      }
      if (dayOfWeek == null) {
        emit(SelectDay());
        return;
      }
      if (startTime == null || endTime == null) {
        emit(SelectTimeSlot()); 
        return;
      }
      if (doctor == null) {
        emit(SelectDoctor());
        return;
      }
      if (selectedRoom == null) {
        // Validation for Room
        // emit(SelectRoomError()); 
        return;
      }

      // Construct timeSlot string
      timeSlot = "${_formatTime(startTime!)} - ${_formatTime(endTime!)}";

      try {
        emit(AddSubjectScheduleLoading());
        
        final data = {
          "subject_id": subject!.id,
          "day_of_week": dayOfWeek,
          "time_slot": timeSlot,
          "admin_id": doctor!.id,
          "year_level": selectedYearLevel, 
          "room_id": selectedRoom!.id,
          "schedule_type": scheduleType,
          "created_at": DateTime.now().toIso8601String(),
        };

        if (editModel != null) {
          // Update
          await supabase.from("subject_schedules").update(data).eq("id", editModel!.id);
          emit(AddSubjectScheduleSuccess());
        } else {
          // Create
          // Check overlap (Basic)
          final overlap = await supabase
              .from("subject_schedules")
              .select()
              .eq("day_of_week", dayOfWeek!)
              .eq("time_slot", timeSlot!)
              .eq("admin_id", doctor!.id); 
              
          if (overlap.isEmpty) {
            await addData(
              tableName: "subject_schedules",
              data: data,
            );
            emit(AddSubjectScheduleSuccess());
          } else {
            emit(SubjectScheduleAlreadyExists());
          }
        }
      } catch (e) {
        emit(AddSubjectScheduleError(message: e.toString()));
      }
    }
  }
}
