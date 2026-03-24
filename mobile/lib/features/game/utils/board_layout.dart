import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const double kBoardAspectRatio = 1.44;

Size computeBoardViewport(
  Size available, {
  double aspectRatio = kBoardAspectRatio,
}) {
  final safeWidth = math.max(0.0, available.width);
  final safeHeight = math.max(0.0, available.height);

  if (safeWidth == 0 || safeHeight == 0) {
    return Size.zero;
  }

  final width = math.min(safeWidth, safeHeight * aspectRatio);
  final height = width / aspectRatio;

  return Size(width, height);
}