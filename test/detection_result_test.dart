import 'package:flutter_test/flutter_test.dart';
import 'package:snore_detection/snore_detection.dart';

void main() {
  group('DetectionResult', () {
    test('creates result with explicit classification', () {
      final result = DetectionResult(
        isSnoring: true,
        snoringConfidence: 0.9,
        noiseConfidence: 0.1,
      );

      expect(result.isSnoring, isTrue);
      expect(result.snoringConfidence, 0.9);
      expect(result.noiseConfidence, 0.1);
      expect(result.confidence, 0.9);
      expect(result.timestamp, isA<DateTime>());
    });

    test('withThreshold classifies as snoring when above threshold', () {
      final result = DetectionResult.withThreshold(
        snoringConfidence: 0.85,
        noiseConfidence: 0.15,
        threshold: 0.7,
      );

      expect(result.isSnoring, isTrue);
      expect(result.confidence, 0.85);
    });

    test('withThreshold classifies as noise when below threshold', () {
      final result = DetectionResult.withThreshold(
        snoringConfidence: 0.65,
        noiseConfidence: 0.35,
        threshold: 0.7,
      );

      expect(result.isSnoring, isFalse);
      expect(result.confidence, 0.35);
    });

    test('withThreshold classifies as noise when snoring not dominant', () {
      final result = DetectionResult.withThreshold(
        snoringConfidence: 0.45,
        noiseConfidence: 0.55,
        threshold: 0.4,
      );

      expect(result.isSnoring, isFalse);
      expect(result.confidence, 0.55);
    });

    test('confidence returns correct value for noise classification', () {
      final result = DetectionResult(
        isSnoring: false,
        snoringConfidence: 0.3,
        noiseConfidence: 0.7,
      );

      expect(result.confidence, 0.7);
    });

    test('uses custom timestamp when provided', () {
      final customTime = DateTime(2025, 1, 1);
      final result = DetectionResult(
        isSnoring: true,
        snoringConfidence: 0.8,
        noiseConfidence: 0.2,
        timestamp: customTime,
      );

      expect(result.timestamp, customTime);
    });

    test('toString includes key information', () {
      final result = DetectionResult(
        isSnoring: true,
        snoringConfidence: 0.9,
        noiseConfidence: 0.1,
      );

      final str = result.toString();
      expect(str, contains('isSnoring: true'));
      expect(str, contains('0.900'));
    });
  });
}
