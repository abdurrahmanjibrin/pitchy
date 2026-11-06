import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class PlaybackStateData {
  final PlayerState state;
  final Duration position;
  final Duration duration;

  PlaybackStateData({
    required this.state,
    required this.position,
    required this.duration,
  });

  bool get isPlaying => state == PlayerState.playing;
  bool get isPaused => state == PlayerState.paused;
  bool get isStopped =>
      state == PlayerState.stopped || state == PlayerState.completed;
}

class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _state = PlayerState.stopped;

  final _playbackController =
      StreamController<PlaybackStateData>.broadcast();
  Stream<PlaybackStateData> get playbackStream => _playbackController.stream;

  AudioPlaybackService() {
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      _emitState();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      _emitState();
    });

    _player.onPlayerStateChanged.listen((st) {
      _state = st;
      _emitState();
    });
  }

  Future<void> play(String filePath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _position = Duration.zero;
    _emitState();
  }

  void _emitState() {
    if (!_playbackController.isClosed) {
      _playbackController.add(
        PlaybackStateData(
          state: _state,
          position: _position,
          duration: _duration,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _playbackController.close();
  }
}

