import 'package:flutter/material.dart';
import '../../../core/theme/tavla_theme.dart';
import 'piece_widget.dart';

/// Vertical tray alongside the board where borne-off pieces collect.
/// Redesigned with 3D inset shadow, realistic stacked pieces, and proper state glow.
class BearingOffTrayWidget<T extends Object> extends StatelessWidget {
  final String player; // 'W' or 'B'
  final int count; // borne-off count (0–15)
  final bool isActive; // true when bearing off is possible
  final bool isValidTarget; // true when this tray is a valid move target
  final double width;
  final VoidCallback? onTap;
  final bool Function(T data)? onWillAccept;
  final void Function(T data)? onAccept;

  const BearingOffTrayWidget({
    super.key,
    required this.player,
    required this.count,
    this.isActive = false,
    this.isValidTarget = false,
    this.width = 38,
    this.onTap,
    this.onWillAccept,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final badgeFontSize = (width * 0.28).clamp(10.0, 12.0).toDouble();

    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => onWillAccept?.call(details.data) ?? false,
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty && isValidTarget;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: width,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  TavlaTheme.boardFrameDark,
                  TavlaTheme.boardFrame,
                  TavlaTheme.boardFrameLight,
                  TavlaTheme.boardFrame,
                  TavlaTheme.boardFrameDark,
                ],
                stops: [0.0, 0.15, 0.5, 0.85, 1.0],
              ),
              border: Border.all(
                color: isValidTarget
                    ? TavlaTheme.success.withValues(alpha: 0.9)
                    : isActive
                        ? TavlaTheme.gold.withValues(alpha: 0.4)
                        : const Color(0xFF1A1008),
                width: isValidTarget ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(2, 0),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 3,
                  spreadRadius: -1,
                  offset: const Offset(-1, 0),
                ),
                if (isValidTarget)
                  BoxShadow(
                    color: TavlaTheme.success.withValues(alpha: isHovering ? 0.7 : 0.5),
                    blurRadius: isHovering ? 14 : 10,
                    spreadRadius: isHovering ? 3 : 2,
                  ),
                if (isActive && !isValidTarget)
                  BoxShadow(
                    color: TavlaTheme.gold.withValues(alpha: 0.15),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                        stops: const [0.0, 0.1, 0.9, 1.0],
                      ),
                    ),
                  ),
                ),
                if (isHovering)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: TavlaTheme.success.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: count > 0
                            ? Border.all(
                                color: TavlaTheme.gold.withValues(alpha: 0.3),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: count > 0
                              ? TavlaTheme.gold
                              : TavlaTheme.cream.withValues(alpha: 0.3),
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.w800,
                          shadows: count > 0
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _buildPieceStack(),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieceStack() {
    final pieceSize = (width * 0.56).clamp(18.0, 24.0).toDouble();

    if (count == 0) {
      // Empty slot indicator
      return Center(
        child: Container(
          width: pieceSize,
          height: pieceSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: TavlaTheme.cream.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
      );
    }

    const maxVisible = 10;
    final visibleCount = count.clamp(0, maxVisible);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          visibleCount,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.5),
            child: PieceWidget(
              player: player,
              size: pieceSize,
            ),
          ),
        ),
        if (count > maxVisible)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${count - maxVisible}',
                style: TextStyle(
                  color: TavlaTheme.cream.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
