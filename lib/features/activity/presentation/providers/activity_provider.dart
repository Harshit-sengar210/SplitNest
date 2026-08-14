import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../data/repositories/firebase_activity_repository.dart';


// ─── Repository Provider ──────────────────────────────────────────────────────

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FirebaseActivityRepository();
});

// ─── Real-time group timeline StreamProvider ──────────────────────────────────

final groupTimelineStreamProvider =
    StreamProvider.family<List<Activity>, String>((ref, groupId) {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.streamGroupActivities(groupId);
});

// ─── State ────────────────────────────────────────────────────────────────────

class ActivityState {
  final List<Activity> activities;
  final List<Activity> filteredActivities;
  final bool isLoading;
  final String? error;
  final String filterType; // 'All', 'Expenses', 'Settlements', 'Members'

  const ActivityState({
    this.activities = const [],
    this.filteredActivities = const [],
    this.isLoading = false,
    this.error,
    this.filterType = 'All',
  });

  ActivityState copyWith({
    List<Activity>? activities,
    List<Activity>? filteredActivities,
    bool? isLoading,
    String? error,
    String? filterType,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      filteredActivities: filteredActivities ?? this.filteredActivities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: filterType ?? this.filterType,
    );
  }
}

// ─── Global Activity Notifier ─────────────────────────────────────────────────

class GlobalActivityNotifier extends StateNotifier<ActivityState> {
  final ActivityRepository _repository;

  GlobalActivityNotifier(this._repository) : super(const ActivityState()) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getGlobalActivities();
      state = state.copyWith(
        isLoading: false,
        activities: list,
        filteredActivities: _applyFilter(list, state.filterType),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(
      filterType: filter,
      filteredActivities: _applyFilter(state.activities, filter),
    );
  }

  List<Activity> _applyFilter(List<Activity> list, String filter) {
    if (filter == 'All') return list;
    return list.where((a) => _matchesFilter(a, filter)).toList();
  }

  bool _matchesFilter(Activity a, String filter) {
    switch (filter) {
      case 'Expenses':
        return a.type == 'expense_added' ||
            a.type == 'expense_updated' ||
            a.type == 'expense_deleted' ||
            a.type == 'expense_created';
      case 'Settlements':
        return a.type == 'settlement_recorded' ||
            a.type == 'settlement_partial' ||
            a.type == 'settlement_completed';
      case 'Members':
        return a.type == 'member_joined' ||
            a.type == 'member_left' ||
            a.type == 'nest_created' ||
            a.type == 'group_created';
      default:
        return true;
    }
  }
}

final globalActivitiesProvider =
    StateNotifierProvider<GlobalActivityNotifier, ActivityState>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  final notifier = GlobalActivityNotifier(repo);
  return notifier;
});

// ─── Group Activity Notifier ──────────────────────────────────────────────────
// Used by group_detail_screen's Timeline tab. Backed by real-time Firestore stream.

class GroupActivityNotifier extends StateNotifier<ActivityState> {
  final ActivityRepository _repository;
  final String groupId;

  GroupActivityNotifier(this._repository, this.groupId)
      : super(const ActivityState()) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getGroupActivities(groupId);
      state = state.copyWith(
        isLoading: false,
        activities: list,
        filteredActivities: _applyFilter(list, state.filterType),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Called by the stream listener in the provider below to push live updates.
  void updateFromStream(List<Activity> activities) {
    state = state.copyWith(
      isLoading: false,
      activities: activities,
      filteredActivities: _applyFilter(activities, state.filterType),
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(
      filterType: filter,
      filteredActivities: _applyFilter(state.activities, filter),
    );
  }

  List<Activity> _applyFilter(List<Activity> list, String filter) {
    if (filter == 'All') return list;
    return list.where((a) => _matchesFilter(a, filter)).toList();
  }

  bool _matchesFilter(Activity a, String filter) {
    switch (filter) {
      case 'Expenses':
        return a.type == 'expense_added' ||
            a.type == 'expense_updated' ||
            a.type == 'expense_deleted' ||
            a.type == 'expense_created';
      case 'Settlements':
        return a.type == 'settlement_recorded' ||
            a.type == 'settlement_partial' ||
            a.type == 'settlement_completed';
      case 'Members':
        return a.type == 'member_joined' ||
            a.type == 'member_left' ||
            a.type == 'nest_created' ||
            a.type == 'group_created';
      default:
        return true;
    }
  }
}

final groupActivitiesProvider =
    StateNotifierProvider.family<GroupActivityNotifier, ActivityState, String>(
        (ref, groupId) {
  final repo = ref.watch(activityRepositoryProvider);
  final notifier = GroupActivityNotifier(repo, groupId);

  // Push real-time Firestore stream updates into the notifier.
  ref.listen(groupTimelineStreamProvider(groupId), (prev, next) {
    next.whenData(notifier.updateFromStream);
  });

  return notifier;
});
