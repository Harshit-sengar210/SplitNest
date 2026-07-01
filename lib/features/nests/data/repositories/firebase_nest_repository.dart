import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/nest_model.dart';
import '../../domain/repositories/nest_repository.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';

class FirebaseNestRepository implements NestRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customFirebaseAuth;

  FirebaseNestRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _customFirestore = firestore,
        _customFirebaseAuth = firebaseAuth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => _customFirebaseAuth ?? FirebaseAuth.instance;

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueInviteCode() async {
    while (true) {
      // Generate code between 6 and 8 characters. Let's use 6 characters.
      final code = _generateCode(6);
      final querySnapshot = await _firestore
          .collection('nests')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return code;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _resolveInvites({
    List<String>? inviteEmails,
    List<String>? inviteUsernames,
    List<String>? invitePhones,
  }) async {
    final List<Map<String, dynamic>> resolvedMembers = [];
    final List<Future<void>> lookupFutures = [];
    final Set<String> processedValues = {};

    if (inviteEmails != null) {
      for (final email in inviteEmails) {
        final trimmed = email.trim();
        if (trimmed.isEmpty || processedValues.contains(trimmed)) continue;
        processedValues.add(trimmed);

        lookupFutures.add(
          _firestore
              .collection('users')
              .where('email', isEqualTo: trimmed)
              .limit(1)
              .get()
              .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final userDoc = snapshot.docs.first;
              final data = userDoc.data();
              resolvedMembers.add({
                'id': userDoc.id,
                'fullName': data['fullName'] ?? data['displayName'] ?? trimmed.split('@').first,
                'email': data['email'] ?? trimmed,
                'profileImage': data['profileImage'] ?? data['photoUrl'],
              });
            } else {
              final tempId = _firestore.collection('placeholder').doc().id;
              resolvedMembers.add({
                'id': tempId,
                'fullName': trimmed.split('@').first,
                'email': trimmed,
                'profileImage': null,
              });
            }
          }),
        );
      }
    }

    if (inviteUsernames != null) {
      for (final username in inviteUsernames) {
        final trimmed = username.trim();
        if (trimmed.isEmpty || processedValues.contains(trimmed)) continue;
        processedValues.add(trimmed);

        lookupFutures.add(
          _firestore
              .collection('users')
              .where('username', isEqualTo: trimmed)
              .limit(1)
              .get()
              .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final userDoc = snapshot.docs.first;
              final data = userDoc.data();
              resolvedMembers.add({
                'id': userDoc.id,
                'fullName': data['fullName'] ?? data['displayName'] ?? trimmed,
                'email': data['email'] ?? '',
                'profileImage': data['profileImage'] ?? data['photoUrl'],
              });
            } else {
              final tempId = _firestore.collection('placeholder').doc().id;
              resolvedMembers.add({
                'id': tempId,
                'fullName': trimmed,
                'email': '',
                'profileImage': null,
              });
            }
          }),
        );
      }
    }

    if (invitePhones != null) {
      for (final phone in invitePhones) {
        final trimmed = phone.trim();
        if (trimmed.isEmpty || processedValues.contains(trimmed)) continue;
        processedValues.add(trimmed);

        lookupFutures.add(
          _firestore
              .collection('users')
              .where('phone', isEqualTo: trimmed)
              .limit(1)
              .get()
              .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final userDoc = snapshot.docs.first;
              final data = userDoc.data();
              resolvedMembers.add({
                'id': userDoc.id,
                'fullName': data['fullName'] ?? data['displayName'] ?? trimmed,
                'email': data['email'] ?? '',
                'profileImage': data['profileImage'] ?? data['photoUrl'],
              });
            } else {
              final tempId = _firestore.collection('placeholder').doc().id;
              resolvedMembers.add({
                'id': tempId,
                'fullName': trimmed,
                'email': '',
                'profileImage': null,
              });
            }
          }),
        );
      }
    }

    await Future.wait(lookupFutures);
    return resolvedMembers;
  }

  @override
  Future<NestModel> createNest({
    required String name,
    required String description,
    required String category,
    String? currency,
    String? coverImage,
    List<String>? inviteEmails,
    List<String>? inviteUsernames,
    List<String>? invitePhones,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      final creatorUid = user.uid;
      final docRef = _firestore.collection('nests').doc();
      final inviteCode = await _generateUniqueInviteCode();

      // Resolve creator profile info first
      final creatorDoc = await _firestore.collection('users').doc(creatorUid).get();
      String creatorName = user.displayName ?? user.email?.split('@').first ?? 'Admin';
      String creatorEmail = user.email ?? '';
      String? creatorPhotoUrl = user.photoURL;

      if (creatorDoc.exists) {
        final data = creatorDoc.data()!;
        creatorName = data['fullName'] ?? data['displayName'] ?? creatorName;
        creatorEmail = data['email'] ?? creatorEmail;
        creatorPhotoUrl = data['profileImage'] ?? data['photoUrl'] ?? creatorPhotoUrl;
      }

      // Resolve invited members
      final resolvedMembers = await _resolveInvites(
        inviteEmails: inviteEmails,
        inviteUsernames: inviteUsernames,
        invitePhones: invitePhones,
      );

      // Exclude creator from the list to avoid duplicate entries if creator invited themselves
      final uniqueInvitedMembers = resolvedMembers.where((m) => m['id'] != creatorUid).toList();
      final memberIds = [creatorUid, ...uniqueInvitedMembers.map((m) => m['id'] as String)];
      final memberCount = memberIds.length;

      // Firestore transaction to ensure atomic Nest creation, Subcollection writing, and User activeNestId update
      await _firestore.runTransaction((transaction) async {
        final bounds = CycleCalculator.calculateCycleBounds(cycleDay: 1);
        final cycleId = 'cycle_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';

        // Prepare Nest data using FieldValue.serverTimestamp() for createdAt, updatedAt, lastActivity
        final nestMap = {
          'name': name,
          'description': description,
          'coverImage': coverImage,
          'category': category,
          'currency': currency ?? 'INR',
          'createdBy': creatorUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'inviteCode': inviteCode,
          'memberCount': memberCount,
          'totalExpense': 0.0,
          'totalSettled': 0.0,
          'currentCycleId': cycleId,
          'lastActivity': FieldValue.serverTimestamp(),
          'isArchived': false,
          'memberIds': memberIds,
        };

        // Write the Nest document
        transaction.set(docRef, nestMap);

        // Write the initial Cycle document
        final cycleRef = docRef.collection('Cycle').doc(cycleId);
        transaction.set(cycleRef, {
          'cycleId': cycleId,
          'cycleStartDate': Timestamp.fromDate(bounds.start),
          'cycleEndDate': Timestamp.fromDate(bounds.end),
          'totalExpenses': 0.0,
          'totalSettled': 0.0,
          'totalPending': 0.0,
          'totalTransactions': 0,
          'memberCount': memberCount,
          'settledPercentage': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Write the creator member document to nests/{nestId}/members/{creatorUid}
        final creatorMemberRef = docRef.collection('members').doc(creatorUid);
        transaction.set(creatorMemberRef, {
          'id': creatorUid,
          'uid': creatorUid,
          'fullName': creatorName,
          'email': creatorEmail,
          'profileImage': creatorPhotoUrl,
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'isActive': true,
        });

        // Write resolved invited member documents to nests/{nestId}/members/{memberId}
        for (final m in uniqueInvitedMembers) {
          final memberRef = docRef.collection('members').doc(m['id']);
          transaction.set(memberRef, {
            'id': m['id'],
            'uid': m['id'],
            'fullName': m['fullName'],
            'email': m['email'],
            'profileImage': m['profileImage'],
            'role': 'member',
            'status': 'invited',
            'isActive': false,
            'invitedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update the creator's user document activeNestId
        final userDocRef = _firestore.collection('users').doc(creatorUid);
        transaction.set(
          userDocRef,
          {'activeNestId': docRef.id},
          SetOptions(merge: true),
        );

        // Write timeline event for nest creation
        final timelineRef =
            docRef.collection('timeline').doc();
        transaction.set(timelineRef, {
          'type': 'nest_created',
          'title': 'Nest Created',
          'description': '$creatorName created the nest “$name”',
          'amount': null,
          'userId': creatorUid,
          'userName': creatorName,
          'expenseId': null,
          'settlementId': null,
          'memberId': creatorUid,
          'icon': 'home',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Retrieve the newly created Nest document to construct a complete NestModel
      final createdDoc = await docRef.get();
      if (!createdDoc.exists) {
        throw Exception('Failed to retrieve created Nest document.');
      }

      return NestModel.fromFirestore(createdDoc);
    } catch (e) {
      throw Exception('Failed to create nest: $e');
    }
  }

  @override
  Future<NestModel?> getNest(String nestId) async {
    try {
      final doc = await _firestore.collection('nests').doc(nestId).get();
      if (!doc.exists) return null;
      return NestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to retrieve nest data: $e');
    }
  }

  @override
  Future<void> updateNest({
    required String nestId,
    String? name,
    String? description,
    String? category,
    String? currency,
    String? coverImage,
    int? memberCount,
    double? totalExpense,
    double? totalSettled,
    String? currentCycleId,
    bool? isArchived,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (currency != null) updates['currency'] = currency;
      if (coverImage != null) updates['coverImage'] = coverImage;
      if (memberCount != null) updates['memberCount'] = memberCount;
      if (totalExpense != null) updates['totalExpense'] = totalExpense;
      if (totalSettled != null) updates['totalSettled'] = totalSettled;
      if (currentCycleId != null) updates['currentCycleId'] = currentCycleId;
      if (isArchived != null) updates['isArchived'] = isArchived;

      if (updates.isEmpty) return;

      updates['updatedAt'] = FieldValue.serverTimestamp();
      updates['lastActivity'] = FieldValue.serverTimestamp();

      await _firestore.collection('nests').doc(nestId).update(updates);
    } catch (e) {
      throw Exception('Failed to update nest: $e');
    }
  }

  @override
  Future<void> archiveNest(String nestId) async {
    try {
      await _firestore.collection('nests').doc(nestId).update({
        'isArchived': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to archive nest: $e');
    }
  }

  @override
  Future<void> deleteNest(String nestId) async {
    try {
      await _firestore.collection('nests').doc(nestId).delete();
    } catch (e) {
      throw Exception('Failed to delete nest: $e');
    }
  }

  @override
  Future<NestModel?> getCurrentNest() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final activeNestId = userDoc.data()?['activeNestId'] as String?;
      if (activeNestId == null) return null;

      return await getNest(activeNestId);
    } catch (e) {
      throw Exception('Failed to fetch current active nest: $e');
    }
  }

  @override
  Future<NestModel?> getNestByInviteCode(String inviteCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('nests')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) return null;
      return NestModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to query nest by invite code: $e');
    }
  }
}
