# Flutter Snore Detection

A Flutter package for detecting snoring in real-time audio streams or pre-recorded audio files using TensorFlow Lite.

## Features

- 🎤 **Live Audio Detection**: Real-time snoring detection from device microphone
- 📁 **File-Based Detection**: Analyze pre-recorded audio files
- 🚀 **Easy Integration**: Simple API for developers
- ⚡ **Efficient**: Uses quantized TensorFlow Lite model optimized for mobile devices
- 📱 **Cross-Platform**: Works on Android and iOS

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  snore_detection: ^0.3.0
```

Then run:
```bash
flutter pub get
```

For detailed installation instructions and platform setup, see the [Installation Guide](INSTALL_GUIDE.md).

## Usage

### Live Audio Detection

```dart
import 'package:snore_detection/snore_detection.dart';

// Initialize detector
final detector = SnoreDetector();
await detector.initialize();

// Request microphone permission
final hasPermission = await detector.requestMicrophonePermission();
if (!hasPermission) {
  print('Microphone permission denied');
  return;
}

// Start live detection
detector.startLiveDetection(
  onResult: (result) {
    print('Snoring detected: ${result.isSnoring}');
    print('Confidence: ${result.confidence}');
  },
);

// Stop detection
await detector.stopLiveDetection();
```

### File-Based Detection

```dart
import 'package:snore_detection/snore_detection.dart';

// Initialize detector
final detector = SnoreDetector();
await detector.initialize();

// Analyze audio file
final result = await detector.detectFromFile('/path/to/audio.wav');
print('Snoring detected: ${result.isSnoring}');
print('Confidence: ${result.confidence}');
```

## Running the Example App

To see the package in action, run the example app:

```bash
cd example
flutter pub get
flutter run
```

The example app demonstrates:
- Live audio detection with real-time results
- Visual feedback (icons, colors, confidence scores)
- Start/stop controls
- History of recent detections

Make sure you have a device or emulator connected, then select your target platform when prompted.

## Permissions

### Android

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Add to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to detect snoring</string>
```

## Model Information

- **Input**: 16 kHz mono audio, 1-second windows
- **Output**: Binary classification (noise vs snoring)
- **Model Type**: Quantized TensorFlow Lite (INT8)
- **Model Size**: 214 KB
- **Processing**: Spectrogram-based feature extraction
- **Inference Time**: ~50-100ms per 1-second window

## Documentation

- [Getting Started Guide](GETTING_STARTED.md) - Step-by-step tutorial with examples
- [API Documentation](API_DOCUMENTATION.md) - Complete API reference and advanced usage
- [Example App](example/) - Full working example with UI

## Troubleshooting

**Issue: Microphone permission denied**
- Ensure permissions are properly configured in platform-specific files
- Call `requestMicrophonePermission()` before starting detection (required on Android 6.0+ and iOS)

**Issue: Model fails to load**
- Make sure `flutter pub get` has been run
- Check that the asset is accessible in your build

**Issue: Low accuracy**
- Ensure quiet environment with minimal background noise
- Check microphone quality and placement
- Consider using confidence thresholds (e.g., > 0.85)

## License

MIT License - see LICENSE file for details

## Credits

Based on the [Snoring Guardian](https://github.com/metanav/Snoring_Guardian) project.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.