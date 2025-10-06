import 'dart:async';
import 'dart:io';
import 'services/tflite_service.dart';
import 'services/audio_recorder_service.dart';
import 'utils/audio_processor.dart';
import 'models/detection_result.dart';

/// Main API for snore detection using TensorFlow Lite.
///
/// Provides both live audio detection from the microphone and file-based
/// detection for analyzing pre-recorded audio. The detector uses a quantized
/// TensorFlow Lite model trained on snoring and noise samples.
///
/// ## Usage
///
/// Always call [initialize] before using any other methods:
///
/// ```dart
/// final detector = SnoreDetector();
/// await detector.initialize();
/// ```
///
/// ### Live Detection
///
/// Start real-time detection from the device microphone:
///
/// ```dart
/// await detector.startLiveDetection(
///   confidenceThreshold: 0.7,
///   onResult: (result) {
///     if (result.isSnoring) {
///       print('Snoring detected! Confidence: ${result.confidence}');
///     }
///   },
///   onError: (error) {
///     print('Detection error: $error');
///   },
/// );
///
/// // Stop when done
/// await detector.stopLiveDetection();
/// ```
///
/// ### File Detection
///
/// Analyze a pre-recorded audio file:
///
/// ```dart
/// final results = await detector.detectFromFile('/path/to/audio.wav');
/// for (final result in results) {
///   print('${result.timestamp}: ${result.isSnoring}');
/// }
/// ```
///
/// ### Cleanup
///
/// Always dispose the detector when done:
///
/// ```dart
/// detector.dispose();
/// ```
class SnoreDetector {
  final TFLiteService _tfliteService = TFLiteService();
  final AudioRecorderService _recorderService = AudioRecorderService();

  bool _isInitialized = false;
  StreamController<DetectionResult>? _liveDetectionController;
  double _currentThreshold = 0.5;

  /// Initializes the detector by loading the TensorFlow Lite model.
  ///
  /// This must be called before using any other methods. It loads the
  /// quantized TFLite model from the package assets into memory.
  ///
  /// Throws an [Exception] if the model fails to load.
  ///
  /// Example:
  /// ```dart
  /// final detector = SnoreDetector();
  /// try {
  ///   await detector.initialize();
  ///   print('Detector ready!');
  /// } catch (e) {
  ///   print('Initialization failed: $e');
  /// }
  /// ```
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _tfliteService.initialize();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize SnoreDetector: $e');
    }
  }

  /// Requests microphone permission from the user.
  ///
  /// This should be called before starting live detection to ensure the app
  /// has the necessary permissions. On Android 6.0+ and iOS, this will show
  /// the system permission dialog if permission hasn't been granted yet.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasPermission = await detector.requestMicrophonePermission();
  /// if (hasPermission) {
  ///   await detector.startLiveDetection(...);
  /// } else {
  ///   print('Microphone permission denied');
  /// }
  /// ```
  Future<bool> requestMicrophonePermission() async {
    return await _recorderService.requestPermission();
  }

  /// Starts live audio detection from the device microphone.
  ///
  /// Records audio in 1-second windows and analyzes each window for snoring.
  /// Results are delivered through both the returned stream and optional callbacks.
  ///
  /// **Parameters:**
  /// - [onResult]: Called for each detection result (once per second)
  /// - [onError]: Called if an error occurs during recording or inference
  /// - [confidenceThreshold]: Minimum confidence (0.0-1.0) required to classify as snoring. Default: 0.5
  /// - [verboseDebug]: Enable verbose console logging for debugging. Default: false
  ///
  /// **Returns:** A [Stream] of [DetectionResult]s that emits once per second
  ///
  /// **Throws:**
  /// - [StateError] if detection is already running
  /// - [Exception] if microphone permission is denied or recording fails
  ///
  /// **Platform Requirements:**
  /// - iOS: Add `NSMicrophoneUsageDescription` to Info.plist
  /// - Android: Add `RECORD_AUDIO` permission to AndroidManifest.xml
  ///
  /// Example:
  /// ```dart
  /// await detector.startLiveDetection(
  ///   confidenceThreshold: 0.7,
  ///   onResult: (result) {
  ///     print('Snoring: ${result.isSnoring}');
  ///   },
  /// );
  /// ```
  Future<Stream<DetectionResult>> startLiveDetection({
    Function(DetectionResult result)? onResult,
    Function(dynamic error)? onError,
    double confidenceThreshold = 0.5,
    bool verboseDebug = false,
  }) async {
    _ensureInitialized();

    if (_liveDetectionController != null) {
      throw StateError(
          'Live detection already running. Call stopLiveDetection() first.');
    }

    _liveDetectionController = StreamController<DetectionResult>.broadcast();

    _currentThreshold = confidenceThreshold;

    try {
      await _recorderService.startRecording(
        onAudioWindow: (audioWindow) async {
          try {
            final result = await _detectFromAudioWindow(audioWindow);
            _liveDetectionController?.add(result);
            onResult?.call(result);
          } catch (e) {
            onError?.call(e);
          }
        },
        verboseDebug: verboseDebug,
      );
    } catch (e) {
      _liveDetectionController?.close();
      _liveDetectionController = null;
      rethrow;
    }

    return _liveDetectionController!.stream;
  }

  /// Stops live audio detection and releases microphone resources.
  ///
  /// Safe to call even if detection is not running.
  ///
  /// Example:
  /// ```dart
  /// await detector.stopLiveDetection();
  /// ```
  Future<void> stopLiveDetection() async {
    if (_liveDetectionController == null) {
      return;
    }

    await _recorderService.stopRecording();
    await _liveDetectionController?.close();
    _liveDetectionController = null;
  }

  /// Detects snoring from a pre-recorded audio file.
  ///
  /// Analyzes the audio file in 1-second windows and returns results for each window.
  ///
  /// **Parameters:**
  /// - [filePath]: Absolute path to the audio file
  /// - [sampleRate]: Original sample rate of the audio (defaults to 16000 Hz if not specified)
  ///
  /// **Returns:** A list of [DetectionResult]s, one per 1-second window
  ///
  /// **Throws:**
  /// - [Exception] if file doesn't exist, is too short (< 1 second), or can't be read
  ///
  /// **Note:** Currently supports raw PCM files. WAV/MP3 support planned for future versions.
  ///
  /// Example:
  /// ```dart
  /// final results = await detector.detectFromFile(
  ///   '/path/to/recording.wav',
  ///   sampleRate: 16000,
  /// );
  ///
  /// print('Found ${results.where((r) => r.isSnoring).length} snoring events');
  /// ```
  Future<List<DetectionResult>> detectFromFile(
    String filePath, {
    int? sampleRate,
  }) async {
    _ensureInitialized();

    try {
      // Read audio file
      final audioData = await _readAudioFile(filePath, sampleRate);

      // Extract 1-second windows
      final windows = AudioProcessor.extractWindows(audioData);

      if (windows.isEmpty) {
        throw Exception(
            'Audio file too short. Need at least 1 second of audio.');
      }

      // Process each window
      final results = <DetectionResult>[];
      for (final window in windows) {
        final result = await _detectFromAudioWindow(window);
        results.add(result);
      }

      return results;
    } catch (e) {
      throw Exception('Failed to detect from file: $e');
    }
  }

  /// Detects snoring from a single 1-second audio window.
  ///
  /// **Parameters:**
  /// - [audioWindow]: Exactly 16000 normalized audio samples (-1.0 to 1.0)
  ///
  /// **Returns:** A [DetectionResult] for this audio window
  ///
  /// **Throws:** [ArgumentError] if window size is not exactly 16000 samples
  ///
  /// This is a low-level API. Most users should use [startLiveDetection]
  /// or [detectFromFile] instead.
  Future<DetectionResult> detectFromAudioWindow(
      List<double> audioWindow) async {
    _ensureInitialized();
    return _detectFromAudioWindow(audioWindow);
  }

  /// Internal method to process a single audio window
  Future<DetectionResult> _detectFromAudioWindow(
      List<double> audioWindow) async {
    // Normalize audio
    final normalizedAudio = AudioProcessor.normalize(audioWindow);

    // Extract spectrogram features
    final features = AudioProcessor.computeSpectrogramFeatures(normalizedAudio);

    // Run inference with current threshold
    return await _tfliteService.runInference(features,
        threshold: _currentThreshold);
  }

  /// Read and preprocess audio file
  Future<List<double>> _readAudioFile(String filePath, int? sampleRate) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // For now, we'll support raw PCM files
    // TODO: Add support for WAV, MP3, etc. using audio_processing packages
    final bytes = await file.readAsBytes();

    // Assume 16-bit PCM for now
    final samples = AudioProcessor.bytesToInt16(bytes);
    final audioData = AudioProcessor.int16ToDouble(samples);

    // Resample if needed
    if (sampleRate != null && sampleRate != AudioProcessor.targetSampleRate) {
      return AudioProcessor.resample(audioData, sampleRate);
    }

    return audioData;
  }

  /// Whether live detection is currently running.
  ///
  /// Returns `true` if [startLiveDetection] has been called and
  /// [stopLiveDetection] has not been called yet.
  bool get isLiveDetectionRunning => _liveDetectionController != null;

  /// Whether the detector has been successfully initialized.
  ///
  /// Returns `true` after [initialize] completes successfully.
  bool get isInitialized => _isInitialized;

  /// Ensure detector is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'SnoreDetector not initialized. Call initialize() first.');
    }
  }

  /// Disposes all resources and stops any active detection.
  ///
  /// Always call this when done using the detector to free memory
  /// and release system resources.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   detector.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    stopLiveDetection();
    _recorderService.dispose();
    _tfliteService.dispose();
    _isInitialized = false;
  }
}
