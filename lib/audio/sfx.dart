import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// All sound effects in the game.
enum Sound {
  click('click'),
  move('move'),
  rotate('rotate'),
  drop('drop'),
  squish('squish'),
  pop('pop'),
  feast('feast'),
  combo('combo'),
  fanfare('fanfare'),
  sad('sad'),
  star('star'),
  badge('badge');

  final String file;
  const Sound(this.file);
}

/// Plays short sounds. Uses a small pool so quick sounds can overlap.
class Sfx {
  static final Sfx instance = Sfx._();
  Sfx._();

  bool enabled = true;

  static const _poolSize = 4;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;

  Future<void> init() async {
    if (_pool.isNotEmpty) return;
    try {
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(player);
      }
    } catch (e) {
      // Sound is a garnish, never a blocker. Play on without it.
      debugPrint('Sfx init failed: $e');
      _pool.clear();
    }
  }

  void play(Sound sound) {
    if (!enabled || _pool.isEmpty) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // Fire and forget; a missed sound must not disturb play.
    player
        .stop()
        .then((_) =>
            player.play(AssetSource('audio/${sound.file}.wav'), volume: 0.9))
        .catchError((_) {});
  }

  Future<void> startMusic() async {
    if (!enabled) return;
    try {
      final player = _music ??= AudioPlayer();
      // Already playing (for example resume after the notification
      // shade): do not restart the loop from zero.
      if (player.state == PlayerState.playing) return;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('audio/bgm.wav'), volume: 0.35);
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  void setEnabled(bool value) {
    enabled = value;
    if (!value) stopMusic();
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
    _music?.dispose();
    _music = null;
  }
}
