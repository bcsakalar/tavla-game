import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages all game audio effects.
class AudioManager {
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;
  AudioManager._();

  final Map<String, AudioPlayer> _players = {};
  bool _soundEnabled = true;
  double _volume = 1.0;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// Sound effect identifiers
  static const String diceRoll = 'dice_roll';
  static const String pieceMove = 'piece_move';
  static const String pieceHit = 'piece_hit';
  static const String bearOff = 'bear_off';
  static const String turnChange = 'turn_change';
  static const String timerWarning = 'timer_warning';
  static const String timerCritical = 'timer_critical';
  static const String gameWin = 'game_win';
  static const String gameLose = 'game_lose';
  static const String chatMessage = 'chat_message';
  static const String matchFound = 'match_found';
  static const String buttonTap = 'button_tap';

  /// Initialize audio system and load preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _volume = prefs.getDouble('sound_volume') ?? 1.0;
  }

  /// Play a sound effect
  Future<void> play(String sound) async {
    if (!_soundEnabled) return;

    try {
      // Reuse or create player for this sound
      if (!_players.containsKey(sound)) {
        _players[sound] = AudioPlayer();
      }

      final player = _players[sound]!;
      await player.setVolume(_volume);
      await player.play(AssetSource('sounds/$sound.mp3'));
    } catch (_) {
      // Sound file might not exist yet, silently ignore
    }
  }

  /// Toggle sound on/off
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  /// Set sound enabled state
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _volume);
  }

  /// Clean up
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
