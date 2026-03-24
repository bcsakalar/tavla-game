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
    final outerShadowBlur = size * 0.17;
    final topHighlightAlpha = isWhite ? 0.68 : 0.18;
    final lowerGlowAlpha = isWhite ? 0.18 : 0.08;

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
                      const Color(0xFFE7E2D8),
                      const Color(0xFFD1C9BB),
                      const Color(0xFFACA393),
                      const Color(0xFF7F776C),
                    ]
                  : [
                      const Color(0xFF72655A),
                      const Color(0xFF584B41),
                      const Color(0xFF443932),
                      const Color(0xFF312822),
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            border: Border.all(
              color: isWhite
                  ? const Color(0xFF776A5B).withValues(alpha: 0.45)
                  : const Color(0xFFDCCAA8).withValues(alpha: 0.16),
              width: rimWidth * 0.55,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: outerShadowBlur,
                spreadRadius: 0.5,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
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
                          const Color(0xFFFFFCF4),
                          const Color(0xFFF3ECDD),
                          const Color(0xFFE3D8BF),
                          const Color(0xFFD1C3A6),
                          const Color(0xFFBAAC8F),
                        ]
                      : [
                          const Color(0xFF6B5A4B),
                          const Color(0xFF55473C),
                          const Color(0xFF473B33),
                          const Color(0xFF382F29),
                          const Color(0xFF2A231F),
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
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: topHighlightAlpha),
                            Colors.transparent,
                            Colors.black.withValues(alpha: isWhite ? 0.06 : 0.14),
                          ],
                          stops: const [0.0, 0.34, 1.0],
                        ),
                      ),
                    ),
                  ),
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: bodySize * 0.62,
                      height: bodySize * 0.16,
                      margin: EdgeInsets.only(bottom: bodySize * 0.12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(bodySize * 0.2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: lowerGlowAlpha),
                          ],
                        ),
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
                            Colors.white.withValues(alpha: isWhite ? 0.62 : 0.18),
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
                            Colors.white.withValues(alpha: isWhite ? 0.16 : 0.06),
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
