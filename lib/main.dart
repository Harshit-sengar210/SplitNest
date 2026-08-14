import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';

import 'core/theme/theme_provider.dart';
import 'core/services/deep_link_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'features/activity/data/services/push_notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }



  // Try to initialize Firebase.
  try {
    if (kIsWeb) {
      final apiKey = dotenv.env['FIREBASE_API_KEY'];
      final appId = dotenv.env['FIREBASE_APP_ID'];
      final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
      final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
      final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];

      if (apiKey != null && appId != null && messagingSenderId != null && projectId != null) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            authDomain: authDomain,
            storageBucket: storageBucket,
            measurementId: measurementId,
          ),
        );
        debugPrint('Firebase initialized successfully with Web Env Options.');
      } else {
        await Firebase.initializeApp();
        debugPrint('Firebase initialized with default configuration.');
      }
    } else {
      // On mobile (Android/iOS), use the native configuration files (google-services.json)
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully on mobile.');
    }
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }


  // Initialize Push Notifications Background Handler
  if (!kIsWeb) {
    PushNotificationService.initializeBackground();
  }

  runApp(
    const ProviderScope(
      child: SplitNestApp(),
    ),
  );
}

class SplitNestApp extends ConsumerStatefulWidget {
  const SplitNestApp({super.key});

  @override
  ConsumerState<SplitNestApp> createState() => _SplitNestAppState();
}

class _SplitNestAppState extends ConsumerState<SplitNestApp> {
  @override
  void initState() {
    super.initState();
    // Initialize DeepLinkService after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        final router = ref.read(routerProvider);
        ref.read(deepLinkServiceProvider).initialize(router);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'SplitNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
