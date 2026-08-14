import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  AppUser _mapFirebaseUser(fb.User user, {String? displayName, String? activeNestId}) {
    return AppUser(
      id: 'user_me',
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? user.email?.split('@').first ?? 'User',
      photoUrl: user.photoURL,
      activeNestId: activeNestId,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return _mapFirebaseUser(fbUser);
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    fb.User? fbUser = _firebaseAuth.currentUser;
    
    // On page load/refresh, currentUser can be temporarily null.
    // Wait briefly for the first authStateChanges event to resolve.
    if (fbUser == null) {
      try {
        fbUser = await _firebaseAuth.authStateChanges().first.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => null,
        );
      } catch (_) {
        fbUser = null;
      }
    }
    
    if (fbUser == null) return null;
    
    // Attempt to fetch additional details from Firestore using real uid
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!).copyWith(id: 'user_me');
      } else {
        // User document was deleted from Firestore but Auth is still valid.
        // Recreate it to avoid race conditions during sign in/up.
        final appUser = _mapFirebaseUser(fbUser);
        await _firestore.collection('users').doc(fbUser.uid).set(appUser.copyWith(id: fbUser.uid).toMap());
        return appUser.copyWith(id: 'user_me');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Token was likely revoked or user was deleted from console
        await _firebaseAuth.signOut();
        return null;
      }
      return _mapFirebaseUser(fbUser);
    } catch (_) {
      // Fallback to basic firebase user data on network errors
      return _mapFirebaseUser(fbUser);
    }
  }
 
  String _mapAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Authentication failed: user is null');
      }
      return await _getOrCreateUserDocument(user);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Registration failed: user is null');
      }
      
      // Update display name in Firebase Auth profile
      await user.updateDisplayName(displayName);
      
      final appUser = _mapFirebaseUser(user, displayName: displayName);
      
      // Write user to Firestore using their real user.uid
      await _firestore.collection('users').doc(user.uid).set(appUser.copyWith(id: user.uid).toMap());
      
      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      // serverClientId is the Web client ID (type 3) from google-services.json.
      // It is required on Android to get an idToken for Firebase authentication.
      const googleClientId = '43531260598-rek2kdfljelidqoh75c29ad1t3lbe93s.apps.googleusercontent.com';
      final googleSignIn = kIsWeb
          ? GoogleSignIn(clientId: googleClientId)
          : GoogleSignIn(serverClientId: googleClientId);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In canceled by user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Google Sign-In failed.');
      }

      return await _getOrCreateUserDocument(firebaseUser);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<AppUser> _getOrCreateUserDocument(fb.User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!).copyWith(id: 'user_me');
      } else {
        final appUser = _mapFirebaseUser(user);
        await _firestore.collection('users').doc(user.uid).set(appUser.copyWith(id: user.uid).toMap());
        return appUser;
      }
    } catch (e) {
      return _mapFirebaseUser(user);
    }
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    required String? username,
    required String? phone,
    required String? bio,
    required String? profileImage,
  }) async {
    try {
      final uid = _firebaseAuth.currentUser?.uid ?? userId;
      final updates = <String, dynamic>{
        'fullName': fullName,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'profileImage': profileImage,
        if (profileImage != null) 'photoUrl': profileImage,
      };

      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
      
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User document not found after update.');
      }
      return AppUser.fromMap(doc.data()!).copyWith(id: uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    throw UnimplementedError('Backend password updates are deferred.');
  }

  @override
  Future<void> logoutAllDevices() async {
    throw UnimplementedError('Backend session management is deferred.');
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    throw UnimplementedError('Backend account deletion is deferred.');
  }

  @override
  Future<void> updateActiveNestId(String userId, String? activeNestId) async {
    try {
      final uid = _firebaseAuth.currentUser?.uid ?? userId;
      await _firestore.collection('users').doc(uid).set({
        'activeNestId': activeNestId,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update active nest: $e');
    }
  }
}
