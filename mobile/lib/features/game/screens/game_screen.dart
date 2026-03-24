import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/timer_widget.dart';
import '../widgets/player_profile_popup.dart';
import '../../../core/theme/tavla_theme.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> gameData;

  const GameScreen({super.key, required this.gameData});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  final _chatController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(gameProvider.notifier).initGame(widget.gameData, user.id);
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    // Show error message only once per change
    ref.listen<GamePlayState>(gameProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: TavlaTheme.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // Show game over dialog once
    if (game.phase == GamePhase.finished && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(context, game);
      });
    }

    if (game.snapshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1A1C),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — opponent info + timer
            _buildPlayerBar(
              context,
              isOpponent: true,
              game: game,
              auth: auth,
            ),

            // Emoji reaction overlay
            if (game.lastEmoji != null)
              _buildEmojiOverlay(game.lastEmoji!),

            // Board (with integrated dice in center bar and bearing-off trays)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: BoardWidget(
                  board: game.snapshot!.board,
                  myColor: game.myColor ?? 'W',
                  selectedPoint: game.selectedPoint,
                  isMyTurn: game.isMyTurn,
                  showPointNumbers: settings.pointNumbersEnabled,
                  dice: game.snapshot!.dice,
                  remainingDice: game.snapshot!.remainingDice,
                  turnPhase: game.snapshot!.turnPhase,
                  canBearOff: _canBearOff(game),
                  validMoveTargets: game.isMyTurn
                      ? (game.selectedPoint != null
                          ? game.validMoveTargets
                          : (game.snapshot!.board.bar[game.myColor] ?? 0) > 0
                              ? ref.read(gameProvider.notifier).computeBarTargets()
                              : const {})
                      : const {},
                  onPointTap: (index) {
                    final notifier = ref.read(gameProvider.notifier);
                    final myBar = game.snapshot!.board.bar[game.myColor] ?? 0;

                    if (myBar > 0 && game.isMyTurn) {
                      notifier.movePieceFromBar(index);
                      return;
                    }

                    if (game.selectedPoint == null) {
                      final point = game.snapshot!.board.points[index];
                      if (point.count > 0 && point.player == game.myColor) {
                        notifier.selectPoint(index);
                      }
                    } else if (game.selectedPoint == index) {
                      notifier.selectPoint(-1);
                    } else {
                      notifier.makeMove(game.selectedPoint!, index);
                    }
                  },
                  onBarTap: () {},
                  onDiceTap: game.isMyTurn && game.snapshot!.turnPhase == 'rolling'
                      ? () => ref.read(gameProvider.notifier).rollDice()
                      : null,
                  onBearOffTap: game.isMyTurn && game.selectedPoint != null
                      ? () => ref.read(gameProvider.notifier).bearOff(game.selectedPoint!)
                      : null,
                ),
              ),
            ),

            // Bottom bar — my info + action buttons
            _buildPlayerBar(
              context,
              isOpponent: false,
              game: game,
              auth: auth,
            ),

            // Action buttons
            _buildActionBar(context, game),
          ],
        ),
      ),

      // Chat overlay
      endDrawer: _buildChatDrawer(context, game),
    );
  }

  Widget _buildEmojiOverlay(EmojiReaction emoji) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.5 + value * 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: TavlaTheme.darkBrown.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                emoji.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerBar(
    BuildContext context, {
    required bool isOpponent,
    required GamePlayState game,
    required AuthState auth,
  }) {
    final isCurrentTurn = isOpponent ? !game.isMyTurn : game.isMyTurn;
    final borneOff = _getBorneOff(game, isOpponent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isCurrentTurn
            ? LinearGradient(
                colors: [
                  const Color(0xFF2A2A2E).withValues(alpha: 0.8),
                  const Color(0xFF1A1A1C).withValues(alpha: 0.6),
                ],
              )
            : null,
        color: isCurrentTurn ? null : const Color(0xFF1A1A1C),
        border: Border(
          bottom: isOpponent
              ? BorderSide(
                  color: isCurrentTurn
                      ? TavlaTheme.gold.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                )
              : BorderSide.none,
          top: !isOpponent
              ? BorderSide(
                  color: isCurrentTurn
                      ? TavlaTheme.gold.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Player avatar with ring — tappable for profile
          GestureDetector(
            onTap: () {
              if (isOpponent && game.opponentUserId != null) {
                PlayerProfilePopup.show(context, ref, game.opponentUserId!);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentTurn ? TavlaTheme.gold : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: isOpponent
                    ? TavlaTheme.blackPiece
                    : TavlaTheme.whitePiece,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: isOpponent ? Colors.white : TavlaTheme.darkBrown,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name + turn indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOpponent
                    ? (game.opponentUsername ?? 'Rakip')
                    : (auth.user?.username ?? ''),
                style: TextStyle(
                  color: TavlaTheme.cream,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: isCurrentTurn
                      ? [
                          Shadow(
                            color: TavlaTheme.gold.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              if (isCurrentTurn)
                Text(
                  'Sıra',
                  style: TextStyle(
                    color: TavlaTheme.gold.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Borne off with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: TavlaTheme.cream.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '$borneOff/15',
                  style: TextStyle(
                    color: TavlaTheme.cream.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Timer
          if (isCurrentTurn && game.phase == GamePhase.playing)
            TimerWidget(
              seconds: game.turnTimer,
              maxSeconds: game.maxTimer,
              isActive: true,
            ),
        ],
      ),
    );
  }
  int _getBorneOff(GamePlayState game, bool isOpponent) {
    final color = isOpponent
        ? (game.myColor == 'W' ? 'B' : 'W')
        : game.myColor;
    return game.snapshot?.board.borneOff[color] ?? 0;
  }

  bool _canBearOff(GamePlayState game) {
    if (game.snapshot == null || game.myColor == null) return false;
    final board = game.snapshot!.board;
    final myColor = game.myColor!;
    // Check if all 15 pieces are in home board (points 0-5 for W, 18-23 for B)
    final bar = board.bar[myColor] ?? 0;
    if (bar > 0) return false;
    final borneOff = board.borneOff[myColor] ?? 0;
    int homeCount = borneOff;
    if (myColor == 'W') {
      for (int i = 0; i < 6; i++) {
        if (board.points[i].player == myColor) homeCount += board.points[i].count;
      }
    } else {
      for (int i = 18; i < 24; i++) {
        if (board.points[i].player == myColor) homeCount += board.points[i].count;
      }
    }
    return homeCount == 15;
  }

  Widget _buildActionBar(BuildContext context, GamePlayState game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF222224), Color(0xFF141416)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Roll dice hint (encourage tapping dice in bar)
          if (game.isMyTurn && game.snapshot?.turnPhase == 'rolling')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TavlaTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TavlaTheme.gold.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Color(0xCCD4A76A)),
                  SizedBox(width: 4),
                  Text(
                    'Zara Dokun',
                    style: TextStyle(
                      color: TavlaTheme.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // End turn
          if (game.isMyTurn && game.snapshot?.turnPhase == 'moving')
            ElevatedButton.icon(
              onPressed: () => ref.read(gameProvider.notifier).endTurn(),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Sıra Bitir', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TavlaTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
            ),

          // Undo button
          if (game.canUndo && game.isMyTurn)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.undo, color: TavlaTheme.gold),
                tooltip: 'Geri Al',
                onPressed: () => ref.read(gameProvider.notifier).undoMove(),
              ),
            ),

          const Spacer(),

          // Emoji bar
          _buildEmojiBar(),

          // Chat toggle
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: TavlaTheme.cream),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),

          // Resign
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: TavlaTheme.danger),
            onPressed: () => _showResignDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiBar() {
    const emojis = ['👍', '😂', '😮', '😡', '🎉', '🤔'];
    return PopupMenuButton<String>(
      icon: const Icon(Icons.emoji_emotions_outlined, color: TavlaTheme.gold),
      onSelected: (emoji) {
        ref.read(gameProvider.notifier).sendEmoji(emoji);
      },
      constraints: const BoxConstraints(maxWidth: 220),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 200,
            child: Wrap(
              alignment: WrapAlignment.center,
              children: emojis
                  .map((e) => InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(gameProvider.notifier).sendEmoji(e);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teslim Ol'),
        content: const Text('Oyunu teslim etmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resign();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TavlaTheme.danger),
            child: const Text('Teslim Ol'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDrawer(BuildContext context, GamePlayState game) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Sohbet'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: game.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = game.chatMessages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: TavlaTheme.brown,
                        ),
                      ),
                      Text(msg.message),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yaz...',
                      isDense: true,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: TavlaTheme.brown),
                  onPressed: () => _sendMessage(_chatController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(gameProvider.notifier).sendChat(text);
    _chatController.clear();
  }

  void _showGameOverDialog(BuildContext context, GamePlayState game) {
    final won = game.resultMessage?.contains('Kazandın') == true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: won ? TavlaTheme.gold : TavlaTheme.danger,
            ),
            const SizedBox(height: 16),
            Text(
              game.resultMessage ?? 'Oyun Bitti',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (game.eloChange != null) ...[
              const SizedBox(height: 12),
              Text(
                'ELO: ${game.eloChange! >= 0 ? '+' : ''}${game.eloChange}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: game.eloChange! >= 0
                      ? TavlaTheme.success
                      : TavlaTheme.danger,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/lobby');
              },
              child: const Text('Lobiye Dön'),
            ),
          ),
        ],
      ),
    );
  }
}
