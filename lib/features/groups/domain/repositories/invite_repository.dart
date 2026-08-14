import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invite.dart';
import '../../data/repositories/firebase_invite_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return FirebaseInviteRepository(authRepo);
});

abstract class InviteRepository {
  /// Fetches an invite by token (safe preview info)
  Future<Invite?> getInvite(String inviteToken);
  
  /// Processes/Joins a Nest using an invite token for the authenticated user
  Future<void> joinNestFromInvite(String inviteToken);
}
