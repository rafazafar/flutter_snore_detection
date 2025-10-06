## 0.3.0

* **NEW:** Add `requestMicrophonePermission()` method to `SnoreDetector` for explicit permission handling
* **FIX:** Resolve Android microphone access issues by properly requesting runtime permissions
* **IMPROVED:** Update example app to request permissions before starting detection
* **IMPROVED:** Add user-friendly permission denial feedback in example app

## 0.2.0

* Update package dependencies to latest compatible releases (path_provider ^2.1.5, permission_handler ^12.0.1, fftea ^1.5.0)
* Adopt flutter_lints 6.0.0 for updated lint rules

## 0.1.0

* Initial release of Flutter Snore Detection package
* Real-time snoring detection from device microphone
* File-based detection for analyzing pre-recorded audio
* Quantized TensorFlow Lite model (214KB) for efficient on-device inference
* Configurable confidence thresholds to reduce false positives
* Stream-based API for live detection results
* Cross-platform support (iOS and Android)
* Comprehensive API documentation with examples
* Unit tests for core functionality
* Example app demonstrating live and file detection