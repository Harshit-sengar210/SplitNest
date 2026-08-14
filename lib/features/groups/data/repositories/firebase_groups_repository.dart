import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../../activity/data/services/notification_writer.dart';

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
            
            // Self-healing: if corrupted 'user_me' exists, delete it
            bool hasCorruptedData = false;
            for (final memberDoc in membersSnap.docs) {
              final data = memberDoc.data();
              if (data['id'] == 'user_me' || memberDoc.id == 'user_me') {
                try {
                  await memberDoc.reference.delete();
                  final memberIdsList = List<dynamic>.from(doc.data()['memberIds'] ?? []);
                  memberIdsList.remove('user_me');
                  await doc.reference.update({
                    'memberIds': memberIdsList,
                    'memberCount': memberIdsList.length,
                  });
                  hasCorruptedData = true;
                  debugPrint('Self-healed corrupted user_me data in nest: ${doc.id}');
                } catch (e) {
                  debugPrint('Self-healing failed: $e');
                }
              }
            }
            
            // Re-fetch members if we healed data
            final finalMembersSnap = hasCorruptedData 
                ? await doc.reference.collection('members').get() 
                : membersSnap;
                
            groups.add(_docToGroup(doc, finalMembersSnap, user.uid));
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

    NotificationWriter.sendToGroup(
      groupId: groupId,
      title: 'New Member Invited',
      description: '$memberName was invited to the nest.',
      type: 'member_joined',
      relatedItemId: memberId,
    );
  }

  @override
  Future<String> generateInviteCode(String groupId) async {
    final doc = await _firestore.collection('nests').doc(groupId).get();
    var inviteCode = doc.data()?['inviteCode'] as String?;
    
    if (inviteCode == null || inviteCode.trim().isEmpty) {
      // Generate a permanent one for older nests
      final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O, 0, I, 1 to avoid confusion
      final rand = DateTime.now().millisecondsSinceEpoch;
      String token = '';
      var seed = rand;
      for (int i = 0; i < 6; i++) {
        token += chars[seed % chars.length];
        seed = (seed * 48271 + 1) % 2147483647;
      }
      inviteCode = token;
      await _firestore.collection('nests').doc(groupId).update({'inviteCode': inviteCode});
    }
    
    return inviteCode;
  }

  @override
  Future<String> generateShareLink(String groupId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Must be logged in to generate invite link.');

    final inviteCode = await generateInviteCode(groupId);
    
    // Copy to clipboard is handled by the UI, but we return the link format here
    return 'https://splitnest.app/join?code=$inviteCode';
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    final user = _firebaseAuth.currentUser;
    final targetId = (userId == 'user_me' && user != null) ? user.uid : userId;
    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST
      final nestRef = _firestore.collection('nests').doc(groupId);
      final nestDoc = await transaction.get(nestRef);
      if (!nestDoc.exists) return;

      final userRef = _firestore.collection('users').doc(targetId);
      final userDoc = await transaction.get(userRef);

      // 2. ALL WRITES AFTER READS
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

      // Clear activeNestId if it matches this group
      if (userDoc.exists && userDoc.data()?['activeNestId'] == groupId) {
        transaction.update(userRef, {'activeNestId': FieldValue.delete()});
      }
    });

    NotificationWriter.sendToGroup(
      groupId: groupId,
      title: 'Member Removed',
      description: 'A member was removed from the nest.',
      type: 'member_removed',
      relatedItemId: targetId,
    );
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
  Future<void> deleteGroup(String groupId) async {
    final nestRef = _firestore.collection('nests').doc(groupId);
    
    // 1. Fetch member IDs before deleting
    final nestDoc = await nestRef.get();
    final memberIds = List<String>.from(nestDoc.data()?['memberIds'] ?? []);

    // 2. For every member, clear their activeNestId if it points to this group
    //    (do this in parallel for speed)
    final batch = _firestore.batch();
    for (final uid in memberIds) {
      final userRef = _firestore.collection('users').doc(uid);
      // Use a conditional update: only clear if activeNestId matches this group
      batch.update(userRef, {
        'activeNestId': FieldValue.delete(),
      });
    }
    try {
      await batch.commit();
    } catch (_) {
      // Best-effort — some users might not have the field, ignore errors
    }

    // 3. Delete the nest document itself. This triggers the real-time stream
    //    (groupDetailProvider / createdNestsStreamProvider / watchGroups) for
    //    ALL members and they will be automatically redirected to the dashboard.
    await nestRef.delete();
  }

  @override
  Future<void> updateGroupImage(String groupId, String? groupImage) async {
    await _firestore.collection('nests').doc(groupId).update({
      'coverImage': groupImage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
