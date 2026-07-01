import '../../domain/models/member_model.dart';
import '../../domain/repositories/member_repository.dart';
import '../services/members_service.dart';

class FirebaseMemberRepository implements MemberRepository {
  final MembersService _service;

  FirebaseMemberRepository(this._service);

  @override
  Stream<List<MemberModel>> streamMembers(String nestId) {
    return _service.streamMembers(nestId).map((snapshot) {
      return snapshot.docs
          .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> addMember(String nestId, MemberModel member) async {
    await _service.addMember(nestId, member.id, member.toMap());
  }

  @override
  Future<void> updateMemberRole(
      String nestId, String memberId, String role) async {
    await _service.updateMemberRole(nestId, memberId, role);
  }

  @override
  Future<void> removeMember(String nestId, String memberId) async {
    await _service.removeMember(nestId, memberId);
  }
}

