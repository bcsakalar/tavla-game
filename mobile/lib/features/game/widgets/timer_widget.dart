import 'package:flutter/material.dart';
import '../../../core/theme/tavla_theme.dart';

class TimerWidget extends StatefulWidget {
  final int seconds;
  final int maxSeconds;
  final bool isActive;

  const TimerWidget({
    super.key,
    required this.seconds,
    required this.maxSeconds,
    this.isActive = true,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds <= 10 && widget.isActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getTimerColor() {
    final ratio = widget.seconds / widget.maxSeconds;
    if (ratio > 0.5) return TavlaTheme.success;
    if (ratio > 0.25) return TavlaTheme.gold;
    return TavlaTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final progress = widget.seconds / widget.maxSeconds;
    final color = _getTimerColor();
    final isCritical = widget.seconds <= 10;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isCritical ? 1.0 + _pulseController.value * 0.15 : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                // Timer text
                Text(
                  '${widget.seconds}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isCritical ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
