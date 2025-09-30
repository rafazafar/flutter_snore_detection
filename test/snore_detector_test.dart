import 'package:flutter_test/flutter_test.dart';
import 'package:snore_detection/snore_detection.dart';

void main() {
  group('SnoreDetector', () {
    test('DetectionResult basic functionality', () {
      final result = DetectionResult(
        isSnoring: true,
        snoringConfidence: 0.9,
        noiseConfidence: 0.1,
      );

      expect(result.isSnoring, isTrue);
      expect(result.confidence, 0.9);
    });

    test('DetectionResult withThreshold applies threshold correctly', () {
      // Above threshold and dominant
      var result = DetectionResult.withThreshold(
        snoringConfidence: 0.8,
        noiseConfidence: 0.2,
        threshold: 0.7,
      );
      expect(result.isSnoring, isTrue);

      // Below threshold
      result = DetectionResult.withThreshold(
        snoringConfidence: 0.6,
        noiseConfidence: 0.4,
        threshold: 0.7,
      );
      expect(result.isSnoring, isFalse);

      // Above threshold but not dominant
      result = DetectionResult.withThreshold(
        snoringConfidence: 0.45,
        noiseConfidence: 0.55,
        threshold: 0.4,
      );
      expect(result.isSnoring, isFalse);
    });

    // Note: Full integration tests with TFLite model, audio recording,
    // and platform-specific components require platform-specific test
    // setup. These unit tests verify the core logic and API surface.
    // For full integration testing, run the example app on a device.
  });
}
