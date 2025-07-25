import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Email & Password Authentication  ///
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String userName,
    BuildContext? context,
  }) async {
    try {
      // Show loading indicator
      if (context != null) {
        _showLoadingSnackBar(context, 'Creating your account...');
      }

      // 1. Create user in Firebase Auth
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // 2. Safely get user reference
      final User? user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // 3. Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': userName,
        'email': user.email ?? email.trim(), // Prefer verified email
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        // Removed password storage (security risk)
      });

      // 4. Send email verification (recommended)
      await user.sendEmailVerification();

      // Show success message
      if (context != null) {
        _showSuccessSnackBar(
          context,
          'Account created successfully! Please check your email for verification.',
        );
      }
      context?.go('/intro');

      return user;
    } on FirebaseAuthException catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, _getFirebaseErrorMessage(e));
      }
      throw _handleFirebaseError(e);
    } on FirebaseException catch (e) {
      if (context != null) {
        _showErrorSnackBar(
          context,
          'Database error occurred. Please try again.',
        );
      }
      throw Exception('Firestore error: ${e.message}');
    } catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, 'Something went wrong. Please try again.');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
    BuildContext? context,
  }) async {
    try {
      // Show loading indicator
      if (context != null) {
        _showLoadingSnackBar(context, 'Signing you in...');
      }

      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Show success message
      if (context != null) {
        _showSuccessSnackBar(context, 'Welcome back!');
      }
      context?.go('/home/0');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, _getFirebaseErrorMessage(e));
      }
      throw _handleFirebaseError(e);
    } catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, 'Login failed. Please try again.');
      }
      rethrow;
    }
  }

  /// Google Authentication  ///

  Future<User?> signInWithGoogle({BuildContext? context}) async {
    try {
      // Show loading indicator
      if (context != null) {
        _showLoadingSnackBar(context, 'Signing in with Google...');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (context != null) {
          _showInfoSnackBar(context, 'Sign in cancelled');
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // Check if this is a new user and create Firestore document
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final User? user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'displayName': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'emailVerified': user.emailVerified,
            'provider': 'google',
          });
        }
      }

      // Show success message
      if (context != null) {
        _showSuccessSnackBar(context, 'Successfully signed in with Google!');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, _getFirebaseErrorMessage(e));
      }
      throw _handleFirebaseError(e);
    } catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, 'Google sign in failed. Please try again.');
      }
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /// Common Methods  ///

  Future<void> signOut({BuildContext? context}) async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      if (context != null) {
        _showSuccessSnackBar(context, 'Successfully signed out');
      }
    } catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, 'Error signing out. Please try again.');
      }
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;

  /// Password Reset ///
  Future<void> sendPasswordResetEmail(
    String email, {
    BuildContext? context,
  }) async {
    try {
      if (context != null) {
        _showLoadingSnackBar(context, 'Sending reset email...');
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());

      if (context != null) {
        _showSuccessSnackBar(
          context,
          'Password reset email sent! Check your inbox.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context != null) {
        _showErrorSnackBar(context, _getFirebaseErrorMessage(e));
      }
      throw _handleFirebaseError(e);
    } catch (e) {
      if (context != null) {
        _showErrorSnackBar(
          context,
          'Failed to send reset email. Please try again.',
        );
      }
      rethrow;
    }
  }

  /// SnackBar Helper Methods ///

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Error Message Mapping ///

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., user@example.com)';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for assistance.';
      case 'user-not-found':
        return 'No account found with this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently disabled. Contact support.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with letters and numbers.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'requires-recent-login':
        return 'Please sign out and sign back in to perform this action.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  /// Legacy Error Handling (for backward compatibility) ///

  Exception _handleFirebaseError(FirebaseAuthException e) {
    return Exception(_getFirebaseErrorMessage(e));
  }
}
