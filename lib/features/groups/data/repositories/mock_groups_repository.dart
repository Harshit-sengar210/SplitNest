import 'dart:math';
import '../../domain/models/group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../../../core/utils/mock_database.dart';

class MockGroupsRepository implements GroupsRepository {
  final MockDatabase _db = MockDatabase();

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  Future<List<Group>> getGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_db.groups);
  }

  @override
  Future<Group> getGroupById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.groups.firstWhere(
      (g) => g.id == id,
      orElse: () => throw Exception('Nest group not found.'),
    );
  }

  @override
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
    await Future.delayed(const Duration(milliseconds: 600));

    final inviteCode = _generateCode(6);
    final now = DateTime.now();

    // Creator as admin member
    final creatorMember = GroupMember(
      id: 'user_me',
      name: 'You',
      email: 'user@example.com',
      role: MemberRole.admin,
      joinedAt: now,
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
    );

    final invitedMembers = <GroupMember>[];
    if (inviteEmails != null) {
      for (int i = 0; i < inviteEmails.length; i++) {
        final email = inviteEmails[i];
        final memberName = email.split('@').first;
        invitedMembers.add(
          GroupMember(
            id: 'user_${memberName.toLowerCase()}',
            name: memberName[0].toUpperCase() + memberName.substring(1),
            email: email,
            role: MemberRole.member,
            joinedAt: now,
          ),
        );
      }
    }

    final allMembers = [creatorMember, ...invitedMembers];

    final newGroup = Group(
      id: 'nest_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      imageUrl: null,
      membersCount: allMembers.length,
      pendingBalance: 0.0,
      type: type,
      status: 'Settled',
      createdBy: 'user_me',
      createdAt: now,
      totalExpenses: 0.0,
      totalPending: 0.0,
      totalSettled: 0.0,
      groupImage: groupImage,
      members: allMembers,
      inviteCode: inviteCode,
      settlementCycleDate: settlementCycleDate ?? 1,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    _db.createGroup(newGroup);
    return newGroup;
  }

  @override
  Future<void> inviteMember({
    required String groupId,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.addMember(groupId, email);
  }

  @override
  Future<String> generateInviteCode(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final code = _generateCode(6);
    final index = _db.groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _db.groups[index] = _db.groups[index].copyWith(inviteCode: code);
      _db.triggerChange();
    }
    return code;
  }

  @override
  Future<String> generateShareLink(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'https://splitnest.app/join/$groupId';
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.removeMember(groupId, userId);
  }

  @override
  Future<void> promoteToAdmin(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final groupIndex = _db.groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final oldGroup = _db.groups[groupIndex];
      final memberIndex = oldGroup.members.indexWhere((m) => m.id == userId);
      if (memberIndex != -1) {
        final updatedMembers = List<GroupMember>.from(oldGroup.members);
        final oldMember = updatedMembers[memberIndex];
        updatedMembers[memberIndex] = oldMember.copyWith(role: MemberRole.admin);
        
        _db.groups[groupIndex] = oldGroup.copyWith(members: updatedMembers);
        
        _db.logActivity(
          groupId: groupId,
          actorId: 'user_me',
          type: 'member_joined', // or similar
          title: 'Role Promoted',
          description: '${oldMember.name} was promoted to Admin',
          createdAt: DateTime.now(),
          actorName: 'You',
          groupName: oldGroup.name,
        );

        _db.triggerNotification('${oldMember.name} is now an Admin in ${oldGroup.name}');
        _db.triggerChange();
      }
    }
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.removeMember(groupId, userId);
  }

  @override
  Future<void> updateGroupImage(String groupId, String? groupImage) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.updateGroupImage(groupId, groupImage);
  }
}
