import 'dart:math';
import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool used;
  final double size;
  final bool isRolling;

  const DiceWidget({
    super.key,
    required this.value,
    this.used = false,
    this.size = 48,
    this.isRolling = false,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  late AnimationController _rollController;
  late AnimationController _continuousController;
  late Animation<double> _rotationZ;
  late Animation<double> _rotationX;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    // Roll-in animation (plays once when value changes)
    _rollController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _rotationZ = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.easeOutCubic),
    );
    _rotationX = Tween<double>(begin: -pi * 0.3, end: 0).animate(
      CurvedAnimation(parent: _rollController, curve: Curves.easeOutBack),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.18), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.92), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _rollController, curve: Curves.easeOut));

    // Continuous spin for isRolling state (idle dice to tap)
    _continuousController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.isRolling) {
      _continuousController.repeat();
    } else {
      _rollController.forward();
    }
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !widget.isRolling) {
      _continuousController.stop();
      _rollController.reset();
      _rollController.forward();
    }
    if (widget.isRolling && !oldWidget.isRolling) {
      _rollController.stop();
      _continuousController.repeat();
    }
    if (!widget.isRolling && oldWidget.isRolling) {
      _continuousController.stop();
      _rollController.reset();
      _rollController.forward();
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    _continuousController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRolling) {
      return AnimatedBuilder(
        animation: _continuousController,
        builder: (context, child) {
          final angle = _continuousController.value * 2 * pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.003) // perspective
              ..rotateY(angle)
              ..rotateX(sin(angle) * 0.3),
            child: child,
          );
        },
        child: _buildDiceFace(),
      );
    }

    return AnimatedBuilder(
      animation: _rollController,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounce.value,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // perspective
              ..rotateZ(_rotationZ.value)
              ..rotateX(_rotationX.value),
            child: child,
          ),
        );
      },
      child: _buildDiceFace(),
    );
  }

  Widget _buildDiceFace() {
    return Opacity(
      opacity: widget.used ? 0.3 : 1.0,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          // Ivory/bone gradient with warm tone
          gradient: const LinearGradient(
            begin: Alignment(-0.9, -0.9),
            end: Alignment(0.9, 0.9),
            colors: [
              Color(0xFFFFFEF8),
              Color(0xFFF8F2E0),
              Color(0xFFEDE4CE),
              Color(0xFFE0D6B8),
              Color(0xFFD5CBA8),
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
          borderRadius: BorderRadius.circular(widget.size * 0.18),
          border: Border.all(
            color: const Color(0xFF9D927E),
            width: 1.2,
          ),
          boxShadow: [
            // Main drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 8,
              offset: const Offset(1, 3),
            ),
            // Bottom edge shadow for 3D cube feel
            BoxShadow(
              color: const Color(0xFF5A5248).withValues(alpha: 0.6),
              blurRadius: 0,
              offset: const Offset(0, 2),
              spreadRadius: -1,
            ),
            // Soft ambient shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DiceBevelPainter(widget.size * 0.18),
                ),
              ),
            ),
            // Surface shine highlight
            Positioned(
              left: widget.size * 0.1,
              top: widget.size * 0.08,
              child: Container(
                width: widget.size * 0.35,
                height: widget.size * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.1),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Dice dots
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DiceDotsPainter(widget.value, widget.size),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiceBevelPainter extends CustomPainter {
  final double radius;

  const _DiceBevelPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius));

    final topLeftPaint = Paint()
      ..color = const Color(0xFFD5CBAE).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bottomRightPaint = Paint()
      ..color = const Color(0xFF6E655C).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    final topLeftPath = Path()
      ..moveTo(rrect.left + radius, rrect.top)
      ..lineTo(rrect.right - radius, rrect.top)
      ..arcToPoint(
        Offset(rrect.right, rrect.top + radius),
        radius: Radius.circular(radius),
      )
      ..moveTo(rrect.left, rrect.bottom - radius)
      ..lineTo(rrect.left, rrect.top + radius)
      ..arcToPoint(
        Offset(rrect.left + radius, rrect.top),
        radius: Radius.circular(radius),
      );

    final bottomRightPath = Path()
      ..moveTo(rrect.left + radius, rrect.bottom)
      ..lineTo(rrect.right - radius, rrect.bottom)
      ..arcToPoint(
        Offset(rrect.right, rrect.bottom - radius),
        radius: Radius.circular(radius),
      )
      ..moveTo(rrect.right, rrect.top + radius)
      ..lineTo(rrect.right, rrect.bottom - radius)
      ..arcToPoint(
        Offset(rrect.right - radius, rrect.bottom),
        radius: Radius.circular(radius),
      );

    canvas.drawPath(topLeftPath, topLeftPaint);
    canvas.drawPath(bottomRightPath, bottomRightPaint);
  }

  @override
  bool shouldRepaint(covariant _DiceBevelPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}

class _DiceDotsPainter extends CustomPainter {
  final int value;
  final double diceSize;
  _DiceDotsPainter(this.value, this.diceSize);

  @override
  void paint(Canvas canvas, Size size) {
    final dotRadius = size.width * 0.095;
    final positions = _getDotPositions(value, size);

    for (final pos in positions) {
      // Inset shadow (recessed dot effect)
      final insetShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(
        pos + const Offset(0.3, 0.8),
        dotRadius + 0.5,
        insetShadowPaint,
      );

      // Main dot with dark rich color
      final paint = Paint()
        ..color = const Color(0xFF1A0E08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, dotRadius, paint);

      // Inner gradient highlight on dot (gives depth)
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        pos + Offset(-dotRadius * 0.2, -dotRadius * 0.25),
        dotRadius * 0.4,
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
  bool shouldRepaint(covariant _DiceDotsPainter old) =>
      old.value != value || old.diceSize != diceSize;
}
