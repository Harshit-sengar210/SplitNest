import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/group.dart';
import '../../domain/models/cycle_stats.dart';
import '../../domain/models/cycle_report.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../data/repositories/firebase_groups_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return FirebaseGroupsRepository();
});

class GroupsListState {
  final List<Group> groups;
  final List<Group> filteredGroups;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const GroupsListState({
    this.groups = const [],
    this.filteredGroups = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  GroupsListState copyWith({
    List<Group>? groups,
    List<Group>? filteredGroups,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return GroupsListState(
      groups: groups ?? this.groups,
      filteredGroups: filteredGroups ?? this.filteredGroups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Internal stream provider ──────────────────────────────────────────────────
// Subscribes directly to Firestore. Watches authNotifierProvider so it
// automatically re-subscribes with the new user's UID when the account changes.
// Widgets should NOT watch this directly; instead watch [groupsListProvider].
final _groupsStreamProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  // Watch auth state so this stream is recreated whenever the user changes.
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return Stream.value([]);

  final repository = ref.watch(groupsRepositoryProvider);
  return repository.watchGroups();
});

/// Manages the state of the entire groups list, including
/// search/filter, creation, and invite operations.
///
/// Internally subscribes to [_groupsStreamProvider] so that the list is
/// updated automatically whenever Firestore pushes a new snapshot.
/// No polling or manual reload is needed.
class GroupsListNotifier extends StateNotifier<GroupsListState> {
  final Ref _ref;

  GroupsListNotifier(this._ref) : super(const GroupsListState(isLoading: true)) {
    // Subscribe to the Firestore stream.  Each emission replaces the groups
    // list while preserving the current search query.
    _ref.listen<AsyncValue<List<Group>>>(
      _groupsStreamProvider,
      (_, next) {
        next.when(
          data: (groups) {
            debugPrint('DEBUG: [GroupsListNotifier] Received ${groups.length} nest(s) from Firestore stream.');
            state = state.copyWith(
              groups: groups,
              filteredGroups: _applySearch(groups, state.searchQuery),
              isLoading: false,
              errorMessage: null,
            );
          },
          loading: () {
            state = state.copyWith(isLoading: true, errorMessage: null);
          },
          error: (e, _) {
            state = state.copyWith(isLoading: false, errorMessage: e.toString());
          },
        );
      },
      fireImmediately: true,
    );
  }

  void searchGroups(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredGroups: _applySearch(state.groups, query),
    );
  }

  List<Group> _applySearch(List<Group> list, String query) {
    if (query.trim().isEmpty) return list;
    final term = query.toLowerCase();
    return list.where((g) => g.name.toLowerCase().contains(term) || g.description.toLowerCase().contains(term)).toList();
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required String type,
    String? groupImage,
    List<String>? inviteEmails,
    List<String>? inviteUsernames,
    int? settlementCycleDate,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newGroup = await _ref.read(groupsRepositoryProvider).createGroup(
        name: name,
        description: description,
        type: type,
        groupImage: groupImage,
        inviteEmails: inviteEmails,
        inviteUsernames: inviteUsernames,
        settlementCycleDate: settlementCycleDate,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );
      // Firestore stream will automatically emit the new group; just clear loading.
      state = state.copyWith(isLoading: false);
      return newGroup;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<String> generateInviteCode(String groupId) async {
    return _ref.read(groupsRepositoryProvider).generateInviteCode(groupId);
  }

  Future<String> generateShareLink(String groupId) async {
    return _ref.read(groupsRepositoryProvider).generateShareLink(groupId);
  }

  Future<void> inviteMember({required String groupId, required String email}) async {
    await _ref.read(groupsRepositoryProvider).inviteMember(groupId: groupId, email: email);
    // Stream will propagate the member addition automatically.
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _ref.read(groupsRepositoryProvider).removeMember(groupId, userId);
  }

  Future<void> promoteToAdmin(String groupId, String userId) async {
    await _ref.read(groupsRepositoryProvider).promoteToAdmin(groupId, userId);
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _ref.read(groupsRepositoryProvider).leaveGroup(groupId, userId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _ref.read(groupsRepositoryProvider).deleteGroup(groupId);
  }

  Future<void> updateGroupImage(String groupId, String? groupImage) async {
    await _ref.read(groupsRepositoryProvider).updateGroupImage(groupId, groupImage);
  }
}

/// Exposes [GroupsListState] backed by a live Firestore stream.
///
/// All widgets that previously called:
///   ```dart
///   final groupsState = ref.watch(groupsListProvider);
///   ```
/// continue to work without changes.  The state now updates automatically
/// whenever the user's nests change in Firestore.
final groupsListProvider = StateNotifierProvider.autoDispose<GroupsListNotifier, GroupsListState>((ref) {
  return GroupsListNotifier(ref);
});


// Provider for specific group detail
final groupDetailProvider = StreamProvider.autoDispose.family<Group, String>((ref, id) {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  final controller = StreamController<Group>();

  DocumentSnapshot<Map<String, dynamic>>? lastNestDoc;
  QuerySnapshot<Map<String, dynamic>>? lastMembersDoc;

  void emitLatest() {
    if (lastNestDoc != null && lastMembersDoc != null) {
      if (!lastNestDoc!.exists) {
        controller.addError(Exception('Nest group not found.'));
        return;
      }

      final nestData = lastNestDoc!.data()!;
      final members = lastMembersDoc!.docs.map((memberDoc) {
        final data = memberDoc.data();
        final rawId = data['id'] ?? data['uid'] ?? memberDoc.id;
        final memberId = (user != null && rawId == user.uid) ? 'user_me' : rawId;
        return GroupMember(
          id: memberId,
          name: data['fullName'] ?? data['name'] ?? '',
          email: data['email'] ?? '',
          role: (data['role'] == 'admin' || data['role'] == 'owner') 
              ? MemberRole.admin 
              : MemberRole.member,
          joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? 
              (data['invitedAt'] as Timestamp?)?.toDate() ?? 
              DateTime.now(),
          photoUrl: data['profileImage'] ?? data['photoUrl'],
        );
      }).toList();

      final group = Group(
        id: lastNestDoc!.id,
        name: nestData['name'] ?? '',
        description: nestData['description'] ?? '',
        imageUrl: nestData['coverImage'],
        membersCount: nestData['memberCount'] ?? members.length,
        pendingBalance: 0.0,
        type: nestData['category'] ?? 'Custom',
        status: 'Settled',
        createdBy: nestData['createdBy'] ?? '',
        createdAt: (nestData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalExpenses: (nestData['totalExpense'] as num?)?.toDouble() ?? 0.0,
        totalPending: ((nestData['totalExpense'] as num?)?.toDouble() ?? 0.0) - 
            ((nestData['totalSettled'] as num?)?.toDouble() ?? 0.0),
        totalSettled: (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0,
        groupImage: nestData['coverImage'],
        members: members,
        inviteCode: nestData['inviteCode'] ?? '',
        settlementCycleDate: nestData['settlementCycleDate'] ?? 1,
        customStartDate: nestData['customStartDate'] != null 
            ? (nestData['customStartDate'] as Timestamp).toDate() 
            : null,
        customEndDate: nestData['customEndDate'] != null 
            ? (nestData['customEndDate'] as Timestamp).toDate() 
            : null,
        lastMessage: nestData['lastMessage'],
        lastMessageSender: nestData['lastMessageSender'],
        lastMessageTime: nestData['lastMessageTime'] != null
            ? (nestData['lastMessageTime'] as Timestamp).toDate()
            : null,
        lastMessageType: nestData['lastMessageType'],
        unreadCount: nestData['unreadCount'] != null
            ? (nestData['unreadCount'] as num).toInt()
            : null,
      );

      controller.add(group);
    }
  }

  final nestSub = firestore.collection('nests').doc(id).snapshots().listen(
    (snap) {
      lastNestDoc = snap;
      emitLatest();
    },
    onError: (err) => controller.addError(err),
  );

  final membersSub = firestore.collection('nests').doc(id).collection('members').snapshots().listen(
    (snap) {
      lastMembersDoc = snap;
      emitLatest();
    },
    onError: (err) => controller.addError(err),
  );

  ref.onDispose(() {
    nestSub.cancel();
    membersSub.cancel();
    controller.close();
  });

  return controller.stream;
});

// Stream of the nest's currentCycleId
final currentCycleIdProvider = StreamProvider.family<String?, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('nests')
      .doc(groupId)
      .snapshots()
      .map((snap) => snap.data()?['currentCycleId'] as String?);
});

/// Provides real-time [CycleStats] for a given group.
final cycleStatsProvider = StreamProvider.family<CycleStats, String>((ref, groupId) {
  final firestore = FirebaseFirestore.instance;
  
  // Watch the current cycle ID stream
  final cycleIdAsync = ref.watch(currentCycleIdProvider(groupId));
  final cycleId = cycleIdAsync.value;
  
  if (cycleId == null || cycleId.isEmpty) {
    return Stream.value(CycleStats(
      groupId: groupId,
      cycleStart: DateTime.now(),
      cycleEnd: DateTime.now(),
      totalExpenses: 0.0,
      totalSettled: 0.0,
      totalPending: 0.0,
      totalTransactions: 0,
      memberCount: 0,
    ));
  }
  
  return firestore
      .collection('nests')
      .doc(groupId)
      .collection('Cycle')
      .doc(cycleId)
      .snapshots()
      .map((cycleSnap) {
        if (!cycleSnap.exists) {
          return CycleStats(
            groupId: groupId,
            cycleStart: DateTime.now(),
            cycleEnd: DateTime.now(),
            totalExpenses: 0.0,
            totalSettled: 0.0,
            totalPending: 0.0,
            totalTransactions: 0,
            memberCount: 0,
          );
        }
        final cycleData = cycleSnap.data()!;
        return CycleStats(
          groupId: groupId,
          cycleStart: (cycleData['cycleStartDate'] as Timestamp).toDate(),
          cycleEnd: (cycleData['cycleEndDate'] as Timestamp).toDate(),
          totalExpenses: (cycleData['totalExpenses'] as num?)?.toDouble() ?? 0.0,
          totalSettled: (cycleData['totalSettled'] as num?)?.toDouble() ?? 0.0,
          totalPending: (cycleData['totalPending'] as num?)?.toDouble() ?? 0.0,
          totalTransactions: (cycleData['totalTransactions'] as num?)?.toInt() ?? 0,
          memberCount: (cycleData['memberCount'] as num?)?.toInt() ?? 0,
        );
      });
});

// ─────────────────────────────────────────────────────────────────────────────
// Global (cross-nest) aggregated cycle stats for the Home dashboard card.
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregated cycle stats across ALL active nests.
class GlobalCycleStats {
  final double totalExpenses;
  final double totalSettled;
  final double totalPending;
  final int totalTransactions;
  final int activeNestCount;

  /// Earliest cycle start across all nests (for the date range label).
  final DateTime? earliestCycleStart;

  /// Latest cycle end across all nests.
  final DateTime? latestCycleEnd;

  const GlobalCycleStats({
    required this.totalExpenses,
    required this.totalSettled,
    required this.totalPending,
    required this.totalTransactions,
    required this.activeNestCount,
    this.earliestCycleStart,
    this.latestCycleEnd,
  });

  double get settledPercent =>
      totalExpenses > 0 ? (totalSettled / totalExpenses).clamp(0.0, 1.0) : 0.0;

  static const GlobalCycleStats empty = GlobalCycleStats(
    totalExpenses: 0,
    totalSettled: 0,
    totalPending: 0,
    totalTransactions: 0,
    activeNestCount: 0,
  );
}

/// Aggregates [CycleStats] from every group into a single [GlobalCycleStats].
/// Rebuilds automatically whenever the Firestore nest stream emits updates.
final globalCycleStatsProvider = Provider<GlobalCycleStats>((ref) {
  final groupsState = ref.watch(groupsListProvider);

  if (groupsState.groups.isEmpty) return GlobalCycleStats.empty;

  double totalExp = 0;
  double totalSettled = 0;
  double totalPending = 0;
  int totalTxns = 0;
  DateTime? earliest;
  DateTime? latest;

  for (final g in groupsState.groups) {
    final statsAsync = ref.watch(cycleStatsProvider(g.id));
    final stats = statsAsync.value;
    if (stats == null) continue;

    totalExp += stats.totalExpenses;
    totalSettled += stats.totalSettled;
    totalPending += stats.totalPending;
    totalTxns += stats.totalTransactions;

    if (earliest == null || stats.cycleStart.isBefore(earliest)) {
      earliest = stats.cycleStart;
    }
    if (latest == null || stats.cycleEnd.isAfter(latest)) {
      latest = stats.cycleEnd;
    }
  }

  return GlobalCycleStats(
    totalExpenses: totalExp,
    totalSettled: totalSettled,
    totalPending: totalPending,
    totalTransactions: totalTxns,
    activeNestCount: groupsState.groups.length,
    earliestCycleStart: earliest,
    latestCycleEnd: latest,
  );
});

/// Returns the list of archived [CycleReport]s for [groupId] (newest first).
final cycleHistoryProvider =
    StreamProvider.family<List<CycleReport>, String>((ref, groupId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('nests')
      .doc(groupId)
      .collection('Cycle')
      .orderBy('cycleStartDate', descending: true)
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      return CycleReport(
        id: doc.id,
        groupId: groupId,
        cycleStart: (data['cycleStartDate'] as Timestamp).toDate(),
        cycleEnd: (data['cycleEndDate'] as Timestamp).toDate(),
        totalExpenses: (data['totalExpenses'] as num?)?.toDouble() ?? 0.0,
        totalSettled: (data['totalSettled'] as num?)?.toDouble() ?? 0.0,
        totalPending: (data['totalPending'] as num?)?.toDouble() ?? 0.0,
        totalTransactions: (data['totalTransactions'] as num?)?.toInt() ?? 0,
        memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
        archivedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  });
});
