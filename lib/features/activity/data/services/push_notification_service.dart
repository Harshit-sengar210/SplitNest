import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/notifications/notification_router.dart';
import '../../../../core/notifications/in_app_notification_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: \${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ProviderContainer? _container;

  PushNotificationService({ProviderContainer? container}) : _container = container;

  static void initializeBackground() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tapping on a local notification (if any are still shown)
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> initialize(dynamic ref) async {
    await _setupLocalNotifications();

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get FCM Token
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
          await saveTokenToDatabase(token);
        }
      } catch(e) {
        debugPrint("Error getting FCM token: \$e");
      }

      // 3. Listen for token changes
      _fcm.onTokenRefresh.listen(saveTokenToDatabase);

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        
        if (notification != null && !kIsWeb) {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            InAppNotificationOverlay.show(
              context: context,
              title: notification.title ?? '',
              body: notification.body ?? '',
              onTap: () {
                if (ref != null) {
                  NotificationRouter.handleNotificationTap(context, message.data, ref);
                }
              },
            );
          } else {
            // Fallback to local notification if context is somehow null
            _localNotificationsPlugin.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      });
      
      // 5. Handle background app open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final context = rootNavigatorKey.currentContext;
        if (context != null && ref != null) {
          NotificationRouter.handleNotificationTap(context, message.data, ref);
        } else {
          // If context is null, store it for later (edge case)
          NotificationRouter.parseRouteFromPayload(message.data);
        }
      });
    }
  }
  
  /// Handle app launch from terminated state via notification
  Future<void> handleInitialMessage(dynamic ref) async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Adding a slight delay allows the router to be fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
           NotificationRouter.handleNotificationTap(context, initialMessage.data, ref);
        });
      }
    }
  }

  Future<void> saveTokenToDatabase(String token) async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch(e) {}
  }
}
