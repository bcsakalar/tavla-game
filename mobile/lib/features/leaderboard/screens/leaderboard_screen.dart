import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/tavla_theme.dart';
import '../../../shared/models/user.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<User> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.getLeaderboard();
      setState(() {
        _players = data.map<User>((p) => User.fromJson(p)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıralama'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? const Center(child: Text('Henüz oyuncu yok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return _buildPlayerTile(context, player, index + 1);
                  },
                ),
    );
  }

  Widget _buildPlayerTile(BuildContext context, User player, int rank) {
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFFFD700);
    if (rank == 2) medalColor = const Color(0xFFC0C0C0);
    if (rank == 3) medalColor = const Color(0xFFCD7F32);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/profile/${player.id}'),
        leading: SizedBox(
          width: 40,
          child: medalColor != null
              ? Icon(Icons.emoji_events, color: medalColor, size: 32)
              : Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: TavlaTheme.brown,
                    ),
                  ),
                ),
        ),
        title: Text(
          player.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${player.ratingTier} • ${player.totalWins}G / ${player.totalLosses}M',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${player.eloRating}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TavlaTheme.brown,
              ),
            ),
            const Text(
              'ELO',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
