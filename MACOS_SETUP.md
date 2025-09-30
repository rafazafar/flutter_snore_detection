# macOS Setup Guide for TFLite Flutter

**⚠️ Important:** macOS requires manual setup of TensorFlow Lite native libraries. For testing, we **strongly recommend using an iOS simulator instead** (see below).

## Option 1: Use iOS Simulator (Recommended - Easy Setup)

The easiest way to test the package is using an iOS simulator:

```bash
# Open Xcode and install iOS simulators
open -a Xcode

# Or create from command line
xcodebuild -downloadPlatform iOS

# List available simulators
xcrun simctl list devices available | grep iPhone

# Create an iPhone simulator if needed
xcrun simctl create "iPhone Test" "iPhone 15"

# Boot the simulator
xcrun simctl boot "iPhone Test"

# Open Simulator app
open -a Simulator

# Run your app
cd snore_detection/example
flutter run -d ios
```

## Option 2: Use Android Emulator (Also Easy)

Android Studio makes it easy to set up emulators:

```bash
# Install Android Studio from https://developer.android.com/studio

# Create an AVD (Android Virtual Device)
# Open Android Studio > Tools > Device Manager > Create Device

# Or use command line
flutter emulators
flutter emulators --launch <emulator_id>

# Run your app
cd snore_detection/example
flutter run -d android
```

## Option 3: Use Physical Device (Best for Testing)

### iOS Device:
```bash
# Connect iPhone via USB
# Trust the computer on your device
flutter devices
flutter run -d <device-id>
```

### Android Device:
```bash
# Enable Developer Options and USB Debugging on your device
# Connect via USB
flutter devices
flutter run -d <device-id>
```

---

## Option 4: macOS Native (Advanced - Manual Setup Required)

⚠️ **Warning:** This is complex and time-consuming. Only do this if you specifically need macOS support.

### Prerequisites

- Xcode Command Line Tools: `xcode-select --install`
- Bazelisk: `brew install bazelisk`
- TensorFlow source code

### Steps to Build TFLite Library for macOS

1. **Clone TensorFlow**:
   ```bash
   git clone https://github.com/tensorflow/tensorflow.git
   cd tensorflow
   git checkout v2.17.1  # Use a stable version
   ```

2. **Build for ARM64 (Apple Silicon)**:
   ```bash
   CC=clang CXX=clang++ bazelisk build \
     -c opt \
     --copt=-O3 \
     --copt=-flto \
     --linkopt=-flto \
     --define=tflite_enable_xnnpack=true \
     --cpu=darwin_arm64 \
     //tensorflow/lite/c:libtensorflowlite_c.dylib

   cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ~/arm64_libtensorflowlite_c.dylib
   ```

3. **Build for x86_64 (Intel)**:
   ```bash
   CC=clang CXX=clang++ bazelisk build \
     -c opt \
     --copt=-O3 \
     --copt=-flto \
     --linkopt=-flto \
     --define=tflite_enable_xnnpack=true \
     --cpu=darwin_x86_64 \
     //tensorflow/lite/c:libtensorflowlite_c.dylib

   cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.dylib ~/x86_64_libtensorflowlite_c.dylib
   ```

4. **Create Universal Binary**:
   ```bash
   lipo -create \
     ~/arm64_libtensorflowlite_c.dylib \
     ~/x86_64_libtensorflowlite_c.dylib \
     -output ~/libtensorflowlite_c.dylib
   ```

5. **Add to Xcode Project**:

   a. Open your Flutter macOS app in Xcode:
   ```bash
   open macos/Runner.xcworkspace
   ```

   b. Drag `libtensorflowlite_c.dylib` into the Xcode project under `Frameworks`

   c. In target settings:
      - Build Phases > Link Binary With Libraries > Add `libtensorflowlite_c.dylib`
      - Build Phases > Embed Frameworks > Add `libtensorflowlite_c.dylib`

   d. Set "Code Sign On Copy" to enabled

6. **Update Signing & Capabilities**:
   - In Xcode, select your target
   - Go to "Signing & Capabilities"
   - Ensure "Automatically manage signing" is enabled
   - Select your development team

7. **Rebuild and Run**:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d macos
   ```

### Troubleshooting Build Issues

**Issue: Bazel build fails**
- Make sure you have Xcode Command Line Tools: `xcode-select --install`
- Update Bazelisk: `brew upgrade bazelisk`
- Check TensorFlow version compatibility

**Issue: Library architecture mismatch**
- Verify you built for the correct architecture
- Use `lipo -info libtensorflowlite_c.dylib` to check architectures
- Ensure universal binary includes both arm64 and x86_64

**Issue: Code signing errors**
- In Xcode, disable "App Sandbox" under Capabilities
- Ensure "Hardened Runtime" is enabled with proper entitlements

---

## Why iOS Simulator is Better

✅ **iOS Simulator Advantages:**
- No manual library building required
- Works out of the box with tflite_flutter
- Same Flutter codebase as iOS devices
- Faster testing iteration
- Easier debugging

❌ **macOS Native Disadvantages:**
- Requires 1-2 hours to build TFLite library
- Complex Xcode project configuration
- Potential code signing issues
- Not well documented
- Bazel build complexity

## Recommendation

**For package development and testing:**
Use iOS simulator or Android emulator

**For production macOS app:**
Only tackle macOS native setup if you specifically need a macOS desktop app

**For quick testing right now:**
```bash
# Start iOS simulator and run
open -a Simulator
cd snore_detection/example
flutter run
# Select iOS simulator when prompted
```