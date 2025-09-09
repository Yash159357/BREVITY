import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brevity/controller/services/firestore_service.dart'; // This is your UserRepository
import 'package:brevity/controller/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import 'user_profile_state.dart';
import '../../../utils/logger.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;

  UserProfileCubit() : super(UserProfileState()) {
    Log.i("USER_PROFILE_CUBIT: Initializing UserProfileCubit");
    // Listen to auth state changes
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      Log.d("USER_PROFILE_CUBIT: Setting up auth state listener");
      _authSubscription = _authService.authStateChanges.listen((user) {
        try {
          if (user != null) {
            Log.i(
              "USER_PROFILE_CUBIT: User logged in, loading profile - userId: ${user.uid}",
            );
            // User is logged in, load their profile
            loadUserProfile();
          } else {
            Log.i("USER_PROFILE_CUBIT: User logged out, clearing profile");
            // User is logged out, clear profile
            emit(UserProfileState());
          }
        } catch (e, stackTrace) {
          Log.e(
            "USER_PROFILE_CUBIT: Error in auth state change handler",
            e,
            stackTrace,
          );
        }
      });
    } catch (e, stackTrace) {
      Log.e(
        "USER_PROFILE_CUBIT: Error setting up auth state listener",
        e,
        stackTrace,
      );
    }
  }

  Future<void> updateProfilePartial(Map<String, dynamic> changedFields) async {
    try {
      Log.i(
        "USER_PROFILE_CUBIT: Starting partial profile update with fields: ${changedFields.keys.join(', ')}",
      );
      emit(state.copyWith(status: UserProfileStatus.loading));

      // Call API with only changed fields
      final updatedUser = await _userRepository.updateUserPartial(
        changedFields,
      );
      Log.i(
        "USER_PROFILE_CUBIT: Successfully updated profile partially - userId: ${updatedUser.uid}",
      );

      // Save to local storage - this ensures name/email changes are persisted
      await saveLocalProfile(updatedUser);

      emit(
        state.copyWith(
          user: updatedUser,
          status: UserProfileStatus.loaded,
          localProfileImage:
              changedFields.containsKey('profileImage')
                  ? changedFields['profileImage']
                  : state.localProfileImage,
        ),
      );

      Log.i(
        "USER_PROFILE_CUBIT: Partial profile update completed successfully",
      );
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in updateProfilePartial", e, stackTrace);
      emit(
        state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> loadLocalProfile() async {
    try {
      Log.d("USER_PROFILE_CUBIT: Loading profile from local storage");
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');

      if (profileJson != null) {
        Log.d("USER_PROFILE_CUBIT: Found local profile data, parsing...");
        final profileData = json.decode(profileJson);
        final user = UserModel.fromMap(
          profileData,
        ); // Use fromMap instead of fromJson

        emit(state.copyWith(user: user, status: UserProfileStatus.loaded));

        Log.i(
          "USER_PROFILE_CUBIT: Successfully loaded local profile - userId: ${user.uid}",
        );
      } else {
        Log.d("USER_PROFILE_CUBIT: No local profile data found");
      }
    } catch (e, stackTrace) {
      // If loading local profile fails, just continue without it
      Log.e("USER_PROFILE_CUBIT: Failed to load local profile", e, stackTrace);
    }
  }

  Future<void> saveLocalProfile(UserModel user) async {
    try {
      Log.d(
        "USER_PROFILE_CUBIT: Saving profile to local storage - userId: ${user.uid}",
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_profile',
        json.encode(user.toMap()),
      ); // Use toMap instead of toJson
      Log.i("USER_PROFILE_CUBIT: Successfully saved profile to local storage");
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Failed to save local profile", e, stackTrace);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String displayName,
    File? profileImage,
    bool removeImage = false,
  }) async {
    try {
      Log.i(
        "USER_PROFILE_CUBIT: Starting profile update - displayName: $displayName, hasImage: ${profileImage != null}, removeImage: $removeImage",
      );

      emit(
        state.copyWith(
          status: UserProfileStatus.loading,
          localProfileImage: removeImage ? null : profileImage,
        ),
      );

      final UserModel? currentUser = _authService.currentUser;
      if (currentUser == null) {
        Log.e(
          "USER_PROFILE_CUBIT: No authenticated user found for profile update",
        );
        emit(
          state.copyWith(
            status: UserProfileStatus.error,
            errorMessage: 'No authenticated user found',
            localProfileImage: null,
          ),
        );
        return;
      }

      Log.d(
        "USER_PROFILE_CUBIT: Creating updated user model for userId: ${currentUser.uid}",
      );
      final UserModel updatedUser = UserModel(
        uid: currentUser.uid,
        displayName: displayName,
        email: currentUser.email,
        emailVerified: currentUser.emailVerified,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
        profileImageUrl: removeImage ? null : currentUser.profileImageUrl,
      );

      final String? accessToken = _authService.accessToken;
      if (accessToken != null) {
        Log.d("USER_PROFILE_CUBIT: Setting access token for repository");
        _userRepository.setAccessToken(accessToken);
      }

      Log.d("USER_PROFILE_CUBIT: Calling repository updateUserProfile");
      final UserModel updatedProfile = await _userRepository.updateUserProfile(
        updatedUser,
        profileImage: removeImage ? null : profileImage,
        removeImage: removeImage,
      );

      // Save updated profile to local storage
      await saveLocalProfile(updatedProfile);

      Log.d("USER_PROFILE_CUBIT: Refreshing auth service user");
      await _authService.refreshUser();

      emit(
        state.copyWith(
          status: UserProfileStatus.loaded,
          user: updatedProfile,
          localProfileImage: null,
        ),
      );

      Log.i(
        "USER_PROFILE_CUBIT: Profile update completed successfully - userId: ${updatedProfile.uid}",
      );
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in updateProfile", e, stackTrace);
      emit(
        state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: 'Failed to update profile: ${e.toString()}',
          localProfileImage: null,
        ),
      );
    }
  }

  // Remove profile image specifically
  Future<void> removeProfileImage() async {
    try {
      Log.i("USER_PROFILE_CUBIT: Starting profile image removal");
      emit(
        state.copyWith(
          status: UserProfileStatus.loading,
          clearLocalImage: true,
        ),
      );

      final UserModel? currentUser = _authService.currentUser;
      if (currentUser == null) {
        Log.e(
          "USER_PROFILE_CUBIT: No authenticated user found for image removal",
        );
        emit(
          state.copyWith(
            status: UserProfileStatus.error,
            errorMessage: 'No authenticated user found',
            clearLocalImage: true,
          ),
        );
        return;
      }

      final String? accessToken = _authService.accessToken;
      if (accessToken != null) {
        Log.d("USER_PROFILE_CUBIT: Setting access token for image removal");
        _userRepository.setAccessToken(accessToken);
      }

      Log.d(
        "USER_PROFILE_CUBIT: Calling repository removeUserProfileImage for userId: ${currentUser.uid}",
      );
      await _userRepository.removeUserProfileImage(currentUser.uid);

      final UserModel updatedUser = UserModel(
        uid: currentUser.uid,
        displayName: currentUser.displayName,
        email: currentUser.email,
        emailVerified: currentUser.emailVerified,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
        profileImageUrl: null,
      );

      // Save updated profile to local storage
      await saveLocalProfile(updatedUser);

      await _authService.refreshUser();

      emit(
        state.copyWith(
          status: UserProfileStatus.loaded,
          user: updatedUser,
          clearLocalImage: true,
        ),
      );

      Log.i("USER_PROFILE_CUBIT: Profile image removal completed successfully");
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in removeProfileImage", e, stackTrace);
      emit(
        state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: 'Failed to remove profile image: ${e.toString()}',
          clearLocalImage: true,
        ),
      );
    }
  }

  // Also update the loadUserProfile method to clear local image when loading from server
  Future<void> loadUserProfile() async {
    try {
      Log.i("USER_PROFILE_CUBIT: Starting loadUserProfile");

      // Load local profile first for instant display
      await loadLocalProfile();

      // If we have local data, show it immediately
      if (state.user != null) {
        Log.d("USER_PROFILE_CUBIT: Found local data, showing immediately");
        emit(state.copyWith(status: UserProfileStatus.loaded));
      }

      // If we haven't loaded from server yet, load from server
      if (!state.hasLoadedFromServer) {
        Log.d(
          "USER_PROFILE_CUBIT: Haven't loaded from server yet, fetching...",
        );

        // Don't show loading if we already have local data
        if (state.user == null) {
          Log.d("USER_PROFILE_CUBIT: No local data, showing loading state");
          emit(state.copyWith(status: UserProfileStatus.loading));
        }

        try {
          final UserModel? currentUser = _authService.currentUser;

          if (currentUser == null) {
            Log.e(
              "USER_PROFILE_CUBIT: No authenticated user found for profile loading",
            );
            emit(
              state.copyWith(
                status: UserProfileStatus.error,
                errorMessage: 'No authenticated user found',
              ),
            );
            return;
          }

          final String? accessToken = _authService.accessToken;
          if (accessToken != null) {
            Log.d(
              "USER_PROFILE_CUBIT: Setting access token for profile loading",
            );
            _userRepository.setAccessToken(accessToken);
          }

          Log.d(
            "USER_PROFILE_CUBIT: Fetching profile from server for userId: ${currentUser.uid}",
          );
          final UserModel profile = await _userRepository.getUserProfile(
            currentUser.uid,
          );
          await saveLocalProfile(profile);

          emit(
            state.copyWith(
              status: UserProfileStatus.loaded,
              user: profile,
              clearLocalImage: true,
              hasLoadedFromServer: true,
            ),
          );

          Log.i(
            "USER_PROFILE_CUBIT: Successfully loaded profile from server - userId: ${profile.uid}",
          );
        } catch (e, stackTrace) {
          Log.e(
            "USER_PROFILE_CUBIT: Error loading profile from server",
            e,
            stackTrace,
          );

          // If we have local data, don't show error, just keep local data
          if (state.user != null) {
            Log.w(
              "USER_PROFILE_CUBIT: Server load failed but have local data, keeping local data",
            );
            emit(
              state.copyWith(
                status: UserProfileStatus.loaded,
                hasLoadedFromServer: false, // Try again next time
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: UserProfileStatus.error,
                errorMessage: e.toString(),
              ),
            );
          }
        }
      } else {
        Log.d(
          "USER_PROFILE_CUBIT: Already loaded from server, skipping server fetch",
        );
      }
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in loadUserProfile", e, stackTrace);
    }
  }

  bool _shouldRefreshProfile() {
    try {
      // Don't refresh if we have valid user data and have loaded from server
      if (state.user != null && state.hasLoadedFromServer) {
        Log.d(
          "USER_PROFILE_CUBIT: Should not refresh - have valid data and loaded from server",
        );
        return false;
      }
      Log.d("USER_PROFILE_CUBIT: Should refresh profile");
      return true;
    } catch (e, stackTrace) {
      Log.e(
        "USER_PROFILE_CUBIT: Error in _shouldRefreshProfile",
        e,
        stackTrace,
      );
      return true;
    }
  }

  // Add this new method for force refresh
  Future<void> forceRefreshProfile() async {
    try {
      Log.i("USER_PROFILE_CUBIT: Starting force refresh profile");
      emit(state.copyWith(status: UserProfileStatus.loading));

      final UserModel? currentUser = _authService.currentUser;

      if (currentUser == null) {
        Log.e(
          "USER_PROFILE_CUBIT: No authenticated user found for force refresh",
        );
        emit(
          state.copyWith(
            status: UserProfileStatus.error,
            errorMessage: 'No authenticated user found',
          ),
        );
        return;
      }

      final String? accessToken = _authService.accessToken;
      if (accessToken != null) {
        Log.d("USER_PROFILE_CUBIT: Setting access token for force refresh");
        _userRepository.setAccessToken(accessToken);
      }

      Log.d(
        "USER_PROFILE_CUBIT: Force fetching profile from server for userId: ${currentUser.uid}",
      );
      final UserModel profile = await _userRepository.getUserProfile(
        currentUser.uid,
      );
      await saveLocalProfile(profile);

      emit(
        state.copyWith(
          status: UserProfileStatus.loaded,
          user: profile,
          clearLocalImage: true,
        ),
      );

      Log.i(
        "USER_PROFILE_CUBIT: Force refresh completed successfully - userId: ${profile.uid}",
      );
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in forceRefreshProfile", e, stackTrace);
      emit(
        state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> refreshProfile() async {
    try {
      Log.i("USER_PROFILE_CUBIT: Refreshing profile");
      await forceRefreshProfile();
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in refreshProfile", e, stackTrace);
    }
  }

  // Call this method after successful profile updates to reset the flag
  void markForRefresh() {
    try {
      Log.d(
        "USER_PROFILE_CUBIT: Marking for refresh - resetting hasLoadedFromServer flag",
      );
      emit(state.copyWith(hasLoadedFromServer: false));
    } catch (e, stackTrace) {
      Log.e("USER_PROFILE_CUBIT: Error in markForRefresh", e, stackTrace);
    }
  }

  // Delete user account
  Future<void> deleteAccount({String? password, String? googleIdToken}) async {
    try {
      emit(state.copyWith(status: UserProfileStatus.loading));

      await _authService.deleteAccount(
        password: password,
        googleIdToken: googleIdToken,
      );

      // Clear local profile data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');

      // Clear state
      emit(UserProfileState());
    } catch (e) {
      emit(
        state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> close() {
    try {
      Log.i(
        "USER_PROFILE_CUBIT: Closing UserProfileCubit - cancelling subscriptions",
      );
      _authSubscription?.cancel();
      return super.close();
    } catch (e, stackTrace) {
      Log.e(
        "USER_PROFILE_CUBIT: Error closing UserProfileCubit",
        e,
        stackTrace,
      );
      return super.close();
    }
  }
}
