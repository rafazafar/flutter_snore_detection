# Getting Started with Flutter Snore Detection

## Quick Start Guide

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  snore_detection: ^0.2.0
```

Or if using locally:

```yaml
dependencies:
  snore_detection:
    path: ../snore_detection
```

Then run:

```bash
flutter pub get
```

### 2. Platform Configuration

#### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <application>
        ...
    </application>
</manifest>
```

#### iOS

Add microphone permission to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to detect snoring</string>
```

### 3. Basic Implementation

#### Live Detection Example

```dart
import 'package:flutter/material.dart';
import 'package:snore_detection/snore_detection.dart';

class SnoreDetectionScreen extends StatefulWidget {
  @override
  State<SnoreDetectionScreen> createState() => _SnoreDetectionScreenState();
}

class _SnoreDetectionScreenState extends State<SnoreDetectionScreen> {
  final SnoreDetector _detector = SnoreDetector();
  DetectionResult? _latestResult;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    try {
      await _detector.initialize();
      print('Detector initialized successfully');
    } catch (e) {
      print('Failed to initialize: $e');
    }
  }

  Future<void> _startDetection() async {
    setState(() => _isDetecting = true);

    await _detector.startLiveDetection(
      onResult: (result) {
        setState(() => _latestResult = result);

        if (result.isSnoring && result.confidence > 0.9) {
          print('High confidence snoring detected!');
          // Trigger alert, vibration, etc.
        }
      },
      onError: (error) {
        print('Detection error: $error');
      },
    );
  }

  Future<void> _stopDetection() async {
    await _detector.stopLiveDetection();
    setState(() => _isDetecting = false);
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Snore Detection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_latestResult != null) ...[
              Icon(
                _latestResult!.isSnoring ? Icons.volume_up : Icons.volume_off,
                size: 100,
                color: _latestResult!.isSnoring ? Colors.red : Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                _latestResult!.isSnoring ? 'SNORING' : 'NO SNORING',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Confidence: ${(_latestResult!.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 18),
              ),
            ],
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isDetecting ? _stopDetection : _startDetection,
              child: Text(_isDetecting ? 'Stop' : 'Start Detection'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### File Detection Example

```dart
import 'package:snore_detection/snore_detection.dart';

Future<void> analyzeAudioFile(String filePath) async {
  final detector = SnoreDetector();

  // Initialize
  await detector.initialize();

  // Analyze file
  final results = await detector.detectFromFile(filePath);

  // Process results
  print('Analyzed ${results.length} windows');

  int snoringWindows = results.where((r) => r.isSnoring).length;
  double snoringPercentage = (snoringWindows / results.length) * 100;

  print('Snoring detected in ${snoringPercentage.toStringAsFixed(1)}% of audio');

  // Find highest confidence snoring moment
  final snoringResults = results.where((r) => r.isSnoring).toList();
  if (snoringResults.isNotEmpty) {
    snoringResults.sort((a, b) => b.confidence.compareTo(a.confidence));
    print('Highest confidence: ${snoringResults.first.confidence}');
  }

  // Clean up
  detector.dispose();
}
```

### 4. Advanced Features

#### Continuous Monitoring with Smart Alerts

```dart
class SmartSnoreMonitor {
  final SnoreDetector _detector = SnoreDetector();
  final List<DetectionResult> _recentResults = [];
  final int _windowSize = 10;
  final int _alertThreshold = 5;

  Future<void> startMonitoring({
    required Function() onSnoreAlert,
  }) async {
    await _detector.initialize();

    await _detector.startLiveDetection(
      onResult: (result) {
        _recentResults.add(result);

        // Keep only recent results
        if (_recentResults.length > _windowSize) {
          _recentResults.removeAt(0);
        }

        // Check for sustained snoring
        final snoringCount = _recentResults
            .where((r) => r.isSnoring && r.confidence > 0.85)
            .length;

        if (snoringCount >= _alertThreshold) {
          onSnoreAlert();
        }
      },
    );
  }

  Future<void> stopMonitoring() async {
    await _detector.stopLiveDetection();
    _recentResults.clear();
  }

  void dispose() {
    _detector.dispose();
  }
}
```

### 5. Testing

Run the example app:

```bash
cd snore_detection/example
flutter run
```

### 6. Common Issues

#### Issue: "Microphone permission denied"

**Solution**: Ensure permissions are properly configured in platform-specific files and request permission at runtime:

```dart
await _detector.startLiveDetection(...);
```

The package automatically requests permissions when starting live detection.

#### Issue: "Model failed to load"

**Solution**: Ensure the asset is properly configured in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - packages/snore_detection/assets/models/snore_detection.tflite
```

#### Issue: "Audio quality is poor"

**Solution**:
- Ensure device is in quiet environment
- Check microphone is not obstructed
- Test with different confidence thresholds
- Consider filtering results over multiple windows

### 7. Next Steps

- Read the [API Documentation](API_DOCUMENTATION.md) for detailed API reference
- Check the [example app](example/lib/main.dart) for complete implementation
- Review model specifications and limitations in README

### 8. Support

For issues, feature requests, or contributions, visit:
https://github.com/metanav/Snoring_Guardian/issues