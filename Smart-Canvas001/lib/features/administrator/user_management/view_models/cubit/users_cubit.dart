import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/helper/pick_image.dart';
import 'package:smart_canvas/core/network/supabase/storage/upload_file.dart';
import 'package:smart_canvas/features/administrator/collages/models/academic_year_model.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';
import 'package:smart_canvas/features/administrator/user_management/models/user_model.dart';
import 'package:smart_canvas/features/auth/select_role/views/screens/select_role_screen.dart';
import 'package:smart_canvas/core/services/presence_service.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit() : super(UsersInitial()) {
    init();
  }

  final supabase = getIt<SupabaseClient>();

  // Controllers for creating new user
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final universityIdController = TextEditingController();
  final searchController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Data lists
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  List<RoleModel> roles = [];
  List<RoleModel> allRoles = [];
  List<CollegeModel> colleges = [];
  List<AcademicYearModel> availableAcademicYears = [];
  Set<String> onlineUserIds = {};

  // Selected values
  String? selectedRoleId;
  String? selectedCollegeId;
  String? selectedAcademicYearId;
  int? selectedYear;
  File? selectedImage;
  String? selectedRoleFilter;

  /// Initialize - fetch users and roles
  Future<void> init() async {
    // 1. Fetch dependencies first (Needed for manual mapping in fetchUsers)
    await Future.wait([
      fetchRoles(),
      fetchColleges(),
    ]);
    
    // 2. Fetch users and map their names
    await fetchUsers();

    // 3. Start real-time presence tracking
    startPresenceTracking();
  }

  void startPresenceTracking() {
    onlineUserIds = PresenceService.instance.onlineUserIds.value;
    PresenceService.instance.onlineUserIds.addListener(_onPresenceChanged);
  }

  void _onPresenceChanged() {
    onlineUserIds = PresenceService.instance.onlineUserIds.value;
    _applyFilters(searchQuery: searchController.text);
    emit(UsersSuccess(users: List.from(filteredUsers)));
  }

  /// Fetch all users with their role info
  Future<void> fetchUsers() async {
    try {
      emit(UsersLoading());
      
      // Debug: Check authentication status
      final currentUser = supabase.auth.currentUser;
      log('Current user: ${currentUser?.id ?? "NOT LOGGED IN"}');
      log('Auth session: ${supabase.auth.currentSession != null ? "EXISTS" : "NULL"}');
      
      log('Attempting to fetch users from Supabase...');

      // Ensure dependencies are loaded for manual mapping if join fails
      if (allRoles.isEmpty || colleges.isEmpty) {
        log('Dependencies missing, fetching roles and colleges...');
        await Future.wait([fetchRoles(), fetchColleges()]);
      }
      
      // Try full query with relations first
      try {
        final response = await supabase
            .from('users')
            .select('*, roles(name), colleges(name), academic_years(name)')
            .order('created_at', ascending: false);

        log('Users query successful, count: ${(response as List).length}');
        
        users = response
            .map((json) => UserModel.fromJson(json))
            .toList();
        
        _manuallyMapUserNames();

        emit(UsersSuccess(users: filteredUsers));
      } catch (joinError) {
        // Fallback: try simpler query without joins
        log('Join query failed, trying simple query: $joinError');
        
        final simpleResponse = await supabase
            .from('users')
            .select('*')
            .order('created_at', ascending: false);

        log('Simple users query successful, count: ${(simpleResponse as List).length}');
        
        users = simpleResponse
            .map((json) => UserModel.fromJson(json))
            .toList();
        
        // Manual Mapping: Fill names from local lists
        _manuallyMapUserNames();
        
        emit(UsersSuccess(users: filteredUsers));
      }
    } catch (e) {
      log('Error fetching users: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Permission denied') || 
          errorMessage.contains('RLS') ||
          errorMessage.contains('policy')) {
        errorMessage = 'Permission denied. Check Supabase RLS policies.';
      } else if (errorMessage.contains('network') || 
                 errorMessage.contains('connection') ||
                 errorMessage.contains('SocketException')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else if (errorMessage.contains('table') || 
                 errorMessage.contains('relation')) {
        errorMessage = 'Database table not found. Check Supabase setup.';
      }
      emit(UsersFailure(message: errorMessage));
    }
  }

  void searchUsers(String query) {
    _applyFilters(searchQuery: query);
    emit(UsersSuccess(users: filteredUsers));
  }

  void filterByRole(String? roleName) {
    selectedRoleFilter = roleName;
    _applyFilters();
    emit(UsersSuccess(users: filteredUsers));
  }

  void _applyFilters({String? searchQuery}) {
    final query = (searchQuery ?? '').toLowerCase();

    filteredUsers = users.where((user) {
      final matchesSearch = user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.universityId?.toLowerCase().contains(query) ?? false);

      // Robust Role Matching: Check both user.roleName AND if we have a match in allRoles list
      String? actualRoleName = user.roleName;
      if (actualRoleName == null && allRoles.isNotEmpty) {
        final role = allRoles.firstWhere((r) => r.id == user.roleId, orElse: () => RoleModel(id: '', name: ''));
        if (role.id.isNotEmpty) actualRoleName = role.name;
      }

      final matchesRole = selectedRoleFilter == null ||
          actualRoleName?.toLowerCase() == selectedRoleFilter!.toLowerCase();

      return matchesSearch && matchesRole;
    }).toList();
  }

  /// Manually fill names if join failed
  void _manuallyMapUserNames() {
    final List<UserModel> mappedList = [];
    for (var i = 0; i < users.length; i++) {
        final user = users[i];
        String? roleName = user.roleName;
        String? collageName = user.collegeName;

        if (roleName == null && allRoles.isNotEmpty) {
          roleName = allRoles.firstWhere((r) => r.id == user.roleId, orElse: () => RoleModel(id: '', name: '')).name;
        }



        if (collageName == null && colleges.isNotEmpty && user.collegeId != null) {
          final matchedCollege = colleges.firstWhere(
            (c) => c.id == user.collegeId, 
            orElse: () => CollegeModel(id: 'NONE', name: '', academicYears: [], abbreviation: '', image: '', createdAt: DateTime.now())
          );
          if (matchedCollege.id != 'NONE') {
            collageName = matchedCollege.name;
          }
        }

        mappedList.add(UserModel(
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: user.phoneNumber,
          roleId: user.roleId,
          roleName: roleName ?? user.roleName,
          image: user.image,
          collegeId: user.collegeId,
          collegeName: collageName ?? user.collegeName,
          academicYearId: user.academicYearId,
          academicYearName: user.academicYearName,
          currentYear: user.currentYear,
          universityId: user.universityId,
          createdAt: user.createdAt,
        ));
    }
    users = mappedList;
    // Sync filtered list with updated users
    _applyFilters(searchQuery: searchController.text);
  }

  /// Fetch all roles
  Future<void> fetchRoles() async {
    try {
      emit(RolesLoading());

      final response = await supabase
          .from('roles')
          .select('id, name, image')
          .order('created_at', ascending: false);

      allRoles = (response as List)
          .map((json) => RoleModel.fromJson(json))
          .toList();

      roles = allRoles;

      emit(RolesSuccess());
      
      // If users already fetched, try to map their names now
      if (users.isNotEmpty) {
        _manuallyMapUserNames();
        emit(UsersSuccess(users: List.from(filteredUsers)));
      }
    } catch (e) {
      log('Error fetching roles: $e');
      emit(RolesFailure(message: e.toString()));
    }
  }

  /// Fetch all colleges
  Future<void> fetchColleges() async {
    try {
      log('Fetching colleges (Manual Join Strategy)...');

      // 1. Fetch Colleges (Raw)
      final collegesResponse = await supabase
          .from('colleges')
          .select()
          .order('created_at', ascending: false);

      final List<CollegeModel> rawColleges = (collegesResponse as List)
          .map((e) => CollegeModel.fromJson(e))
          .toList();

      // 2. Fetch Academic Years (Raw)
      final yearsResponse = await supabase
          .from('academic_years')
          .select()
          .order('created_at', ascending: false);
          
      final List<AcademicYearModel> allYears = (yearsResponse as List)
          .map((e) => AcademicYearModel.fromJson(e))
          .toList();

      if (yearsResponse.isNotEmpty) {
        final firstYear = yearsResponse.first;
        log('DEBUG: First Academic Year Raw Keys: ${firstYear.keys.toList()}');
        log('DEBUG: First Academic Year raw college_id: ${firstYear['college_id']}');
        log('DEBUG: First Academic Year raw collage_id: ${firstYear['collage_id']}');
      }

      log('Raw Colleges count: ${rawColleges.length}');
      log('Raw Academic Years count: ${allYears.length}');
      if (allYears.isNotEmpty) {
        log('Sample Year: ID=${allYears.first.id}, CollegeID=${allYears.first.collegeId}');
      }

      // 3. Manual Join
      // 3. Manual Join (Dual Strategy)
      colleges = rawColleges.map((college) {
        List<AcademicYearModel> collegeYears = [];
        
        // Strategy A: Check if Child (Year) points to Parent (College)
        collegeYears = allYears.where((year) => year.collegeId == college.id).toList();
        
        // Strategy B: Check if Parent (College) points to Children (Years) via Array
        if (collegeYears.isEmpty && college.rawAcademicYearIds != null) {
          collegeYears = allYears.where((year) => college.rawAcademicYearIds!.contains(year.id)).toList();
        }
        
        log('College [${college.name}] (ID: ${college.id}) -> Joined ${collegeYears.length} depts/years');

        // Return updated model using copyWith
        return college.copyWith(academicYears: collegeYears);
      }).toList();
      
      log('Successfully joined ${colleges.length} colleges with their years.');
      // Trigger manual mapping since we got new college data
      if (users.isNotEmpty) {
        _manuallyMapUserNames();
        emit(UsersSuccess(users: List.from(filteredUsers)));
      }
      
      emit(CollegesLoadedSuccess());

    } catch (e) {
      log('Error fetching colleges (Manual): $e');
      // If even this fails, empty list
      colleges = []; 
      emit(CollegesLoadedSuccess()); // Emit success to avoid UI blocking, just empty
    }
  }

  /// Select role for new user
  void selectRole(String roleId) {
    selectedRoleId = roleId;
    // Clear college/year if not student, professor, or admin role
    if (!isStudentRole && !isProfessorRole && !isAdminRole) {
      selectedCollegeId = null;
      selectedAcademicYearId = null;
      selectedYear = null;
      availableAcademicYears = [];
    }
    emit(RolesSuccess());
  }

  /// Select college for student (Fetch departments on demand)
  Future<void> selectCollege(CollegeModel college) async {
    selectedCollegeId = college.id;
    selectedAcademicYearId = null;
    selectedYear = null;
    availableAcademicYears = [];
    
    emit(RolesLoading()); // Show small loading state

    try {
      log('Fetching academic years for college: ${college.id}');
      
      dynamic response;
      
      try {
        // Attempt 1: Try 'college_id' (Correct spelling)
        response = await supabase
            .from('academic_years')
            .select()
            .eq('college_id', college.id);
      } catch (e) {
        log('Query with college_id failed (${e.toString()}), switching to collage_id...');
        
        // Attempt 2: Try 'collage_id' (Legacy/Typo spelling)
        response = await supabase
            .from('academic_years')
            .select()
            .eq('collage_id', college.id);
      }

      if (response != null) {
        availableAcademicYears = (response as List)
            .map((e) => AcademicYearModel.fromJson(e))
            .toList();
            
        log('Fetched ${availableAcademicYears.length} academic years');
      }

    } catch (e) {
      log('Error fetching academic years (Both attempts failed): $e');
      availableAcademicYears = [];
    }

    emit(CollegesLoadedSuccess());
  }

  /// Select academic year (Specialization/Department) for student
  void selectAcademicYear(String yearId) {
    selectedAcademicYearId = yearId;
    emit(AcademicYearsUpdated());
  }

  /// Select academic level (Year 1, 2, 3...)
  void selectYear(int year) {
    selectedYear = year;
    emit(AcademicYearsUpdated());
  }

  /// Pick profile image
  void pickProfileImage() {
    pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        selectedImage = value;
        emit(PickImageSuccess());
      } else {
        emit(PickImageFailure(message: "No image selected"));
      }
    });
  }

  /// Create new user (Admin creates account)
  Future<void> createUser() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      emit(CreateUserFailure(message: "Please fill all required fields"));
      return;
    }

    if (selectedRoleId == null) {
      emit(CreateUserFailure(message: "Please select a role"));
      return;
    }

    // Check if student/professor/admin needs college
    if (isStudentRole || isProfessorRole || isAdminRole) {
      if (selectedCollegeId == null) {
        emit(CreateUserFailure(message: "Please select a college"));
        return;
      }
    }

    // Student specific requirements
    if (isStudentRole) {
      if (selectedAcademicYearId == null) {
        emit(CreateUserFailure(message: "Please select a specialization"));
        return;
      }
      if (selectedYear == null) {
        emit(CreateUserFailure(message: "Please select an academic year"));
        return;
      }
    }

    try {
      emit(CreateUserLoading());

      // 1. Create a temporary Supabase client to create the user without logging out the admin
      final tempClient = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      final authResponse = await tempClient.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception("Failed to create user account");
      }

      final userId = authResponse.user!.id;

      // 2. Upload image if selected
      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await uploadFileToSupabaseStorage(
          file: selectedImage!,
          pucketName: "user-avatars",
        );
      }

      // 3. Insert user data
      await supabase.from('users').insert({
        'id': userId,
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'role_id': selectedRoleId,
        'image': imageUrl,
        if (selectedCollegeId != null) 'college_id': selectedCollegeId,
        if (selectedAcademicYearId != null) 'academic_year_id': selectedAcademicYearId,
        if (selectedYear != null) 'current_year': selectedYear,
        if (universityIdController.text.isNotEmpty) 'university_id': universityIdController.text.trim(),
      });

      // Reset form
      resetForm();
      
      // Refresh users list
      await fetchUsers();

      emit(CreateUserSuccess());
    } catch (e) {
      log('Error creating user: $e');
      emit(CreateUserFailure(message: e.toString()));
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      emit(DeleteUserLoading());
      
      await supabase.from('users').delete().eq('id', userId);
      await fetchUsers();

      emit(DeleteUserSuccess());
    } catch (e) {
      log('Error deleting user: $e');
      emit(DeleteUserFailure(message: e.toString()));
    }
  }

  // Currently editing user ID (for edit mode)
  String? editingUserId;
  String? editingUserEmail;
  
  // Controller for new password when resetting
  final newPasswordController = TextEditingController();

  /// Load user data for editing
  void loadUserForEdit(UserModel user) {
    editingUserId = user.id;
    editingUserEmail = user.email;
    fullNameController.text = user.fullName;
    emailController.text = user.email;
    phoneController.text = user.phoneNumber ?? '';
    universityIdController.text = user.universityId ?? '';
    newPasswordController.clear();
    selectedRoleId = user.roleId;
    selectedCollegeId = user.collegeId;
    selectedAcademicYearId = user.academicYearId;
    selectedYear = user.currentYear;
    selectedImage = null;
    
    // If student & college selected, populate academic years
    if (user.collegeId != null) {
      final college = colleges.firstWhere(
        (c) => c.id == user.collegeId, 
        orElse: () => CollegeModel(id: '', name: '', academicYears: [], abbreviation: '', image: '', createdAt: DateTime.now()),
      );
      availableAcademicYears = college.academicYears ?? [];
    } else {
      availableAcademicYears = [];
    }
    
    emit(EditUserLoaded(user: user));
  }

  /// Update existing user (role, name, college, etc.)
  Future<void> updateUser() async {
    try {
      if (editingUserId == null) {
        emit(UpdateUserFailure(message: 'No user selected for editing'));
        return;
      }

      emit(UpdateUserLoading());

      // 1. Reset Password if provided
      if (newPasswordController.text.trim().isNotEmpty) {
        final newPassword = newPasswordController.text.trim();
        if (newPassword.length < 6) {
          emit(UpdateUserFailure(message: 'Password must be at least 6 characters'));
          return;
        }
        
        log('🔵 [DIAGNOSTIC] Calling admin_reset_password for ID: $editingUserId');
        try {
          // Calling RPC and expecting a JSONB/Map response
          final response = await supabase.rpc('admin_reset_password', params: {
            'target_user_id': editingUserId!,
            'new_password': newPassword,
          });
          
          log('📊 [DIAGNOSTIC] RPC Response received: $response (type: ${response.runtimeType})');
          
          if (response == null) {
            emit(UpdateUserFailure(message: 'فشل تغيير كلمة السر: لم يتم استقبال أي رد من السيرفر (No Response)'));
            return;
          }

          // Handle Map/JSONB response
          if (response is Map) {
            final bool success = response['success'] ?? false;
            final String message = response['message'] ?? 'Unknown error from server';
            
            if (!success) {
              log('🔴 [DIAGNOSTIC] Server reported failure: $message');
              emit(UpdateUserFailure(message: 'فشل السيرفر: $message'));
              return;
            }
            log('✅ [DIAGNOSTIC] Server reported success: $message');
          } 
          // Handle String response (if they used the old SQL)
          else if (response is String) {
            if (!response.startsWith('Success')) {
              log('🔴 [DIAGNOSTIC] String response failure: $response');
              emit(UpdateUserFailure(message: 'فشل السيرفر: $response'));
              return;
            }
            log('✅ [DIAGNOSTIC] String success reported');
          } 
          else {
            log('⚠️ [DIAGNOSTIC] Unexpected response type: ${response.runtimeType}');
          }

        } catch (rpcError) {
          log('🔴 [DIAGNOSTIC] RPC Exception caught: $rpcError');
          String errorMsg = 'خطأ تقني في الربط: ';
          if (rpcError.toString().contains('404')) {
            errorMsg += 'الوظيفة غير موجودة في Supabase. تأكد من تنفيذ كود SQL.';
          } else {
            errorMsg += rpcError.toString();
          }
          emit(UpdateUserFailure(message: errorMsg));
          return;
        }
      }

      // 2. Update Auth email if changed
      if (emailController.text.trim() != editingUserEmail) {
        log('🔵 [DIAGNOSTIC] Updating Auth Email for ID: $editingUserId');
        await supabase.auth.admin.updateUserById(
          editingUserId!,
          attributes: AdminUserAttributes(email: emailController.text.trim()),
        );
      }

      // 3. Build table update map
      final updateData = <String, dynamic>{
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'role_id': selectedRoleId,
      };

      // Add optional fields if provided
      if (phoneController.text.isNotEmpty) {
        updateData['phone_number'] = phoneController.text.trim();
      }
      
      // Update university_id
      if (universityIdController.text.isNotEmpty) {
        updateData['university_id'] = universityIdController.text.trim();
      } else {
        updateData['university_id'] = null;
      }
      
      // Role-specific fields (Student, Professor & Admin)
      if (isStudentRole || isProfessorRole || isAdminRole) {
        if (selectedCollegeId != null) {
          updateData['college_id'] = selectedCollegeId;
        } else {
          updateData['college_id'] = null;
        }
        
        // Student & Professor only: Academic Year (Department)
        if (isStudentRole || isProfessorRole) {
          if (selectedAcademicYearId != null) {
            updateData['academic_year_id'] = selectedAcademicYearId;
          } else {
            updateData['academic_year_id'] = null;
          }
        } else {
          updateData['academic_year_id'] = null;
        }
        
        // Student only: Year level
        if (isStudentRole) {
          if (selectedYear != null) {
            updateData['current_year'] = selectedYear;
          }
        } else {
          updateData['current_year'] = null;
        }
      } else {
        // Clear all academic fields for other roles
        updateData['college_id'] = null;
        updateData['academic_year_id'] = null;
        updateData['current_year'] = null;
      }

      log('Updating user $editingUserId with data: $updateData');

      // Perform update
      await supabase
          .from('users')
          .update(updateData)
          .eq('id', editingUserId!);


      // Reset and refresh
      _resetEditForm();
      await fetchUsers();

      emit(UpdateUserSuccess());
    } catch (e) {
      log('Error updating user: $e');
      emit(UpdateUserFailure(message: e.toString()));
    }
  }

  /// Reset edit form
  void _resetEditForm() {
    editingUserId = null;
    editingUserEmail = null;
    newPasswordController.clear();
    resetForm();
  }

  /// Reset password for user (Admin function)
  Future<void> resetPasswordForUser() async {
    try {
      if (editingUserId == null) {
        emit(PasswordResetFailure(message: 'No user selected'));
        return;
      }

      final newPassword = newPasswordController.text.trim();
      if (newPassword.isEmpty) {
        emit(PasswordResetFailure(message: 'Please enter a new password'));
        return;
      }

      if (newPassword.length < 6) {
        emit(PasswordResetFailure(message: 'Password must be at least 6 characters'));
        return;
      }

      emit(PasswordResetLoading());

      log('Resetting password for user: $editingUserId');

      await supabase.auth.admin.updateUserById(
        editingUserId!,
        attributes: AdminUserAttributes(password: newPassword),
      );

      newPasswordController.clear();
      
      emit(PasswordResetSuccess());
    } catch (e) {
      log('Error resetting password: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('admin')) {
        errorMessage = 'Admin privileges required. Configure Supabase service role key.';
      }
      emit(PasswordResetFailure(message: errorMessage));
    }
  }

  /// Reset form for new user
  void resetForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    universityIdController.clear();
    selectedRoleId = null;
    selectedCollegeId = null;
    selectedAcademicYearId = null;
    selectedYear = null;
    selectedImage = null;
    availableAcademicYears = [];
  }

  /// Check if selected role is Student
  bool get isStudentRole {
    if (selectedRoleId == null) return false;
    final role = allRoles.firstWhere((r) => r.id == selectedRoleId, orElse: () => RoleModel(id: '', name: ''));
    return role.name.toLowerCase() == 'student';
  }

  /// Check if selected role is Professor
  bool get isProfessorRole {
    if (selectedRoleId == null) return false;
    final role = allRoles.firstWhere((r) => r.id == selectedRoleId, orElse: () => RoleModel(id: '', name: ''));
    return role.name.toLowerCase() == 'professor';
  }

  /// Check if selected role is Doctor
  bool get isDoctorRole {
    if (selectedRoleId == null) return false;
    final role = allRoles.firstWhere((r) => r.id == selectedRoleId, orElse: () => RoleModel(id: '', name: ''));
    return role.name.toLowerCase() == 'doctor';
  }

  /// Check if selected role is Admin
  bool get isAdminRole {
    if (selectedRoleId == null) return false;
    final role = allRoles.firstWhere((r) => r.id == selectedRoleId, orElse: () => RoleModel(id: '', name: ''));
    final name = role.name.toLowerCase();
    return name == 'admin' || name == 'administrator';
  }

  @override
  Future<void> close() {
    PresenceService.instance.onlineUserIds.removeListener(_onPresenceChanged);
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    universityIdController.dispose();
    return super.close();
  }
}
