import 'dart:async';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/mock_database.dart';

class MockAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository() {
    // Start as null (unauthenticated)
    _authStateController.add(null);
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate error triggers for demonstration
    if (email.contains('error')) {
      throw Exception('Invalid email or password. Please try again.');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // Toggle mock database based on user type simulation
    if (email.toLowerCase().contains('new')) {
      MockDatabase().clearDatabase();
    } else {
      MockDatabase().resetToDefault();
    }

    _currentUser = AppUser(
      id: 'user_me',
      email: email,
      displayName: email.split('@').first.toUpperCase(),
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      activeNestId: email.toLowerCase().contains('new') ? null : 'nest_1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (email.contains('exists')) {
      throw Exception('An account already exists with this email.');
    }

    // Since they registered a new account, clear the database to simulate new user flow
    MockDatabase().clearDatabase();

    _currentUser = AppUser(
      id: 'user_me',
      email: email,
      displayName: displayName,
      photoUrl: null,
      activeNestId: null,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    
    _currentUser = AppUser(
      id: 'user_me',
      email: 'gold.member@splitnest.com',
      displayName: 'Gold Member',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
      activeNestId: 'nest_1',
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    // Success simulation
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
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
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate username uniqueness check
    final takenUsernames = ['sarah', 'mike', 'emily', 'aman', 'rohit', 'deepak'];
    if (username != null && username.isNotEmpty) {
      if (takenUsernames.contains(username.toLowerCase().trim())) {
        throw Exception('Username already taken');
      }
    }

    _currentUser = _currentUser?.copyWith(
      displayName: fullName,
      username: username,
      phone: phone,
      bio: bio,
      photoUrl: profileImage,
      updatedAt: DateTime.now(),
    );

    if (_currentUser != null) {
      _authStateController.add(_currentUser);
    }
    return _currentUser!;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (currentPassword.isEmpty) {
      throw Exception('Current password is required');
    }
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters');
    }
  }

  @override
  Future<void> logoutAllDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    await signOut();
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password.length < 6) {
      throw Exception('Incorrect password. For mock mode, password must be at least 6 characters.');
    }
    await signOut();
  }

  @override
  Future<void> updateActiveNestId(String userId, String? activeNestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = _currentUser?.copyWith(
      activeNestId: activeNestId,
      clearActiveNestId: activeNestId == null,
    );
    _authStateController.add(_currentUser);
  }
}
