import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/nest_model.dart';
import '../../domain/repositories/nest_repository.dart';
import '../../data/repositories/firebase_nest_repository.dart';

final nestRepositoryProvider = Provider<NestRepository>((ref) {
  return FirebaseNestRepository();
});

final currentNestProvider = FutureProvider<NestModel?>((ref) async {
  final repository = ref.watch(nestRepositoryProvider);
  return repository.getCurrentNest();
});

final nestDetailsProvider = FutureProvider.family<NestModel?, String>((ref, nestId) async {
  final repository = ref.watch(nestRepositoryProvider);
  return repository.getNest(nestId);
});

// Stream of nests where the current authenticated user is a member
final createdNestsStreamProvider = StreamProvider<List<NestModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection('nests')
      .where('memberIds', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => NestModel.fromFirestore(doc)).toList());
});

// Stream of user's activeNestId to handle joined nests
final activeNestIdStreamProvider = StreamProvider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data()?['activeNestId'] as String?);
});

// Combines created nests and joined active nest in real-time
final userNestsProvider = FutureProvider<List<NestModel>>((ref) async {
  final createdNestsAsync = ref.watch(createdNestsStreamProvider);
  final activeNestIdAsync = ref.watch(activeNestIdStreamProvider);

  final createdNests = createdNestsAsync.value ?? [];
  final activeNestId = activeNestIdAsync.value;

  final List<NestModel> combined = List.from(createdNests);

  if (activeNestId != null && !combined.any((n) => n.nestId == activeNestId)) {
    try {
      final doc = await FirebaseFirestore.instance.collection('nests').doc(activeNestId).get();
      if (doc.exists) {
        combined.add(NestModel.fromFirestore(doc));
      }
    } catch (_) {
      // Ignore activeNestId fetch issues gracefully
    }
  }

  // Sort by lastActivity or createdAt descending
  combined.sort((a, b) {
    final aTime = a.lastActivity ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.lastActivity ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  return combined;
});

// Holds search query state for Nests list screen
final nestsSearchQueryProvider = StateProvider<String>((ref) => '');

// Filters combined user nests according to search query
final filteredNestsProvider = Provider<AsyncValue<List<NestModel>>>((ref) {
  final nestsAsync = ref.watch(userNestsProvider);
  final searchQuery = ref.watch(nestsSearchQueryProvider);

  return nestsAsync.whenData((nests) {
    if (searchQuery.trim().isEmpty) return nests;
    final query = searchQuery.toLowerCase().trim();
    return nests.where((nest) {
      return nest.name.toLowerCase().contains(query) ||
             nest.description.toLowerCase().contains(query);
    }).toList();
  });
});
