import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/group.dart';
import '../../domain/repositories/groups_repository.dart';

class FirebaseGroupsRepository implements GroupsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<List<Group>> getGroups() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];
    
    final snapshot = await _firestore
        .collection('nests')
        .where('memberIds', arrayContains: user.uid)
        .get();
    
    final List<Group> groups = [];
    for (final doc in snapshot.docs) {
      final nestData = doc.data();
      final membersSnapshot = await doc.reference.collection('members').get();
      final members = membersSnapshot.docs.map((memberDoc) {
        final data = memberDoc.data();
        final rawId = data['id'] ?? data['uid'] ?? memberDoc.id;
        final id = rawId == user.uid ? 'user_me' : rawId;
        return GroupMember(
          id: id,
          name: data['fullName'] ?? data['name'] ?? '',
          email: data['email'] ?? '',
          role: (data['role'] == 'admin' || data['role'] == 'owner') ? MemberRole.admin : MemberRole.member,
          joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          photoUrl: data['profileImage'] ?? data['photoUrl'],
        );
      }).toList();

      groups.add(Group(
        id: doc.id,
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
        totalPending: ((nestData['totalExpense'] as num?)?.toDouble() ?? 0.0) - ((nestData['totalSettled'] as num?)?.toDouble() ?? 0.0),
        totalSettled: (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0,
        groupImage: nestData['coverImage'],
        members: members,
        inviteCode: nestData['inviteCode'] ?? '',
        settlementCycleDate: nestData['settlementCycleDate'] ?? 1,
        customStartDate: nestData['customStartDate'] != null ? (nestData['customStartDate'] as Timestamp).toDate() : null,
        customEndDate: nestData['customEndDate'] != null ? (nestData['customEndDate'] as Timestamp).toDate() : null,
        lastMessage: nestData['lastMessage'],
        lastMessageSender: nestData['lastMessageSender'],
        lastMessageTime: nestData['lastMessageTime'] != null ? (nestData['lastMessageTime'] as Timestamp).toDate() : null,
        lastMessageType: nestData['lastMessageType'],
        unreadCount: nestData['unreadCount'] != null ? (nestData['unreadCount'] as num).toInt() : null,
      ));
    }
    return groups;
  }

  /// Converts a Firestore [DocumentSnapshot] + [members] sub-collection into a [Group].
  Group _docToGroup(
    DocumentSnapshot<Map<String, dynamic>> doc,
    QuerySnapshot<Map<String, dynamic>> membersSnap,
    String currentUserId,
  ) {
    final nestData = doc.data()!;
    final members = membersSnap.docs.map((memberDoc) {
      final data = memberDoc.data();
      final rawId = data['id'] ?? data['uid'] ?? memberDoc.id;
      final id = rawId == currentUserId ? 'user_me' : rawId;
      return GroupMember(
        id: id,
        name: data['fullName'] ?? data['name'] ?? '',
        email: data['email'] ?? '',
        role: (data['role'] == 'admin' || data['role'] == 'owner') ? MemberRole.admin : MemberRole.member,
        joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        photoUrl: data['profileImage'] ?? data['photoUrl'],
      );
    }).toList();

    return Group(
      id: doc.id,
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
      totalPending: ((nestData['totalExpense'] as num?)?.toDouble() ?? 0.0) - ((nestData['totalSettled'] as num?)?.toDouble() ?? 0.0),
      totalSettled: (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0,
      groupImage: nestData['coverImage'],
      members: members,
      inviteCode: nestData['inviteCode'] ?? '',
      settlementCycleDate: nestData['settlementCycleDate'] ?? 1,
      customStartDate: nestData['customStartDate'] != null ? (nestData['customStartDate'] as Timestamp).toDate() : null,
      customEndDate: nestData['customEndDate'] != null ? (nestData['customEndDate'] as Timestamp).toDate() : null,
      lastMessage: nestData['lastMessage'],
      lastMessageSender: nestData['lastMessageSender'],
      lastMessageTime: nestData['lastMessageTime'] != null ? (nestData['lastMessageTime'] as Timestamp).toDate() : null,
      lastMessageType: nestData['lastMessageType'],
      unreadCount: nestData['unreadCount'] != null ? (nestData['unreadCount'] as num).toInt() : null,
    );
  }

  @override
  Stream<List<Group>> watchGroups() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return Stream.value([]);

    // Subscribe to the nests query; each new snapshot triggers a fresh build.
    return _firestore
        .collection('nests')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .asyncMap((querySnap) async {
          debugPrint('DEBUG: [watchGroups] Firestore snapshot received — ${querySnap.docs.length} nest(s)');
          final List<Group> groups = [];
          for (final doc in querySnap.docs) {
            final membersSnap = await doc.reference.collection('members').get();
            groups.add(_docToGroup(doc, membersSnap, user.uid));
          }
          return groups;
        });
  }

  @override
  Future<Group> getGroupById(String id) async {
    debugPrint('DEBUG: [GroupsRepository] Selected nestId: $id');
    debugPrint('DEBUG: [GroupsRepository] Received nestId on details screen: $id');
    final docPath = 'nests/$id';
    debugPrint('DEBUG: [GroupsRepository] Firestore document path being queried: $docPath');

    final doc = await _firestore.collection('nests').doc(id).get();
    final docExists = doc.exists;
    debugPrint('DEBUG: [GroupsRepository] Whether the document exists: $docExists');

    if (!docExists) {
      throw Exception('Nest group not found.');
    }

    final nestData = doc.data()!;
    final user = _firebaseAuth.currentUser;
    final membersSnapshot = await doc.reference.collection('members').get();
    final members = membersSnapshot.docs.map((memberDoc) {
      final data = memberDoc.data();
      final rawId = data['id'] ?? data['uid'] ?? memberDoc.id;
      final id = (user != null && rawId == user.uid) ? 'user_me' : rawId;
      return GroupMember(
        id: id,
        name: data['fullName'] ?? data['name'] ?? '',
        email: data['email'] ?? '',
        role: (data['role'] == 'admin' || data['role'] == 'owner') ? MemberRole.admin : MemberRole.member,
        joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        photoUrl: data['profileImage'] ?? data['photoUrl'],
      );
    }).toList();

    return Group(
      id: doc.id,
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
      totalPending: ((nestData['totalExpense'] as num?)?.toDouble() ?? 0.0) - ((nestData['totalSettled'] as num?)?.toDouble() ?? 0.0),
      totalSettled: (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0,
      groupImage: nestData['coverImage'],
      members: members,
      inviteCode: nestData['inviteCode'] ?? '',
      settlementCycleDate: nestData['settlementCycleDate'] ?? 1,
      customStartDate: nestData['customStartDate'] != null ? (nestData['customStartDate'] as Timestamp).toDate() : null,
      customEndDate: nestData['customEndDate'] != null ? (nestData['customEndDate'] as Timestamp).toDate() : null,
      lastMessage: nestData['lastMessage'],
      lastMessageSender: nestData['lastMessageSender'],
      lastMessageTime: nestData['lastMessageTime'] != null ? (nestData['lastMessageTime'] as Timestamp).toDate() : null,
      lastMessageType: nestData['lastMessageType'],
      unreadCount: nestData['unreadCount'] != null ? (nestData['unreadCount'] as num).toInt() : null,
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
    throw UnimplementedError('Creation has migrated to FirebaseNestRepository.');
  }

  @override
  Future<void> inviteMember({required String groupId, required String email}) async {
    final userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    
    String memberId;
    String memberName;
    String? memberPhotoUrl;

    if (userSnapshot.docs.isNotEmpty) {
      final userDoc = userSnapshot.docs.first;
      memberId = userDoc.id;
      final data = userDoc.data();
      memberName = data['fullName'] ?? data['displayName'] ?? email.split('@').first;
      memberPhotoUrl = data['profileImage'] ?? data['photoUrl'];
    } else {
      memberId = _firestore.collection('placeholder').doc().id;
      memberName = email.split('@').first;
      memberPhotoUrl = null;
    }

    await _firestore.runTransaction((transaction) async {
      final nestRef = _firestore.collection('nests').doc(groupId);
      final nestDoc = await transaction.get(nestRef);
      if (!nestDoc.exists) return;

      final data = nestDoc.data()!;
      final List<String> memberIds = List<String>.from(data['memberIds'] ?? []);
      if (!memberIds.contains(memberId)) {
        memberIds.add(memberId);
      }

      transaction.update(nestRef, {
        'memberIds': memberIds,
        'memberCount': memberIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final memberRef = nestRef.collection('members').doc(memberId);
      transaction.set(memberRef, {
        'id': memberId,
        'uid': memberId,
        'fullName': memberName,
        'email': email,
        'role': 'member',
        'status': 'invited',
        'isActive': false,
        'invitedAt': FieldValue.serverTimestamp(),
        'profileImage': memberPhotoUrl,
      });
    });
  }

  @override
  Future<String> generateInviteCode(String groupId) async {
    final doc = await _firestore.collection('nests').doc(groupId).get();
    return doc.data()?['inviteCode'] ?? '';
  }

  @override
  Future<String> generateShareLink(String groupId) async {
    final doc = await _firestore.collection('nests').doc(groupId).get();
    final code = doc.data()?['inviteCode'] ?? '';
    return 'https://splitnest.page.link/join?code=$code';
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    final user = _firebaseAuth.currentUser;
    final targetId = (userId == 'user_me' && user != null) ? user.uid : userId;
    await _firestore.runTransaction((transaction) async {
      final nestRef = _firestore.collection('nests').doc(groupId);
      final nestDoc = await transaction.get(nestRef);
      if (!nestDoc.exists) return;

      final data = nestDoc.data()!;
      final List<String> memberIds = List<String>.from(data['memberIds'] ?? []);
      memberIds.remove(targetId);

      transaction.update(nestRef, {
        'memberIds': memberIds,
        'memberCount': memberIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final memberRef = nestRef.collection('members').doc(targetId);
      transaction.delete(memberRef);
    });
  }

  @override
  Future<void> promoteToAdmin(String groupId, String userId) async {
    final user = _firebaseAuth.currentUser;
    final targetId = (userId == 'user_me' && user != null) ? user.uid : userId;
    await _firestore
        .collection('nests')
        .doc(groupId)
        .collection('members')
        .doc(targetId)
        .update({'role': 'admin'});
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    await removeMember(groupId, userId);
  }

  @override
  Future<void> updateGroupImage(String groupId, String? groupImage) async {
    await _firestore.collection('nests').doc(groupId).update({
      'coverImage': groupImage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
