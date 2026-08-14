import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../domain/models/invite.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FirebaseInviteRepository implements InviteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final AuthRepository _authRepository;

  FirebaseInviteRepository(this._authRepository);

  @override
  Future<Invite?> getInvite(String inviteToken) async {
    try {
      // 1. Check for a permanent group invite code first
      final nestQuery = await _firestore.collection('nests').where('inviteCode', isEqualTo: inviteToken.toUpperCase()).limit(1).get();
      if (nestQuery.docs.isNotEmpty) {
        final nestDoc = nestQuery.docs.first;
        final nestData = nestDoc.data();
        return Invite(
          inviteToken: inviteToken,
          nestId: nestDoc.id,
          nestName: nestData['name'] ?? 'Nest Group',
          inviterUserId: 'system',
          status: InviteStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 3650)),
          memberCount: (nestData['memberIds'] as List<dynamic>? ?? []).length,
        );
      }

      // 2. Fallback to legacy invites
      final doc = await _firestore.collection('invites').doc(inviteToken).get();
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null) return null;
      
      return Invite.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching invite: $e');
      return null;
    }
  }

  @override
  Future<void> joinNestFromInvite(String inviteToken) async {
    final user = await _authRepository.getCurrentUser();
    final realUser = _firebaseAuth.currentUser;
    if (user == null || realUser == null) {
      throw Exception('User must be logged in to join a Nest.');
    }
    final String realUid = realUser.uid;

    // First, check if the token matches a permanent nest inviteCode
    final nestQuery = await _firestore.collection('nests').where('inviteCode', isEqualTo: inviteToken.toUpperCase()).limit(1).get();
    
    String nestId;
    Invite? invite;
    if (nestQuery.docs.isNotEmpty) {
      nestId = nestQuery.docs.first.id;
    } else {
      // Fallback to legacy invite token
      invite = await getInvite(inviteToken);
      if (invite == null) {
        throw Exception('This invitation is no longer available or invalid.');
      }
      if (invite.status == InviteStatus.expired ||
          invite.expiresAt.isBefore(DateTime.now())) {
        throw Exception('This invitation has expired.');
      }
      if (invite.status == InviteStatus.revoked) {
        throw Exception('This invitation is no longer available.');
      }
      if (invite.allowedEmail != null && invite.allowedEmail!.isNotEmpty) {
        if (user.email.toLowerCase() != invite.allowedEmail!.toLowerCase()) {
          throw Exception('This invitation was created for another account.');
        }
      }
      nestId = invite.nestId;
    }

    // ── ALL READS (outside batch — no ordering constraint) ──────────
    final nestRef = _firestore.collection('nests').doc(nestId);
    final nestSnapshot = await nestRef.get();

    if (!nestSnapshot.exists) {
      throw Exception('This Nest is no longer available.');
    }

    final nestData = nestSnapshot.data()!;
    final List<dynamic> memberIds =
        List<dynamic>.from(nestData['memberIds'] ?? []);

    if (memberIds.contains(realUid)) {
      throw Exception('You are already a member of this Nest.');
    }

    // Check if user document exists
    final userRef = _firestore.collection('users').doc(realUid);
    final userSnapshot = await userRef.get();
    // ── END READS ────────────────────────────────────────────────────

    // Build the updated memberIds list
    memberIds.add(realUid);
    final int newCount = memberIds.length;

    // ── ALL WRITES via batch (atomic, no read-after-write issue) ─────
    final batch = _firestore.batch();

    // 1. Update nest memberIds and memberCount
    batch.update(nestRef, {
      'memberIds': memberIds,
      'memberCount': newCount,
    });

    // 2. Add to members subcollection
    final memberRef = nestRef.collection('members').doc(realUid);
    batch.set(memberRef, {
      'id': realUid,
      'uid': realUid, // Adding uid field to match existing pattern
      'fullName': user.displayName,
      'name': user.displayName,
      'email': user.email,
      'role': 'member',
      'photoUrl': user.photoUrl,
      'profileImage': user.photoUrl,
      'joinedAt': Timestamp.fromDate(DateTime.now()),
    });

    // 3. Set the joined user's active nest
    if (userSnapshot.exists) {
      batch.update(userRef, {'activeNestId': nestId});
    }

    // 4. Mark email-restricted invites as accepted
    if (invite != null && invite.allowedEmail != null && invite.allowedEmail!.isNotEmpty) {
      final inviteRef = _firestore.collection('invites').doc(inviteToken);
      batch.update(inviteRef, {'status': InviteStatus.accepted.name});
    }

    await batch.commit();
    // ── END WRITES ───────────────────────────────────────────────────
  }
}

