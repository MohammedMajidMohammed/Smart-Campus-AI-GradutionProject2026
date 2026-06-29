import 'dart:developer';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/app/my_app.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/network/supabase/auth/sign_in_with_google.dart';
import 'package:smart_canvas/core/network/supabase/auth/sign_in_with_password.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(SignInInitial()) {
    loadSavedCredentials();
  }

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = getIt<SupabaseClient>();
  UserModel? userModel;
  bool isRememberMeChecked = true;

  void toggleRememberMe(bool value) {
    isRememberMeChecked = value;
    emit(SignInInitial());
  }

  void loadSavedCredentials() {
    final remember = getIt<CacheHelper>().getData(key: 'remember_me') == true;
    if (remember) {
      isRememberMeChecked = true;
      final savedUser = getIt<CacheHelper>().getData(key: 'saved_username') as String?;
      final savedPass = getIt<CacheHelper>().getData(key: 'saved_password') as String?;
      if (savedUser != null) emailController.text = savedUser;
      if (savedPass != null) passwordController.text = savedPass;
    }
  }

  // Sign in Method (Supports ID and Email)
  Future<void> signIn() async {
    if (formKey.currentState?.validate() ?? false) {
      try {
        emit(SignInLoading());
        FocusScope.of(navigatorKey.currentContext!).unfocus();
        
        String input = emailController.text.trim();
        String password = passwordController.text.trim();
        String loginEmail = input;

        // If the input does not look like an email (e.g. doesn't contain '@'), look up the email by ID
        if (!input.contains('@')) {
          try {
            final response = await supabase.rpc(
              'get_email_by_university_id',
              params: {'p_university_id': input},
            );
            if (response != null && response is List && response.isNotEmpty) {
              loginEmail = response.first['email']?.toString() ?? input;
            } else if (response != null && response is String && response.isNotEmpty) {
              loginEmail = response;
            } else {
              // Try querying the users table directly in case the RPC function wasn't created yet
              final directQuery = await supabase
                  .from('users')
                  .select('email')
                  .eq('university_id', input)
                  .maybeSingle();
              if (directQuery != null && directQuery['email'] != null) {
                loginEmail = directQuery['email'] as String;
              } else {
                throw Exception("No account matches this Student ID");
              }
            }
          } catch (rpcErr) {
            // Fallback direct query if RPC fails
            try {
              final directQuery = await supabase
                  .from('users')
                  .select('email')
                  .eq('university_id', input)
                  .maybeSingle();
              if (directQuery != null && directQuery['email'] != null) {
                loginEmail = directQuery['email'] as String;
              } else {
                throw Exception("Student ID not found: $rpcErr");
              }
            } catch (fallbackErr) {
              throw Exception("ID lookup failed. Please use your email to log in.");
            }
          }
        }

        await signInWithPassword(
          email: loginEmail,
          password: password,
        );

        if (supabase.auth.currentUser == null) {
          throw Exception("Sign in failed: No user found");
        }
        await getUserData();

        // Save credentials if Remember Me is checked
        if (isRememberMeChecked) {
          await getIt<CacheHelper>().saveData(key: 'saved_username', value: input);
          await getIt<CacheHelper>().saveData(key: 'saved_password', value: password);
          await getIt<CacheHelper>().saveData(key: 'remember_me', value: true);
        } else {
          await getIt<CacheHelper>().removeData(key: 'saved_username');
          await getIt<CacheHelper>().removeData(key: 'saved_password');
          await getIt<CacheHelper>().saveData(key: 'remember_me', value: false);
        }

        emit(SignInSuccess(route: getScreenRoute()));
      } on Exception catch (e) {
        emit(SignInFailure(message: e.toString()));
      }
    } else {
      emit(SignInFailure(message: "Please fill all required fields correctly"));
    }
  }

  // Face ID sign in method
  Future<void> signInWithFaceID() async {
    try {
      emit(SignInLoading());
      
      final savedUser = getIt<CacheHelper>().getData(key: 'saved_username') as String?;
      final savedPass = getIt<CacheHelper>().getData(key: 'saved_password') as String?;
      
      if (savedUser == null || savedPass == null) {
        throw Exception(EasyLocalization.of(navigatorKey.currentContext!)?.currentLocale?.languageCode == 'ar'
            ? "يرجى تسجيل الدخول بكلمة المرور أولاً لتفعيل بصمة الوجه."
            : "Please log in with password first to enable Face ID.");
      }

      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (photo == null) {
        emit(SignInInitial());
        return;
      }

      emit(SignInLoading()); // Show loader during AI matching

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://adhamohamed-fast-api.hf.space/recognize"),
      );
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception("Server connection error: Code ${response.statusCode}");
      }

      var data = jsonDecode(response.body);
      if (data['found'] != true) {
        throw Exception("Face not recognized. Please try again.");
      }

      String recognizedName = data['name'];
      log("Face recognized: $recognizedName");

      // Verify names match
      String loginEmail = savedUser;
      if (!savedUser.contains('@')) {
        final lookup = await supabase.from('users').select('email, full_name').eq('university_id', savedUser).maybeSingle();
        if (lookup != null) {
          loginEmail = lookup['email'] as String;
          final String fullName = lookup['full_name'] as String;
          if (!fullName.toLowerCase().contains(recognizedName.toLowerCase())) {
            throw Exception("Face matches '$recognizedName', but doesn't match the current saved account.");
          }
        }
      } else {
        final lookup = await supabase.from('users').select('full_name').eq('email', savedUser).maybeSingle();
        if (lookup != null) {
          final String fullName = lookup['full_name'] as String;
          if (!fullName.toLowerCase().contains(recognizedName.toLowerCase())) {
            throw Exception("Face matches '$recognizedName', but doesn't match the current saved account.");
          }
        }
      }

      await signInWithPassword(
        email: loginEmail,
        password: savedPass,
      );
      
      if (supabase.auth.currentUser == null) {
        throw Exception("Face ID Sign in failed: No user session found");
      }
      
      await getUserData();
      emit(SignInSuccess(route: getScreenRoute()));

    } on Exception catch (e) {
      emit(SignInFailure(message: e.toString()));
    } catch (e) {
      emit(SignInFailure(message: "Face ID connection failed: $e"));
    }
  }

  Future<void> getUserData() async {
    try {
      final res = await supabase.rpc(
        'get_user_with_role',
        params: {'p_user_id': supabase.auth.currentUser!.id},
      );
      final data = res as List;
      final user = data.first;
      log(user.toString());
      if (user.isEmpty) {
        throw Exception("User not found");
      }
      userModel = UserModel.fromJson(user);
      log("User Model Data: college_id=${userModel!.collegeId}, academic_year_id=${userModel!.academicYearId}, year_level=${userModel!.yearLevel}");
      await getIt<CacheHelper>().saveUserModel(userModel!);
    } catch (e) {
      log("SignInCubit Log Error: $e");
      throw Exception("Failed to fetch user data: $e");
    }
  }

  // get screen route
  String getScreenRoute() {
    final roleName = (userModel?.roleName ?? '').trim().toLowerCase();
    if (roleName == "student") {
      return RouteNames.studentHomeScreen;
    } else if (roleName == "administrator") {
      return RouteNames.administratorHomeScreen;
    } else if (roleName == "professor") {
      return RouteNames.professorHomeScreen;
    } else if (roleName == "admin") {
      return RouteNames.doctorHomeScreen;
    } else {
      return RouteNames.doctorHomeScreen;
    }
  }

  // sign in with google
  Future<void> signInWithGoogle() async {
    try {
      emit(SignInWithGoogleLoading());
      await getIt<GoogleAuthService>().signWithGoogle();
      if (supabase.auth.currentUser == null) {
        throw Exception("Google sign in failed: No user found");
      }
      await getUserData(); // Fetch user data after Google sign-in to set userModel and role
      emit(SignInWithGoogleSuccess(route: getScreenRoute()));
    } on Exception catch (e) {
      emit(SignInWithGoogleFailure(message: e.toString()));
    }
  }

  // Dispose Controllers
  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
