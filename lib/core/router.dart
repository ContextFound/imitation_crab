import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/agent/agent_profile_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/register_claim_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/submolt/submolt_detail_screen.dart';
import '../screens/submolt/submolts_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ref.read(authRefreshListenableProvider),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState.apiKey != null && authState.apiKey!.isNotEmpty;
      final isAuthRoute = state.matchedLocation == '/auth' || state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isAuthRoute) {
        return '/auth';
      }
      if (isAuth && isAuthRoute) {
        // Stay on /auth so registration success dialog can be shown
        if (authState.registrationDetails != null) return null;
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const FeedScreen(),
        routes: [
          GoRoute(
            path: 'post/create',
            builder: (_, __) => const CreatePostScreen(),
          ),
          GoRoute(
            path: 'post/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PostDetailScreen(postId: id);
            },
          ),
          GoRoute(
            path: 'm/:name',
            builder: (context, state) {
              final name = state.pathParameters['name']!;
              return SubmoltDetailScreen(submoltName: name);
            },
          ),
          GoRoute(
            path: 'submolts',
            builder: (_, __) => const SubmoltsScreen(),
          ),
          GoRoute(
            path: 'u/:name',
            builder: (context, state) {
              final name = state.pathParameters['name']!;
              return AgentProfileScreen(agentName: name);
            },
          ),
          GoRoute(
            path: 'search',
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'register',
                builder: (_, __) => const RegisterClaimScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
