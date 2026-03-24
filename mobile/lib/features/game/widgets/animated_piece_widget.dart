import 'package:flutter/material.dart';
import 'piece_widget.dart';

/// Wraps [PieceWidget] with a smooth sliding animation (400ms).
/// Used within the board to animate piece transitions between points.
class AnimatedPieceWidget extends StatelessWidget {
  final String player;
  final int count;
  final double size;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback? onTap;
  final void Function(DragStartDetails)? onDragStart;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final void Function(DragEndDetails)? onDragEnd;

  const AnimatedPieceWidget({
    super.key,
    required this.player,
    this.count = 1,
    this.size = 36,
    this.isSelected = false,
    this.isDragging = false,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: onDragStart,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: AnimatedScale(
        scale: isDragging ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: isDragging ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: PieceWidget(
            player: player,
            count: count,
            size: size,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

/// Overlay widget shown while dragging a piece across the board.
class DragPieceOverlay extends StatelessWidget {
  final String player;
  final double size;
  final Offset position;

  const DragPieceOverlay({
    super.key,
    required this.player,
    required this.size,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.2,
          child: PieceWidget(
            player: player,
            size: size,
            isSelected: true,
          ),
        ),
      ),
    );
  }
}
