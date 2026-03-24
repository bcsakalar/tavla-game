import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bot_game_provider.dart';
import '../providers/game_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../utils/board_layout.dart';
import '../widgets/board_widget.dart';
import '../../../core/theme/tavla_theme.dart';

class BotGameScreen extends ConsumerStatefulWidget {
  final String difficulty;

  const BotGameScreen({super.key, required this.difficulty});

  @override
  ConsumerState<BotGameScreen> createState() => _BotGameScreenState();
}

class _BotGameScreenState extends ConsumerState<BotGameScreen> {
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref
            .read(botGameProvider.notifier)
            .startBotGame(widget.difficulty, user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(botGameProvider);
    final settings = ref.watch(settingsProvider);

    // Show error message only once per change
    ref.listen<GamePlayState>(botGameProvider, (prev, next) {
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

    if (game.phase == GamePhase.finished && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog(context, game);
      });
    }

    if (game.snapshot == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1C),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: TavlaTheme.gold),
              const SizedBox(height: 16),
              Text(
                'Bot oyunu başlatılıyor...',
                style: TextStyle(
                  color: TavlaTheme.cream.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1C),
      body: SafeArea(
        child: Column(
          children: [
            // Bot info bar (top)
            _buildPlayerBar(context, isBot: true, game: game),

            // Board (with integrated dice in center bar and bearing-off trays)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _boardHorizontalPadding(context);
                  final boardViewport = computeBoardViewport(
                    Size(
                      constraints.maxWidth - (horizontalPadding * 2),
                      constraints.maxHeight,
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Center(
                      child: SizedBox(
                        width: boardViewport.width,
                        height: boardViewport.height,
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
                          highlightedPoints: {
                            if (game.botMoveFrom != null) game.botMoveFrom!,
                            if (game.botMoveTo != null) game.botMoveTo!,
                          },
                          validMoveTargets: game.isMyTurn
                              ? (game.selectedPoint != null
                                  ? game.validMoveTargets
                                  : (game.snapshot!.board.bar[game.myColor] ?? 0) > 0
                                      ? ref.read(botGameProvider.notifier).computeBarTargets()
                                      : const {})
                              : const {},
                          onPointDragStart: (fromPoint) {
                            ref.read(botGameProvider.notifier).selectPoint(fromPoint);
                          },
                          onPointDrop: (fromPoint, toPoint) {
                            ref.read(botGameProvider.notifier).makeMove(fromPoint, toPoint);
                          },
                          onBarDrop: (toPoint) {
                            ref.read(botGameProvider.notifier).movePieceFromBar(toPoint);
                          },
                          onBearOffDrop: (fromPoint) {
                            ref.read(botGameProvider.notifier).bearOff(fromPoint);
                          },
                          onPointTap: (index) {
                            final notifier = ref.read(botGameProvider.notifier);
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
                              ? () => ref.read(botGameProvider.notifier).rollDice()
                              : null,
                          onBearOffTap: game.isMyTurn && game.selectedPoint != null
                              ? () => ref.read(botGameProvider.notifier).bearOff(game.selectedPoint!)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Player info bar (bottom)
            _buildPlayerBar(context, isBot: false, game: game),

            // Action buttons
            _buildActionBar(context, game),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerBar(
    BuildContext context, {
    required bool isBot,
    required GamePlayState game,
  }) {
    final isCurrentTurn = isBot ? !game.isMyTurn : game.isMyTurn;
    final auth = ref.watch(authProvider);
    final diffLabel = widget.difficulty == 'easy'
        ? 'Kolay'
        : widget.difficulty == 'medium'
            ? 'Orta'
            : 'Zor';
    final borneOff = _getBorneOff(game, isBot);
    final isBotThinking = isBot && !game.isMyTurn && game.phase == GamePhase.playing;

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
          bottom: isBot
              ? BorderSide(
                  color: isCurrentTurn
                      ? TavlaTheme.gold.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                )
              : BorderSide.none,
          top: !isBot
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
          Container(
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
              backgroundColor:
                  isBot ? TavlaTheme.blackPiece : TavlaTheme.whitePiece,
              child: Icon(
                isBot ? Icons.smart_toy : Icons.person,
                size: 16,
                color: isBot ? Colors.white : TavlaTheme.darkBrown,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBot ? 'Bot ($diffLabel)' : (auth.user?.username ?? 'Sen'),
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
              if (isCurrentTurn && !isBotThinking)
                Text(
                  'Sıra',
                  style: TextStyle(
                    color: TavlaTheme.gold.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              if (isBotThinking)
                _BotThinkingIndicator(),
            ],
          ),
          const Spacer(),
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
        ],
      ),
    );
  }

  int _getBorneOff(GamePlayState game, bool isBot) {
    final color =
        isBot ? (game.myColor == 'W' ? 'B' : 'W') : game.myColor;
    return game.snapshot?.board.borneOff[color] ?? 0;
  }

  bool _canBearOff(GamePlayState game) {
    if (game.snapshot == null || game.myColor == null) return false;
    final board = game.snapshot!.board;
    final myColor = game.myColor!;
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

  double _boardHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 2;
    if (width < 430) return 4;
    if (width < 520) return 8;
    return 12;
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
              onPressed: () =>
                  ref.read(botGameProvider.notifier).endTurn(),
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

          // Undo
          if (game.canUndo && game.isMyTurn)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.undo, color: TavlaTheme.gold),
                tooltip: 'Geri Al',
                onPressed: () =>
                    ref.read(botGameProvider.notifier).undoMove(),
              ),
            ),

          const Spacer(),

          // Resign
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: TavlaTheme.danger),
            onPressed: () => _showResignDialog(context),
          ),
        ],
      ),
    );
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teslim Ol'),
        content: const Text('Bot oyununu teslim etmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(botGameProvider.notifier).resign();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: TavlaTheme.danger),
            child: const Text('Teslim Ol'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GamePlayState game) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          game.resultMessage?.contains('Kazandın') == true
              ? '🎉 Tebrikler!'
              : '😔 Oyun Bitti',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              game.resultMessage ?? '',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bot oyununda ELO değişmez.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/lobby');
            },
            child: const Text('Lobiye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Restart with same difficulty
              setState(() => _gameOverShown = false);
              final user = ref.read(authProvider).user;
              if (user != null) {
                ref
                    .read(botGameProvider.notifier)
                    .startBotGame(widget.difficulty, user.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TavlaTheme.brown,
            ),
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }
}

/// Animated "thinking..." dots indicator for bot turn
class _BotThinkingIndicator extends StatefulWidget {
  @override
  State<_BotThinkingIndicator> createState() => _BotThinkingIndicatorState();
}

class _BotThinkingIndicatorState extends State<_BotThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.25;
            final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TavlaTheme.gold.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
