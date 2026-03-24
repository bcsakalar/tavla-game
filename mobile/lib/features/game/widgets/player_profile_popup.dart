import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tavla_theme.dart';
import '../../../shared/models/user.dart';
import '../../auth/providers/auth_provider.dart';

/// Shows a compact profile popup when tapping a player's avatar during a game.
class PlayerProfilePopup {
  /// Shows opponent's stats in a bottom sheet (loads from API).
  static void show(BuildContext context, WidgetRef ref, int userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(userId: userId, ref: ref),
    );
  }

  /// Shows a simple profile card with provided data (no API call).
  static void showQuick(
    BuildContext context, {
    required String username,
    int? elo,
    int? userId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickProfileCard(
        username: username,
        elo: elo,
      ),
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  final int userId;
  final WidgetRef ref;

  const _ProfileSheet({required this.userId, required this.ref});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = widget.ref.read(apiClientProvider);
      final data = await api.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _user = User.fromJson(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: TavlaTheme.gold),
              ),
            )
          : _user == null
              ? const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'Profil yüklenemedi',
                      style: TextStyle(color: TavlaTheme.cream),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TavlaTheme.cream.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar + Name
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: TavlaTheme.darkBrown,
                      child: Text(
                        _user!.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: TavlaTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.username,
                      style: const TextStyle(
                        color: TavlaTheme.cream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: TavlaTheme.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _user!.ratingTier,
                        style: const TextStyle(
                          color: TavlaTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('ELO', '${_user!.eloRating}', Icons.star),
                        _statItem('Galibiyet', '${_user!.totalWins}',
                            Icons.emoji_events),
                        _statItem(
                            'Mağlubiyet', '${_user!.totalLosses}', Icons.close),
                        _statItem(
                          'Kazanma',
                          '%${_user!.winRate.toStringAsFixed(0)}',
                          Icons.percent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Mars / Backgammon row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('Toplam', '${_user!.totalGamesPlayed}',
                            Icons.sports_esports),
                        _statItem(
                            'Mars', '${_user!.totalGammons}', Icons.whatshot),
                        _statItem('Üç Mars', '${_user!.totalBackgammons}',
                            Icons.local_fire_department),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: TavlaTheme.gold.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: TavlaTheme.cream,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: TavlaTheme.cream.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _QuickProfileCard extends StatelessWidget {
  final String username;
  final int? elo;

  const _QuickProfileCard({required this.username, this.elo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TavlaTheme.cream.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: TavlaTheme.darkBrown,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                color: TavlaTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            username,
            style: const TextStyle(
              color: TavlaTheme.cream,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (elo != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: TavlaTheme.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$elo ELO',
                  style: const TextStyle(
                    color: TavlaTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
