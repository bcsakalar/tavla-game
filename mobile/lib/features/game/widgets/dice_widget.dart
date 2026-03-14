import 'dart:math';
import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool used;
  final double size;

  const DiceWidget({
    super.key,
    required this.value,
    this.used = false,
    this.size = 48,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
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
      builder: (context, child) {
        return Transform.scale(
          scale: _bounce.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: widget.used ? 0.35 : 1.0,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            // Clean premium dice face
            gradient: const LinearGradient(
              begin: Alignment(-0.8, -0.8),
              end: Alignment(0.8, 0.8),
              colors: [
                Color(0xFFFAFAF5),
                Color(0xFFF0EAD8),
                Color(0xFFE5DCC6),
                Color(0xFFD8CEB0),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.2),
            border: Border.all(
              color: const Color(0xFF6A6A6C),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
              BoxShadow(
                color: const Color(0xFF6A6A6C).withValues(alpha: 0.5),
                blurRadius: 0,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _DiceDotsPainter(widget.value),
          ),
        ),
      ),
    );
  }
}

class _DiceDotsPainter extends CustomPainter {
  final int value;
  _DiceDotsPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final dotRadius = size.width * 0.09;
    final positions = _getDotPositions(value, size);

    for (final pos in positions) {
      // Dot shadow for inset effect
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos + const Offset(0.5, 0.5), dotRadius, shadowPaint);

      // Main dot
      final paint = Paint()
        ..color = const Color(0xFF2C1810)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, dotRadius, paint);

      // Tiny highlight on dot
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        pos + Offset(-dotRadius * 0.25, -dotRadius * 0.25),
        dotRadius * 0.35,
        highlightPaint,
      );
    }
  }

  List<Offset> _getDotPositions(int value, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final q = size.width * 0.25;

    switch (value) {
      case 1:
        return [Offset(cx, cy)];
      case 2:
        return [Offset(cx - q, cy - q), Offset(cx + q, cy + q)];
      case 3:
        return [Offset(cx - q, cy - q), Offset(cx, cy), Offset(cx + q, cy + q)];
      case 4:
        return [
          Offset(cx - q, cy - q), Offset(cx + q, cy - q),
          Offset(cx - q, cy + q), Offset(cx + q, cy + q),
        ];
      case 5:
        return [
          Offset(cx - q, cy - q), Offset(cx + q, cy - q),
          Offset(cx, cy),
          Offset(cx - q, cy + q), Offset(cx + q, cy + q),
        ];
      case 6:
        return [
          Offset(cx - q, cy - q), Offset(cx + q, cy - q),
          Offset(cx - q, cy), Offset(cx + q, cy),
          Offset(cx - q, cy + q), Offset(cx + q, cy + q),
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(covariant _DiceDotsPainter old) => old.value != value;
}
