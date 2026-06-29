import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/network/supabase/database/get_data.dart';
import 'package:smart_canvas/core/network/supabase/storage/upload_file.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'add_college_state.dart';

class AddCollegeCubit extends Cubit<AddCollegeState> {
  final CollegesCubit? collegesCubit; // Optional reference for refresh
  
  AddCollegeCubit({this.collegesCubit}) : super(AddCollegeInitial()) {
    getAcademicYears();
  }
  // --> variables
  final formKey = GlobalKey<FormState>();
  final collegeNameController = TextEditingController();
  final collegeAbbreviationController = TextEditingController();
  final durationController = TextEditingController(text: '4');
  final internshipController = TextEditingController(text: '0');
  File? collegeImageFile;
  String? existingImageUrl;
  String? collegeId; // If null, we are in "Add" mode. If not null, "Edit" mode.
  List<AcademicYearModel> availableAcademicYears = [];
  List<AcademicYearModel> selectedAcademicYears = [];

  // init for edit
  void initEdit(CollegeModel college) {
    collegeId = college.id;
    collegeNameController.text = college.name;
    collegeAbbreviationController.text = college.abbreviation;
    durationController.text = college.durationYears?.toString() ?? '4';
    internshipController.text = college.internshipYears?.toString() ?? '0';
    existingImageUrl = college.image;
    selectedAcademicYears = List.from(college.academicYears ?? []);
    emit(AcademicYearsUpdated());
  }
  // --> functions
  // get academic years
  getAcademicYears() async {
    try {
      emit(GetAcademicYearsLoading());
      final years = await getData(tableName: "academic_years");
      log(years.toString());
      availableAcademicYears = years
          .map((e) => AcademicYearModel.fromJson(e))
          .toList();
      availableAcademicYears.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(GetAcademicYearsSuccess());
    } catch (e) {
      emit(GetAcademicYearsError(message: e.toString()));
    }
  }

  // toggle academic year
  void toggleAcademicYear(AcademicYearModel year) {
    if (selectedAcademicYears.contains(year)) {
      selectedAcademicYears.remove(year);
    } else {
      selectedAcademicYears.add(year);
    }
    emit(AcademicYearsUpdated());
  }

  // pick college image
  pickCollegeImage() async {
    try {
      await pickImage(source: ImageSource.gallery).then((value) {
        if (value != null) {
          collegeImageFile = value;
          emit(PickImageSuccess());
        }
      });
    } catch (e) {
      emit(PickImageError(message: e.toString()));
    }
  }

  // add college
  addCollege() async {
    if (formKey.currentState!.validate()) {
      if (collegeImageFile == null && collegeId == null) {
        emit(SelectCollageImage());
        return;
      }
      try {
        emit(AddCollegeLoading());
        
        final imageUrl = collegeImageFile != null 
          ? await uploadFileToSupabaseStorage(file: collegeImageFile!, pucketName: "colleges")
          : existingImageUrl;
        
        log("Saving college with Image URL: $imageUrl");

        final data = {
          "name": collegeNameController.text,
          "image": imageUrl,
          "academic_years": selectedAcademicYears.map((e) => e.id).toList(),
          "abbreviation": collegeAbbreviationController.text,
          "duration_years": int.tryParse(durationController.text) ?? 4,
          "internship_years": int.tryParse(internshipController.text) ?? 0,
        };
        
        log("FINAL DATA TO SAVE: $data");

        if (collegeId == null) {
          log("Mode: INSERT");
          data["added_by"] = getIt<SupabaseClient>().auth.currentUser?.id ?? "715d235b-a0d4-467b-9174-d1cd934645f7";
          data["created_at"] = DateTime.now().toString();
          await getIt<SupabaseClient>().from('colleges').insert(data);
        } else {
          log("Mode: UPDATE for ID: $collegeId");
          await getIt<SupabaseClient>().from('colleges').update(data).eq('id', collegeId!);
        }
        
        log("Database update finished. Refreshing list...");
        if (collegesCubit != null) {
          await collegesCubit!.getColleges();
        }

        log("College saved and list refreshed successfully!");
        emit(AddCollegeSuccess());
      } catch (e, stack) {
        log("CRITICAL ERROR saving college: $e");
        log(stack.toString());
        emit(AddCollegeError(message: "Failed to save: $e"));
      }
    }
  }
  /////////////////////////////////

  @override
  Future<void> close() {
    collegeNameController.dispose();
    collegeAbbreviationController.dispose();
    return super.close();
  }
}
