import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class NotificationRouter {
  static String? _pendingRoute;

  /// Parses the FCM payload data into a valid deep link path
  static String? parseRouteFromPayload(Map<String, dynamic> data) {
    if (data.containsKey('route')) {
      return data['route'];
    }

    final type = data['type'];
    final nestId = data['groupId'];
    final expenseId = data['relatedItemId']; // Or whatever logic is used

    if (type == null) return null;

    switch (type) {
      case 'expense_created':
      case 'expense_updated':
        if (expenseId != null && nestId != null) {
          return '/expenses/detail/\$expenseId?groupId=\$nestId';
        }
        break;
      case 'nest_invite':
        if (data['token'] != null) {
          final token = data['token'];
          return '/invite/\$token';
        }
        break;
      case 'chat_message':
        if (nestId != null) {
          return '/groups/\$nestId/chat'; // Assuming there is a chat route, fallback to group
        }
        break;
      case 'settlement_completed':
        if (data['settlementId'] != null && nestId != null) {
          final settlementId = data['settlementId'];
          return '/settlement/detail/\$settlementId?groupId=\$nestId';
        }
        break;
      case 'balance_updated':
        return '/balances';
    }

    if (nestId != null) {
      return '/groups/\$nestId';
    }

    return '/dashboard';
  }

  /// Called when a notification is tapped. 
  /// If the user is authenticated and ready, navigates immediately.
  /// If not, stores the route and waits for initialization.
  static void handleNotificationTap(BuildContext context, Map<String, dynamic> data, dynamic ref) {
    final route = parseRouteFromPayload(data);
    if (route == null) return;

    final authState = ref.read(authStateChangesProvider);
    final user = authState.value;

    if (user != null) {
      context.push(route);
    } else {
      _pendingRoute = route;
      // The GoRouter redirect logic or a post-login listener should check _pendingRoute
      context.go('/login');
    }
  }

  /// Returns and clears the pending route
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }
}
