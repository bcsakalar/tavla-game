import 'package:flutter/material.dart';
import '../../../core/theme/tavla_theme.dart';
import '../models/game_state.dart';
import 'piece_widget.dart';

class BoardWidget extends StatelessWidget {
  final BoardState board;
  final String myColor;
  final int? selectedPoint;
  final bool isMyTurn;
  final void Function(int pointIndex) onPointTap;
  final VoidCallback? onBarTap;
  final bool showPointNumbers;
  final Set<int> validMoveTargets;
  final Set<int> highlightedPoints;

  const BoardWidget({
    super.key,
    required this.board,
    required this.myColor,
    this.selectedPoint,
    this.isMyTurn = false,
    required this.onPointTap,
    this.onBarTap,
    this.showPointNumbers = false,
    this.validMoveTargets = const {},
    this.highlightedPoints = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = myColor == 'W';

    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
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
            // Wood frame with gradient
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
            padding: const EdgeInsets.all(6),
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
                child: Column(
                  children: [
                    // Point numbers top
                    if (showPointNumbers)
                      _buildPointNumbers(isTop: true, isWhite: isWhite),
                    // Top half
                    Expanded(
                      child: _buildHalf(
                        context,
                        isTop: true,
                        isWhite: isWhite,
                      ),
                    ),
                    // Middle bar
                    _buildBar(context),
                    // Bottom half
                    Expanded(
                      child: _buildHalf(
                        context,
                        isTop: false,
                        isWhite: isWhite,
                      ),
                    ),
                    // Point numbers bottom
                    if (showPointNumbers)
                      _buildPointNumbers(isTop: false, isWhite: isWhite),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointNumbers({required bool isTop, required bool isWhite}) {
    List<int> pointIndices;
    if (isTop) {
      pointIndices = isWhite
          ? [12, 13, 14, 15, 16, 17, -1, 18, 19, 20, 21, 22, 23]
          : [11, 10, 9, 8, 7, 6, -1, 5, 4, 3, 2, 1, 0];
    } else {
      pointIndices = isWhite
          ? [11, 10, 9, 8, 7, 6, -1, 5, 4, 3, 2, 1, 0]
          : [12, 13, 14, 15, 16, 17, -1, 18, 19, 20, 21, 22, 23];
    }

    return Container(
      height: 18,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A0E), Color(0xFF3A2414)],
        ),
      ),
      child: Row(
        children: pointIndices.map((idx) {
          if (idx == -1) {
            return Container(
              width: 10,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A1A0E), Color(0xFF3A2414), Color(0xFF2A1A0E)],
                ),
              ),
            );
          }
          final displayNum = idx + 1;
          return Expanded(
            child: Center(
              child: Text(
                '$displayNum',
                style: TextStyle(
                  color: TavlaTheme.gold.withValues(alpha: 0.7),
                  fontSize: 9,
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

  Widget _buildHalf(BuildContext context, {required bool isTop, required bool isWhite}) {
    List<int> pointIndices;
    if (isTop) {
      pointIndices = isWhite
          ? [12, 13, 14, 15, 16, 17, -1, 18, 19, 20, 21, 22, 23]
          : [11, 10, 9, 8, 7, 6, -1, 5, 4, 3, 2, 1, 0];
    } else {
      pointIndices = isWhite
          ? [11, 10, 9, 8, 7, 6, -1, 5, 4, 3, 2, 1, 0]
          : [12, 13, 14, 15, 16, 17, -1, 18, 19, 20, 21, 22, 23];
    }

    return Container(
      // Felt green playing surface
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF383838),
            Color(0xFF404042),
            Color(0xFF383838),
          ],
        ),
      ),
      child: Row(
        children: pointIndices.map((idx) {
          if (idx == -1) {
            // Center bar divider
            return Container(
              width: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                  ),
                ],
              ),
            );
          }
          return Expanded(
            child: _buildPoint(context, idx, isTop),
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

    // Alternate dark/cream triangle colors
    final triangleColor1 = isEven ? TavlaTheme.pointRed : TavlaTheme.pointCream;
    final triangleColor2 = isEven ? TavlaTheme.pointRedLight : TavlaTheme.pointCreamDark;

    // Highlight color for valid move targets or bot move
    Color? highlightColor;
    if (isValidTarget) {
      final hasOpponent = point.count == 1 &&
          point.player != null &&
          point.player != myColor;
      highlightColor = hasOpponent
          ? TavlaTheme.danger.withValues(alpha: 0.35)
          : TavlaTheme.success.withValues(alpha: 0.35);
    } else if (isBotHighlight) {
      highlightColor = TavlaTheme.gold.withValues(alpha: 0.25);
    }

    return GestureDetector(
      onTap: isMyTurn ? () => onPointTap(pointIndex) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pieceSize = constraints.maxWidth * 0.82;
          final maxPiecesVisible = (constraints.maxHeight / (pieceSize * 0.85)).floor().clamp(1, 5);
          final piecesToShow = point.count > maxPiecesVisible ? maxPiecesVisible : point.count;

          return Stack(
            children: [
              // Triangle background (full height)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: highlightColor,
                  child: CustomPaint(
                    painter: _TrianglePainter(
                      color1: triangleColor1,
                      color2: triangleColor2,
                      isTop: isTop,
                    ),
                  ),
                ),
              ),

              // Selected border
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

              // Pieces stacked on top of the triangle
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

              // Valid move indicator (empty point)
              if (isValidTarget && point.count == 0)
                Positioned(
                  top: isTop ? constraints.maxHeight * 0.35 : null,
                  bottom: isTop ? null : constraints.maxHeight * 0.35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TavlaTheme.success.withValues(alpha: 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: TavlaTheme.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    final whiteBar = board.bar['W'] ?? 0;
    final blackBar = board.bar['B'] ?? 0;

    return GestureDetector(
      onTap: onBarTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2A2A2C),
              Color(0xFF363638),
              Color(0xFF3E3E40),
              Color(0xFF363638),
              Color(0xFF2A2A2C),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (whiteBar > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PieceWidget(
                  player: 'W',
                  count: whiteBar,
                  size: 34,
                ),
              ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TavlaTheme.gold.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'BAR',
                style: TextStyle(
                  color: TavlaTheme.gold.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
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
            const SizedBox(width: 12),
            if (blackBar > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: PieceWidget(
                  player: 'B',
                  count: blackBar,
                  size: 34,
                ),
              ),
          ],
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
    // Triangle spans ~85% of the cell height for backgammon look
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

    // Gradient fill
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

    // Subtle outline for depth
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, outlinePaint);

    // Inner highlight line for 3D feel
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
