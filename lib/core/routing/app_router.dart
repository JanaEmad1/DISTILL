import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/forgot_password_screen.dart';
import '../../features/auth/ui/sign_in_screen.dart';
import '../../features/auth/ui/sign_up_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../features/chat/ui/chats_list_screen.dart';
import '../../features/documents/ui/document_detail_screen.dart';
import '../../features/documents/ui/home_screen.dart';
import '../../features/documents/ui/processing_screen.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/onboarding/ui/splash_screen.dart';
import '../../features/profile/ui/edit_profile_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/profile/ui/settings_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../di/providers.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Public routes reachable while signed out.
const _publicRoutes = {
  '/splash',
  '/onboarding',
  '/sign-in',
  '/sign-up',
  '/forgot-password',
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  // Bump the notifier whenever auth state changes so the router re-evaluates.
  ref.listen(authStateProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      // Wait on splash until auth resolves.
      if (state.matchedLocation == '/splash') return null;
      if (authState.isLoading) return null;

      final loggedIn = authState.value != null;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (!loggedIn && !isPublic) return '/sign-in';
      if (loggedIn &&
          (state.matchedLocation == '/sign-in' ||
              state.matchedLocation == '/sign-up')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen()),

      // Primary tabbed area.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(navigatorKey: _shellKey, routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/chats', builder: (_, _) => const ChatsListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),

      // Full-screen routes above the shell.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/processing/:id',
        builder: (_, s) =>
            ProcessingScreen(documentId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/document/:id',
        builder: (_, s) =>
            DocumentDetailScreen(documentId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/chat/:id',
        builder: (_, s) => ChatScreen(documentId: s.pathParameters['id']!),
      ),
      GoRoute(
          parentNavigatorKey: _rootKey,
          path: '/edit-profile',
          builder: (_, _) => const EditProfileScreen()),
      GoRoute(
          parentNavigatorKey: _rootKey,
          path: '/settings',
          builder: (_, _) => const SettingsScreen()),
    ],
  );
});
