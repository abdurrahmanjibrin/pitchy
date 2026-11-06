import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingStateData {
  final bool isRecording;
  final bool isPaused;
  final int durationSeconds;
  final double currentAmplitude; // 0.0 to 1.0

  RecordingStateData({
    required this.isRecording,
    required this.isPaused,
    required this.durationSeconds,
    required this.currentAmplitude,
  });
}

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSub;

  int _seconds = 0;
  bool _isPaused = false;
  String? _currentFilePath;

  final _stateController = StreamController<RecordingStateData>.broadcast();
  Stream<RecordingStateData> get stateStream => _stateController.stream;

  int get elapsedSeconds => _seconds;
  String? get currentFilePath => _currentFilePath;

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> checkMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  Future<String?> startRecording() async {
    final hasPerm = await requestMicrophonePermission();
    if (!hasPerm) {
      throw Exception('Izin mikrofon diperlukan untuk merekam latihan presentasi.');
    }

    final hasRecorderPerm = await _recorder.hasPermission();
    if (!hasRecorderPerm) {
      throw Exception('Izin akses audio tidak diberikan.');
    }

    // Prepare target directory in private app documents
    final docsDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(docsDir.path, 'pitchy_recordings'));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final fileName = 'pitch_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final targetPath = p.join(recordingsDir.path, fileName);
    _currentFilePath = targetPath;
    _seconds = 0;
    _isPaused = false;

    // Start recording AAC audio
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: targetPath,
    );

    // Duration timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _seconds++;
        _notifyState(0.2);
      }
    });

    // Listen to amplitude
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      // amp.current is typically in dB (e.g. -160 to 0)
      // Normalize to 0.0 - 1.0
      double normalized = 0.0;
      if (amp.current > -60) {
        normalized = (amp.current + 60) / 60.0;
        normalized = normalized.clamp(0.05, 1.0);
      }
      _notifyState(normalized);
    });

    _notifyState(0.1);
    return targetPath;
  }

  Future<void> pauseRecording() async {
    if (await _recorder.isRecording() && !_isPaused) {
      await _recorder.pause();
      _isPaused = true;
      _notifyState(0.0);
    }
  }

  Future<void> resumeRecording() async {
    if (_isPaused) {
      await _recorder.resume();
      _isPaused = false;
      _notifyState(0.2);
    }
  }

  Future<String?> stopRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();

    final path = await _recorder.stop();
    _isPaused = false;
    _notifyState(0.0);
    return path ?? _currentFilePath;
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();

    try {
      await _recorder.stop();
    } catch (_) {}

    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }
    _seconds = 0;
    _isPaused = false;
    _notifyState(0.0);
  }

  void _notifyState(double amp) {
    if (!_stateController.isClosed) {
      _stateController.add(RecordingStateData(
        isRecording: _seconds > 0 || _isPaused,
        isPaused: _isPaused,
        durationSeconds: _seconds,
        currentAmplitude: amp,
      ));
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    await _recorder.dispose();
    await _stateController.close();
  }
}

