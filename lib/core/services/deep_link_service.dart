import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;

  DeepLinkService() {
    _appLinks = AppLinks();
  }

  void initialize(GoRouter router) {
    _router = router;
    
    // Check initial link if app was cold started from a link
    _checkInitialLink();

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // slight delay to let router finish initial navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (_router == null) return;
    
    // Check if it's an invite link
    // https://splitnest.app/invite/{token}
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'invite') {
      if (uri.pathSegments.length > 1) {
        final token = uri.pathSegments[1];
        debugPrint('Deep link captured invite token: $token');
        _router!.push('/invite/$token');
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
