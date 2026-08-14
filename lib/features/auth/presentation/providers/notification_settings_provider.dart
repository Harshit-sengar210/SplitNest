import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_settings.dart';
import '../../data/repositories/notification_settings_repository.dart';
import 'auth_provider.dart';

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettings?>>((ref) {
  final repository = ref.watch(notificationSettingsRepositoryProvider);
  final userAsync = ref.watch(authStateChangesProvider);
  
  return NotificationSettingsNotifier(repository, userAsync.value?.id);
});

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettings?>> {
  final NotificationSettingsRepository _repository;
  final String? _userId;

  NotificationSettingsNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final settings = await _repository.getSettings(_userId!);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    if (_userId == null) return;

    try {
      // Optimistic update
      state = AsyncValue.data(newSettings);
      await _repository.updateSettings(newSettings);
    } catch (e, st) {
      // Revert on error
      state = AsyncValue.error(e, st);
      _loadSettings(); // Reload actual
    }
  }
}
