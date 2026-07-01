import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';

// Check if Firebase is initialized. If yes, use FirebaseAuthRepository, else fall back to MockAuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuthRepository();
    }
  } catch (_) {
    // Firebase is not initialized, fallback to mock
  }
  
  // Return mock auth repository (default fallback)
  return MockAuthRepository();
});

// Stream provider to listen to login state updates
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Tracks if the user has just registered a new account in this session
final isJustRegisteredProvider = StateProvider<bool>((ref) => false);

// ViewState class to manage state transitions in UI
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable override
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// StateNotifier to process auth events and update UI status
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState()) {
    // Sync notifier user with repository changes and fetch full profile
    _repository.authStateChanges.listen((user) async {
      if (user == null) {
        state = state.copyWith(user: null, isLoading: false);
      } else {
        state = state.copyWith(isLoading: true, errorMessage: null);
        try {
          final fullUser = await _repository.getCurrentUser();
          state = state.copyWith(user: fullUser ?? user, isLoading: false);
        } catch (e) {
          state = state.copyWith(user: user, isLoading: false);
        }
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    _ref.read(isJustRegisteredProvider.notifier).state = false;
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = await _repository.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false, user: user, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    _ref.read(isJustRegisteredProvider.notifier).state = true;
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false, user: user, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signInWithGoogle() async {
    _ref.read(isJustRegisteredProvider.notifier).state = false;
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(isLoading: false, user: user, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    _ref.read(isJustRegisteredProvider.notifier).state = false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String? username,
    required String? phone,
    required String? bio,
    required String? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = await _repository.updateProfile(
        userId: userId,
        fullName: fullName,
        username: username,
        phone: phone,
        bio: bio,
        profileImage: profileImage,
      );
      state = state.copyWith(isLoading: false, user: user, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> updateActiveNestId(String? activeNestId) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _repository.updateActiveNestId(currentUser.id, activeNestId);
      final updatedUser = currentUser.copyWith(
        activeNestId: activeNestId,
        clearActiveNestId: activeNestId == null,
      );
      state = state.copyWith(user: updatedUser, isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

final activeNestIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.activeNestId;
});
