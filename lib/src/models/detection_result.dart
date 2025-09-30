/// Result of a single snore detection inference.
///
/// Contains confidence scores for both snoring and noise classes,
/// along with the final classification decision and timestamp.
class DetectionResult {
  /// Whether snoring was detected in this audio window.
  ///
  /// This is `true` if the snoring confidence exceeds the configured
  /// threshold and is higher than the noise confidence.
  final bool isSnoring;

  /// Confidence score for the snoring class (0.0 to 1.0).
  ///
  /// Higher values indicate stronger likelihood that snoring was present
  /// in the analyzed audio window.
  final double snoringConfidence;

  /// Confidence score for the noise class (0.0 to 1.0).
  ///
  /// Higher values indicate stronger likelihood that only noise (no snoring)
  /// was present in the analyzed audio window.
  final double noiseConfidence;

  /// Timestamp when this detection occurred.
  ///
  /// Defaults to [DateTime.now()] if not explicitly provided.
  final DateTime timestamp;

  /// Creates a detection result with explicit classification.
  ///
  /// Use [DetectionResult.withThreshold] for automatic threshold-based classification.
  DetectionResult({
    required this.isSnoring,
    required this.snoringConfidence,
    required this.noiseConfidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a detection result by applying a confidence threshold.
  ///
  /// Classifies as snoring only if:
  /// - [snoringConfidence] exceeds [threshold]
  /// - [snoringConfidence] is higher than [noiseConfidence]
  ///
  /// This helps reduce false positives by requiring a minimum confidence level.
  ///
  /// Example:
  /// ```dart
  /// final result = DetectionResult.withThreshold(
  ///   snoringConfidence: 0.85,
  ///   noiseConfidence: 0.15,
  ///   threshold: 0.7,  // Require 70% confidence
  /// );
  /// print(result.isSnoring); // true (85% > 70% and 85% > 15%)
  /// ```
  factory DetectionResult.withThreshold({
    required double snoringConfidence,
    required double noiseConfidence,
    required double threshold,
    DateTime? timestamp,
  }) {
    // Only classify as snoring if confidence exceeds threshold
    final isSnoring =
        snoringConfidence > threshold && snoringConfidence > noiseConfidence;

    return DetectionResult(
      isSnoring: isSnoring,
      snoringConfidence: snoringConfidence,
      noiseConfidence: noiseConfidence,
      timestamp: timestamp,
    );
  }

  /// Returns the confidence score of the predicted class.
  ///
  /// Returns [snoringConfidence] if [isSnoring] is true,
  /// otherwise returns [noiseConfidence].
  double get confidence => isSnoring ? snoringConfidence : noiseConfidence;

  @override
  String toString() {
    return 'DetectionResult(isSnoring: $isSnoring, confidence: ${confidence.toStringAsFixed(3)}, '
        'snoringConf: ${snoringConfidence.toStringAsFixed(3)}, '
        'noiseConf: ${noiseConfidence.toStringAsFixed(3)})';
  }
}
