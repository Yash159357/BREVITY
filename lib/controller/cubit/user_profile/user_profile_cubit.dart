import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brevity/controller/services/firestore_service.dart'; // This is your UserRepository
import 'package:brevity/controller/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;

  UserProfileCubit() : super(UserProfileState()) {
    // Listen to auth state changes
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        // User is logged in, load their profile
        loadUserProfile();
      } else {
        // User is logged out, clear profile
        emit(UserProfileState());
      }
    });
  }

  Future<void> updateProfilePartial(Map<String, dynamic> changedFields) async {
    try {
      emit(state.copyWith(status: UserProfileStatus.loading));

      // Call API with only changed fields
      final updatedUser = await _userRepository.updateUserPartial(changedFields);

      // Save to local storage - this ensures name/email changes are persisted
      await saveLocalProfile(updatedUser);

      emit(state.copyWith(
        user: updatedUser,
        status: UserProfileStatus.loaded,
        localProfileImage: changedFields.containsKey('profileImage')
            ? changedFields['profileImage']
            : state.localProfileImage,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserProfileStatus.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');
      if (profileJson != null) {
        final profileData = json.decode(profileJson);
        final user = UserModel.fromMap(profileData); // Use fromMap instead of fromJson
        emit(state.copyWith(
          user: user,
          status: UserProfileStatus.loaded,
        ));
      }
    } catch (e) {
      // If loading local profile fails, just continue without it
      print('Failed to load local profile: $e');
    }
  }

  Future<void> saveLocalProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', json.encode(user.toMap())); // Use toMap instead of toJson
    } catch (e) {
      print('Failed to save local profile: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String displayName,
    File? profileImage,
    bool removeImage = false,
  }) async {
    try {
      emit(state.copyWith(
        status: UserProfileStatus.loading,
        localProfileImage: removeImage ? null : profileImage,
      ));

      final UserModel? currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: 'No authenticated user found',
          localProfileImage: null,
        ));
        return;
      }

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
        _userRepository.setAccessToken(accessToken);
      }

      final UserModel updatedProfile = await _userRepository.updateUserProfile(
          updatedUser,
          profileImage: removeImage ? null : profileImage,
          removeImage: removeImage
      );

      // Save updated profile to local storage
      await saveLocalProfile(updatedProfile);

      await _authService.refreshUser();

      emit(state.copyWith(
        status: UserProfileStatus.loaded,
        user: updatedProfile,
        localProfileImage: null,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: UserProfileStatus.error,
        errorMessage: 'Failed to update profile: ${e.toString()}',
        localProfileImage: null,
      ));
    }
  }

  // Remove profile image specifically
  Future<void> removeProfileImage() async {
    try {
      emit(state.copyWith(
        status: UserProfileStatus.loading,
        clearLocalImage: true,
      ));

      final UserModel? currentUser = _authService.currentUser;
      if (currentUser == null) {
        emit(state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: 'No authenticated user found',
          clearLocalImage: true,
        ));
        return;
      }

      final String? accessToken = _authService.accessToken;
      if (accessToken != null) {
        _userRepository.setAccessToken(accessToken);
      }

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

      emit(state.copyWith(
        status: UserProfileStatus.loaded,
        user: updatedUser,
        clearLocalImage: true,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: UserProfileStatus.error,
        errorMessage: 'Failed to remove profile image: ${e.toString()}',
        clearLocalImage: true,
      ));
    }
  }

// Also update the loadUserProfile method to clear local image when loading from server
  Future<void> loadUserProfile() async {
    // Load local profile first for instant display
    await loadLocalProfile();

    // If we have local data, show it immediately
    if (state.user != null) {
      emit(state.copyWith(status: UserProfileStatus.loaded));
    }

    // If we haven't loaded from server yet, load from server
    if (!state.hasLoadedFromServer) {
      // Don't show loading if we already have local data
      if (state.user == null) {
        emit(state.copyWith(status: UserProfileStatus.loading));
      }

      try {
        final UserModel? currentUser = _authService.currentUser;

        if (currentUser == null) {
          emit(state.copyWith(
            status: UserProfileStatus.error,
            errorMessage: 'No authenticated user found',
          ));
          return;
        }

        final String? accessToken = _authService.accessToken;
        if (accessToken != null) {
          _userRepository.setAccessToken(accessToken);
        }

        final UserModel profile = await _userRepository.getUserProfile(currentUser.uid);
        await saveLocalProfile(profile);

        emit(state.copyWith(
          status: UserProfileStatus.loaded,
          user: profile,
          clearLocalImage: true,
          hasLoadedFromServer: true,
        ));
      } catch (e) {
        // If we have local data, don't show error, just keep local data
        if (state.user != null) {
          emit(state.copyWith(
            status: UserProfileStatus.loaded,
            hasLoadedFromServer: false, // Try again next time
          ));
        } else {
          emit(state.copyWith(
            status: UserProfileStatus.error,
            errorMessage: e.toString(),
          ));
        }
      }
    }
  }

  bool _shouldRefreshProfile() {
    // Don't refresh if we have valid user data and have loaded from server
    if (state.user != null && state.hasLoadedFromServer) {
      return false;
    }
    return true;
  }

// Add this new method for force refresh
  Future<void> forceRefreshProfile() async {
    emit(state.copyWith(status: UserProfileStatus.loading));

    try {
      final UserModel? currentUser = _authService.currentUser;

      if (currentUser == null) {
        emit(state.copyWith(
          status: UserProfileStatus.error,
          errorMessage: 'No authenticated user found',
        ));
        return;
      }

      final String? accessToken = _authService.accessToken;
      if (accessToken != null) {
        _userRepository.setAccessToken(accessToken);
      }

      final UserModel profile = await _userRepository.getUserProfile(currentUser.uid);
      await saveLocalProfile(profile);

      emit(state.copyWith(
        status: UserProfileStatus.loaded,
        user: profile,
        clearLocalImage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserProfileStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refreshProfile() async {
    await forceRefreshProfile();
  }

  // Call this method after successful profile updates to reset the flag
  void markForRefresh() {
    emit(state.copyWith(hasLoadedFromServer: false));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
