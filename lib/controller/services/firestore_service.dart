import 'dart:io';

import 'package:brevity/models/user_model.dart';
import 'package:brevity/utils/api_config.dart';
import 'package:brevity/utils/logger.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http_parser/http_parser.dart';

class UserRepository {
  String get _baseUrl => ApiConfig.usersUrl;
  String? _accessToken;

  // Singleton pattern
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // Set access token from auth service
  void setAccessToken(String token) {
    Log.d('FIRESTORE_SERVICE: Access token updated');
    _accessToken = token;
  }

  // Get user profile
  Future<UserModel> getUserProfile(String uid) async {
    Log.i('FIRESTORE_SERVICE: Fetching user profile for UID: $uid');

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.authUrl}/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      Log.d(
        'FIRESTORE_SERVICE: Profile fetch response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        Log.d(
          'FIRESTORE_SERVICE: Successfully parsed user data - Email: ${userData['email']}, Display Name: ${userData['displayName']}',
        );

        return UserModel(
          uid: userData['_id'], // Node.js uses _id
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt:
              userData['createdAt'] != null
                  ? DateTime.parse(userData['createdAt'])
                  : null,
          updatedAt:
              userData['updatedAt'] != null
                  ? DateTime.parse(userData['updatedAt'])
                  : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to load user profile';
        Log.e(
          'FIRESTORE_SERVICE: Profile fetch failed - Status: ${response.statusCode}, Message: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      Log.e('FIRESTORE_SERVICE: Exception during profile fetch', e);
      throw Exception('Failed to load user profile: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile(
    UserModel user, {
    File? profileImage,
    bool removeImage = false,
  }) async {
    Log.i(
      'FIRESTORE_SERVICE: Updating user profile - Display Name: ${user.displayName}, Remove Image: $removeImage',
    );

    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
        Log.d('FIRESTORE_SERVICE: Added authorization header');
      }

      // Add form fields
      request.fields['displayName'] = user.displayName;
      Log.d('FIRESTORE_SERVICE: Added display name field: ${user.displayName}');

      // Add removeImage flag if needed
      if (removeImage) {
        request.fields['removeImage'] = 'true';
        Log.d('FIRESTORE_SERVICE: Added removeImage flag');
      }

      // Add profile image if provided
      if (profileImage != null) {
        // Get file extension and determine content type
        final extension = profileImage.path.split('.').last.toLowerCase();
        String contentType;

        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg'; // Default fallback
        }

        Log.d(
          'FIRESTORE_SERVICE: Adding profile image - Extension: $extension, Content Type: $contentType',
        );

        final multipartFile = http.MultipartFile(
          'profileImage',
          profileImage.readAsBytes().asStream(),
          profileImage.lengthSync(),
          filename: 'profile_image.$extension',
          contentType: MediaType.parse(contentType),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Log.d(
        'FIRESTORE_SERVICE: Profile update response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        Log.i('FIRESTORE_SERVICE: Profile updated successfully');

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt:
              userData['createdAt'] != null
                  ? DateTime.parse(userData['createdAt'])
                  : null,
          updatedAt:
              userData['updatedAt'] != null
                  ? DateTime.parse(userData['updatedAt'])
                  : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update profile';
        Log.e(
          'FIRESTORE_SERVICE: Profile update failed - Status: ${response.statusCode}, Message: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      Log.e('FIRESTORE_SERVICE: Exception during profile update', e);
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<UserModel> updateUserPartial(
    Map<String, dynamic> changedFields,
  ) async {
    Log.i(
      'FIRESTORE_SERVICE: Updating user profile partially - Fields: ${changedFields.keys.join(', ')}',
    );

    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
        Log.d(
          'FIRESTORE_SERVICE: Added authorization header for partial update',
        );
      }

      // Handle image update
      if (changedFields.containsKey('profileImage') &&
          changedFields['profileImage'] != null) {
        final File imageFile = changedFields['profileImage'];
        final extension = imageFile.path.split('.').last.toLowerCase();
        String contentType;

        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }

        Log.d(
          'FIRESTORE_SERVICE: Partial update - Adding profile image with content type: $contentType',
        );

        final multipartFile = http.MultipartFile(
          'profileImage',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: 'profile_image.$extension',
          contentType: MediaType.parse(contentType),
        );
        request.files.add(multipartFile);
      }

      // Add only the changed text fields
      changedFields.forEach((key, value) {
        if (key != 'profileImage') {
          request.fields[key] = value.toString();
          Log.d('FIRESTORE_SERVICE: Added field $key: $value');
        }
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Log.d(
        'FIRESTORE_SERVICE: Partial update response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        Log.i(
          'FIRESTORE_SERVICE: Partial profile update completed successfully',
        );

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt:
              userData['createdAt'] != null
                  ? DateTime.parse(userData['createdAt'])
                  : null,
          updatedAt:
              userData['updatedAt'] != null
                  ? DateTime.parse(userData['updatedAt'])
                  : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update profile';
        Log.e(
          'FIRESTORE_SERVICE: Partial update failed - Status: ${response.statusCode}, Message: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      Log.e('FIRESTORE_SERVICE: Exception during partial update', e);
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> removeUserProfileImage(String uid) async {
    Log.i('FIRESTORE_SERVICE: Removing profile image for UID: $uid');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/profile/image'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      Log.d(
        'FIRESTORE_SERVICE: Remove image response status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to remove profile image';
        Log.e(
          'FIRESTORE_SERVICE: Remove image failed - Status: ${response.statusCode}, Message: $errorMessage',
        );
        throw Exception(errorMessage);
      } else {
        Log.i('FIRESTORE_SERVICE: Profile image removed successfully');
      }
    } catch (e) {
      Log.e('FIRESTORE_SERVICE: Exception during image removal', e);
      throw Exception('Failed to remove profile image: $e');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount({
    String? password,
    String? googleIdToken,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (password != null) {
        body['password'] = password;
      }
      if (googleIdToken != null) {
        body['googleIdToken'] = googleIdToken;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/deleteAccount'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Get user by ID (if needed for admin purposes)
  Future<UserModel> getUserById(String userId) async {
    Log.i('FIRESTORE_SERVICE: Fetching user by ID: $userId');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      Log.d(
        'FIRESTORE_SERVICE: Get user by ID response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        Log.d(
          'FIRESTORE_SERVICE: Successfully retrieved user data for ID: $userId',
        );

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt:
              userData['createdAt'] != null
                  ? DateTime.parse(userData['createdAt'])
                  : null,
          updatedAt:
              userData['updatedAt'] != null
                  ? DateTime.parse(userData['updatedAt'])
                  : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to load user';
        Log.e(
          'FIRESTORE_SERVICE: Get user by ID failed - Status: ${response.statusCode}, Message: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      Log.e('FIRESTORE_SERVICE: Exception during get user by ID', e);
      throw Exception('Failed to load user: $e');
    }
  }
}
