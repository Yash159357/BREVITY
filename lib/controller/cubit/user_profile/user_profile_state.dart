import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../models/user_model.dart';
import '../../../utils/logger.dart';

enum UserProfileStatus { initial, loading, loaded, error }

class UserProfileState extends Equatable {
  final UserProfileStatus status;
  final UserModel? user;
  final String? errorMessage;
  final File? localProfileImage;
  final bool hasLoadedFromServer;

  const UserProfileState({
    this.status = UserProfileStatus.initial,
    this.user,
    this.errorMessage,
    this.localProfileImage,
    this.hasLoadedFromServer = false,
  });

  UserProfileState copyWith({
    UserProfileStatus? status,
    UserModel? user,
    String? errorMessage,
    File? localProfileImage,
    bool clearLocalImage = false,
    bool? hasLoadedFromServer,
  }) {
    try {
      Log.d(
        "USER_PROFILE_STATE: Creating copyWith - status: ${status ?? this.status}, hasUser: ${(user ?? this.user) != null}, clearLocalImage: $clearLocalImage",
      );

      final newState = UserProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
        localProfileImage:
            clearLocalImage
                ? null
                : (localProfileImage ?? this.localProfileImage),
        hasLoadedFromServer: hasLoadedFromServer ?? this.hasLoadedFromServer,
      );

      Log.d("USER_PROFILE_STATE: CopyWith completed successfully");
      return newState;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in copyWith", e, stackTrace);
      rethrow;
    }
  }

  // Helper getters
  bool get isLoading {
    try {
      final result = status == UserProfileStatus.loading;
      Log.d("USER_PROFILE_STATE: isLoading getter called - result: $result");
      return result;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in isLoading getter", e, stackTrace);
      return false;
    }
  }

  bool get isLoaded {
    try {
      final result = status == UserProfileStatus.loaded;
      Log.d("USER_PROFILE_STATE: isLoaded getter called - result: $result");
      return result;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in isLoaded getter", e, stackTrace);
      return false;
    }
  }

  bool get hasError {
    try {
      final result = status == UserProfileStatus.error;
      Log.d("USER_PROFILE_STATE: hasError getter called - result: $result");
      return result;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in hasError getter", e, stackTrace);
      return false;
    }
  }

  bool get isInitial {
    try {
      final result = status == UserProfileStatus.initial;
      Log.d("USER_PROFILE_STATE: isInitial getter called - result: $result");
      return result;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in isInitial getter", e, stackTrace);
      return false;
    }
  }

  bool get hasUser {
    try {
      final result = user != null;
      Log.d("USER_PROFILE_STATE: hasUser getter called - result: $result");
      return result;
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error in hasUser getter", e, stackTrace);
      return false;
    }
  }

  @override
  List<Object?> get props {
    try {
      Log.d("USER_PROFILE_STATE: Getting props for state comparison");
      return [
        status,
        user,
        errorMessage,
        localProfileImage,
        hasLoadedFromServer,
      ];
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_STATE: Error getting props", e, stackTrace);
      return [];
    }
  }
}
