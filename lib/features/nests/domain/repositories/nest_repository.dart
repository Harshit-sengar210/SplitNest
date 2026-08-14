import '../models/nest_model.dart';

abstract class NestRepository {
  Future<NestModel> createNest({
    required String name,
    required String description,
    required String category,
    String? currency,
    String? coverImage,
    List<String>? inviteEmails,
    List<String>? inviteUsernames,
    List<String>? invitePhones,
    int settlementCycleDate = 1,
    DateTime? customStartDate,
    DateTime? customEndDate,
  });

  Future<NestModel?> getNest(String nestId);

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
  });

  Future<void> archiveNest(String nestId);

  Future<void> deleteNest(String nestId);

  Future<NestModel?> getCurrentNest();

  Future<NestModel?> getNestByInviteCode(String inviteCode);
}
