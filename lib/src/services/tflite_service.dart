import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection_result.dart';

/// TensorFlow Lite inference service for snore detection
class TFLiteService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model configuration
  static const String _modelPath =
      'packages/snore_detection/assets/models/snore_detection.tflite';
  static const int _inputSize = 4160; // Spectrogram features
  static const int _outputSize = 2; // [noise, snoring]

  // Quantization parameters (from model metadata)
  static const double _inputScale = 0.003921568859368563;
  static const int _inputZeroPoint = -128;
  static const double _outputScale = 0.00390625;
  static const int _outputZeroPoint = -128;

  /// Initialize the TFLite interpreter
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Verify input/output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('TFLite Model loaded successfully');
      print('Input shape: $inputShape');
      print('Output shape: $outputShape');

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TFLite model: $e');
    }
  }

  /// Run inference on spectrogram features
  Future<DetectionResult> runInference(List<double> features,
      {double threshold = 0.5}) async {
    if (!_isInitialized) {
      throw StateError(
          'TFLiteService not initialized. Call initialize() first.');
    }

    if (features.length != _inputSize) {
      throw ArgumentError(
          'Expected $_inputSize features, got ${features.length}');
    }

    try {
      // Quantize input features to INT8
      final quantizedInput = _quantizeInput(features);

      // Prepare input tensor
      final input = [quantizedInput];

      // Prepare output tensor
      final output = List.filled(1, List<int>.filled(_outputSize, 0));

      // Run inference
      _interpreter!.run(input, output);

      // Dequantize output
      final probabilities = _dequantizeOutput(output[0]);

      // Create result with threshold
      final noiseProb = probabilities[0];
      final snoringProb = probabilities[1];

      return DetectionResult.withThreshold(
        snoringConfidence: snoringProb,
        noiseConfidence: noiseProb,
        threshold: threshold,
      );
    } catch (e) {
      throw Exception('Inference failed: $e');
    }
  }

  /// Quantize float features to INT8 using model's quantization parameters
  List<int> _quantizeInput(List<double> features) {
    return features.map((f) {
      final quantized = (f / _inputScale).round() + _inputZeroPoint;
      // Clamp to INT8 range [-128, 127]
      return quantized.clamp(-128, 127);
    }).toList();
  }

  /// Dequantize INT8 output to probabilities
  List<double> _dequantizeOutput(List<int> quantized) {
    final dequantized = quantized.map((q) {
      return (q - _outputZeroPoint) * _outputScale;
    }).toList();

    // Apply softmax to get probabilities
    return _softmax(dequantized);
  }

  /// Apply softmax function to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    // Find max for numerical stability
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);

    // Compute exp(x - max)
    final expValues = logits.map((x) => _exp(x - maxLogit)).toList();

    // Compute sum of exponentials
    final sumExp = expValues.reduce((a, b) => a + b);

    // Normalize
    return expValues.map((exp) => exp / sumExp).toList();
  }

  /// Fast exponential approximation for mobile devices
  double _exp(double x) {
    // Use Dart's built-in exp for accuracy
    return x.exp();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

extension on double {
  double exp() {
    // Using Taylor series approximation for better performance
    if (this < -10) return 0.0;
    if (this > 10) return 22026.465794806718; // e^10

    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 20; i++) {
      term *= this / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }
    return result;
  }
}
