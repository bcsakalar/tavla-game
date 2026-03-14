import 'package:flutter/services.dart';

/// Centralized haptic feedback helper.
class HapticHelper {
  static bool enabled = true;

  /// Light tap — piece selection
  static void selectionTap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Light impact — piece placed
  static void lightImpact() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact — piece hit/captured
  static void mediumImpact() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact — dice roll, timer warning
  static void heavyImpact() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Success pattern — game won
  static void success() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Error pattern — time running out
  static void error() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}
