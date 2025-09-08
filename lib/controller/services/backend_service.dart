import 'dart:convert';
import 'dart:io';

import 'package:brevity/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:image_picker/image_picker.dart';

class ApiService {
  // Update this URL to match your backend
  static const String baseUrl = 'https://brevity-backend-khaki.vercel.app/api';
  //static const String baseUrl = 'http://10.0.2.2:5000/api';

  // For Android emulator: http://10.0.2.2:5000/api
  // For iOS simulator: http://localhost:5000/api
  // For production: https://your-domain.com/api

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with timeout
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  // Token management
  String? _accessToken;
  String? _refreshToken;

  /// Initialize tokens from storage
  Future<void> initializeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(
      'accessToken',
    ); // Changed from 'access_token' to match AuthService
    _refreshToken = prefs.getString('refresh_token');

    try {
      Log.d('BACKEND_SERVICE: Initializing tokens from storage');
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accesstoken');
      _refreshToken = prefs.getString('refresh_token');

      if (_accessToken != null) {
        Log.i('BACKEND_SERVICE: Access token loaded from storage');
      } else {
        Log.d('BACKEND_SERVICE: No access token found in storage');
      }
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error initializing tokens', e);
      rethrow;
    }
  }

  /// Save tokens to storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refresh_token', refreshToken);

    try {
      Log.d('BACKEND_SERVICE: Saving tokens to storage');
      _accessToken = accessToken;
      _refreshToken = refreshToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accesstoken', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      Log.i('BACKEND_SERVICE: Tokens saved successfully');
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error saving tokens', e);
      rethrow;
    }
  }

  /// Clear tokens from storage
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      'accessToken',
    ); // Changed from 'access_token' to match AuthService
    await prefs.remove('refresh_token');
    try {
      Log.d('BACKEND_SERVICE: Clearing tokens from storage');
      _accessToken = null;
      _refreshToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accesstoken');
      await prefs.remove('refresh_token');
      Log.i('BACKEND_SERVICE: Tokens cleared successfully');
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error clearing tokens', e);
      rethrow;
    }
  }

  /// Get auth headers
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    try {
      Log.d('BACKEND_SERVICE: Generating headers (includeAuth: $includeAuth)');
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (includeAuth && _accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
        Log.d('BACKEND_SERVICE: Authorization header added');
      } else if (includeAuth && _accessToken == null) {
        Log.w('BACKEND_SERVICE: Auth requested but no access token available');
      }

      return headers;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error generating headers', e);
      rethrow;
    }
  }

  /// Handle API response
  ApiResponse _handleResponse(http.Response response) {
    try {
      Log.d(
        'BACKEND_SERVICE: Handling API response (status: ${response.statusCode})',
      );
      final Map<String, dynamic> data = json.decode(response.body);

      final apiResponse = ApiResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        data: data['data'],
        statusCode: response.statusCode,
        errors: data['errors'],
      );

      if (apiResponse.success) {
        Log.i('BACKEND_SERVICE: API response successful');
      } else {
        Log.w('BACKEND_SERVICE: API response failed - ${apiResponse.message}');
      }

      return apiResponse;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error handling API response', e);
      return ApiResponse(
        success: false,
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Make HTTP request with error handling
  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    try {
      Log.d('BACKEND_SERVICE: Making $method request to $endpoint');
      final uri = Uri.parse('$baseUrl$endpoint');
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          Log.d('BACKEND_SERVICE: Executing GET request');
          response = await _client
              .get(uri, headers: _getHeaders(includeAuth: requireAuth))
              .timeout(_timeout);
          break;
        case 'POST':
          Log.d('BACKEND_SERVICE: Executing POST request');
          response = await _client
              .post(
                uri,
                headers: _getHeaders(includeAuth: requireAuth),
                body: body != null ? json.encode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          Log.d('BACKEND_SERVICE: Executing PUT request');
          response = await _client
              .put(
                uri,
                headers: _getHeaders(includeAuth: requireAuth),
                body: body != null ? json.encode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          Log.d('BACKEND_SERVICE: Executing DELETE request');
          response = await _client
              .delete(uri, headers: _getHeaders(includeAuth: requireAuth))
              .timeout(_timeout);
          break;
        default:
          Log.e('BACKEND_SERVICE: Unsupported HTTP method: $method');
          throw Exception('Unsupported HTTP method: $method');
      }

      Log.i(
        'BACKEND_SERVICE: Request completed with status ${response.statusCode}',
      );
      return _handleResponse(response);
    } catch (e) {
      Log.e('BACKEND_SERVICE: Request failed for $method $endpoint', e);
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    String errorMessage;

    if (error is SocketException) {
      errorMessage = 'No internet connection. Please check your network.';
    } else if (error is http.ClientException) {
      errorMessage = 'Network error. Please try again.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Request timeout. Please try again.';
    } else {
      errorMessage = 'Something went wrong. Please try again.';
    }

    Log.w('BACKEND_SERVICE: Error message generated: $errorMessage');
    return errorMessage;
  }

  /// Authentication Methods ///

  /// Register new user
  Future<ApiResponse> register({
    required String displayName,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      Log.i('BACKEND_SERVICE: Starting user registration for email: $email');
      final uri = Uri.parse('$baseUrl/auth/register');
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['displayName'] = displayName;
      request.fields['email'] = email;
      request.fields['password'] = password;

      Log.d('BACKEND_SERVICE: Registration form fields added');

      // Add profile image if provided
      if (profileImage != null) {
        Log.d('BACKEND_SERVICE: Adding profile image to registration');
        final multipartFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
        );
        request.files.add(multipartFile);
        Log.d('BACKEND_SERVICE: Profile image added successfully');
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final apiResponse = _handleResponse(response);

      // Save tokens on successful registration
      if (apiResponse.success && apiResponse.data != null) {
        Log.i('BACKEND_SERVICE: Registration successful, saving tokens');
        final data = apiResponse.data as Map<String, dynamic>;
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      } else {
        Log.w('BACKEND_SERVICE: Registration failed - ${apiResponse.message}');
      }

      return apiResponse;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Registration error', e);
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  /// Login user
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      Log.i('BACKEND_SERVICE: Starting user login for email: $email');
      final response = await _makeRequest(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      );

      // Save tokens on successful login
      if (response.success && response.data != null) {
        Log.i('BACKEND_SERVICE: Login successful, saving tokens');
        final data = response.data as Map<String, dynamic>;
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
      } else {
        Log.w('BACKEND_SERVICE: Login failed - ${response.message}');
      }

      return response;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Login error', e);
      rethrow;
    }
  }

  /// Logout user
  Future<ApiResponse> logout() async {
    try {
      Log.i('BACKEND_SERVICE: Starting user logout');
      final response = await _makeRequest(
        'POST',
        '/auth/logout',
        body: {'refreshToken': _refreshToken},
        requireAuth: true,
      );

      if (response.success) {
        Log.i('BACKEND_SERVICE: Logout successful, clearing tokens');
        await _clearTokens();
      } else {
        Log.w(
          'BACKEND_SERVICE: Logout API call failed but clearing tokens anyway',
        );
        await _clearTokens();
      }

      return response;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Logout error', e);
      // Clear tokens even if logout fails
      await _clearTokens();
      rethrow;
    }
  }

  /// Get current user
  Future<ApiResponse> getCurrentUser() async {
    try {
      Log.d('BACKEND_SERVICE: Fetching current user');
      final response = await _makeRequest('GET', '/auth/me', requireAuth: true);

      if (response.success) {
        Log.i('BACKEND_SERVICE: Current user fetched successfully');
      } else {
        Log.w(
          'BACKEND_SERVICE: Failed to fetch current user - ${response.message}',
        );
      }

      return response;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Get current user error', e);
      rethrow;
    }
  }

  /// User Profile Methods ///

  /// Update user profile
  Future<ApiResponse> updateProfile({
    String? displayName,
    Map<String, dynamic>? preferences,
    File? profileImage,
  }) async {
    try {
      Log.i('BACKEND_SERVICE: Starting profile update');
      final uri = Uri.parse('$baseUrl/users/profile');
      final request = http.MultipartRequest('PUT', uri);

      // Add auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
        Log.d('BACKEND_SERVICE: Authorization header added for profile update');
      } else {
        Log.e('BACKEND_SERVICE: No access token available for profile update');
        throw Exception('No access token available');
      }

      // Add form fields
      if (displayName != null) {
        request.fields['displayName'] = displayName;
        Log.d('BACKEND_SERVICE: Display name field added');
      }
      if (preferences != null) {
        request.fields['preferences'] = json.encode(preferences);
        Log.d('BACKEND_SERVICE: Preferences field added');
      }

      // Add profile image if provided
      if (profileImage != null) {
        Log.d('BACKEND_SERVICE: Adding profile image to update');
        final multipartFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
        );
        request.files.add(multipartFile);
        Log.d('BACKEND_SERVICE: Profile image added to update request');
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final apiResponse = _handleResponse(response);

      if (apiResponse.success) {
        Log.i('BACKEND_SERVICE: Profile updated successfully');
      } else {
        Log.w(
          'BACKEND_SERVICE: Profile update failed - ${apiResponse.message}',
        );
      }

      return apiResponse;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Profile update error', e);
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  /// Delete profile image
  Future<ApiResponse> deleteProfileImage() async {
    try {
      Log.i('BACKEND_SERVICE: Deleting profile image');
      final response = await _makeRequest(
        'DELETE',
        '/users/profile/image',
        requireAuth: true,
      );

      if (response.success) {
        Log.i('BACKEND_SERVICE: Profile image deleted successfully');
      } else {
        Log.w(
          'BACKEND_SERVICE: Profile image deletion failed - ${response.message}',
        );
      }

      return response;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Delete profile image error', e);
      rethrow;
    }
  }

  /// Utility Methods ///

  /// Check if user is authenticated
  bool get isAuthenticated {
    final authenticated = _accessToken != null;
    Log.d('BACKEND_SERVICE: Authentication check result: $authenticated');
    return authenticated;
  }

  /// Get access token
  String? get accessToken {
    Log.d('BACKEND_SERVICE: Access token requested');
    return _accessToken;
  }

  /// Check backend health
  Future<ApiResponse> checkHealth() async {
    try {
      Log.d('BACKEND_SERVICE: Checking backend health');
      final response = await _makeRequest('GET', '/health');

      if (response.success) {
        Log.i('BACKEND_SERVICE: Backend health check passed');
      } else {
        Log.w(
          'BACKEND_SERVICE: Backend health check failed - ${response.message}',
        );
      }

      return response;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Health check error', e);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      Log.d('BACKEND_SERVICE: Disposing HTTP client resources');
      _client.close();
      Log.i('BACKEND_SERVICE: Resources disposed successfully');
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error disposing resources', e);
    }
  }
}

/// API Response model
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;
  final List<dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}

/// User model for API responses
class ApiUser {
  final String id;
  final String displayName;
  final String email;
  final bool emailVerified;
  final ProfileImage? profileImage;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;

  ApiUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.emailVerified,
    this.profileImage,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    try {
      Log.d('BACKEND_SERVICE: Parsing ApiUser from JSON');
      final user = ApiUser(
        id: json['_id'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        emailVerified: json['emailVerified'] as bool? ?? false,
        profileImage:
            json['profileImage'] != null
                ? ProfileImage.fromJson(json['profileImage'])
                : null,
        preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        lastLogin:
            json['lastLogin'] != null
                ? DateTime.parse(json['lastLogin'])
                : null,
      );
      Log.i('BACKEND_SERVICE: ApiUser parsed successfully');
      return user;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error parsing ApiUser from JSON', e);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      Log.d('BACKEND_SERVICE: Converting ApiUser to JSON');
      final json = {
        '_id': id,
        'displayName': displayName,
        'email': email,
        'emailVerified': emailVerified,
        'profileImage': profileImage?.toJson(),
        'preferences': preferences.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
      };
      Log.d('BACKEND_SERVICE: ApiUser converted to JSON successfully');
      return json;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error converting ApiUser to JSON', e);
      rethrow;
    }
  }
}

/// Profile Image model
class ProfileImage {
  final String url;
  final String publicId;

  ProfileImage({required this.url, required this.publicId});

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    try {
      Log.d('BACKEND_SERVICE: Parsing ProfileImage from JSON');
      final profileImage = ProfileImage(
        url: json['url'] as String,
        publicId: json['publicId'] as String,
      );
      Log.d('BACKEND_SERVICE: ProfileImage parsed successfully');
      return profileImage;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error parsing ProfileImage from JSON', e);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      Log.d('BACKEND_SERVICE: Converting ProfileImage to JSON');
      final json = {'url': url, 'publicId': publicId};
      Log.d('BACKEND_SERVICE: ProfileImage converted to JSON successfully');
      return json;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error converting ProfileImage to JSON', e);
      rethrow;
    }
  }
}

/// User Preferences model
class UserPreferences {
  final List<String> categories;
  final String language;

  UserPreferences({required this.categories, required this.language});

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    try {
      Log.d('BACKEND_SERVICE: Parsing UserPreferences from JSON');
      final preferences = UserPreferences(
        categories: List<String>.from(json['categories'] ?? []),
        language: json['language'] as String? ?? 'en',
      );
      Log.d('BACKEND_SERVICE: UserPreferences parsed successfully');
      return preferences;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error parsing UserPreferences from JSON', e);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      Log.d('BACKEND_SERVICE: Converting UserPreferences to JSON');
      final json = {'categories': categories, 'language': language};
      Log.d('BACKEND_SERVICE: UserPreferences converted to JSON successfully');
      return json;
    } catch (e) {
      Log.e('BACKEND_SERVICE: Error converting UserPreferences to JSON', e);
      rethrow;
    }
  }
}

/// Updated AuthService to use ApiService
class AuthService {
  final ApiService _apiService = ApiService();

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Initialize service
  Future<void> initialize() async {
    try {
      Log.i('AUTH_SERVICE: Initializing AuthService');
      await _apiService.initializeTokens();
      Log.i('AUTH_SERVICE: AuthService initialized successfully');
    } catch (e) {
      Log.e('AUTH_SERVICE: Error initializing AuthService', e);
      rethrow;
    }
  }

  /// Register with email and password
  Future<ApiUser?> signUpWithEmail({
    required String email,
    required String password,
    required String userName,
    File? profileImage,
  }) async {
    try {
      Log.i('AUTH_SERVICE: Starting signup for email: $email');
      final response = await _apiService.register(
        displayName: userName,
        email: email,
        password: password,
        profileImage: profileImage,
      );

      if (response.success && response.data != null) {
        Log.i('AUTH_SERVICE: Signup successful');
        final userData = response.data['user'] as Map<String, dynamic>;
        return ApiUser.fromJson(userData);
      } else {
        Log.w('AUTH_SERVICE: Signup failed - ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      Log.e('AUTH_SERVICE: Signup error', e);
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Login with email and password
  Future<ApiUser?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      Log.i('AUTH_SERVICE: Starting login for email: $email');
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        Log.i('AUTH_SERVICE: Login successful');
        final userData = response.data['user'] as Map<String, dynamic>;
        return ApiUser.fromJson(userData);
      } else {
        Log.w('AUTH_SERVICE: Login failed - ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      Log.e('AUTH_SERVICE: Login error', e);
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      Log.i('AUTH_SERVICE: Starting signout');
      await _apiService.logout();
      Log.i('AUTH_SERVICE: Signout completed successfully');
    } catch (e) {
      // Continue with local logout even if API call fails
      Log.e('AUTH_SERVICE: Logout API call failed but continuing', e);
    }
  }

  /// Get current user
  Future<ApiUser?> getCurrentUser() async {
    try {
      Log.d('AUTH_SERVICE: Fetching current user');
      final response = await _apiService.getCurrentUser();

      if (response.success && response.data != null) {
        Log.i('AUTH_SERVICE: Current user fetched successfully');
        final userData = response.data['user'] as Map<String, dynamic>;
        return ApiUser.fromJson(userData);
      }
      Log.w('AUTH_SERVICE: No current user found or fetch failed');
      return null;
    } catch (e) {
      Log.e('AUTH_SERVICE: Get current user failed', e);
      return null;
    }
  }

  /// Update user profile
  Future<ApiUser?> updateProfile({
    String? displayName,
    Map<String, dynamic>? preferences,
    File? profileImage,
  }) async {
    try {
      Log.i('AUTH_SERVICE: Starting profile update');
      final response = await _apiService.updateProfile(
        displayName: displayName,
        preferences: preferences,
        profileImage: profileImage,
      );

      if (response.success && response.data != null) {
        Log.i('AUTH_SERVICE: Profile updated successfully');
        final userData = response.data['user'] as Map<String, dynamic>;
        return ApiUser.fromJson(userData);
      } else {
        Log.w('AUTH_SERVICE: Profile update failed - ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      Log.e('AUTH_SERVICE: Profile update error', e);
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      Log.i('AUTH_SERVICE: Starting profile image deletion');
      final response = await _apiService.deleteProfileImage();

      if (!response.success) {
        Log.w(
          'AUTH_SERVICE: Profile image deletion failed - ${response.message}',
        );
        throw Exception(response.message);
      }
      Log.i('AUTH_SERVICE: Profile image deleted successfully');
    } catch (e) {
      Log.e('AUTH_SERVICE: Delete profile image error', e);
      throw Exception('Delete profile image failed: ${e.toString()}');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final authenticated = _apiService.isAuthenticated;
    Log.d('AUTH_SERVICE: Authentication check result: $authenticated');
    return authenticated;
  }

  /// Stream for auth state changes (simplified version)
  Stream<ApiUser?> get authStateChanges async* {
    try {
      Log.d('AUTH_SERVICE: Getting auth state changes stream');
      // Initial state
      yield await getCurrentUser();

      // Note: For real-time auth state changes, you might want to implement
      // a more sophisticated solution with StreamController
    } catch (e) {
      Log.e('AUTH_SERVICE: Error in auth state changes stream', e);
      yield null;
    }
  }
}
