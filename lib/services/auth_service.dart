import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '447441384618-et9knuf0vt55u4ouq7ii5upccbs4em30.apps.googleusercontent.com'
        : null,
  );

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // ============= EMAIL & PASSWORD =============

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update profile
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firebaseService.createUserProfile(credential.user!.uid, {
        'name': displayName,
        'email': email,
      });

      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  // ============= SOCIAL AUTH =============

  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential credentialResult = await _auth.signInWithCredential(
        credential,
      );

      // Create profile if new user
      if (credentialResult.additionalUserInfo?.isNewUser ?? false) {
        await _firebaseService.createUserProfile(credentialResult.user!.uid, {
          'name': credentialResult.user?.displayName ?? 'New User',
          'email': credentialResult.user?.email ?? '',
          'photoUrl': credentialResult.user?.photoURL ?? '',
        });
      }

      return credentialResult;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      if (await SignInWithApple.isAvailable()) {
        // Generate nonce
        final rawNonce = generateNonce();
        final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

        // Request credential
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // Create OAuth credential
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        // Sign in to Firebase
        final UserCredential credentialResult =
            await _auth.signInWithCredential(oauthCredential);

        // Create profile if new user
        if (credentialResult.additionalUserInfo?.isNewUser ?? false) {
          await _firebaseService.createUserProfile(credentialResult.user!.uid, {
            'name': credentialResult.user?.displayName ?? 'New User',
            'email': credentialResult.user?.email ?? '',
            'photoUrl': credentialResult.user?.photoURL ?? '',
          });
        }

        return credentialResult;
      } else {
        throw Exception('Apple Sign In is not available on this device');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= ANONYMOUS =============

  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= PASSWORD MANAGEMENT =============

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= EMAIL VERIFICATION =============

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= PROFILE MANAGEMENT =============

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= SIGN OUT =============

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= ACCOUNT DELETION =============

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from Firestore first
      await _firebaseService.deleteUserData(user.uid);

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============= UTILITIES =============

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('This email is already registered.');
      case 'weak-password':
        return Exception('Password should be at least 6 characters.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'account-exists-with-different-credential':
        return Exception(
          'An account already exists with the same email address but different sign-in credentials.',
        );
      case 'invalid-credential':
        return Exception('Invalid credentials provided.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled.');
      case 'network-request-failed':
        return Exception(
          'Network error. Please check your internet connection.',
        );
      default:
        return Exception(e.message ?? 'An authentication error occurred.');
    }
  }

  // ============= CHECK AUTH STATE =============

  bool get isSignedIn => _auth.currentUser != null;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  String? get userId => _auth.currentUser?.uid;

  String? get userEmail => _auth.currentUser?.email;

  String? get displayName => _auth.currentUser?.displayName;

  String? get photoURL => _auth.currentUser?.photoURL;
}
