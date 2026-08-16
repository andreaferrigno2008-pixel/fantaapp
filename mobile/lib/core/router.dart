import 'package:go_router/go_router.dart';

import '../features/asta/asta_rose_screen.dart';
import '../features/asta/asta_screen.dart';
import '../features/formazione/formazione_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/scambio/scambio_screen.dart';
import '../features/players/player_detail_screen.dart';
import '../features/players/players_list_screen.dart';
import '../features/roster/my_roster_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/players', builder: (context, state) => const PlayersListScreen()),
    GoRoute(
      path: '/players/:id',
      builder: (context, state) =>
          PlayerDetailScreen(playerId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/roster', builder: (context, state) => const MyRosterScreen()),
    GoRoute(path: '/asta', builder: (context, state) => const AstaScreen()),
    GoRoute(
      path: '/asta/:id/rose',
      builder: (context, state) => AstaRoseScreen(astaId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/formazione', builder: (context, state) => const FormazioneSetupScreen()),
    GoRoute(path: '/scambio', builder: (context, state) => const ScambioScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);
