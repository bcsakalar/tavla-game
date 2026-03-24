import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/tavla_theme.dart';
import '../models/game_state.dart';
import 'piece_widget.dart';
import 'dice_widget.dart';
import 'bearing_off_tray_widget.dart';

/// Backgammon board with physical-style LEFT–RIGHT vertical split layout.
///
/// Layout: [Left Tray] [Left Panel (6top+6bot)] [Center Bar + Dice] [Right Panel (6top+6bot)] [Right Tray]
class BoardWidget extends StatelessWidget {
  final BoardState board;
  final String myColor;
  final int? selectedPoint;
  final bool isMyTurn;
  final void Function(int pointIndex) onPointTap;
  final void Function(int fromPoint)? onPointDragStart;
  final void Function(int fromPoint, int toPoint)? onPointDrop;
  final void Function(int toPoint)? onBarDrop;
  final void Function(int fromPoint)? onBearOffDrop;
  final VoidCallback? onBarTap;
  final VoidCallback? onBearOffTap;
  final VoidCallback? onDiceTap;
  final bool showPointNumbers;
  final Set<int> validMoveTargets;
  final Set<int> highlightedPoints;
  final List<int>? dice;
  final List<int>? remainingDice;
  final String? turnPhase;
  final bool canBearOff;

  const BoardWidget({
    super.key,
    required this.board,
    required this.myColor,
    this.selectedPoint,
    this.isMyTurn = false,
    required this.onPointTap,
    this.onPointDragStart,
    this.onPointDrop,
    this.onBarDrop,
    this.onBearOffDrop,
    this.onBarTap,
    this.onBearOffTap,
    this.onDiceTap,
    this.showPointNumbers = false,
    this.validMoveTargets = const {},
    this.highlightedPoints = const {},
    this.dice,
    this.remainingDice,
    this.turnPhase,
    this.canBearOff = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = myColor == 'W';
    final myBorneOff = board.borneOff[myColor] ?? 0;
    final opponentColor = myColor == 'W' ? 'B' : 'W';
    final opponentBorneOff = board.borneOff[opponentColor] ?? 0;
    final isBearOffTarget = validMoveTargets.contains(-1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final outerRadius = (boardWidth * 0.036).clamp(14.0, 18.0).toDouble();
        final framePadding = (boardWidth * 0.012).clamp(3.5, 5.5).toDouble();
        final trayWidth = (boardWidth * 0.074).clamp(28.0, 34.0).toDouble();
        final centerBarWidth = (boardWidth * 0.092).clamp(32.0, 40.0).toDouble();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.62),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 9,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(outerRadius),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TavlaTheme.boardFrameLight,
                    TavlaTheme.boardFrame,
                    TavlaTheme.boardFrameDark,
                    TavlaTheme.boardFrame,
                    TavlaTheme.boardFrameLight,
                  ],
                  stops: [0.0, 0.18, 0.5, 0.82, 1.0],
                ),
                borderRadius: BorderRadius.circular(outerRadius),
              ),
              padding: EdgeInsets.all(framePadding),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF493223),
                      Color(0xFF312015),
                      Color(0xFF24170F),
                    ],
                    stops: [0.0, 0.56, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(outerRadius * 0.55),
                  border: Border.all(
                    color: TavlaTheme.boardFrameDark,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 5,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(outerRadius * 0.42),
                  child: Row(
                    children: [
                      BearingOffTrayWidget<_DragPayload>(
                        key: ValueKey('bearing-off-tray-${isWhite ? opponentColor : myColor}'),
                        player: isWhite ? opponentColor : myColor,
                        count: isWhite ? opponentBorneOff : myBorneOff,
                        width: trayWidth,
                        isActive: !isWhite && canBearOff,
                        isValidTarget: !isWhite && isBearOffTarget,
                        onWillAccept: (data) =>
                            !data.fromBar && !isWhite && isBearOffTarget && onBearOffDrop != null,
                        onAccept: (data) {
                          final fromPoint = data.fromPoint;
                          if (fromPoint != null) {
                            onBearOffDrop?.call(fromPoint);
                          }
                        },
                        onTap: !isWhite && isBearOffTarget ? onBearOffTap : null,
                      ),
                      Expanded(
                        child: _buildPanel(
                          context,
                          isLeft: true,
                          isWhite: isWhite,
                        ),
                      ),
                      _buildCenterBar(context, centerBarWidth),
                      Expanded(
                        child: _buildPanel(
                          context,
                          isLeft: false,
                          isWhite: isWhite,
                        ),
                      ),
                      BearingOffTrayWidget<_DragPayload>(
                        key: ValueKey('bearing-off-tray-${isWhite ? myColor : opponentColor}'),
                        player: isWhite ? myColor : opponentColor,
                        count: isWhite ? myBorneOff : opponentBorneOff,
                        width: trayWidth,
                        isActive: isWhite && canBearOff,
                        isValidTarget: isWhite && isBearOffTarget,
                        onWillAccept: (data) =>
                            !data.fromBar && isWhite && isBearOffTarget && onBearOffDrop != null,
                        onAccept: (data) {
                          final fromPoint = data.fromPoint;
                          if (fromPoint != null) {
                            onBearOffDrop?.call(fromPoint);
                          }
                        },
                        onTap: isWhite && isBearOffTarget ? onBearOffTap : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds one half of the board (left or right), containing 12 points
  /// arranged as 6 on top row + 6 on bottom row.
  Widget _buildPanel(BuildContext context, {required bool isLeft, required bool isWhite}) {
    // Point index mapping (White perspective):
    //   Left panel:  top=[12,13,14,15,16,17]  bottom=[11,10,9,8,7,6]
    //   Right panel: top=[18,19,20,21,22,23]  bottom=[5,4,3,2,1,0]
    // Black perspective: mirrored
    List<int> topIndices;
    List<int> bottomIndices;

    if (isWhite) {
      if (isLeft) {
        topIndices = [12, 13, 14, 15, 16, 17];
        bottomIndices = [11, 10, 9, 8, 7, 6];
      } else {
        topIndices = [18, 19, 20, 21, 22, 23];
        bottomIndices = [5, 4, 3, 2, 1, 0];
      }
    } else {
      if (isLeft) {
        topIndices = [11, 10, 9, 8, 7, 6];
        bottomIndices = [12, 13, 14, 15, 16, 17];
      } else {
        topIndices = [5, 4, 3, 2, 1, 0];
        bottomIndices = [18, 19, 20, 21, 22, 23];
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 3,
            spreadRadius: -1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: [
            if (showPointNumbers) _buildPointNumberRow(topIndices),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5D5751),
                      TavlaTheme.surfaceGrayLight,
                      TavlaTheme.surfaceGray,
                      Color(0xFF2D2927),
                    ],
                    stops: [0.0, 0.16, 0.56, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: topIndices.map((idx) {
                    return Expanded(child: _buildPoint(context, idx, true));
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2D2927),
                      TavlaTheme.surfaceGray,
                      TavlaTheme.surfaceGrayLight,
                      Color(0xFF5D5751),
                    ],
                    stops: [0.0, 0.44, 0.84, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: bottomIndices.map((idx) {
                    return Expanded(child: _buildPoint(context, idx, false));
                  }).toList(),
                ),
              ),
            ),
            if (showPointNumbers) _buildPointNumberRow(bottomIndices),
          ],
        ),
      ),
    );
  }

  Widget _buildPointNumberRow(List<int> indices) {
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF27190F), Color(0xFF402717), Color(0xFF26170E)],
          stops: [0.0, 0.52, 1.0],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.6,
          ),
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.24),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: indices.map((idx) {
          return Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    color: TavlaTheme.gold.withValues(alpha: 0.82),
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.58),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPoint(BuildContext context, int pointIndex, bool isTop) {
    final point = board.points[pointIndex];
    final isSelected = selectedPoint == pointIndex;
    final isValidTarget = validMoveTargets.contains(pointIndex);
    final isBotHighlight = highlightedPoints.contains(pointIndex);
    final isEven = pointIndex % 2 == 0;
    final canDragPoint =
        isMyTurn && point.count > 0 && point.player == myColor && onPointDrop != null;

    final triangleColor1 = isEven ? TavlaTheme.pointRed : TavlaTheme.pointCream;
    final triangleColor2 = isEven ? TavlaTheme.pointRedLight : TavlaTheme.pointCreamDark;

    return DragTarget<_DragPayload>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (!isValidTarget) return false;
        if (data.fromBar) {
          return onBarDrop != null;
        }
        return onPointDrop != null && data.fromPoint != pointIndex;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data.fromBar) {
          onBarDrop?.call(pointIndex);
          return;
        }
        final fromPoint = data.fromPoint;
        if (fromPoint != null && fromPoint != pointIndex) {
          onPointDrop?.call(fromPoint, pointIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty && isValidTarget;

        return GestureDetector(
          key: ValueKey('board-point-$pointIndex'),
          onTap: isMyTurn ? () => onPointTap(pointIndex) : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pieceSize = math.min(
                constraints.maxWidth * 0.82,
                constraints.maxHeight * 0.19,
              ).clamp(16.0, 32.0).toDouble();
              final stackGap = (pieceSize * 0.055).clamp(0.7, 1.4).toDouble();
              final maxPiecesVisible =
                  (constraints.maxHeight / (pieceSize * 0.72)).floor().clamp(1, 7);
              final piecesToShow = point.count > maxPiecesVisible ? maxPiecesVisible : point.count;

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrianglePainter(
                        color1: triangleColor1,
                        color2: triangleColor2,
                        isTop: isTop,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: TavlaTheme.gold, width: 2),
                        ),
                      ),
                    ),
                  if (isBotHighlight)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: TavlaTheme.gold.withValues(alpha: 0.85),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TavlaTheme.gold.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: TavlaTheme.gold.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isHovering)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TavlaTheme.success.withValues(alpha: 0.12),
                          border: Border.all(
                            color: TavlaTheme.success.withValues(alpha: 0.75),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  if (point.count > 0)
                    Positioned(
                      top: isTop ? 4 : null,
                      bottom: isTop ? null : 4,
                      left: 0,
                      right: 0,
                      child: _buildDraggablePointStack(
                        pointIndex: pointIndex,
                        player: point.player ?? 'W',
                        pointCount: point.count,
                        pieceSize: pieceSize,
                        piecesToShow: piecesToShow,
                        maxPiecesVisible: maxPiecesVisible,
                        isSelected: isSelected,
                        canDrag: canDragPoint,
                        stackGap: stackGap,
                      ),
                    ),
                  if (isValidTarget && point.count > 0)
                    Positioned(
                      top: isTop ? 0 : null,
                      bottom: isTop ? null : 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildMoveHintCircle(
                          pieceSize,
                          point.player != null && point.player != myColor,
                        ),
                      ),
                    ),
                  if (isValidTarget && point.count == 0)
                    Positioned(
                      top: isTop ? constraints.maxHeight * 0.35 : null,
                      bottom: isTop ? null : constraints.maxHeight * 0.35,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildMoveHintDot(false),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDraggablePointStack({
    required int pointIndex,
    required String player,
    required int pointCount,
    required double pieceSize,
    required int piecesToShow,
    required int maxPiecesVisible,
    required bool isSelected,
    required bool canDrag,
    required double stackGap,
  }) {
    final stack = KeyedSubtree(
      key: ValueKey('point-stack-$pointIndex'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          piecesToShow,
          (i) => Padding(
            padding: EdgeInsets.symmetric(vertical: stackGap),
            child: PieceWidget(
              player: player,
              count: (i == piecesToShow - 1 && pointCount > maxPiecesVisible)
                  ? pointCount
                  : 1,
              size: pieceSize,
              isSelected: isSelected && i == 0,
            ),
          ),
        ),
      ),
    );

    if (!canDrag) {
      return stack;
    }

    return Draggable<_DragPayload>(
      data: _DragPayload.fromPoint(pointIndex),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        onPointDragStart?.call(pointIndex);
      },
      feedback: Material(
        color: Colors.transparent,
        child: PieceWidget(
          player: player,
          size: pieceSize * 1.06,
          isSelected: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.32,
        child: stack,
      ),
      child: stack,
    );
  }

  /// Small filled circle hint for empty target points
  Widget _buildMoveHintDot(bool isDanger) {
    final color = isDanger ? TavlaTheme.danger : TavlaTheme.success;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.65),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  /// Ring indicator around an existing piece (for occupied target points)
  Widget _buildMoveHintCircle(double pieceSize, bool isCapture) {
    final color = isCapture ? TavlaTheme.danger : TavlaTheme.success;
    return Container(
      width: pieceSize + 8,
      height: pieceSize + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.9), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  /// The central vertical bar dividing the two halves, containing:
  /// - Bar pieces (captured pieces)
  /// - Dice display
  Widget _buildCenterBar(BuildContext context, double width) {
    final whiteBar = board.bar['W'] ?? 0;
    final blackBar = board.bar['B'] ?? 0;
    final isWhite = myColor == 'W';
    final pieceSize = (width * 0.6).clamp(19.0, 25.0).toDouble();

    // Determine which bar pieces go on top vs bottom based on perspective
    final topBarCount = isWhite ? blackBar : whiteBar;
    final topBarPlayer = isWhite ? 'B' : 'W';
    final bottomBarCount = isWhite ? whiteBar : blackBar;
    final bottomBarPlayer = isWhite ? 'W' : 'B';

    final hasDice = dice != null && dice!.isNotEmpty;
    final isRolling = turnPhase == 'rolling' && isMyTurn;
    final canDragFromBar = isMyTurn && bottomBarPlayer == myColor && bottomBarCount > 0 && onBarDrop != null;

    return GestureDetector(
      onTap: onBarTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              TavlaTheme.boardFrameDark,
              TavlaTheme.barWood,
              TavlaTheme.barWoodLight,
              TavlaTheme.barWood,
              TavlaTheme.boardFrameDark,
            ],
            stops: [0.0, 0.18, 0.5, 0.82, 1.0],
          ),
          border: Border(
            left: BorderSide(
              color: Colors.black.withValues(alpha: 0.42),
              width: 1,
            ),
            right: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.46),
              blurRadius: 5,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
              offset: const Offset(-2, 0),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 3,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Top bar pieces (opponent's captured pieces)
            if (topBarCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    topBarCount.clamp(0, 5),
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.8),
                      child: PieceWidget(
                        player: topBarPlayer,
                        count: (i == topBarCount.clamp(0, 5) - 1 && topBarCount > 5)
                            ? topBarCount
                            : 1,
                        size: pieceSize,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Dice area (centered in bar)
            if (hasDice || isRolling) _buildDiceArea(isRolling, width),
            if (!hasDice && !isRolling) _buildBarLabel(),

            const Spacer(),

            // Bottom bar pieces (my captured pieces)
            if (bottomBarCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _buildBottomBarStack(
                  player: bottomBarPlayer,
                  pieceSize: pieceSize,
                  bottomBarCount: bottomBarCount,
                  canDragFromBar: canDragFromBar,
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarStack({
    required String player,
    required double pieceSize,
    required int bottomBarCount,
    required bool canDragFromBar,
  }) {
    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        bottomBarCount.clamp(0, 5),
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.8),
          child: PieceWidget(
            player: player,
            count: (i == bottomBarCount.clamp(0, 5) - 1 && bottomBarCount > 5)
                ? bottomBarCount
                : 1,
            size: pieceSize,
          ),
        ),
      ),
    );

    if (!canDragFromBar) {
      return stack;
    }

    return Draggable<_DragPayload>(
      data: const _DragPayload.fromBar(),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: PieceWidget(
          player: player,
          size: pieceSize * 1.06,
          isSelected: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: stack,
      ),
      child: stack,
    );
  }

  Widget _buildBarLabel() {
    return RotatedBox(
      quarterTurns: 1,
      child: Text(
        'BAR',
        style: TextStyle(
          color: TavlaTheme.gold.withValues(alpha: 0.4),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.4,
        ),
      ),
    );
  }

  Widget _buildDiceArea(bool isRolling, double barWidth) {
    final remaining = remainingDice ?? [];
    final diceSize = (barWidth * 0.8).clamp(28.0, 34.0).toDouble();

    return GestureDetector(
      onTap: isRolling ? onDiceTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRolling && (dice == null || dice!.isEmpty))
              // Show placeholder dice that can be tapped to roll
              _buildDicePlaceholder()
            else if (dice != null)
              ...dice!.asMap().entries.map((entry) {
                final used = !remaining.contains(entry.value);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: DiceWidget(
                    value: entry.value,
                    used: used,
                    size: diceSize,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDicePlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSinglePlaceholderDie(),
        const SizedBox(height: 4),
        _buildSinglePlaceholderDie(),
      ],
    );
  }

  Widget _buildSinglePlaceholderDie() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -0.8),
          end: const Alignment(0.8, 0.8),
          colors: [
            const Color(0xFFFAFAF5).withValues(alpha: 0.25),
            const Color(0xFFD8CEB0).withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: TavlaTheme.gold.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: TavlaTheme.gold.withValues(alpha: 0.15),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.casino,
          size: 18,
          color: TavlaTheme.gold.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _DragPayload {
  final int? fromPoint;
  final bool fromBar;

  const _DragPayload._({this.fromPoint, required this.fromBar});

  const _DragPayload.fromPoint(int pointIndex)
    : this._(fromPoint: pointIndex, fromBar: false);

  const _DragPayload.fromBar()
    : this._(fromPoint: null, fromBar: true);
}

class _TrianglePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final bool isTop;

  _TrianglePainter({required this.color1, required this.color2, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final triHeight = size.height * 0.94;
    final baseInset = math.max(0.8, size.width * 0.04);
    final path = Path();
    if (isTop) {
      path.moveTo(baseInset, 0);
      path.lineTo(size.width - baseInset, 0);
      path.lineTo(size.width / 2, triHeight);
    } else {
      path.moveTo(baseInset, size.height);
      path.lineTo(size.width - baseInset, size.height);
      path.lineTo(size.width / 2, size.height - triHeight);
    }
    path.close();

    final rect = path.getBounds();
    final gradient = LinearGradient(
      begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
      end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
      colors: [
        _shiftColor(color2, 0.14),
        color1,
        _shiftColor(color1, -0.12),
      ],
      stops: const [0.0, 0.42, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final sideShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.14),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, sideShade);

    final baseEdgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final baseHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    if (isTop) {
      canvas.drawLine(
        Offset(baseInset, 0.8),
        Offset(size.width - baseInset, 0.8),
        baseEdgePaint,
      );
      canvas.drawLine(
        Offset(baseInset, 1.8),
        Offset(size.width - baseInset, 1.8),
        baseHighlightPaint,
      );
    } else {
      canvas.drawLine(
        Offset(baseInset, size.height - 0.8),
        Offset(size.width - baseInset, size.height - 0.8),
        baseEdgePaint,
      );
      canvas.drawLine(
        Offset(baseInset, size.height - 1.8),
        Offset(size.width - baseInset, size.height - 1.8),
        baseHighlightPaint,
      );
    }

    // Darker outline for depth
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawPath(path, outlinePaint);

    // Inner highlight line (3D edge)
    final highlightPath = Path();
    if (isTop) {
      highlightPath.moveTo(size.width * 0.32, size.height * 0.02);
      highlightPath.lineTo(size.width / 2, triHeight * 0.92);
    } else {
      highlightPath.moveTo(size.width * 0.32, size.height * 0.98);
      highlightPath.lineTo(size.width / 2, size.height - triHeight * 0.92);
    }
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(highlightPath, highlightPaint);

    final shadowPath = Path();
    if (isTop) {
      shadowPath.moveTo(size.width * 0.72, size.height * 0.03);
      shadowPath.lineTo(size.width / 2, triHeight * 0.9);
    } else {
      shadowPath.moveTo(size.width * 0.72, size.height * 0.97);
      shadowPath.lineTo(size.width / 2, size.height - triHeight * 0.9);
    }
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(shadowPath, shadowPaint);
  }

  Color _shiftColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final shiftedLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(shiftedLightness).toColor();
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color1 != color1 || old.color2 != color2 || old.isTop != isTop;
}
