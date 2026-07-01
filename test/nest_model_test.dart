import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/nests/domain/models/nest_model.dart';
import 'package:splitnest/features/nests/domain/repositories/nest_repository.dart';
import 'package:splitnest/features/nests/data/repositories/firebase_nest_repository.dart';

void main() {
  group('NestModel Tests', () {
    test('Initialization with default values', () {
      final nest = NestModel(
        nestId: 'nest_123',
        name: 'Cozy Nest',
        description: 'Roommate sharing',
        category: 'Home',
        createdBy: 'user_owner',
        inviteCode: 'CODE12',
      );

      expect(nest.nestId, 'nest_123');
      expect(nest.name, 'Cozy Nest');
      expect(nest.description, 'Roommate sharing');
      expect(nest.category, 'Home');
      expect(nest.currency, 'INR');
      expect(nest.createdBy, 'user_owner');
      expect(nest.createdAt, isNull);
      expect(nest.updatedAt, isNull);
      expect(nest.inviteCode, 'CODE12');
      expect(nest.memberCount, 1);
      expect(nest.totalExpense, 0.0);
      expect(nest.totalSettled, 0.0);
      expect(nest.currentCycleId, isNull);
      expect(nest.lastActivity, isNull);
      expect(nest.isArchived, isFalse);
    });

    test('copyWith updates fields correctly', () {
      final nest = NestModel(
        nestId: 'nest_123',
        name: 'Cozy Nest',
        description: 'Roommate sharing',
        category: 'Home',
        createdBy: 'user_owner',
        inviteCode: 'CODE12',
        coverImage: 'some_image_url',
        currentCycleId: 'cycle_1',
        memberIds: const ['user_owner'],
      );

      final updated = nest.copyWith(
        name: 'New Nest Name',
        memberCount: 3,
        totalExpense: 150.0,
        isArchived: true,
        clearCoverImage: true,
        clearCurrentCycleId: true,
        memberIds: ['user_owner', 'member_1', 'member_2'],
      );

      expect(updated.nestId, 'nest_123');
      expect(updated.name, 'New Nest Name');
      expect(updated.description, 'Roommate sharing');
      expect(updated.category, 'Home');
      expect(updated.coverImage, isNull);
      expect(updated.memberCount, 3);
      expect(updated.totalExpense, 150.0);
      expect(updated.currentCycleId, isNull);
      expect(updated.isArchived, isTrue);
      expect(updated.memberIds, equals(['user_owner', 'member_1', 'member_2']));
    });

    test('toFirestore and fromMap serialization roundtrip', () {
      final date = DateTime(2026, 6, 20, 12, 0, 0);
      final nest = NestModel(
        nestId: 'nest_123',
        name: 'Cozy Nest',
        description: 'Roommate sharing',
        coverImage: 'image_url',
        category: 'Home',
        currency: 'USD',
        createdBy: 'user_owner',
        createdAt: date,
        updatedAt: date,
        inviteCode: 'CODE12',
        memberCount: 2,
        totalExpense: 100.5,
        totalSettled: 50.0,
        currentCycleId: 'cycle_abc',
        lastActivity: date,
        isArchived: true,
        memberIds: const ['user_owner', 'member_1'],
      );

      final firestoreMap = nest.toFirestore();
      
      // Simulating Firebase converting timestamps
      final parsedMap = <String, dynamic>{
        ...firestoreMap,
        'createdAt': Timestamp.fromDate(date),
        'updatedAt': Timestamp.fromDate(date),
        'lastActivity': Timestamp.fromDate(date),
      };

      final reconstructed = NestModel.fromMap(parsedMap, 'nest_123');

      expect(reconstructed, equals(nest));
      expect(reconstructed.hashCode, equals(nest.hashCode));
    });

    test('Equality operators evaluate correctly', () {
      final nestA = NestModel(
        nestId: 'nest_123',
        name: 'Cozy Nest',
        description: 'Roommate sharing',
        category: 'Home',
        createdBy: 'user_owner',
        inviteCode: 'CODE12',
        memberIds: const ['user_owner'],
      );

      final nestB = NestModel(
        nestId: 'nest_123',
        name: 'Cozy Nest',
        description: 'Roommate sharing',
        category: 'Home',
        createdBy: 'user_owner',
        inviteCode: 'CODE12',
        memberIds: const ['user_owner'],
      );

      final nestC = NestModel(
        nestId: 'nest_123',
        name: 'Different Nest',
        description: 'Roommate sharing',
        category: 'Home',
        createdBy: 'user_owner',
        inviteCode: 'CODE12',
        memberIds: const ['user_owner', 'other'],
      );

      expect(nestA, equals(nestB));
      expect(nestA == nestC, isFalse);
    });
  });

  group('NestRepository Interface compliance', () {
    test('FirebaseNestRepository matches NestRepository contract', () {
      final FirebaseNestRepository repo = FirebaseNestRepository();
      expect(repo, isA<NestRepository>());
    });
  });
}
