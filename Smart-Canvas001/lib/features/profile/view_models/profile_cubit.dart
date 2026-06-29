import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/profile/view_models/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadUserProfile() async {
    print('🔵 loadUserProfile called');
    emit(ProfileLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('🔴 ERROR: User not logged in');
        if (isClosed) return;
        emit(ProfileUpdateFailure("User not logged in"));
        return;
      }

      print('🔵 Fetching user data for: ${user.id}');
      // Fetch user data with roles - Using 'role' alias to match UserModel.fromJson
      final userData = await _supabase
          .from('users')
          .select('*, role:roles(*)')
          .eq('id', user.id)
          .single();
      
      // Inject email from auth if not present in public table
      if (user.email != null) {
        userData['email'] = user.email;
      }

      print('✅ User data loaded: $userData');
      
      // Update CacheHelper so other cubits (like StudentScheduleCubit) get updated data
      try {
        final userModel = UserModel.fromJson(userData);
        await getIt<CacheHelper>().saveUserModel(userModel);
        print('✅ CacheHelper updated with fresh user data');
      } catch (cacheError) {
        print('⚠️ Failed to update CacheHelper: $cacheError');
      }

      // If user has college_id, fetch college data separately
      if (userData['college_id'] != null) {
        print('🔵 Fetching college data for college_id: ${userData['college_id']}');
        try {
          final college = await _supabase
              .from('colleges')
              .select('id, name, abbreviation')
              .eq('id', userData['college_id'])
              .single();
          
          // Add college data to userData
          userData['colleges'] = college;
          print('✅ College data added: $college');
        } catch (e) {
          print('⚠️ Could not fetch college: $e');
        }
      }
      
      if (isClosed) return;
      emit(ProfileLoaded(userData));
    } catch (e) {
      print('🔴 ERROR loading profile: $e');
      if (isClosed) return;
      emit(ProfileUpdateFailure(e.toString()));
    }
  }

  Future<void> updateProfile({
    required String name, 
    required String phone,
    String? collegeId,
    String? academicYearId,
    int? yearLevel,
  }) async {
    print('🔵 updateProfile called: name=$name, phone=$phone, college=$collegeId, program=$academicYearId, year=$yearLevel');
    emit(ProfileLoading());
    try {
      final user = _supabase.auth.currentUser;
      print('🔵 Current user: ${user?.id}');
      if (user == null) {
        print('🔴 ERROR: User is null!');
        if (isClosed) return;
        emit(ProfileUpdateFailure('User not logged in'));
        return;
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'full_name': name,
        'phone_number': phone,
      };
      
      // Add optional fields
      if (collegeId != null) updateData['college_id'] = collegeId;
      if (academicYearId != null) updateData['academic_year_id'] = academicYearId;
      if (yearLevel != null) updateData['year_level'] = yearLevel;

      print('🔵 Updating users table with data: $updateData');
      
      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select(); // Add select to get response
      
      print('✅ Update response: $response');
      
      // Also update auth metadata if needed
      print('🔵 Updating auth metadata...');
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': name},
        ),
      );
      print('✅ Auth metadata updated');

      if (isClosed) return;
      emit(ProfileUpdateSuccess("Profile updated successfully"));
      print('✅ Profile update successful, reloading profile...');
      await loadUserProfile(); // Await the reload
    } catch (e) {
      print('🔴 ERROR updating profile: $e');
      if (isClosed) return;
      emit(ProfileUpdateFailure(e.toString()));
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    print('🔵 uploadProfileImage called with file: ${imageFile.path}');
    emit(ProfileImageUploadLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('🔴 ERROR: User not logged in');
        if (isClosed) return;
        emit(ProfileImageUploadFailure('User not logged in'));
        return;
      }

      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/$timestamp.$fileExt';

      print('🔵 Reading file bytes...');
      final bytes = await imageFile.readAsBytes();
      print('✅ File size: ${bytes.length} bytes');

      print('🔵 Attempting upload to avatars bucket: $fileName');
      
      String? imageUrl;
      
      try {
        // Method 1: Try creating signed upload URL (bypasses RLS)
        print('🔵 Method 1: Trying signed upload URL...');
        final signedUrl = await _supabase.storage
            .from('avatars')
            .createSignedUploadUrl(fileName);
        
        print('✅ Got signed URL: ${signedUrl.path}');
        
        // Upload using signed URL (expects File, not bytes)
        await _supabase.storage
            .from('avatars')
            .uploadToSignedUrl(
              signedUrl.path,
              signedUrl.token,
              imageFile,
            );
        
        imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
        print('✅ Uploaded via signed URL successfully');
        
      } catch (signedUrlError) {
        print('⚠️ Signed URL method failed: $signedUrlError');
        
        try {
          // Method 2: Try uploadBinary with upsert
          print('🔵 Method 2: Trying uploadBinary...');
          await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );
          imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
          print('✅ Uploaded via uploadBinary successfully');
          
        } catch (uploadBinaryError) {
          print('⚠️ uploadBinary failed: $uploadBinaryError');
          
          // Method 3: Try regular upload
          print('🔵 Method 3: Trying regular upload...');
          await _supabase.storage.from('avatars').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
          imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
          print('✅ Uploaded via regular upload successfully');
        }
      }



      print('🔵 Public URL: $imageUrl');

      // Update user image in database
      print('🔵 Updating image in users table...');
      try {
        final updateResult = await _supabase
            .from('users')
            .update({'image': imageUrl})
            .eq('id', user.id)
            .select()
            .single();
        
        print('✅ Database updated: $updateResult');
        
        // IMPORTANT: Directly update the state with the new image URL 
        // while also reloading everything to be safe.
        if (isClosed) return;
        emit(ProfileImageUploadSuccess(imageUrl));
        
        // Update the current state if it's ProfileLoaded
        if (state is ProfileLoaded) {
          final currentData = Map<String, dynamic>.from((state as ProfileLoaded).userData);
          currentData['image'] = imageUrl;
          if (isClosed) return;
          emit(ProfileLoaded(currentData));
          print('✅ State updated with new image URL locally');
        }
        
      } catch (dbError) {
        print('🔴 Database update failed: $dbError');
        throw Exception('Failed to update profile image in database: $dbError');
      }

      print('✅ Reloading profile from server for full sync...');
      await loadUserProfile();
    } catch (e) {
      print('🔴 ERROR uploading image: $e');
      String errorMsg = 'فشل رفع الصورة';
      
      if (e.toString().contains('Bucket not found')) {
        errorMsg = 'الرجاء إنشاء bucket اسمه avatars في Supabase Storage';
      } else if (e.toString().contains('row-level security')) {
        errorMsg = 'خطأ في الصلاحيات - تواصل مع مطور النظام لحل مشكلة RLS';
      }
      
      if (isClosed) return;
      emit(ProfileImageUploadFailure(errorMsg));
    }
  }

  Future<void> changePassword({required String newPassword}) async {
    emit(PasswordChangeLoading());
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      if (isClosed) return;
      emit(PasswordChangeSuccess("Password changed successfully"));
    } catch (e) {
      if (isClosed) return;
      emit(PasswordChangeFailure(e.toString()));
    }
  }
}
