import 'package:audioplayers/audioplayers.dart';

class AudioController {
  AudioController() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;
  bool _muted = false;

  bool get isMuted => _muted;

  void toggleMuted() {
    _muted = !_muted;
  }

  Future<void> playMove() => _play('move.wav');

  Future<void> playCapture() => _play('capture.wav');

  Future<void> playWin() => _play('win.wav');

  Future<void> playDraw() => _play('draw.wav');

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<void> _play(String fileName) async {
    if (_muted) {
      return;
    }
    await _player.stop();
    await _player.play(AssetSource('sounds/$fileName'));
  }
}
