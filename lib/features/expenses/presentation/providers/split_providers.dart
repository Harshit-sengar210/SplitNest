import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/split_model.dart';
import '../../domain/repositories/split_repository.dart';
import '../../data/repositories/firebase_split_repository.dart';
import '../../data/services/split_service.dart';

final splitServiceProvider = Provider<SplitService>((ref) {
  return SplitService();
});

final splitRepositoryProvider = Provider<SplitRepository>((ref) {
  final service = ref.watch(splitServiceProvider);
  return FirebaseSplitRepository(service);
});

final expenseSplitsStreamProvider = StreamProvider.family<List<SplitModel>, ({String groupId, String expenseId})>((ref, arg) {
  final repository = ref.watch(splitRepositoryProvider);
  return repository.streamSplits(arg.groupId, arg.expenseId);
});
