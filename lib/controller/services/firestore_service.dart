import 'dart:io';

import 'package:brevity/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http_parser/http_parser.dart';

class UserRepository {
  final String _baseUrl = 'https://brevity-backend-khaki.vercel.app/api/users';
  String? _accessToken;

  // Singleton pattern
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // Set access token from auth service
  void setAccessToken(String token) {
    _accessToken = token;
  }

  // Get user profile
  Future<UserModel> getUserProfile(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('https://brevity-backend-khaki.vercel.app/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        return UserModel(
          uid: userData['_id'], // Node.js uses _id
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load user profile');
      }
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile(UserModel user, {File? profileImage, bool removeImage = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Add form fields
      request.fields['displayName'] = user.displayName;

      // Add removeImage flag if needed
      if (removeImage) {
        request.fields['removeImage'] = 'true';
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<UserModel> updateUserPartial(Map<String, dynamic> changedFields) async {
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final request = http.MultipartRequest('PUT', uri); // Changed from PUT to PATCH

      // Add auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Handle image update
      if (changedFields.containsKey('profileImage') && changedFields['profileImage'] != null) {
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
        }
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> removeUserProfileImage(String uid) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/profile/image'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to remove profile image');
      }
    } catch (e) {
      throw Exception('Failed to remove profile image: $e');
    }
  }

  // Get user by ID (if needed for admin purposes)
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        return UserModel(
          uid: userData['_id'],
          displayName: userData['displayName'] ?? '',
          email: userData['email'] ?? '',
          emailVerified: userData['emailVerified'] ?? false,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: userData['updatedAt'] != null
              ? DateTime.parse(userData['updatedAt'])
              : null,
          profileImageUrl: userData['profileImage']?['url'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load user');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }
}
