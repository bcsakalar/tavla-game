import 'package:flutter/material.dart';
import '../../../core/theme/tavla_theme.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/haptic/haptic_helper.dart';

class MatchFoundScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final VoidCallback onReady;

  const MatchFoundScreen({
    super.key,
    required this.gameData,
    required this.onReady,
  });

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _vsController;
  late Animation<double> _scaleAnim;
  late Animation<double> _vsAnim;

  @override
  void initState() {
    super.initState();

    AudioManager().play(AudioManager.matchFound);
    HapticHelper.heavyImpact();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _vsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _vsAnim = CurvedAnimation(
      parent: _vsController,
      curve: Curves.easeOut,
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _vsController.forward();
    });

    // Auto-proceed after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onReady();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavlaTheme.darkBrown,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Rakip Bulundu!" text
            ScaleTransition(
              scale: _scaleAnim,
              child: const Text(
                'Rakip Bulundu!',
                style: TextStyle(
                  color: TavlaTheme.gold,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // VS animation
            FadeTransition(
              opacity: _vsAnim,
              child: ScaleTransition(
                scale: _vsAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Player
                    _buildPlayerAvatar(
                      icon: Icons.person,
                      color: TavlaTheme.whitePiece,
                      label: 'Sen',
                    ),
                    const SizedBox(width: 24),
                    // VS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TavlaTheme.danger.withValues(alpha: 0.8),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Opponent
                    _buildPlayerAvatar(
                      icon: Icons.person,
                      color: TavlaTheme.blackPiece,
                      label: 'Rakip',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Loading
            FadeTransition(
              opacity: _vsAnim,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(TavlaTheme.gold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Oyun hazırlanıyor...',
                    style: TextStyle(
                      color: TavlaTheme.cream.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: color,
          child: Icon(
            icon,
            size: 36,
            color: color == TavlaTheme.whitePiece
                ? TavlaTheme.darkBrown
                : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: TavlaTheme.cream,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
