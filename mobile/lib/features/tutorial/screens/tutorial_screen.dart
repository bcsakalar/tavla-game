import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/tutorial_step.dart';
import '../../../core/theme/tavla_theme.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavlaTheme.darkBrown,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeTutorial,
                child: const Text(
                  'Atla',
                  style: TextStyle(color: TavlaTheme.gold, fontSize: 16),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: tutorialSteps.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final step = tutorialSteps[index];
                  return _buildStepPage(step, index);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tutorialSteps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? TavlaTheme.gold
                          : TavlaTheme.gold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TavlaTheme.cream,
                          side: const BorderSide(color: TavlaTheme.gold),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Geri'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < tutorialSteps.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeTutorial();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TavlaTheme.gold,
                        foregroundColor: TavlaTheme.darkBrown,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _currentPage < tutorialSteps.length - 1
                            ? 'İleri'
                            : 'Başla!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildStepPage(TutorialStep step, int index) {
    final icon = _getHighlightIcon(step.highlight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavlaTheme.brown.withValues(alpha: 0.3),
              border: Border.all(color: TavlaTheme.gold, width: 2),
            ),
            child: Icon(
              icon,
              size: 48,
              color: TavlaTheme.gold,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              color: TavlaTheme.cream,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              color: TavlaTheme.cream.withValues(alpha: 0.85),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Step number
          const SizedBox(height: 24),
          Text(
            '${index + 1} / ${tutorialSteps.length}',
            style: TextStyle(
              color: TavlaTheme.gold.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHighlightIcon(TutorialHighlight? highlight) {
    switch (highlight) {
      case TutorialHighlight.board:
        return Icons.grid_on;
      case TutorialHighlight.dice:
        return Icons.casino;
      case TutorialHighlight.bar:
        return Icons.vertical_distribute;
      case TutorialHighlight.bearOff:
        return Icons.exit_to_app;
      case TutorialHighlight.timer:
        return Icons.timer;
      case TutorialHighlight.actions:
        return Icons.rocket_launch;
      case null:
        return Icons.school;
    }
  }

  void _completeTutorial() {
    ref.read(settingsProvider.notifier).markTutorialSeen();
    context.go('/lobby');
  }
}
