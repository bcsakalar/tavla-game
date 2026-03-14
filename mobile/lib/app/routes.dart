import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/lobby/screens/lobby_screen.dart';
import '../features/lobby/screens/match_found_screen.dart';
import '../features/game/screens/game_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tutorial/screens/tutorial_screen.dart';
import '../features/game/screens/bot_game_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/match-found',
      redirect: (context, state) {
        if (state.extra == null) return '/lobby';
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MatchFoundScreen(
          gameData: extra,
          onReady: () {
            // Navigate handled by the screen itself
          },
        );
      },
    ),
    GoRoute(
      path: '/game',
      redirect: (context, state) {
        if (state.extra == null) return '/lobby';
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return GameScreen(gameData: extra);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        return ProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/bot',
      redirect: (context, state) {
        if (state.extra == null) return '/lobby';
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BotGameScreen(difficulty: extra['difficulty'] ?? 'easy');
      },
    ),
  ],
);
