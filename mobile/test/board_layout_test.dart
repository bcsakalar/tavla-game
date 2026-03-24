import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/features/game/utils/board_layout.dart';

void main() {
  test('should keep a wide board ratio in tall mobile space', () {
    final viewport = computeBoardViewport(const Size(382, 620));

    expect(viewport.width, closeTo(382, 0.01));
    expect(viewport.height, closeTo(230.12, 0.01));
    expect(viewport.width / viewport.height, closeTo(kBoardAspectRatio, 0.001));
  });

  test('should cap board width when height becomes the limiting dimension', () {
    final viewport = computeBoardViewport(const Size(900, 320));

    expect(viewport.width, closeTo(531.2, 0.01));
    expect(viewport.height, closeTo(320, 0.01));
    expect(viewport.width / viewport.height, closeTo(kBoardAspectRatio, 0.001));
  });
}