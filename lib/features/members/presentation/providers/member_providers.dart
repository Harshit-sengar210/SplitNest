import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/members_service.dart';
import '../../data/repositories/firebase_member_repository.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/models/member_model.dart';

final membersServiceProvider = Provider<MembersService>((ref) {
  return MembersService();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final service = ref.watch(membersServiceProvider);
  return FirebaseMemberRepository(service);
});

final nestMembersStreamProvider = StreamProvider.family<List<MemberModel>, String>((ref, nestId) {
  final repository = ref.watch(memberRepositoryProvider);
  return repository.streamMembers(nestId).map((list) {
    // Separate owner(s) and other members
    final owners = list.where((m) => m.role == 'owner').toList();
    final nonOwners = list.where((m) => m.role != 'owner').toList();

    // Sort owners alphabetically by fullName
    owners.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    // Sort non-owners: active first, then alphabetically
    nonOwners.sort((a, b) {
      if (a.status == b.status) {
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      }
      // 'active' comes before 'invited'
      return a.status == 'active' ? -1 : 1;
    });

    return [...owners, ...nonOwners];
  });
});
