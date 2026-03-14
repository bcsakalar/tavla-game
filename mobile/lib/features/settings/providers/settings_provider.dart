import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/haptic/haptic_helper.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool moveHintsEnabled;
  final bool pointNumbersEnabled;
  final bool hasSeenTutorial;

  const SettingsState({
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.moveHintsEnabled = true,
    this.pointNumbersEnabled = false,
    this.hasSeenTutorial = false,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? moveHintsEnabled,
    bool? pointNumbersEnabled,
    bool? hasSeenTutorial,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      moveHintsEnabled: moveHintsEnabled ?? this.moveHintsEnabled,
      pointNumbersEnabled: pointNumbersEnabled ?? this.pointNumbersEnabled,
      hasSeenTutorial: hasSeenTutorial ?? this.hasSeenTutorial,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      soundEnabled: prefs.getBool('sound_enabled') ?? true,
      hapticEnabled: prefs.getBool('haptic_enabled') ?? true,
      moveHintsEnabled: prefs.getBool('move_hints_enabled') ?? true,
      pointNumbersEnabled: prefs.getBool('point_numbers_enabled') ?? false,
      hasSeenTutorial: prefs.getBool('has_seen_tutorial') ?? false,
    );

    // Sync audio manager
    AudioManager().setSoundEnabled(state.soundEnabled);
    HapticHelper.enabled = state.hapticEnabled;
  }

  Future<void> toggleSound() async {
    final newVal = !state.soundEnabled;
    state = state.copyWith(soundEnabled: newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', newVal);
    AudioManager().setSoundEnabled(newVal);
  }

  Future<void> toggleHaptic() async {
    final newVal = !state.hapticEnabled;
    state = state.copyWith(hapticEnabled: newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', newVal);
    HapticHelper.enabled = newVal;
  }

  Future<void> toggleMoveHints() async {
    final newVal = !state.moveHintsEnabled;
    state = state.copyWith(moveHintsEnabled: newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('move_hints_enabled', newVal);
  }

  Future<void> togglePointNumbers() async {
    final newVal = !state.pointNumbersEnabled;
    state = state.copyWith(pointNumbersEnabled: newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('point_numbers_enabled', newVal);
  }

  Future<void> markTutorialSeen() async {
    state = state.copyWith(hasSeenTutorial: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
  }

  Future<void> resetTutorial() async {
    state = state.copyWith(hasSeenTutorial: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', false);
  }
}
