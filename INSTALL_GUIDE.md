# Installation & Setup Guide

## Quick Install

### Option 1: Local Package (Development)

If you're working with the package locally:

```yaml
# pubspec.yaml
dependencies:
  snore_detection:
    path: ../snore_detection
```

### Option 2: From Git Repository

```yaml
# pubspec.yaml
dependencies:
  snore_detection:
    git:
      url: https://github.com/metanav/Snoring_Guardian.git
      path: snore_detection
```

### Option 3: From pub.dev (When Published)

```yaml
# pubspec.yaml
dependencies:
  snore_detection: ^0.2.0
```

## Platform Setup

### Android Configuration

1. **Minimum SDK Version**: Ensure `android/app/build.gradle` has:
   ```gradle
   android {
       defaultConfig {
           minSdkVersion 21  // Minimum required
       }
   }
   ```

2. **Permissions**: Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <uses-permission android:name="android.permission.RECORD_AUDIO" />
       <application>
           ...
       </application>
   </manifest>
   ```

### iOS Configuration

1. **Minimum iOS Version**: Ensure `ios/Podfile` has:
   ```ruby
   platform :ios, '12.0'  # Minimum required
   ```

2. **Microphone Permission**: Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access to detect snoring</string>
   ```

3. **Run pod install**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Verify Installation

Create a test file to verify the package is working:

```dart
// test_installation.dart
import 'package:snore_detection/snore_detection.dart';

Future<void> testInstallation() async {
  print('Testing Flutter Snore Detection package...');

  final detector = SnoreDetector();

  try {
    print('Initializing detector...');
    await detector.initialize();
    print('✅ Detector initialized successfully!');

    print('Package is working correctly.');
    detector.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

## Common Installation Issues

### Issue: "Target of URI doesn't exist"

**Solution**: Run `flutter pub get` in your project directory:
```bash
flutter pub get
```

### Issue: "MissingPluginException"

**Solution**:
1. Stop your app
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. For iOS: `cd ios && pod install && cd ..`
5. Rebuild and run your app

### Issue: "Execution failed for task ':app:checkDebugAarMetadata'"

**Solution**: Update your `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Update this
    }
}
```

### Issue: Xcode build fails on iOS

**Solution**:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

### Issue: "tflite_flutter" native library not found

**Solution**: The package will automatically download the TFLite native libraries on first build. Ensure you have internet connection during the first build.

## Dependencies

The package uses the following dependencies:

- **tflite_flutter** (^0.9.0): TensorFlow Lite runtime for Flutter
- **record** (^5.0.4): Audio recording capabilities
- **permission_handler** (^11.3.0): Runtime permissions handling
- **path_provider** (^2.1.2): File system access
- **fftea** (^1.0.0): Fast Fourier Transform for audio processing

All dependencies will be automatically installed when you run `flutter pub get`.

## Verify Your Setup

Run these commands to verify everything is set up correctly:

```bash
# Check Flutter version (should be 3.0.0 or higher)
flutter --version

# Check for any setup issues
flutter doctor

# Get dependencies
flutter pub get

# Analyze for any errors
flutter analyze

# Run the example app
cd example
flutter run
```

## Next Steps

Once installation is complete:

1. Read the [Getting Started Guide](GETTING_STARTED.md)
2. Check out the [API Documentation](API_DOCUMENTATION.md)
3. Run the [Example App](example/README.md)
4. Start building!

## Support

If you encounter any installation issues not covered here:

1. Check the [GitHub Issues](https://github.com/metanav/Snoring_Guardian/issues)
2. Create a new issue with:
   - Your Flutter version (`flutter --version`)
   - Your platform (Android/iOS)
   - Full error message
   - Steps to reproduce

## Testing the Installation

After installation, test with this minimal example:

```dart
import 'package:flutter/material.dart';
import 'package:snore_detection/snore_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final detector = SnoreDetector();
  await detector.initialize();
  print('Package installed and working!');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Flutter Snore Detection is ready!'),
        ),
      ),
    );
  }
}
```

If this runs without errors, your installation is successful!