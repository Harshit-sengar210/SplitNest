import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';

import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  // Try to initialize Firebase. If it fails, the app still runs gracefully using our Mock Fallbacks.
  try {
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
      debugPrint('Firebase initialized successfully with Env Options.');
    } else {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized with default configuration.');
    }
  } catch (e) {
    // Firebase initialization failed or config was not provided.
    // The AppProvider automatically detects this and falls back to MockAuthRepository.
    debugPrint('Firebase not initialized: running in Local Mock mode. Error: $e');
  }

  runApp(
    const ProviderScope(
      child: SplitNestApp(),
    ),
  );
}

class SplitNestApp extends ConsumerWidget {
  const SplitNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
