import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/audio_processor.dart';

/// Service for recording and processing live audio
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  bool _isRecording = false;

  final List<int> _audioBuffer = [];
  static const int _bufferSizeSeconds = 1;
  static const int _bufferSizeSamples =
      AudioProcessor.targetSampleRate * _bufferSizeSeconds;

  /// Check and request microphone permission
  Future<bool> requestPermission() async {
    // First check if permission is already granted
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    // Request permission
    final newStatus = await Permission.microphone.request();
    return newStatus.isGranted;
  }

  /// Start recording with a callback for each audio window
  Future<void> startRecording({
    required Function(List<double> audioWindow) onAudioWindow,
    bool verboseDebug = false,
  }) async {
    if (_isRecording) {
      return;
    }

    // Check permission using record package's hasPermission
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    // Clear buffer
    _audioBuffer.clear();

    // Configure recording
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: AudioProcessor.targetSampleRate,
      numChannels: 1, // Mono
      bitRate: 128000,
    );

    // Start streaming
    final stream = await _recorder.startStream(config);

    _isRecording = true;

    // Process audio stream
    _audioStreamSubscription = stream.listen((audioData) {
      _processAudioChunk(audioData, onAudioWindow, verboseDebug);
    });
  }

  /// Process incoming audio chunks
  void _processAudioChunk(
    Uint8List audioData,
    Function(List<double> audioWindow) onAudioWindow,
    bool verboseDebug,
  ) {
    // Convert bytes to Int16 PCM samples
    final samples = AudioProcessor.bytesToInt16(audioData);

    // Add to buffer
    _audioBuffer.addAll(samples);

    if (verboseDebug) {
      print(
          '🎤 Audio buffer: ${_audioBuffer.length}/$_bufferSizeSamples samples');
    }

    // Process complete windows
    while (_audioBuffer.length >= _bufferSizeSamples) {
      if (verboseDebug) {
        print('✅ Processing 1-second audio window...');
      }

      // Extract window
      final windowSamples = _audioBuffer.sublist(0, _bufferSizeSamples);
      _audioBuffer.removeRange(0, _bufferSizeSamples);

      // Convert to normalized doubles
      final audioWindow = AudioProcessor.int16ToDouble(windowSamples);

      // Callback with audio window
      onAudioWindow(audioWindow);
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    await _recorder.stop();
    _isRecording = false;
    _audioBuffer.clear();
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Dispose resources
  void dispose() {
    stopRecording();
    _recorder.dispose();
  }
}
