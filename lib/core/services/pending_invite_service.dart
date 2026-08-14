import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pendingInviteServiceProvider = Provider<PendingInviteService>((ref) {
  return PendingInviteService();
});

class PendingInviteService {
  static const String _pendingInviteKey = 'pending_invite_token';

  Future<void> savePendingInvite(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInviteKey, token);
  }

  Future<String?> getPendingInvite() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingInviteKey);
  }

  Future<void> clearPendingInvite() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingInviteKey);
  }
}
