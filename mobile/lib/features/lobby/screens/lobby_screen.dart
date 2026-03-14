import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lobby_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/theme/tavla_theme.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobby = ref.watch(lobbyProvider);
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final user = auth.user;

    // Show tutorial for first-time users
    if (!settings.hasSeenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/tutorial');
      });
    }

    // Navigate via match found splash when matched
    ref.listen(lobbyProvider, (prev, next) {
      if (next.status == QueueStatus.matched && next.matchData != null) {
        ref.read(lobbyProvider.notifier).clearMatch();
        context.go('/game', extra: next.matchData);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tavla Online'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User info card
              if (user != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: TavlaTheme.darkBrown,
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              color: TavlaTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.username,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.ratingTier} • ${user.eloRating} ELO',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: TavlaTheme.brown,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user.totalWins}G / ${user.totalLosses}M • %${user.winRate.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Online count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: TavlaTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lobby.onlineCount} oyuncu çevrimiçi',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Queue button
              if (lobby.status == QueueStatus.idle) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(lobbyProvider.notifier).joinQueue(),
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'Rakip Bul',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBotDifficultyDialog(context),
                    icon: const Icon(Icons.smart_toy, size: 28),
                    label: const Text(
                      'Bota Karşı Oyna',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TavlaTheme.brown,
                      side: const BorderSide(color: TavlaTheme.brown, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // Searching state
              if (lobby.status == QueueStatus.searching) ...[
                const CircularProgressIndicator(color: TavlaTheme.brown),
                const SizedBox(height: 16),
                Text(
                  'Rakip aranıyor... ${lobby.searchSeconds}s',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.read(lobbyProvider.notifier).cancelQueue(),
                  child: const Text('İptal'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showBotDifficultyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Zorluk Seçin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DifficultyTile(
            icon: Icons.sentiment_satisfied,
            label: 'Kolay',
            subtitle: 'Rastgele hamleler',
            color: TavlaTheme.success,
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/bot', extra: {'difficulty': 'easy'});
            },
          ),
          const SizedBox(height: 8),
          _DifficultyTile(
            icon: Icons.sentiment_neutral,
            label: 'Orta',
            subtitle: 'Dengeli strateji',
            color: TavlaTheme.gold,
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/bot', extra: {'difficulty': 'medium'});
            },
          ),
          const SizedBox(height: 8),
          _DifficultyTile(
            icon: Icons.sentiment_very_dissatisfied,
            label: 'Zor',
            subtitle: 'Güçlü pozisyonel oyun',
            color: TavlaTheme.danger,
            onTap: () {
              Navigator.of(ctx).pop();
              context.go('/bot', extra: {'difficulty': 'hard'});
            },
          ),
        ],
      ),
    ),
  );
}

class _DifficultyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
