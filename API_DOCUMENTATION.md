# Flutter Snore Detection - API Documentation

## Core Classes

### SnoreDetector

The main entry point for the snore detection package. Provides both live and file-based detection capabilities.

#### Methods

##### `Future<void> initialize()`

Initializes the TensorFlow Lite model. Must be called before any other methods.

**Throws**: `Exception` if initialization fails.

```dart
final detector = SnoreDetector();
await detector.initialize();
```

---

##### `Future<Stream<DetectionResult>> startLiveDetection({Function(DetectionResult)? onResult, Function(dynamic)? onError})`

Starts live audio detection from the device microphone.

**Parameters**:
- `onResult`: Optional callback called for each detection result
- `onError`: Optional callback called when errors occur

**Returns**: A broadcast `Stream<DetectionResult>`

**Throws**:
- `StateError` if not initialized or already running
- `Exception` if microphone permission denied

```dart
await detector.startLiveDetection(
  onResult: (result) {
    print('Snoring: ${result.isSnoring}');
    print('Confidence: ${result.confidence}');
  },
  onError: (error) {
    print('Error: $error');
  },
);
```

---

##### `Future<void> stopLiveDetection()`

Stops live audio detection.

```dart
await detector.stopLiveDetection();
```

---

##### `Future<List<DetectionResult>> detectFromFile(String filePath, {int? sampleRate})`

Analyzes a pre-recorded audio file for snoring.

**Parameters**:
- `filePath`: Path to the audio file (WAV, PCM formats supported)
- `sampleRate`: Optional sample rate of the input file (defaults to 16000)

**Returns**: List of `DetectionResult`s, one per 1-second window

**Throws**:
- `StateError` if not initialized
- `Exception` if file not found or processing fails

```dart
final results = await detector.detectFromFile(
  '/path/to/audio.wav',
  sampleRate: 44100, // Optional: specify if different from 16kHz
);

for (final result in results) {
  print('Window ${results.indexOf(result)}: ${result.isSnoring}');
}
```

---

##### `Future<DetectionResult> detectFromAudioWindow(List<double> audioWindow)`

Runs detection on a single 1-second audio window.

**Parameters**:
- `audioWindow`: Exactly 16000 normalized audio samples (1 second at 16kHz)

**Returns**: `DetectionResult`

**Throws**:
- `StateError` if not initialized
- `ArgumentError` if window size incorrect

```dart
// audioWindow must be List<double> with 16000 samples
final result = await detector.detectFromAudioWindow(audioWindow);
```

---

##### `void dispose()`

Releases all resources. Should be called when detector is no longer needed.

```dart
@override
void dispose() {
  detector.dispose();
  super.dispose();
}
```

---

#### Properties

##### `bool isInitialized`

Returns `true` if the detector has been initialized.

##### `bool isLiveDetectionRunning`

Returns `true` if live detection is currently active.

---

### DetectionResult

Represents the result of a snore detection inference.

#### Properties

##### `bool isSnoring`

`true` if snoring was detected, `false` for noise.

##### `double snoringConfidence`

Confidence score for snoring class (0.0 to 1.0).

##### `double noiseConfidence`

Confidence score for noise class (0.0 to 1.0).

##### `double confidence`

Returns the confidence of the predicted class (convenience getter).

##### `DateTime timestamp`

When the detection occurred.

#### Example

```dart
final result = DetectionResult(
  isSnoring: true,
  snoringConfidence: 0.95,
  noiseConfidence: 0.05,
);

print(result.isSnoring); // true
print(result.confidence); // 0.95 (confidence of predicted class)
print(result.toString()); // Formatted string representation
```

---

## Audio Processing Utilities

### AudioProcessor

Static utility class for audio preprocessing. Generally not needed by end users, but available for custom implementations.

#### Static Methods

##### `List<double> resample(List<double> audio, int originalSampleRate)`

Resamples audio to 16kHz using linear interpolation.

##### `List<List<double>> extractWindows(List<double> audio)`

Extracts non-overlapping 1-second windows from audio.

##### `List<double> computeSpectrogramFeatures(List<double> audioWindow)`

Computes 4160 spectrogram features required by the model.

##### `List<double> normalize(List<double> audio)`

Normalizes audio to [-1.0, 1.0] range.

##### `List<double> int16ToDouble(List<int> pcmData)`

Converts Int16 PCM samples to normalized doubles.

##### `List<int> bytesToInt16(List<int> bytes)`

Converts byte array to Int16 PCM samples (little endian).

---

## Model Specifications

### Input Requirements

- **Sample Rate**: 16000 Hz (16 kHz)
- **Channels**: Mono (1 channel)
- **Window Size**: 1 second (16000 samples)
- **Format**: Normalized float (-1.0 to 1.0)

### Feature Extraction

- **Method**: Spectrogram
- **Frame Length**: 20ms (320 samples)
- **Frame Stride**: ~15.38ms (246 samples)
- **FFT Size**: 128
- **Output Features**: 4160

### Model Output

- **Classes**: 2 (noise, snoring)
- **Type**: Softmax probabilities
- **Quantization**: INT8 with dequantization

---

## Platform Requirements

### Android

Minimum SDK: 21 (Android 5.0)

Required permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Minimum iOS: 12.0

Required key in `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to detect snoring</string>
```

---

## Error Handling

All async methods may throw exceptions. Recommended error handling:

```dart
try {
  await detector.initialize();
  await detector.startLiveDetection(
    onResult: (result) {
      // Handle result
    },
    onError: (error) {
      print('Detection error: $error');
    },
  );
} catch (e) {
  print('Failed to start detection: $e');
}
```

---

## Performance Considerations

- **Processing Time**: ~50-100ms per 1-second window on modern mobile devices
- **Memory Usage**: ~30MB for model + processing buffers
- **Battery Impact**: Moderate during live detection (continuous microphone use)

### Optimization Tips

1. Stop live detection when app is in background
2. Use file-based detection for batch processing
3. Consider throttling result updates in UI
4. Dispose detector when no longer needed

---

## Limitations

1. **Audio Format**: Currently supports raw PCM and WAV files. MP3/AAC support planned.
2. **Language**: Model trained on English speakers. Performance may vary for other languages/accents.
3. **Environment**: Works best in quiet environments. Loud background noise may affect accuracy.
4. **Latency**: Minimum 1-second delay due to window-based processing.

---

## Advanced Usage

### Custom Audio Pipeline

```dart
// Process custom audio data
final audioData = [...]; // Your audio samples
final windows = AudioProcessor.extractWindows(audioData);

for (final window in windows) {
  final normalized = AudioProcessor.normalize(window);
  final result = await detector.detectFromAudioWindow(normalized);
  print(result);
}
```

### Continuous Monitoring with Aggregation

```dart
final recentResults = <DetectionResult>[];

await detector.startLiveDetection(
  onResult: (result) {
    recentResults.add(result);
    if (recentResults.length > 10) {
      recentResults.removeAt(0);
    }

    // Trigger alert only if 5+ of last 10 detections were snoring
    final snoringCount = recentResults.where((r) => r.isSnoring).length;
    if (snoringCount >= 5) {
      triggerAlert();
    }
  },
);
```