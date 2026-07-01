import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/mock_database.dart';

final databaseChangeProvider = StreamProvider<int>((ref) {
  return MockDatabase().changeStream;
});

final notificationsStreamProvider = StreamProvider<String>((ref) {
  return MockDatabase().notificationsStream;
});
