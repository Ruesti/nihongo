import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/kaiwa/kaiwa_hub.dart';
import 'features/kanji_games/games_hub.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/travel/travel_screen.dart';

// Router
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          _MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: HomeScreen()),
        ),
        GoRoute(
          path: '/review',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: ReviewScreen()),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: ProgressScreen()),
        ),
        GoRoute(
          path: '/kaiwa',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: KaiwaHub()),
        ),
        GoRoute(
          path: '/travel',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: TravelScreen()),
        ),
        GoRoute(
          path: '/games',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: GamesHub()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (ctx, state) => const NoTransitionPage(
              child: SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (ctx, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
        return LessonScreen(lessonId: id);
      },
    ),
  ],
);

class NihongoApp extends ConsumerWidget {
  const NihongoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Nihongo',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _MainShell extends StatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.refresh_outlined),
      selectedIcon: Icon(Icons.refresh),
      label: 'Review',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Fortschritt',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Gespräch',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports),
      label: 'Spiele',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Einstellungen',
    ),
  ];

  static const _routes = ['/', '/review', '/progress', '/kaiwa', '/games', '/settings'];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    GoRouter.of(context).go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}
