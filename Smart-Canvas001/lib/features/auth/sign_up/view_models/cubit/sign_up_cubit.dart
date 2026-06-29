import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_canvas/app/my_app.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/network/supabase/auth/sign_in_with_google.dart';
import 'package:smart_canvas/core/network/supabase/auth/sign_up_with_password.dart';
import 'package:smart_canvas/core/network/supabase/database/add_data.dart';
import 'package:smart_canvas/core/network/supabase/storage/upload_file.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(SignUpInitial()) {
    init();
  }

  /// Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final universityIdController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Variables
  String? collegeId;
  String? academicYearId;
  File? image;

  final supabase = getIt<SupabaseClient>();

  List<CollegeModel> colleges = [];
  List<AcademicYearModel> availableAcademicYears = [];
  List<AcademicYearModel> selectedAcademicYears = [];

  /// ================= INIT =================
  Future<void> init() async {
    final roleName = getIt<CacheHelper>().getData(key: "role_name");

    if (roleName == "Student") {
      emit(GetCollegesLoading());
      try {
        final response = await supabase.rpc('get_colleges_full');

        if (response == null) {
          emit(GetCollegesFailure(errorMessage: "No colleges found"));
          return;
        }

        final List data = response as List;
        colleges = data.map((e) => CollegeModel.fromJson(e)).toList();

        emit(GetCollegesSuccess());
      } catch (e) {
        emit(GetCollegesFailure(errorMessage: e.toString()));
      }
    }
  }

  List<int> availableYearLevels = [];
  int? yearLevel;

  /// ================= COLLEGE =================
  Future<void> selectCollege({required CollegeModel college}) async {
    collegeId = college.id;
    academicYearId = null;
    selectedAcademicYears.clear();
    availableAcademicYears = [];
    
    // Reset Year Level
    yearLevel = null; 
    availableYearLevels = [];
    
    // Generate Year Levels based on duration
    final duration = college.durationYears ?? 5; // Default to 5 if null
    availableYearLevels = List.generate(duration, (index) => index + 1);

    // Prioritize safe fetching using raw academic year IDs (prevents "all programs" issue)
    if (college.rawAcademicYearIds != null && college.rawAcademicYearIds!.isNotEmpty) {
      try {
        final response = await supabase
            .from('academic_years')
            .select()
            .inFilter('id', college.rawAcademicYearIds!);

        final List data = response as List;
        availableAcademicYears = data.map((e) => AcademicYearModel.fromJson(e)).toList();
              emit(GetAcademicYearsSuccess());
      } catch (e) {
        log("Error fetching programs: $e");
        emit(GetCollegesFailure(errorMessage: "Failed to load programs"));
      }
    } 
    // Fallback if model already has valid object list (and we didn't fetch above)
    else if (college.academicYears != null && college.academicYears!.isNotEmpty) {
      availableAcademicYears = college.academicYears!;
      emit(GetAcademicYearsSuccess());
    } else {
      // No programs available
      emit(GetAcademicYearsSuccess());
    }
  }

  void toggleAcademicYear(AcademicYearModel year) {
    selectedAcademicYears
      ..clear()
      ..add(year);
    academicYearId = year.id;
    emit(AcademicYearsUpdated());
  }

  void selectYearLevel(int level) {
    yearLevel = level;
    emit(AcademicYearsUpdated()); // Re-use state or create specific one
  }

  /// ================= SIGN UP =================
  Future<void> signUp() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      emit(SignUpFailure(
          errorMessage: "Please fill all required fields correctly"));
      return;
    }

    final roleName = getIt<CacheHelper>().getData(key: "role_name");

    if (roleName == "Student") {
      if (collegeId == null) {
        emit(SignUpFailure(errorMessage: "Please select a college"));
        return;
      }
      if (academicYearId == null) {
        emit(SignUpFailure(errorMessage: "Please select an academic year"));
        return;
      }
      if (yearLevel == null) {
        emit(SignUpFailure(errorMessage: "Please select your year level"));
        return;
      }
    }

    if (image == null) {
      emit(PickImageFailure(errorMessage: "Please select a profile image"));
      return;
    }

    try {
      emit(SignUpLoading());

      FocusScope.of(navigatorKey.currentContext!).unfocus();

      await signUpWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (supabase.auth.currentUser == null) {
        throw Exception("Sign up failed: No user created");
      }

      /// 2️⃣ Upload Image
      final String? imageUrl = await uploadFileToSupabaseStorage(
        file: image!,
        pucketName: "user-avatars",
      );

      /// 3️⃣ Insert User Data
      await addData(
        tableName: "users",
        data: {
          "id": supabase.auth.currentUser!.id,
          "full_name": fullNameController.text.trim(),
          "phone_number": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "role_id": getIt<CacheHelper>().getData(key: "role_id"),
          "image": imageUrl,
          if (collegeId != null) "college_id": collegeId,
          if (academicYearId != null) "academic_year_id": academicYearId,
          if (yearLevel != null) "year_level": yearLevel,
          if (universityIdController.text.isNotEmpty) "university_id": universityIdController.text.trim(),
        },
      );

      emit(SignUpSuccess(route: RouteNames.signInScreen));
    } catch (e) {
      log("SIGN UP ERROR: $e");
      emit(SignUpFailure(errorMessage: e.toString()));
    }
  }

  /// ================= IMAGE =================
  void pickProfileImage() {
    pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        image = value;
        emit(PickImageSuccess());
      } else {
        emit(PickImageFailure(errorMessage: "No image selected"));
      }
    });
  }

  /// ================= GOOGLE =================
  Future<void> signUpWithGoogle() async {
    try {
      emit(SignUpWithGoogleLoading());

      await getIt<GoogleAuthService>().signWithGoogle();

      emit(SignUpWithGoogleSuccess());
    } catch (e) {
      emit(SignUpWithGoogleFailure(errorMessage: e.toString()));
    }
  }

  /// ================= DISPOSE =================
  @override
  Future<void> close() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    universityIdController.dispose();
    return super.close();
  }
}