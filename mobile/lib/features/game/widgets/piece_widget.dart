import 'package:flutter/material.dart';
import '../../../core/theme/tavla_theme.dart';

class PieceWidget extends StatelessWidget {
  final String player; // 'W' or 'B'
  final int count;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const PieceWidget({
    super.key,
    required this.player,
    this.count = 1,
    this.size = 36,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = player == 'W';
    final rimWidth = size * 0.08;
    final bodySize = size - rimWidth * 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.3),
              radius: 0.9,
              colors: isWhite
                  ? [
                      const Color(0xFFD8D8DA),
                      const Color(0xFFC0C0C2),
                      const Color(0xFF9A9A9C),
                      const Color(0xFF747476),
                    ]
                  : [
                      const Color(0xFF8A8A8C),
                      const Color(0xFF6A6A6C),
                      const Color(0xFF525254),
                      const Color(0xFF404042),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: [
              // Main drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 0.5,
                offset: const Offset(0, 3),
              ),
              // Subtle ambient shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
              // Selected gold glow
              if (isSelected)
                BoxShadow(
                  color: TavlaTheme.gold.withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Container(
              width: bodySize,
              height: bodySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.15, -0.25),
                  radius: 0.85,
                  colors: isWhite
                      ? [
                          const Color(0xFFFAF6F0),
                          const Color(0xFFEDE5D8),
                          const Color(0xFFDDD4C4),
                          const Color(0xFFCEC4B2),
                          const Color(0xFFC0B6A0),
                        ]
                      : [
                          const Color(0xFF686868),
                          const Color(0xFF545456),
                          const Color(0xFF444446),
                          const Color(0xFF363638),
                          const Color(0xFF2C2C2E),
                        ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
                border: Border.all(
                  color: isSelected
                      ? TavlaTheme.gold
                      : isWhite
                          ? const Color(0x25000000)
                          : const Color(0x18000000),
                  width: isSelected ? 1.8 : 0.8,
                ),
              ),
              child: Stack(
                children: [
                  // Inner concentric groove
                  Center(
                    child: Container(
                      width: bodySize * 0.58,
                      height: bodySize * 0.58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isWhite
                              ? const Color(0x22000000)
                              : const Color(0x1AFFFFFF),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isWhite
                                ? Colors.black.withValues(alpha: 0.04)
                                : Colors.white.withValues(alpha: 0.03),
                            blurRadius: 2,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Primary shine highlight
                  Positioned(
                    left: bodySize * 0.18,
                    top: bodySize * 0.08,
                    child: Container(
                      width: bodySize * 0.3,
                      height: bodySize * 0.18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: isWhite ? 0.55 : 0.15),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Secondary subtle edge highlight
                  Positioned(
                    right: bodySize * 0.2,
                    bottom: bodySize * 0.2,
                    child: Container(
                      width: bodySize * 0.15,
                      height: bodySize * 0.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: isWhite ? 0.12 : 0.05),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Count badge
                  if (count > 1)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(bodySize * 0.06),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWhite
                              ? Colors.black.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isWhite ? TavlaTheme.darkBrown : Colors.white,
                            fontSize: bodySize * 0.38,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: isWhite
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
