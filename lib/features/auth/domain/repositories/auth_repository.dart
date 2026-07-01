import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  
  Future<AppUser?> getCurrentUser();
  
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });
  
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  
  Future<AppUser> signInWithGoogle();
  
  Future<void> sendPasswordResetEmail({required String email});
  
  Future<void> signOut();

  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    required String? username,
    required String? phone,
    required String? bio,
    required String? profileImage,
  });

  Future<void> changePassword({required String currentPassword, required String newPassword});
  
  Future<void> logoutAllDevices();
  
  Future<void> deleteAccount({required String password});

  Future<void> updateActiveNestId(String userId, String? activeNestId);
}
