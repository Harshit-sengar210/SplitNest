import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitnest/main.dart';

void main() {
  testWidgets('SplitNest app initial load and navigation test', (WidgetTester tester) async {
    // Suppress NetworkImageLoadExceptions since HTTP requests are blocked in tests
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      if (exceptionStr.contains('NetworkImageLoadException') || 
          exceptionStr.contains('statusCode: 400')) {
        return; // Ignore network image exceptions
      }
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    
    addTearDown(() {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SplitNestApp(),
      ),
    );

    // 1. Let GoRouter's initial redirect resolve (waits on MockAuthRepository's 500ms delay)
    // We advance the clock by 1000ms to ensure the splash screen is fully built and mounted.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Verify that the splash screen is now active
    expect(find.text('SPLITNEST'), findsOneWidget);
    expect(find.text('SHARED EXPENSES. ELEVATED.'), findsOneWidget);

    // Verify that the app successfully navigated to the Login Screen
    await tester.pump(const Duration(milliseconds: 5000));
    
    // Allow the 500ms getCurrentUser redirect delay in MockAuthRepository to complete
    await tester.pump(const Duration(milliseconds: 1000));
    
    // Pump frames to allow route transition (1500ms) and login screen entrance animations (1500ms) to run
    await tester.pump(const Duration(milliseconds: 3000));
    
    // Verify that the Login Screen is displayed
    expect(find.text('Welcome Back 👋'), findsOneWidget);
    expect(find.text('Split expenses. Live easy.'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
