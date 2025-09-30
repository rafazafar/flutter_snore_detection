# Flutter Snore Detection - Example App

This example app demonstrates how to use the `snore_detection` package for real-time snoring detection.

## Running the Example

### Prerequisites

- Flutter SDK installed (3.0.0 or higher)
- Android device/emulator or iOS device/simulator
- Microphone access on your test device

### Steps

1. **Navigate to the example directory**:
   ```bash
   cd example
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Connect a device or start an emulator**:
   ```bash
   # List available devices
   flutter devices
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

   Or for a specific platform:
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios
   ```

## Using the Example App

1. **Tap "Initialize Detector"** - This loads the TFLite model (takes 1-2 seconds)

2. **Tap "Start Detection"** - The app will:
   - Request microphone permission (first time only)
   - Start capturing audio from your device microphone
   - Display real-time detection results every second

3. **Test snoring detection**:
   - Make snoring sounds near the microphone
   - Watch the confidence scores update in real-time
   - See the history of recent detections at the bottom

4. **Tap "Stop Detection"** to stop the microphone

## Features Demonstrated

- ✅ Model initialization
- ✅ Real-time audio detection with streaming results
- ✅ Visual feedback (icons, colors, confidence display)
- ✅ Recent detection history (last 10 results)
- ✅ Start/stop controls
- ✅ Error handling
- ✅ Proper resource cleanup

## What to Expect

### When No Snoring is Detected:
- 🟢 Green icon (volume off)
- Status: "No snoring"
- High confidence in "Noise" class

### When Snoring is Detected:
- 🔴 Red icon (volume up)
- Status: "Snoring detected!"
- High confidence in "Snoring" class

## Testing Tips

1. **Test in a quiet room** for best results
2. **Position microphone correctly** - not obstructed
3. **Play snoring sounds** from online videos if needed
4. **Try different volumes** to see confidence variations
5. **Check recent history** to see pattern over time

## Code Structure

```
lib/
└── main.dart                 # Main example app
    ├── MyApp                 # App root
    └── SnoreDetectionDemo    # Main demo screen
        ├── _initialize()     # Initialize detector
        ├── _startDetection() # Start live detection
        ├── _stopDetection()  # Stop detection
        └── build()           # UI layout
```

## Troubleshooting

### "Microphone permission denied"
- Go to device Settings > Apps > Example App > Permissions
- Enable microphone permission manually
- Restart the app

### "Failed to initialize detector"
- Make sure you ran `flutter pub get` in the example directory
- Check that the parent package dependencies are resolved
- Try `flutter clean && flutter pub get`

### "No detection results appearing"
- Ensure microphone is working (test with other apps)
- Check device volume/microphone settings
- Try making louder snoring sounds
- Verify you tapped "Start Detection" after initializing

## Next Steps

- Modify the example code to experiment with different features
- Adjust the confidence threshold for triggering alerts
- Add vibration or sound alerts when snoring is detected
- Try implementing file-based detection

## Support

For issues with the example app or package, please visit:
https://github.com/metanav/Snoring_Guardian/issues