import 'package:flutter/material.dart';
import 'package:snore_detection/snore_detection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snore Detection Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SnoreDetectionDemo(),
    );
  }
}

class SnoreDetectionDemo extends StatefulWidget {
  const SnoreDetectionDemo({super.key});

  @override
  State<SnoreDetectionDemo> createState() => _SnoreDetectionDemoState();
}

class _SnoreDetectionDemoState extends State<SnoreDetectionDemo> {
  final SnoreDetector _detector = SnoreDetector();
  bool _isInitialized = false;
  bool _isDetecting = false;
  DetectionResult? _latestResult;
  final List<DetectionResult> _recentResults = [];
  String _statusMessage = 'Tap "Initialize" to start';
  double _confidenceThreshold = 0.5; // 50% threshold
  bool _verboseDebug = true; // Debug logging toggle

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _statusMessage = 'Initializing...';
    });

    try {
      await _detector.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready! Tap "Start Detection" to begin.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _startDetection() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please initialize first')),
      );
      return;
    }

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Listening... (Processing 1-second windows)';
      _recentResults.clear();
    });

    try {
      await _detector.startLiveDetection(
        confidenceThreshold: _confidenceThreshold,
        verboseDebug: _verboseDebug,
        onResult: (result) {
          if (_verboseDebug) {
            // ignore: avoid_print
            print(
                '📊 Detection result: ${result.isSnoring ? "SNORING" : "NOISE"} '
                '(confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)');
          }

          setState(() {
            _latestResult = result;
            _recentResults.insert(0, result);
            if (_recentResults.length > 10) {
              _recentResults.removeLast();
            }

            if (result.isSnoring) {
              _statusMessage =
                  '🔴 Snoring detected! (${(result.confidence * 100).toStringAsFixed(1)}%)';
            } else {
              _statusMessage =
                  '🟢 No snoring (${(result.confidence * 100).toStringAsFixed(1)}%)';
            }
          });
        },
        onError: (error) {
          if (_verboseDebug) {
            // ignore: avoid_print
            print('❌ Detection error: $error');
          }
          setState(() {
            _statusMessage = 'Error: $error';
          });
        },
      );
    } catch (e) {
      if (_verboseDebug) {
        // ignore: avoid_print
        print('❌ Failed to start: $e');
      }
      setState(() {
        _isDetecting = false;
        _statusMessage = 'Error starting detection: $e';
      });
    }
  }

  Future<void> _stopDetection() async {
    await _detector.stopLiveDetection();
    setState(() {
      _isDetecting = false;
      _statusMessage = 'Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snore Detection Demo'),
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Latest Result Card
              if (_latestResult != null)
                Card(
                  color: _latestResult!.isSnoring
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _latestResult!.isSnoring
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              size: 32,
                              color: _latestResult!.isSnoring
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latestResult!.isSnoring
                                        ? 'SNORING'
                                        : 'NOISE',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _latestResult!.isSnoring
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Confidence: ${(_latestResult!.confidence * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildConfidenceChip(
                              'Snoring',
                              _latestResult!.snoringConfidence,
                              Colors.red,
                            ),
                            _buildConfidenceChip(
                              'Noise',
                              _latestResult!.noiseConfidence,
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Settings Card
              if (_isInitialized) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Confidence Threshold Slider
                        if (!_isDetecting) ...[
                          Text(
                            'Confidence Threshold: ${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _confidenceThreshold,
                            min: 0.1,
                            max: 0.9,
                            divisions: 16,
                            label:
                                '${(_confidenceThreshold * 100).toStringAsFixed(0)}%',
                            onChanged: (value) {
                              setState(() => _confidenceThreshold = value);
                            },
                          ),
                          const Text(
                            'Higher threshold = fewer false positives',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],

                        // Verbose Debug Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Verbose Debug Logging',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Log detection results to console',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: _verboseDebug,
                          onChanged: (value) {
                            setState(() => _verboseDebug = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Control Buttons
              if (!_isInitialized)
                ElevatedButton.icon(
                  onPressed: _initialize,
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Initialize Detector'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

              if (_isInitialized && !_isDetecting)
                ElevatedButton.icon(
                  onPressed: _startDetection,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Detection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

              if (_isDetecting)
                ElevatedButton.icon(
                  onPressed: _stopDetection,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Detection'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 16),

              // Recent Results
              if (_recentResults.isNotEmpty) ...[
                const Text(
                  'Recent Detections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recentResults.length,
                    itemBuilder: (context, index) {
                      final result = _recentResults[index];
                      return ListTile(
                        leading: Icon(
                          result.isSnoring ? Icons.volume_up : Icons.volume_off,
                          color: result.isSnoring ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          result.isSnoring ? 'Snoring' : 'Noise',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                        ),
                        trailing: Text(
                          _formatTime(result.timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceChip(String label, double confidence, Color color) {
    return Chip(
      label: Text(
        '$label: ${(confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
