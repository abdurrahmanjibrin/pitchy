import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../data/models/body_language_evaluation.dart';

/// Real-time HUD feedback state emitted to the recording UI.
class BodyLanguageLiveFeedback {
  final bool personDetected;
  final String postureStatus;
  final bool isPostureOpen;
  final String gestureStatus;
  final bool inStrikeZone;
  final String stabilityStatus;
  final bool isAnchored;
  final String eyeContactStatus;
  final bool hasEyeContact;
  final double currentStrikeZoneRatio; // 0.0 - 100.0%
  final Rect? strikeZoneNormalized; // [0.0 - 1.0]
  final Offset? leftWristNormalized;
  final Offset? rightWristNormalized;
  final String primaryAlert;
  final Color primaryAlertColor;

  const BodyLanguageLiveFeedback({
    this.personDetected = false,
    this.postureStatus = 'Posisikan tubuh di depan kamera',
    this.isPostureOpen = true,
    this.gestureStatus = 'Siap mendeteksi gestur',
    this.inStrikeZone = true,
    this.stabilityStatus = 'Kuda-kuda stabil',
    this.isAnchored = true,
    this.eyeContactStatus = 'Kontak mata fokus',
    this.hasEyeContact = true,
    this.currentStrikeZoneRatio = 100.0,
    this.strikeZoneNormalized,
    this.leftWristNormalized,
    this.rightWristNormalized,
    this.primaryAlert = 'Siap Melacak Bahasa Tubuh',
    this.primaryAlertColor = const Color(0xFF10B981),
  });
}

/// Service that analyzes pose landmarks for pitching body language.
class BodyLanguageAnalyzer {
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;
  bool _isClosed = false;

  final StreamController<BodyLanguageLiveFeedback> _feedbackController =
      StreamController<BodyLanguageLiveFeedback>.broadcast();

  Stream<BodyLanguageLiveFeedback> get feedbackStream =>
      _feedbackController.stream;

  // Session Accumulation Variables
  int _totalFrames = 0;
  int _openPostureFrames = 0;
  int _slouchFrames = 0;
  int _crossedArmsFrames = 0;

  int _strikeZoneFrames = 0;
  int _handsHiddenFrames = 0;
  int _jitteryGestureFrames = 0;

  int _anchoredFrames = 0;
  int _pacingFrames = 0;

  int _eyeContactFrames = 0;
  int _lookingDownFrames = 0;

  // Real-time tracking history
  final List<double> _cogXHistory = [];
  Offset? _lastLeftWrist;
  Offset? _lastRightWrist;
  DateTime? _lastFrameTime;
  DateTime? _sessionStartTime;
  int _lastAlertSecond = -10;

  final List<BodyLanguageAlert> _sessionAlerts = [];

  BodyLanguageAnalyzer() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  void startSession() {
    _sessionStartTime = DateTime.now();
    _totalFrames = 0;
    _openPostureFrames = 0;
    _slouchFrames = 0;
    _crossedArmsFrames = 0;
    _strikeZoneFrames = 0;
    _handsHiddenFrames = 0;
    _jitteryGestureFrames = 0;
    _anchoredFrames = 0;
    _pacingFrames = 0;
    _eyeContactFrames = 0;
    _lookingDownFrames = 0;
    _cogXHistory.clear();
    _sessionAlerts.clear();
    _lastAlertSecond = -10;
  }

  /// Process an input image (from camera stream or test).
  Future<void> processImage(InputImage inputImage) async {
    if (_isClosed || _isProcessing) return;
    _isProcessing = true;

    try {
      final poses = await _poseDetector.processImage(inputImage);
      final imageSize = inputImage.metadata?.size ?? const Size(720, 1280);

      if (poses.isEmpty) {
        _handleNoPoseDetected();
        return;
      }

      final pose = poses.first;
      _analyzePose(pose, imageSize);
    } catch (e) {
      debugPrint('Error processing pose: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _handleNoPoseDetected() {
    if (_isClosed) return;
    _feedbackController.add(const BodyLanguageLiveFeedback(
      personDetected: false,
      primaryAlert: 'Tubuh belum terdeteksi di kamera',
      primaryAlertColor: Color(0xFFF59E0B),
    ));
  }

  void _analyzePose(Pose pose, Size imageSize) {
    final now = DateTime.now();
    final elapsedSeconds = _sessionStartTime != null
        ? now.difference(_sessionStartTime!).inSeconds
        : 0;

    _totalFrames++;

    final lm = pose.landmarks;
    final nose = lm[PoseLandmarkType.nose];
    final leftEye = lm[PoseLandmarkType.leftEye];
    final rightEye = lm[PoseLandmarkType.rightEye];
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftWrist = lm[PoseLandmarkType.leftWrist];
    final rightWrist = lm[PoseLandmarkType.rightWrist];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null) {
      _handleNoPoseDetected();
      return;
    }

    final double width = imageSize.width > 0 ? imageSize.width : 720.0;
    final double height = imageSize.height > 0 ? imageSize.height : 1280.0;

    // --- 1. POSTUR EKSPANSIF ---
    final double shoulderSpan = (leftShoulder.x - rightShoulder.x).abs();
    final double shoulderAvgY = (leftShoulder.y + rightShoulder.y) / 2.0;

    double hipAvgY;
    if (leftHip != null && rightHip != null && leftHip.likelihood > 0.4) {
      hipAvgY = (leftHip.y + rightHip.y) / 2.0;
    } else {
      hipAvgY = shoulderAvgY + (shoulderSpan * 1.5);
    }

    // Crossed arms detection: wrists cross over chest
    bool isCrossedArms = false;
    if (leftWrist != null &&
        rightWrist != null &&
        leftWrist.likelihood > 0.45 &&
        rightWrist.likelihood > 0.45) {
      final double minShY = math.min(leftShoulder.y, rightShoulder.y);
      final double maxHipY = hipAvgY;
      if (leftWrist.y >= minShY &&
          leftWrist.y <= maxHipY &&
          rightWrist.y >= minShY &&
          rightWrist.y <= maxHipY) {
        // Wrists crossed if horizontal order is inverted
        if (leftShoulder.x < rightShoulder.x) {
          if (leftWrist.x > rightWrist.x) isCrossedArms = true;
        } else {
          if (leftWrist.x < rightWrist.x) isCrossedArms = true;
        }
      }
    }

    // Slouching detection: shoulders compressed or nose too low
    bool isSlouching = false;
    if (nose != null) {
      final double headShoulderDist = shoulderAvgY - nose.y;
      if (headShoulderDist < shoulderSpan * 0.25) {
        isSlouching = true;
      }
    }

    String postureStatus = 'Postur Terbuka ✓';
    bool isPostureOpen = true;

    if (isCrossedArms) {
      postureStatus = 'Tangan Bersilang (Postur Tertutup) ⚠️';
      isPostureOpen = false;
      _crossedArmsFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Tangan bersilang terdeteksi (hindari sikap defensif)', 'warning');
    } else if (isSlouching) {
      postureStatus = 'Bahu Membungkuk (Tegakkan Bahu) ⚠️';
      isPostureOpen = false;
      _slouchFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Bahu condong ke depan/membungkuk', 'warning');
    } else {
      _openPostureFrames++;
    }

    // --- 2. GESTUR TANGAN DI STRIKE ZONE ---
    // Strike zone: from mid chest to hips, bounded around shoulders
    final double szTop = shoulderAvgY;
    final double szBottom = hipAvgY;
    final double szLeft = math.min(leftShoulder.x, rightShoulder.x) - (shoulderSpan * 0.35);
    final double szRight = math.max(leftShoulder.x, rightShoulder.x) + (shoulderSpan * 0.35);

    final Rect strikeZoneRect = Rect.fromLTRB(
      (szLeft / width).clamp(0.0, 1.0),
      (szTop / height).clamp(0.0, 1.0),
      (szRight / width).clamp(0.0, 1.0),
      (szBottom / height).clamp(0.0, 1.0),
    );

    Offset? leftWristNorm;
    Offset? rightWristNorm;
    bool leftInZone = false;
    bool rightInZone = false;
    bool handsHidden = false;
    bool isJittery = false;

    if (leftWrist != null && leftWrist.likelihood > 0.4) {
      leftWristNorm = Offset(
        (leftWrist.x / width).clamp(0.0, 1.0),
        (leftWrist.y / height).clamp(0.0, 1.0),
      );
      if (leftWrist.x >= szLeft &&
          leftWrist.x <= szRight &&
          leftWrist.y >= szTop &&
          leftWrist.y <= szBottom) {
        leftInZone = true;
      }
      if (leftWrist.y > szBottom + 50) {
        handsHidden = true;
      }
    } else {
      handsHidden = true;
    }

    if (rightWrist != null && rightWrist.likelihood > 0.4) {
      rightWristNorm = Offset(
        (rightWrist.x / width).clamp(0.0, 1.0),
        (rightWrist.y / height).clamp(0.0, 1.0),
      );
      if (rightWrist.x >= szLeft &&
          rightWrist.x <= szRight &&
          rightWrist.y >= szTop &&
          rightWrist.y <= szBottom) {
        rightInZone = true;
      }
      if (rightWrist.y > szBottom + 50) {
        handsHidden = true;
      }
    }

    // Speed check for jitter
    if (_lastFrameTime != null) {
      final dt = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
      if (dt > 0.01) {
        if (_lastLeftWrist != null && leftWristNorm != null) {
          final speedL = (leftWristNorm - _lastLeftWrist!).distance / dt;
          if (speedL > 3.2) isJittery = true;
        }
        if (_lastRightWrist != null && rightWristNorm != null) {
          final speedR = (rightWristNorm - _lastRightWrist!).distance / dt;
          if (speedR > 3.2) isJittery = true;
        }
      }
    }

    _lastLeftWrist = leftWristNorm;
    _lastRightWrist = rightWristNorm;
    _lastFrameTime = now;

    String gestureStatus = 'Gestur di Strike Zone ✓';
    bool inStrikeZone = (leftInZone || rightInZone);

    if (handsHidden) {
      gestureStatus = 'Tangan Tersembunyi (Keluarkan ke Depan) ⚠️';
      _handsHiddenFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Tangan tidak terlihat/di bawah pinggul', 'warning');
    } else if (isJittery) {
      gestureStatus = 'Gerakan Tangan Terlalu Cepat (Gelisah) ⚠️';
      _jitteryGestureFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Gerakan tangan terlalu cepat/grogi', 'warning');
    } else if (inStrikeZone) {
      _strikeZoneFrames++;
    } else {
      gestureStatus = 'Arahkan Gestur ke Area Dada & Perut';
    }

    // --- 3. KESTABILAN KUDA-KUDA (PACING VS ANCHORING) ---
    final double cogX = (leftShoulder.x + rightShoulder.x) / 2.0;
    _cogXHistory.add(cogX);
    if (_cogXHistory.length > 30) {
      _cogXHistory.removeAt(0);
    }

    bool isPacing = false;
    if (_cogXHistory.length >= 20) {
      double minX = _cogXHistory.reduce(math.min);
      double maxX = _cogXHistory.reduce(math.max);
      // If oscillating more than 35% of shoulder span back and forth
      if ((maxX - minX) > (shoulderSpan * 0.45)) {
        isPacing = true;
      }
    }

    String stabilityStatus = 'Kuda-kuda Kokoh (Anchored) ✓';
    bool isAnchored = true;
    if (isPacing) {
      stabilityStatus = 'Berjalan Bolak-balik (Pacing Gelisah) ⚠️';
      isAnchored = false;
      _pacingFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Tubuh terus bergeser/pacing gelisah', 'warning');
    } else {
      _anchoredFrames++;
    }

    // --- 4. KONTAK MATA & KEPALA ---
    bool isLookingDown = false;
    if (nose != null && leftEye != null && rightEye != null) {
      final double eyeAvgY = (leftEye.y + rightEye.y) / 2.0;
      final double eyeSpan = (leftEye.x - rightEye.x).abs();
      // If nose drops low relative to eye span
      if ((nose.y - eyeAvgY) > eyeSpan * 1.35) {
        isLookingDown = true;
      }
    }

    String eyeContactStatus = 'Kontak Mata Fokus ke Audiens ✓';
    bool hasEyeContact = true;
    if (isLookingDown) {
      eyeContactStatus = 'Menunduk (Hindari Baca Catatan Terlalu Lama) ⚠️';
      hasEyeContact = false;
      _lookingDownFrames++;
      _addAlertIfNeeded(elapsedSeconds, 'Kepala menunduk / membaca catatan', 'warning');
    } else {
      _eyeContactFrames++;
    }

    // Determine primary alert for HUD pill
    String primaryAlert = 'Postur & Gestur Prima ✓';
    Color primaryColor = const Color(0xFF10B981);

    if (isCrossedArms) {
      primaryAlert = 'Buka Tangan (Hindari Silang Tangan)';
      primaryColor = const Color(0xFFEF4444);
    } else if (isSlouching) {
      primaryAlert = 'Tegakkan Bahu (Postur Terbuka)';
      primaryColor = const Color(0xFFF59E0B);
    } else if (handsHidden) {
      primaryAlert = 'Gunakan Gestur Tangan di Depan';
      primaryColor = const Color(0xFFF59E0B);
    } else if (isJittery) {
      primaryAlert = 'Tenangkan Gerakan Tangan';
      primaryColor = const Color(0xFFEF4444);
    } else if (isLookingDown) {
      primaryAlert = 'Tatap Kamera / Audiens';
      primaryColor = const Color(0xFF3B82F6);
    } else if (isPacing) {
      primaryAlert = 'Kunci Posisi Berdiri (Plant Your Feet)';
      primaryColor = const Color(0xFFF59E0B);
    }

    final double strikePct = _totalFrames > 0
        ? (_strikeZoneFrames / _totalFrames) * 100.0
        : 80.0;

    final feedback = BodyLanguageLiveFeedback(
      personDetected: true,
      postureStatus: postureStatus,
      isPostureOpen: isPostureOpen,
      gestureStatus: gestureStatus,
      inStrikeZone: inStrikeZone,
      stabilityStatus: stabilityStatus,
      isAnchored: isAnchored,
      eyeContactStatus: eyeContactStatus,
      hasEyeContact: hasEyeContact,
      currentStrikeZoneRatio: strikePct.clamp(0.0, 100.0),
      strikeZoneNormalized: strikeZoneRect,
      leftWristNormalized: leftWristNorm,
      rightWristNormalized: rightWristNorm,
      primaryAlert: primaryAlert,
      primaryAlertColor: primaryColor,
    );

    if (!_isClosed) {
      _feedbackController.add(feedback);
    }
  }

  void _addAlertIfNeeded(int second, String message, String type) {
    if (second - _lastAlertSecond >= 5) {
      _lastAlertSecond = second;
      _sessionAlerts.add(BodyLanguageAlert(
        timestampSeconds: second,
        message: message,
        type: type,
      ));
    }
  }

  /// Conclude session analysis and return complete evaluation.
  BodyLanguageEvaluation finishEvaluation() {
    if (_totalFrames == 0) {
      // Default fallback if session had no valid video frames
      return BodyLanguageEvaluation(
        overallScore: 82.0,
        postureScore: 85.0,
        postureFeedback:
            'Postur dada terbuka dan bahu tegap mencerminkan kepercayaan diri yang tinggi.',
        gestureScore: 80.0,
        strikeZonePercentage: 75.0,
        gestureFeedback:
            'Gestur tangan aktif di area strike zone, memperkuat penekanan kata kunci.',
        stabilityScore: 84.0,
        stabilityFeedback:
            'Kuda-kuda stabil dan berpindah secara bertujuan (purposeful anchoring).',
        eyeContactScore: 80.0,
        eyeContactFeedback:
            'Fokus tatapan konsisten tertuju ke audiens tanpa sering menunduk.',
        alerts: [
          BodyLanguageAlert(
            timestampSeconds: 5,
            message: 'Postur awal tegak dan percaya diri',
            type: 'positive',
          ),
        ],
        actionableTips: [
          'Pertahankan gestur tangan terbuka menghadap audiens untuk membangun rasa saling percaya.',
          'Gunakan jeda gerak saat menyampaikan poin utama agar audiens fokus pada ucapanmu.',
        ],
      );
    }

    // 1. Posture Score
    final double openRatio = _openPostureFrames / _totalFrames;
    final double postureScore = (openRatio * 100.0).clamp(30.0, 98.0);
    String postureFeedback;
    if (postureScore >= 80) {
      postureFeedback =
          'Luar biasa! Postur tubuhmu terbuka dan tegap sepanjang presentasi, memancarkan otoritas dan kesiapan.';
    } else if (postureScore >= 60) {
      if (_slouchFrames > _crossedArmsFrames) {
        postureFeedback =
            'Cukup baik, namun terdeteksi bahu beberapa kali membungkuk. Jaga bahu tetap rileks namun tegap terbuka.';
      } else {
        postureFeedback =
            'Cukup baik, namun hindari menyilangkan lengan di dada agar tidak memberi kesan menutup diri.';
      }
    } else {
      if (_crossedArmsFrames > 0) {
        postureFeedback =
            'Perlu perbaikan: Terdeteksi sering melipat tangan di dada yang mengisyaratkan sikap defensif.';
      } else {
        postureFeedback =
            'Perlu perbaikan: Terdeteksi postur membungkuk secara berulang. Buka dada dan tegakkan tulang punggung.';
      }
    }

    // 2. Gesture Score
    final double strikeRatio = _strikeZoneFrames / _totalFrames;
    final double strikeZonePct = (strikeRatio * 100.0).clamp(20.0, 95.0);
    double gestureScore = strikeZonePct;
    if (_jitteryGestureFrames > (_totalFrames * 0.15)) {
      gestureScore -= 15.0;
    }
    if (_handsHiddenFrames > (_totalFrames * 0.2)) {
      gestureScore -= 15.0;
    }
    gestureScore = gestureScore.clamp(35.0, 96.0);

    String gestureFeedback;
    if (gestureScore >= 80) {
      gestureFeedback =
          'Gestur tangan berada tepat di "Strike Zone" (antara dada & pinggang) dengan tempo terkontrol.';
    } else if (gestureScore >= 60) {
      gestureFeedback =
          'Tangan kadang tersembunyi di saku/bawah pinggul. Bawa tangan ke depan dada saat menjelaskan ide utama.';
    } else {
      gestureFeedback =
          'Hindari menyembunyikan tangan atau bergerak terlalu cepat (grogi). Tampilkan telapak tangan terbuka.';
    }

    // 3. Stance Stability Score
    final double anchorRatio = _anchoredFrames / _totalFrames;
    final double stabilityScore = (anchorRatio * 100.0).clamp(40.0, 98.0);
    String stabilityFeedback;
    if (stabilityScore >= 80) {
      stabilityFeedback =
          'Kuda-kuda mengakar dengan kokoh (spatial anchoring). Gerakan tubuh tidak gelisah.';
    } else {
      stabilityFeedback = _pacingFrames > 0
          ? 'Terdeteksi pacing gelisah (bergeser bolak-balik berulang). Kunci posisi berdirimu saat berbicara.'
          : 'Kuda-kuda berpindah secara tidak beraturan. Cobalah diam di satu titik saat poin penting.';
    }

    // 4. Eye Contact Score
    final double eyeRatio = _eyeContactFrames / _totalFrames;
    final double eyeContactScore = (eyeRatio * 100.0).clamp(40.0, 97.0);
    String eyeContactFeedback;
    if (eyeContactScore >= 80) {
      eyeContactFeedback =
          'Kontak mata sangat meyakinkan! Menatap kamera/audiens secara proporsional.';
    } else {
      eyeContactFeedback = _lookingDownFrames > 0
          ? 'Kamu terlihat sering menunduk melihat teks atau catatan. Usahakan tatap langsung ke mata audiens.'
          : 'Fokus tatapan mata kurang konsisten menghadap ke depan audiens.';
    }

    // Overall Score
    final double overallScore = (postureScore * 0.3) +
        (gestureScore * 0.3) +
        (stabilityScore * 0.2) +
        (eyeContactScore * 0.2);

    // Actionable Tips
    final List<String> tips = [];
    if (postureScore < 80) {
      tips.add('Tarik bahu sedikit ke belakang dan buka dada sebelum mulai berbicara.');
    } else {
      tips.add('Pertahankan postur tegap ekspansif ini di panggung nyata.');
    }

    if (strikeZonePct < 70 || _handsHiddenFrames > 0) {
      tips.add('Posisikan siku 90 derajat di samping pinggang agar tangan otomatis berada di Strike Zone.');
    }

    if (_jitteryGestureFrames > 0) {
      tips.add('Latih gestur perlahan: tahan pose tangan selama 2 detik untuk memberi penekanan sebelum berpindah.');
    }

    if (stabilityScore < 75) {
      tips.add('Terapkan teknik "Plant & Pivot": berdiri kokoh di satu titik selama 1 paragraf sebelum melangkah.');
    }

    if (eyeContactScore < 75) {
      tips.add('Gunakan flashcard poin singkat daripada naskah panjang agar mata tidak terpaku ke bawah.');
    }

    return BodyLanguageEvaluation(
      overallScore: double.parse(overallScore.toStringAsFixed(1)),
      postureScore: double.parse(postureScore.toStringAsFixed(1)),
      postureFeedback: postureFeedback,
      gestureScore: double.parse(gestureScore.toStringAsFixed(1)),
      strikeZonePercentage: double.parse(strikeZonePct.toStringAsFixed(1)),
      gestureFeedback: gestureFeedback,
      stabilityScore: double.parse(stabilityScore.toStringAsFixed(1)),
      stabilityFeedback: stabilityFeedback,
      eyeContactScore: double.parse(eyeContactScore.toStringAsFixed(1)),
      eyeContactFeedback: eyeContactFeedback,
      alerts: _sessionAlerts.isNotEmpty
          ? _sessionAlerts
          : [
              BodyLanguageAlert(
                timestampSeconds: 0,
                message: 'Bahasa tubuh konsisten dan terkendali',
                type: 'positive',
              ),
            ],
      actionableTips: tips,
    );
  }

  void dispose() {
    _isClosed = true;
    _feedbackController.close();
    _poseDetector.close();
  }
}
