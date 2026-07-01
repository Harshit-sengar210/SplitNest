import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/login_success_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/calendar_screen.dart';
import '../../features/activity/presentation/screens/notifications_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/cycle_screen.dart';
import '../../features/groups/presentation/screens/member_detail_screen.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/screens/scan_receipt_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/settlement/presentation/screens/settlement_screen.dart';
import '../../features/settlement/presentation/screens/settlement_detail_screen.dart';
import '../../features/profile/presentation/screens/placeholder_setting_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/push_alerts_screen.dart';
import '../../features/profile/presentation/screens/security_settings_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/about_app_screen.dart';
import '../../features/profile/presentation/screens/theme_settings_screen.dart';
import '../../features/profile/presentation/screens/payment_methods_screen.dart';
import '../../features/ledger/presentation/screens/ledger_screen.dart';
import '../../features/ledger/presentation/screens/add_ledger_transaction_screen.dart';
import '../../features/ledger/presentation/screens/ledger_transaction_detail_screen.dart';
import '../../features/balances/presentation/screens/balances_screen.dart';
import '../../features/chat/presentation/screens/group_chat_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) {
        return null;
      }

      final user = await authRepository.getCurrentUser();
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isOnboarding = state.matchedLocation == '/onboarding';
      
      final isAuthRoute = isLoggingIn || isRegistering || isForgotPassword || isOnboarding;
      
      if (user == null) {
        // Let user stay on auth routes, otherwise redirect to login.
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }
      
      // User is logged in.
      final activeNestId = user.activeNestId;

      if (isAuthRoute) {
        return '/login-success?isNew=${activeNestId == null}';
      }

      if (activeNestId == null) {
        if (state.matchedLocation != '/welcome' &&
            state.matchedLocation != '/groups/create' &&
            state.matchedLocation != '/login-success') {
          return '/welcome';
        }
      } else {
        if (state.matchedLocation == '/welcome') {
          return '/dashboard';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: false,
            transitionDuration: const Duration(milliseconds: 1500),
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;
            },
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/calendar',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CalendarScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/login-success',
        builder: (context, state) {
          final isNew = state.uri.queryParameters['isNew'] == 'true';
          return LoginSuccessScreen(isNewUser: isNew);
        },
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/groups/create',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CreateGroupScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/groups/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: GroupDetailScreen(groupId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0), // subtle slide from right
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/groups/:id/chat',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: GroupChatScreen(groupId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          );
        },
      ),
      GoRoute(
        path: '/groups/:id/balances',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BalancesScreen(groupId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/groups/:id/cycle',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CycleScreen(groupId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/members/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MemberDetailScreen(memberId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/expenses/add',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AddExpenseScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/expenses/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final groupId = state.uri.queryParameters['groupId'];
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: ExpenseDetailScreen(
              id: id,
              groupId: groupId,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/scan-receipt',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ScanReceiptScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/settlement',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SettlementScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/settlement/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? 'Settlement';
          final amount = state.uri.queryParameters['amount'] ?? '\$0.00';
          final iconCode = int.tryParse(state.uri.queryParameters['icon'] ?? '0') ?? Icons.done_all_rounded.codePoint;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: SettlementDetailScreen(
              id: id,
              title: title,
              amount: amount,
              iconCodePoint: iconCode,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0), // Slide up from bottom for edit screens
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/push-alerts',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PushAlertsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/security',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SecuritySettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/help-support',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const HelpSupportScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/about',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AboutAppScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/theme',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ThemeSettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/payment-methods',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PaymentMethodsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/settings/:id',
        pageBuilder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Settings';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaceholderSettingScreen(title: title),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/personal-ledger',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LedgerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/personal-ledger/add',
        builder: (context, state) => const AddLedgerTransactionScreen(),
      ),
      GoRoute(
        path: '/personal-ledger/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LedgerTransactionDetailScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/personal-ledger/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddLedgerTransactionScreen(editId: id);
        },
      ),
    ],
  );
});
