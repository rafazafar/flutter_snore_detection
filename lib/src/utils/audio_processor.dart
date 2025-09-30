import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

/// Audio preprocessing utilities for snore detection
class AudioProcessor {
  // Model configuration constants
  static const int targetSampleRate = 16000;
  static const int samplesPerWindow = 16000; // 1 second
  static const double frameLengthSec = 0.02; // 20ms
  static const double frameStrideSec = 0.01538; // ~15.38ms
  static const int fftLength = 128;
  static const int noiseFloorDb = -54;
  static const int expectedFeatures = 4160; // Output features for NN

  /// Resample audio to target sample rate (16kHz)
  static List<double> resample(List<double> audio, int originalSampleRate) {
    if (originalSampleRate == targetSampleRate) {
      return List.from(audio);
    }

    final ratio = targetSampleRate / originalSampleRate;
    final newLength = (audio.length * ratio).round();
    final resampled = List<double>.filled(newLength, 0.0);

    for (int i = 0; i < newLength; i++) {
      final srcIndex = i / ratio;
      final index1 = srcIndex.floor();
      final index2 = math.min(index1 + 1, audio.length - 1);
      final frac = srcIndex - index1;

      // Linear interpolation
      resampled[i] = audio[index1] * (1.0 - frac) + audio[index2] * frac;
    }

    return resampled;
  }

  /// Extract 1-second windows from audio
  static List<List<double>> extractWindows(List<double> audio) {
    final windows = <List<double>>[];

    for (int i = 0;
        i + samplesPerWindow <= audio.length;
        i += samplesPerWindow) {
      windows.add(audio.sublist(i, i + samplesPerWindow));
    }

    return windows;
  }

  /// Compute spectrogram features for a 1-second audio window
  static List<double> computeSpectrogramFeatures(List<double> audioWindow) {
    if (audioWindow.length != samplesPerWindow) {
      throw ArgumentError(
          'Audio window must be exactly $samplesPerWindow samples (1 second at ${targetSampleRate}Hz)');
    }

    final frameLengthSamples = (frameLengthSec * targetSampleRate).round();
    final frameStrideSamples = (frameStrideSec * targetSampleRate).round();

    final frames = <List<double>>[];

    // Extract overlapping frames
    for (int start = 0;
        start + frameLengthSamples <= audioWindow.length;
        start += frameStrideSamples) {
      frames.add(audioWindow.sublist(start, start + frameLengthSamples));
    }

    final spectrogramFeatures = <double>[];

    // Process each frame
    for (final frame in frames) {
      // Apply Hamming window
      final windowedFrame = _applyHammingWindow(frame);

      // Compute FFT
      final fftResult = _computeFFT(windowedFrame, fftLength);

      // Convert to power spectrum
      final powerSpectrum = _computePowerSpectrum(fftResult);

      // Apply log scale with noise floor
      final logSpectrum = _applyLogScale(powerSpectrum, noiseFloorDb);

      spectrogramFeatures.addAll(logSpectrum);
    }

    // Ensure we have the expected number of features
    if (spectrogramFeatures.length < expectedFeatures) {
      // Pad with zeros if needed
      spectrogramFeatures.addAll(
          List.filled(expectedFeatures - spectrogramFeatures.length, 0.0));
    } else if (spectrogramFeatures.length > expectedFeatures) {
      // Truncate if we have too many
      return spectrogramFeatures.sublist(0, expectedFeatures);
    }

    return spectrogramFeatures;
  }

  /// Apply Hamming window to reduce spectral leakage
  static List<double> _applyHammingWindow(List<double> frame) {
    final n = frame.length;
    final windowed = List<double>.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final window = 0.54 - 0.46 * math.cos(2.0 * math.pi * i / (n - 1));
      windowed[i] = frame[i] * window;
    }

    return windowed;
  }

  /// Compute FFT using fftea package
  static List<double> _computeFFT(List<double> signal, int fftSize) {
    // Pad or truncate to FFT size
    final padded = List<double>.filled(fftSize, 0.0);
    final copyLength = math.min(signal.length, fftSize);
    for (int i = 0; i < copyLength; i++) {
      padded[i] = signal[i];
    }

    // Perform FFT
    final fft = FFT(fftSize);
    final complexInput = Float64x2List(fftSize);
    for (int i = 0; i < fftSize; i++) {
      complexInput[i] = Float64x2(padded[i], 0.0);
    }

    fft.inPlaceFft(complexInput);

    // Extract magnitudes (only first half due to symmetry)
    final magnitudes = List<double>.filled(fftSize ~/ 2 + 1, 0.0);
    for (int i = 0; i < magnitudes.length; i++) {
      final real = complexInput[i].x;
      final imag = complexInput[i].y;
      magnitudes[i] = math.sqrt(real * real + imag * imag);
    }

    return magnitudes;
  }

  /// Compute power spectrum from FFT magnitudes
  static List<double> _computePowerSpectrum(List<double> magnitudes) {
    return magnitudes.map((m) => m * m).toList();
  }

  /// Apply log scale with noise floor
  static List<double> _applyLogScale(
      List<double> powerSpectrum, int noiseFloorDb) {
    final noiseFloorLinear = math.pow(10.0, noiseFloorDb / 10.0).toDouble();

    return powerSpectrum.map((power) {
      // Ensure minimum value
      final clampedPower = math.max(power, noiseFloorLinear);
      // Convert to dB scale
      return 10.0 * (math.log(clampedPower) / math.ln10);
    }).toList();
  }

  /// Normalize audio to [-1.0, 1.0] range
  static List<double> normalize(List<double> audio) {
    if (audio.isEmpty) return audio;

    final maxAbs = audio.map((s) => s.abs()).reduce(math.max);
    if (maxAbs == 0.0) return audio;

    return audio.map((s) => s / maxAbs).toList();
  }

  /// Convert Int16 PCM data to normalized doubles
  static List<double> int16ToDouble(List<int> pcmData) {
    return pcmData.map((sample) => sample / 32768.0).toList();
  }

  /// Convert bytes to Int16 PCM samples (little endian)
  static List<int> bytesToInt16(List<int> bytes) {
    final samples = <int>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      // Little endian: low byte first
      final sample = bytes[i] | (bytes[i + 1] << 8);
      // Convert unsigned to signed
      samples.add(sample > 32767 ? sample - 65536 : sample);
    }
    return samples;
  }
}
