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
    final rimWidth = size * 0.07;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Metallic rim gradient (chrome ring effect)
          gradient: RadialGradient(
            center: const Alignment(-0.25, -0.35),
            radius: 0.85,
            colors: isWhite
                ? [
                    const Color(0xFFD0D0D2),
                    const Color(0xFFB8B8BA),
                    const Color(0xFF9A9A9C),
                    const Color(0xFF808082),
                  ]
                : [
                    const Color(0xFF8A8A8C),
                    const Color(0xFF727274),
                    const Color(0xFF5A5A5C),
                    const Color(0xFF4A4A4C),
                  ],
            stops: const [0.0, 0.3, 0.65, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: TavlaTheme.gold.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Container(
            width: size - rimWidth * 2,
            height: size - rimWidth * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Piece body
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.3),
                radius: 0.85,
                colors: isWhite
                    ? [
                        const Color(0xFFF0EAE0),
                        const Color(0xFFE0D8CC),
                        const Color(0xFFD0C8BA),
                        const Color(0xFFC2BAA8),
                      ]
                    : [
                        const Color(0xFF5A5A5C),
                        const Color(0xFF4A4A4C),
                        const Color(0xFF3C3C3E),
                        const Color(0xFF303032),
                      ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
              border: Border.all(
                color: isSelected
                    ? TavlaTheme.gold
                    : Colors.black.withValues(alpha: 0.12),
                width: isSelected ? 2.0 : 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Inner concentric groove ring
                Center(
                  child: Container(
                    width: (size - rimWidth * 2) * 0.6,
                    height: (size - rimWidth * 2) * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isWhite
                            ? const Color(0x20000000)
                            : const Color(0x18FFFFFF),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                // Shine highlight
                Positioned(
                  left: (size - rimWidth * 2) * 0.2,
                  top: (size - rimWidth * 2) * 0.1,
                  child: Container(
                    width: (size - rimWidth * 2) * 0.25,
                    height: (size - rimWidth * 2) * 0.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: isWhite ? 0.45 : 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Count text
                if (count > 1)
                  Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isWhite ? TavlaTheme.darkBrown : Colors.white,
                        fontSize: (size - rimWidth * 2) * 0.38,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: isWhite
                                ? Colors.black.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
