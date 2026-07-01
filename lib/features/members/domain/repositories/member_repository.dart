import '../models/member_model.dart';

abstract class MemberRepository {
  Stream<List<MemberModel>> streamMembers(String nestId);
  Future<void> addMember(String nestId, MemberModel member);
  Future<void> updateMemberRole(String nestId, String memberId, String role);
  Future<void> removeMember(String nestId, String memberId);
}
