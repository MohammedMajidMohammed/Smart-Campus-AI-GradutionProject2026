part of 'users_cubit.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

// Fetch Users States
class UsersLoading extends UsersState {}

class UsersSuccess extends UsersState {
  final List<UserModel> users;
  UsersSuccess({required this.users});
}

class UsersFailure extends UsersState {
  final String message;
  UsersFailure({required this.message});
}

// Fetch Roles States
class RolesLoading extends UsersState {}

class RolesSuccess extends UsersState {}

class RolesFailure extends UsersState {
  final String message;
  RolesFailure({required this.message});
}

// Create User States
class CreateUserLoading extends UsersState {}

class CreateUserSuccess extends UsersState {}

class CreateUserFailure extends UsersState {
  final String message;
  CreateUserFailure({required this.message});
}

// Delete User States
class DeleteUserLoading extends UsersState {}

class DeleteUserSuccess extends UsersState {}

class DeleteUserFailure extends UsersState {
  final String message;
  DeleteUserFailure({required this.message});
}

// Update User States
class UpdateUserLoading extends UsersState {}

class UpdateUserSuccess extends UsersState {}

class UpdateUserFailure extends UsersState {
  final String message;
  UpdateUserFailure({required this.message});
}

// Edit Mode State
class EditUserLoaded extends UsersState {
  final UserModel user;
  EditUserLoaded({required this.user});
}

// Image Picker States
class PickImageSuccess extends UsersState {}

class PickImageFailure extends UsersState {
  final String message;
  PickImageFailure({required this.message});
}

// College & Academic Year States
class CollegesLoadedSuccess extends UsersState {}

class AcademicYearsUpdated extends UsersState {}

// Password Reset States
class PasswordResetLoading extends UsersState {}

class PasswordResetSuccess extends UsersState {}

class PasswordResetFailure extends UsersState {
  final String message;
  PasswordResetFailure({required this.message});
}

