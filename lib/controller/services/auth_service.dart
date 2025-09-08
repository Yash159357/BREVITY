import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brevity/models/user_model.dart';
import 'package:brevity/utils/logger.dart';
import 'package:brevity/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // final String _baseUrl = 'https://brevity-backend-khaki.vercel.app/api/auth';
  //static const String _baseUrl = 'http://10.0.2.2:5001/api/auth';
  String get _baseUrl => ApiConfig.authUrl;

  // HTTP timeout duration
  static const Duration _httpTimeout = Duration(seconds: 30);

  String? _accessToken;
  UserModel? _currentUser;

  // Auth state management
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  final _authStateController = StreamController<UserModel?>.broadcast();

  String? get accessToken => _accessToken;
  UserModel? get currentUser => _currentUser;

  // Initialize auth state (call this when app starts)
  Future<void> initializeAuth() async {
    try {
      Log.i('<AUTH_SERVICE> initializeAuth started');
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('accessToken');

      if (storedToken != null && storedToken.isNotEmpty) {
        _accessToken = storedToken;
        // Attempt to refresh user data with the stored token
        await refreshUser();
        if (_currentUser != null) {
          _authStateController.add(_currentUser);
        } else {
          // If refresh fails (e.g., token expired), clear local state without calling logout API
          await _clearLocalAuthState();
        }
      } else {
        _authStateController.add(null);
      }
    } catch (e) {
      // Handle any errors during initialization, e.g., SharedPreferences error
      _authStateController.add(null);
      Log.e('<AUTH_SERVICE> Error initializing auth: $e'); // For debugging
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String userName,
    BuildContext? context,
    File? profileImage, // Add this parameter
  }) async {
    try {
      Log.i(
        '<AUTH_SERVICE> signUpWithEmail started for email=$email, userName=$userName',
      );
      final uri = Uri.parse('$_baseUrl/register');
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['displayName'] = userName;
      request.fields['email'] = email.trim();
      request.fields['password'] = password.trim();

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

      // Log request details
      try {
        final fileInfo = request.files
            .map((f) => '${f.field}-${f.filename}')
            .join(',');
        Log.d(
          '<AUTH_SERVICE> signUp request -> URL: $uri, headers: ${request.headers}, fields: ${request.fields}, files: $fileInfo',
        );
      } catch (e) {
        Log.w('<AUTH_SERVICE> signUp request logging failed: $e');
      }

      final streamedResponse = await request.send().timeout(_httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      // Log response details
      Log.d(
        '<AUTH_SERVICE> signUp response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 201) {
        // Rest of your existing success handling code remains the same
        final data = json.decode(response.body);
        _accessToken = data['data']['accessToken'];
        final userData = data['data']['user'];

        // Save access token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);

        // Create UserModel from backend response
        _currentUser = UserModel(
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

        if (context != null && context.mounted) {
          // Redirect to email verification - no success snackbar as user needs to verify email
          context.go(
            '/email-verification?email=${Uri.encodeComponent(email)}&isFromLogin=false',
          );
        }

        // Notify listeners of auth state change
        _authStateController.add(_currentUser);
        Log.i('<AUTH_SERVICE> signUpWithEmail succeeded for email=$email');
        return _currentUser;
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> signUp failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Sign up error: $e'); // For debugging
      // Let the calling screen handle error display for better UX control
      rethrow;
    }
  }

  Future<void> forgotPassword({
    required String email,
    BuildContext? context,
  }) async {
    try {
      Log.i('<AUTH_SERVICE> forgotPassword started for email=$email');
      final uri = Uri.parse('$_baseUrl/forgot-password');
      final body = json.encode({'email': email.trim()});
      Log.d(
        '<AUTH_SERVICE> forgotPassword request -> URL: $uri, headers: {"Content-Type": "application/json"}, body: $body',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      Log.d(
        '<AUTH_SERVICE> forgotPassword response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        if (context != null && context.mounted) {
          _showSuccessSnackBar(context, 'Reset OTP sent to your email');
        }
        Log.i('<AUTH_SERVICE> forgotPassword succeeded for email=$email');
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> forgotPassword failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Failed to send reset OTP');
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Forgot password error: $e'); // For debugging
      // Let the calling screen handle error display for better UX control
      rethrow;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    BuildContext? context,
  }) async {
    try {
      Log.i('<AUTH_SERVICE> resetPassword started for email=$email');
      final uri = Uri.parse('$_baseUrl/reset-password');
      final bodyMap = {
        'email': email.trim(),
        'token': otp.trim(),
        'newPassword': newPassword.trim(),
      };
      final body = json.encode(bodyMap);
      Log.d(
        '<AUTH_SERVICE> resetPassword request -> URL: $uri, headers: {"Content-Type": "application/json"}, body: $body',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      Log.d(
        '<AUTH_SERVICE> resetPassword response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        if (context != null && context.mounted) {
          _showSuccessSnackBar(context, 'Password reset successfully');
          Log.i('<AUTH_SERVICE> resetPassword succeeded for email=$email');
          return true;
        }
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> resetPassword failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Reset password error: $e'); // For debugging
      // Let the calling screen handle error display for better UX control
      rethrow;
    }
    return false; // Return false if reset failed
  }

  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
    BuildContext? context,
  }) async {
    try {
      Log.i('<AUTH_SERVICE> loginWithEmail started for email=$email');
      final uri = Uri.parse('$_baseUrl/login');
      final bodyMap = {'email': email.trim(), 'password': password.trim()};
      final body = json.encode(bodyMap);
      Log.d(
        '<AUTH_SERVICE> login request -> URL: $uri, headers: {"Content-Type": "application/json"}, body: $body',
      );

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_httpTimeout);

      Log.d(
        '<AUTH_SERVICE> login response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['data']['accessToken'];
        final userData = data['data']['user'];

        // Save access token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', _accessToken!);

        // Create UserModel from backend response
        _currentUser = UserModel(
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

        if (context != null && context.mounted) {
          // Check if email is verified before redirecting
          if (_currentUser!.emailVerified) {
            _showSuccessSnackBar(context, 'Welcome back!');
            context.go('/home/0');
          } else {
            // Don't show success snackbar when redirecting to email verification
            context.go(
              '/email-verification?email=${Uri.encodeComponent(email)}&isFromLogin=true',
            );
          }
        }

        // Notify listeners of auth state change
        _authStateController.add(_currentUser);
        Log.i('<AUTH_SERVICE> loginWithEmail succeeded for email=$email');
        return _currentUser;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Email not verified or access denied - check if it's email verification issue
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> login failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        if (errorData['message']?.contains('verify your email') == true ||
            errorData['message']?.contains('Email not verified') == true) {
          if (context != null && context.mounted) {
            context.go(
              '/email-verification?email=${Uri.encodeComponent(email)}&isFromLogin=true',
            );
          }
          // Don't show snackbar here as we're redirecting to verification screen
          throw Exception('Please verify your email to continue');
        } else {
          throw Exception(errorData['message'] ?? 'Login failed');
        }
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> login failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Login error: $e'); // For debugging
      // Let the calling screen handle error display for better UX control
      rethrow;
    }
  }

  Future<void> signOut({BuildContext? context}) async {
    try {
      Log.i('<AUTH_SERVICE> signOut started');
      // Call logout endpoint if token exists
      if (_accessToken != null) {
        final uri = Uri.parse('$_baseUrl/logout');
        Log.d(
          '<AUTH_SERVICE> signOut request -> URL: $uri, headers: {"Authorization": "Bearer $_accessToken", "Content-Type": "application/json"}',
        );
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        );
        Log.d(
          '<AUTH_SERVICE> signOut response -> status: ${response.statusCode}, body: ${response.body}',
        );
      }

      // Clear local state
      _accessToken = null;
      _currentUser = null;

      // Clear token from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');

      // Notify listeners of auth state change
      _authStateController.add(null);

      Log.i('<AUTH_SERVICE> signOut local state cleared');

      if (context != null && context.mounted) {
        _showSuccessSnackBar(context, 'Successfully signed out');
        context.go('/login'); // Redirect to login page
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Logout error: $e'); // For debugging
      // Even if logout fails on server, clear local state
      _accessToken = null;
      _currentUser = null;
      _authStateController.add(null);

      // Ensure token is cleared from local storage even on server error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');

      if (context != null) {
        if (!context.mounted) return;
        context.go('/login');
      }
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  // Refresh user data
  Future<void> refreshUser() async {
    if (_accessToken == null) {
      throw Exception('No access token available');
    }
    try {
      Log.i('<AUTH_SERVICE> refreshUser started');
      final uri = Uri.parse('$_baseUrl/me');
      Log.d(
        '<AUTH_SERVICE> refreshUser request -> URL: $uri, headers: {"Authorization": "Bearer $_accessToken", "Content-Type": "application/json"}',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_httpTimeout);

      Log.d(
        '<AUTH_SERVICE> refreshUser response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data']['user'];

        _currentUser = UserModel(
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

        _authStateController.add(_currentUser);
        Log.i('<AUTH_SERVICE> refreshUser succeeded');
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _clearLocalAuthState();
        Log.w('<AUTH_SERVICE> refreshUser token expired (401)');
        throw Exception('Token expired');
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> refreshUser failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Failed to refresh user data');
      }
    } on TimeoutException {
      Log.e('<AUTH_SERVICE> refreshUser timeout');
      throw Exception('Network timeout. Please check your connection.');
    } catch (e) {
      // Only clear state if it's an auth error, not network error
      if (e.toString().contains('Token expired') ||
          e.toString().contains('401')) {
        await _clearLocalAuthState();
      }
      Log.e('<AUTH_SERVICE> Error refreshing user: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // Clear local auth state without calling logout API
  Future<void> _clearLocalAuthState() async {
    Log.i('<AUTH_SERVICE> Clearing local auth state');
    _accessToken = null;
    _currentUser = null;

    // Clear token from local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');

    // Notify listeners of auth state change
    _authStateController.add(null);
  }

  // Email verification methods
  Future<void> resendVerificationEmail(String email) async {
    try {
      Log.i('<AUTH_SERVICE> resendVerificationEmail started for email=$email');
      final uri = Uri.parse('$_baseUrl/resend-verification');
      final body = json.encode({'email': email.trim()});
      Log.d(
        '<AUTH_SERVICE> resendVerificationEmail request -> URL: $uri, headers: {"Content-Type": "application/json"}, body: $body',
      );

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_httpTimeout);

      Log.d(
        '<AUTH_SERVICE> resendVerificationEmail response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Success - verification email sent
        Log.i(
          '<AUTH_SERVICE> resendVerificationEmail succeeded for email=$email',
        );
        return;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> resendVerificationEmail failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        if (errorData['message']?.contains('already verified') == true) {
          throw Exception('Email is already verified');
        } else {
          throw Exception(
            errorData['message'] ?? 'Failed to resend verification email',
          );
        }
      } else if (response.statusCode == 404) {
        Log.e(
          '<AUTH_SERVICE> resendVerificationEmail failed -> 404 user not found for email=$email',
        );
        throw Exception('User not found with this email');
      } else if (response.statusCode >= 500) {
        Log.e(
          '<AUTH_SERVICE> resendVerificationEmail server error -> status: ${response.statusCode}',
        );
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> resendVerificationEmail failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(
          errorData['message'] ?? 'Failed to resend verification email',
        );
      }
    } on TimeoutException {
      Log.e('<AUTH_SERVICE> resendVerificationEmail timeout');
      throw Exception(
        'Network timeout. Please check your connection and try again.',
      );
    } catch (e) {
      Log.e('<AUTH_SERVICE> resendVerificationEmail error: $e');
      if (e is Exception) {
        rethrow; // Re-throw our custom exceptions
      }
      // Handle network errors
      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    }
  }

  // Check if current user's email is verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // Debug method to get current auth state
  Map<String, dynamic> get debugAuthState => {
    'hasToken': _accessToken != null,
    'hasUser': _currentUser != null,
    'userEmail': _currentUser?.email,
    'emailVerified': _currentUser?.emailVerified,
    'isAuthenticated': isAuthenticated,
  };

  // Delete user account
  Future<void> deleteAccount({
    String? password,
    String? googleIdToken,
    BuildContext? context,
  }) async {
    try {
      Log.i('<AUTH_SERVICE> deleteAccount started');

      if (_accessToken == null) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('${ApiConfig.usersUrl}/deleteAccount');
      final body = <String, dynamic>{};

      // Add password for normal users, googleIdToken for OAuth users
      if (password != null) {
        body['password'] = password.trim();
      }
      if (googleIdToken != null) {
        body['googleIdToken'] = googleIdToken;
      }

      Log.d(
        '<AUTH_SERVICE> deleteAccount request -> URL: $uri, headers: {"Authorization": "Bearer $_accessToken", "Content-Type": "application/json"}',
      );

      final response = await http
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(_httpTimeout);

      Log.d(
        '<AUTH_SERVICE> deleteAccount response -> status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Account deleted successfully
        final data = json.decode(response.body);
        Log.i('<AUTH_SERVICE> deleteAccount succeeded');

        // Clear local state immediately
        await _clearLocalAuthState();

        if (context != null && context.mounted) {
          _showSuccessSnackBar(
            context,
            data['message'] ?? 'Account deleted successfully',
          );
          context.go('/login');
        }
      } else {
        final errorData = json.decode(response.body);
        Log.e(
          '<AUTH_SERVICE> deleteAccount failed -> status: ${response.statusCode}, body: ${response.body}',
        );
        throw Exception(errorData['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      Log.e('<AUTH_SERVICE> Delete account error: $e');
      rethrow;
    }
  }

  // Helper method to check if current user is OAuth-only
  bool get isOAuthOnlyUser {
    return false;
  }

  // Dispose of resources
  void dispose() {
    _authStateController.close();
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
