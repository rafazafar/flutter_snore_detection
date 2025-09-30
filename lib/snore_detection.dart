/// A Flutter package for real-time and file-based snoring detection using TensorFlow Lite.
///
/// This package provides an easy-to-use API for detecting snoring in audio streams
/// or pre-recorded files. It uses a quantized TensorFlow Lite model trained on
/// snoring and noise samples for efficient on-device inference.
///
/// ## Features
///
/// - Real-time snoring detection from device microphone
/// - File-based detection for analyzing pre-recorded audio
/// - Configurable confidence thresholds
/// - Cross-platform support (iOS and Android)
/// - Low memory footprint with quantized model
///
/// ## Quick Start
///
/// ```dart
/// import 'package:snore_detection/snore_detection.dart';
///
/// final detector = SnoreDetector();
/// await detector.initialize();
///
/// // Live detection
/// await detector.startLiveDetection(
///   confidenceThreshold: 0.7,
///   onResult: (result) {
///     if (result.isSnoring) {
///       print('Snoring detected! Confidence: ${result.confidence}');
///     }
///   },
/// );
///
/// // File detection
/// final results = await detector.detectFromFile('/path/to/audio.wav');
/// ```
///
/// See [SnoreDetector] for detailed API documentation.
library snore_detection;

export 'src/snore_detector.dart';
export 'src/models/detection_result.dart';
