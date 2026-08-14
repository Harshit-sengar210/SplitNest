import '../models/group.dart';

abstract class GroupsRepository {
  Future<List<Group>> getGroups();

  /// Real-time stream of the current user's nests.
  Stream<List<Group>> watchGroups();

  Future<Group> getGroupById(String id);

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
  });

  Future<void> inviteMember({
    required String groupId,
    required String email,
  });

  Future<String> generateInviteCode(String groupId);

  Future<String> generateShareLink(String groupId);

  // Admin and Member actions
  Future<void> removeMember(String groupId, String userId);
  
  Future<void> promoteToAdmin(String groupId, String userId);
  
  Future<void> leaveGroup(String groupId, String userId);

  Future<void> deleteGroup(String groupId);

  Future<void> updateGroupImage(String groupId, String? groupImage);
}
