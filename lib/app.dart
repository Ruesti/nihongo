import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'features/home/home_screen.dart';
import 'features/kaiwa/kaiwa_hub.dart';
import 'features/kanji_games/games_hub.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/mining_slice/reading_tab.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/onboarding_providers.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/travel/travel_screen.dart';

export 'features/onboarding/onboarding_providers.dart'
    show onboardingCompleteProvider;

// Routes
final List<RouteBase> _routes = [
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
        path: '/read',
        pageBuilder: (ctx, state) => const NoTransitionPage(
            child: ReadingTab()),
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
  GoRoute(
    path: '/onboarding',
    builder: (ctx, state) => OnboardingFlow(
      onFinished: () => ctx.go('/'),
    ),
  ),
];

/// The app's single `GoRouter` instance, built once and kept stable across
/// rebuilds.
///
/// `redirect` deliberately `ref.read`s the onboarding flag (not `ref.watch`)
/// so flipping `onboardingCompleteProvider` does NOT recreate this provider
/// or the router — GoRouter re-evaluates `redirect` on every navigation on
/// its own, so a live read is all that's needed. Rebuilding the router on
/// every onboarding-flag change (or on every widget rebuild, as the old
/// locally-constructed router did) would reset navigation state; that was
/// the root cause of the redirect-loop bug this provider fixes.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final complete = ref.read(onboardingCompleteProvider);
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!complete && !atOnboarding) return '/onboarding';
      return null;
    },
    routes: _routes,
  );
});

class NihongoApp extends ConsumerWidget {
  const NihongoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Nihongo',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (final locale in supportedLocales) {
          if (locale.languageCode == deviceLocale?.languageCode) return locale;
        }
        return const Locale('en');
      },
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
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Lesen',
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

  static const _routes = ['/', '/read', '/review', '/progress', '/kaiwa', '/games', '/settings'];

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
