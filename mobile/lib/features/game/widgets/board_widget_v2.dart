import 'package:flutter/material.dart';
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A3020),
                Color(0xFF3A2414),
                Color(0xFF2A1A0E),
                Color(0xFF3A2414),
                Color(0xFF4A3020),
              ],
              stops: [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2D1A10),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: [
                  // Left bearing-off tray (opponent's tray when White, my tray when Black)
                  BearingOffTrayWidget(
                    player: isWhite ? opponentColor : myColor,
                    count: isWhite ? opponentBorneOff : myBorneOff,
                    isActive: !isWhite && canBearOff,
                    isValidTarget: !isWhite && isBearOffTarget,
                    onTap: !isWhite && isBearOffTarget ? onBearOffTap : null,
                  ),

                  // Left panel (6 points top + 6 points bottom)
                  Expanded(
                    child: _buildPanel(
                      context,
                      isLeft: true,
                      isWhite: isWhite,
                    ),
                  ),

                  // Center bar (vertical) with dice
                  _buildCenterBar(context),

                  // Right panel (6 points top + 6 points bottom)
                  Expanded(
                    child: _buildPanel(
                      context,
                      isLeft: false,
                      isWhite: isWhite,
                    ),
                  ),

                  // Right bearing-off tray (my tray when White, opponent's when Black)
                  BearingOffTrayWidget(
                    player: isWhite ? myColor : opponentColor,
                    count: isWhite ? myBorneOff : opponentBorneOff,
                    isActive: isWhite && canBearOff,
                    isValidTarget: isWhite && isBearOffTarget,
                    onTap: isWhite && isBearOffTarget ? onBearOffTap : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

    return Column(
      children: [
        // Top point numbers
        if (showPointNumbers)
          _buildPointNumberRow(topIndices),
        // Top row of 6 points (triangles pointing down)
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF383838), Color(0xFF404042), Color(0xFF383838)],
              ),
            ),
            child: Row(
              children: topIndices.map((idx) {
                return Expanded(child: _buildPoint(context, idx, true));
              }).toList(),
            ),
          ),
        ),
        // Bottom row of 6 points (triangles pointing up)
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF383838), Color(0xFF404042), Color(0xFF383838)],
              ),
            ),
            child: Row(
              children: bottomIndices.map((idx) {
                return Expanded(child: _buildPoint(context, idx, false));
              }).toList(),
            ),
          ),
        ),
        // Bottom point numbers
        if (showPointNumbers)
          _buildPointNumberRow(bottomIndices),
      ],
    );
  }

  Widget _buildPointNumberRow(List<int> indices) {
    return Container(
      height: 16,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A0E), Color(0xFF3A2414)],
        ),
      ),
      child: Row(
        children: indices.map((idx) {
          return Expanded(
            child: Center(
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  color: TavlaTheme.gold.withValues(alpha: 0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
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

    final triangleColor1 = isEven ? TavlaTheme.pointRed : TavlaTheme.pointCream;
    final triangleColor2 = isEven ? TavlaTheme.pointRedLight : TavlaTheme.pointCreamDark;

    return GestureDetector(
      onTap: isMyTurn ? () => onPointTap(pointIndex) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pieceSize = constraints.maxWidth * 0.85;
          final maxPiecesVisible = (constraints.maxHeight / (pieceSize * 0.82)).floor().clamp(1, 5);
          final piecesToShow = point.count > maxPiecesVisible ? maxPiecesVisible : point.count;

          return Stack(
            children: [
              // Triangle background
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrianglePainter(
                    color1: triangleColor1,
                    color2: triangleColor2,
                    isTop: isTop,
                  ),
                ),
              ),

              // Selected border (gold outline)
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: TavlaTheme.gold, width: 2),
                    ),
                  ),
                ),

              // Bot move glow border
              if (isBotHighlight)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TavlaTheme.gold.withValues(alpha: 0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TavlaTheme.gold.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

              // Pieces stacked on the triangle
              if (point.count > 0)
                Positioned(
                  top: isTop ? 0 : null,
                  bottom: isTop ? null : 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      piecesToShow,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.5),
                        child: PieceWidget(
                          player: point.player ?? 'W',
                          count: (i == piecesToShow - 1 && point.count > maxPiecesVisible)
                              ? point.count
                              : 1,
                          size: pieceSize,
                          isSelected: isSelected && i == 0,
                        ),
                      ),
                    ),
                  ),
                ),

              // --- HINT INDICATORS (circle style) ---

              // Valid move target with pieces: ring around bottom/top piece
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

              // Valid move target on empty point: small circle at tip
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
  }

  /// Small filled circle hint for empty target points
  Widget _buildMoveHintDot(bool isDanger) {
    final color = isDanger ? TavlaTheme.danger : TavlaTheme.success;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.7),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// Ring indicator around an existing piece (for occupied target points)
  Widget _buildMoveHintCircle(double pieceSize, bool isCapture) {
    final color = isCapture ? TavlaTheme.danger : TavlaTheme.success;
    return Container(
      width: pieceSize + 6,
      height: pieceSize + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// The central vertical bar dividing the two halves, containing:
  /// - Bar pieces (captured pieces)
  /// - Dice display
  Widget _buildCenterBar(BuildContext context) {
    final whiteBar = board.bar['W'] ?? 0;
    final blackBar = board.bar['B'] ?? 0;
    final isWhite = myColor == 'W';

    // Determine which bar pieces go on top vs bottom based on perspective
    final topBarCount = isWhite ? blackBar : whiteBar;
    final topBarPlayer = isWhite ? 'B' : 'W';
    final bottomBarCount = isWhite ? whiteBar : blackBar;
    final bottomBarPlayer = isWhite ? 'W' : 'B';

    final hasDice = dice != null && dice!.isNotEmpty;
    final isRolling = turnPhase == 'rolling' && isMyTurn;

    return GestureDetector(
      onTap: onBarTap,
      child: Container(
        width: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF2A2A2C),
              Color(0xFF3A3A3C),
              Color(0xFF2E2E30),
              Color(0xFF3A3A3C),
              Color(0xFF2A2A2C),
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top bar pieces (opponent's captured pieces)
            if (topBarCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    topBarCount.clamp(0, 3),
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: PieceWidget(
                        player: topBarPlayer,
                        count: (i == topBarCount.clamp(0, 3) - 1 && topBarCount > 3)
                            ? topBarCount
                            : 1,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Dice area (centered in bar)
            if (hasDice || isRolling) _buildDiceArea(isRolling),
            if (!hasDice && !isRolling) _buildBarLabel(),

            const Spacer(),

            // Bottom bar pieces (my captured pieces)
            if (bottomBarCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    bottomBarCount.clamp(0, 3),
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: PieceWidget(
                        player: bottomBarPlayer,
                        count: (i == bottomBarCount.clamp(0, 3) - 1 && bottomBarCount > 3)
                            ? bottomBarCount
                            : 1,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarLabel() {
    return RotatedBox(
      quarterTurns: 1,
      child: Text(
        'BAR',
        style: TextStyle(
          color: TavlaTheme.gold.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildDiceArea(bool isRolling) {
    final remaining = remainingDice ?? [];

    return GestureDetector(
      onTap: isRolling ? onDiceTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
                    size: 34,
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
            const Color(0xFFFAFAF5).withValues(alpha: 0.3),
            const Color(0xFFD8CEB0).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: TavlaTheme.gold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.casino,
          size: 18,
          color: TavlaTheme.gold.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final bool isTop;

  _TrianglePainter({required this.color1, required this.color2, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final triHeight = size.height * 0.85;
    final path = Path();
    if (isTop) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, triHeight);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, size.height - triHeight);
    }
    path.close();

    final rect = path.getBounds();
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [color2, color1, color1, color2],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, outlinePaint);

    final highlightPath = Path();
    if (isTop) {
      highlightPath.moveTo(size.width * 0.35, size.height * 0.03);
      highlightPath.lineTo(size.width / 2, triHeight * 0.9);
    } else {
      highlightPath.moveTo(size.width * 0.35, size.height * 0.97);
      highlightPath.lineTo(size.width / 2, size.height - triHeight * 0.9);
    }
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color1 != color1 || old.color2 != color2 || old.isTop != isTop;
}
