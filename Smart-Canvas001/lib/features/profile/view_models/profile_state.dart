
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;

  ProfileLoaded(this.userData);
}

class ProfileUpdateSuccess extends ProfileState {
  final String message;

  ProfileUpdateSuccess(this.message);
}

class ProfileUpdateFailure extends ProfileState {
  final String error;

  ProfileUpdateFailure(this.error);
}

class PasswordChangeLoading extends ProfileState {}

class PasswordChangeSuccess extends ProfileState {
    final String message;
    PasswordChangeSuccess(this.message);
}

class PasswordChangeFailure extends ProfileState {
  final String error;

  PasswordChangeFailure(this.error);
}

class ProfileImageUploadLoading extends ProfileState {}

class ProfileImageUploadSuccess extends ProfileState {
    final String imageUrl;
    ProfileImageUploadSuccess(this.imageUrl);
}

class ProfileImageUploadFailure extends ProfileState {
    final String error;
    ProfileImageUploadFailure(this.error);
}
